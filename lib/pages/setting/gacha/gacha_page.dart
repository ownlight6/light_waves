import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:light_waves/config/hive.dart';
import 'package:light_waves/constant/common.dart';

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
                            _url.split('?')[1].split('&').forEach((ele) {
                              var key = ele.split('=')[0];
                              var value = ele.split('=')[1];
                              setState(() {
                                if (_gachaSetting.containsKey(key)) {
                                  _gachaSetting[key] = value;
                                }
                              });
                            });
                            setting.put(SettingKey.gachaUrl, _url);
                            setting.put(
                              SettingKey.gachaSetting,
                              jsonEncode(_gachaSetting),
                            );
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
                                  content: const Text('请检查链接是否正确'),
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
                  onPressed: () {
                    setState(() {
                      _url = '';
                      _gachaSetting = {...gachaSetting};
                    });
                    textController.text = '';
                    HiveData.setting.clear();
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
