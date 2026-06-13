import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:light_waves/config/hive.dart';
import 'package:light_waves/constant/common.dart';
import 'package:light_waves/service/gacha_storage.dart';

class GachaPage extends StatefulWidget {
  const GachaPage({super.key});

  @override
  State<GachaPage> createState() => _GachaPageState();
}

class _GachaPageState extends State<GachaPage> {
  // 抽卡链接
  String _url = '';
  // 抽卡设置
  Map<String, dynamic> _gachaSetting = {...gachaSetting};
  Box setting = HiveData.setting;
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _url = setting.get(SettingKey.gachaUrl, defaultValue: '');
    textController.text = _url;
    _gachaSetting = jsonDecode(setting.get(
      SettingKey.gachaSetting,
      defaultValue: jsonEncode(gachaSetting),
    ));
  }

  // 是否有抽卡数据
  bool showGachaSetting() {
    return !_gachaSetting.values.contains('');
  }

  /// 解析抽卡链接，提取请求参数
  /// 参考 Rust 代码的 get_param_from_logfile 逻辑，
  /// 从 URL 中提取抽卡记录 API 所需的参数。
  ///
  /// 支持两种格式：
  /// 1. 参数在主 URL query 中: https://...?svr_id=...&player_id=...
  /// 2. 参数在 hash fragment 中（游戏官方格式）:
  ///    https://...#/record?svr_id=...&player_id=...
  ///
  /// 会自动过滤公告链接 (/announcement/) 等非抽卡链接。
  Map<String, String> _parseGachaUrl(String url) {
    final trimmed = url.trim();
    final uri = Uri.parse(trimmed);

    // 拒绝公告链接等非抽卡链接
    if (uri.path.contains('/announcement/') ||
        uri.path.contains('/announce/')) {
      throw const FormatException(
        '检测到公告链接，请复制抽卡记录页面的链接（包含 /gacha/ 路径）',
      );
    }

    String? queryString;

    // 优先检查 hash fragment 中的参数（游戏官方链接格式）
    // 官方链接形如: https://aki-gm-resources.aki-game.com/aki/gacha/index.html#/record?svr_id=...&...
    if (uri.hasFragment && uri.fragment.contains('?')) {
      queryString = uri.fragment.split('?').last;
    }
    // 其次检查主 URL 的 query 参数
    if (queryString == null || queryString.isEmpty) {
      if (uri.hasQuery) {
        queryString = uri.query;
      }
    }

    if (queryString == null || queryString.isEmpty) {
      throw const FormatException('未找到有效的查询参数，请检查是否完整复制了浏览器地址栏中的链接');
    }

    // 使用 Uri.splitQueryString 正确解码 URL 编码的参数
    return Uri.splitQueryString(queryString);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('设置链接'),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20,
              ),
              child: CupertinoTextField(
                controller: textController,
                placeholder: '请输入抽卡链接',
                onChanged: (value) {
                  setState(() {
                    _url = value;
                  });
                },
                suffix: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  onPressed: _url.isNotEmpty
                      ? () async {
                          try {
                            final params = _parseGachaUrl(_url);

                            // 验证必需参数（参考 Rust RequestParam::init）
                            final requiredKeys = [
                              'player_id',
                              'svr_id',
                              'record_id',
                              'resources_id',
                            ];
                            for (final key in requiredKeys) {
                              if (!params.containsKey(key) ||
                                  params[key]!.isEmpty) {
                                throw FormatException('缺少必需参数: $key，请确认链接是否完整');
                              }
                            }

                            // 更新设置
                            setState(() {
                              _gachaSetting['player_id'] =
                                  params['player_id']!;
                              _gachaSetting['svr_id'] =
                                  params['svr_id']!;
                              _gachaSetting['record_id'] =
                                  params['record_id']!;
                              _gachaSetting['resources_id'] =
                                  params['resources_id']!;
                              _gachaSetting['lang'] =
                                  params['lang'] ?? 'zh-Hans';
                              _gachaSetting['svr_area'] =
                                  params['svr_area'] ?? 'cn';
                            });

                            setting.put(SettingKey.gachaUrl, _url);
                            setting.put(
                              SettingKey.gachaSetting,
                              jsonEncode(_gachaSetting),
                            );
                            // 清除旧缓存，下次首页加载时会重新拉取并存储
                            await GachaStorage.clearAll();
                            showCupertinoDialog(
                              context: context,
                              builder: (context) {
                                return CupertinoAlertDialog(
                                  title: const Text('设置成功'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('确定'),
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                          '/home_page',
                                          (Route<dynamic> route) => false,
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          } catch (e) {
                            showCupertinoDialog(
                              context: context,
                              builder: (context) {
                                return CupertinoAlertDialog(
                                  title: const Text('解析失败'),
                                  content: Text(
                                    e is FormatException
                                        ? e.message
                                        : '请检查链接是否正确，或直接复制完整的浏览器地址栏链接',
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('确定'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        }
                      : null,
                  child: const Text('确认'),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                '示例：https://aki-gm-resources.aki-game.com/aki/gacha/index.html#/record?svr_id=76402e5b20be2c39f095a152090afddc&player_id=100114514&lang=zh-Hans&gacha_id=2&gacha_type=3&svr_area=cn&record_id=2a5c49f39db5031aaffee87d69916dfb&resources_id=6a6544dd7ce748e541a528967e4395c8',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.inactiveGray,
                ),
              ),
            ),
            if (showGachaSetting())
              CupertinoListSection.insetGrouped(
                children: gachaSettingList.map((ele) {
                  return CupertinoListTile.notched(
                    title: Text(ele['name'] as String),
                    additionalInfo: Expanded(
                      child: Text(
                        _gachaSetting[ele['id']],
                        textAlign: TextAlign.end,
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (showGachaSetting())
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: CupertinoButton.filled(
                  child: const Text(
                    '清除数据',
                    style: TextStyle(
                      color: CupertinoColors.white,
                    ),
                  ),
                  onPressed: () async {
                    setState(() {
                      _url = '';
                      _gachaSetting = {...gachaSetting};
                    });
                    textController.text = '';
                    await HiveData.setting.delete(SettingKey.gachaUrl);
                    await HiveData.setting.delete(SettingKey.gachaSetting);
                    await GachaStorage.clearAll();
                    showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          title: const Text('清除成功'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('确定'),
                              onPressed: () {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/home_page',
                                  (Route<dynamic> route) => false,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
