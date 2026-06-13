import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:light_waves/config/api.dart';
import 'package:light_waves/config/config.dart';
import 'package:light_waves/config/hive.dart';
import 'package:light_waves/constant/common.dart';
import 'package:light_waves/pages/home/analysis_card.dart';
import 'package:light_waves/provider/theme.dart';
import 'package:light_waves/service/gacha_storage.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Box setting = HiveData.setting;
  // 首页可见的卡池列表
  List _visibleCardPoolType = [];
  // 抽卡设置
  Map<String, dynamic> _gachaSetting = {...gachaSetting};
  // 请求参数
  Map<String, dynamic> _params = {...defaultRequest};
  // 未处理的抽卡记录
  List _list = [];
  // 暂存每个池子处理后的抽卡记录
  List _gachaList = [];
  // tab选择器
  int _selected = 1;
  // 处理后的抽卡数据
  List _allList = [];
  // 图片
  List imgs = [];
  // 是否正在从 API 刷新
  bool _isRefreshing = false;
  // 总体分析数据
  Map _totalData = {
    'num': 0,
    'num_c': 0,
    'num_w': 0,
    'num_n': 0,
    'level5_c': 0,
    'level5_c_up': 0,
    'level5_c_normal': 0,
    'level5_w': 0,
    'level5_n': 0,
    'need_w': 0,
    'need_n': 0,
  };

  // 分析抽卡数据
  void _analysisData() {
    _totalData = {
      'num': 0,
      'num_c': 0,
      'num_w': 0,
      'num_n': 0,
      'level5_c': 0,
      'level5_c_up': 0,
      'level5_c_normal': 0,
      'level5_w': 0,
      'level5_n': 0,
      'need_w': 0,
      'need_n': 0,
    };
    for (int i = 0; i < _allList.length; i++) {
      List pool = _allList[i]['list'];
      final poolId = _allList[i]['poolId'] as int;
      int needFlag = 0;
      for (int j = 0; j < pool.length; j++) {
        Map stage = pool[j];
        _totalData['num'] += stage['flag'];
        if (poolId == 1 || poolId == 10) {
          _totalData['num_c'] += stage['flag'];
          if (stage['qualityLevel'] == 5) {
            if (defaultFiveStar.contains(stage['resourceId'])) {
              _totalData['level5_c_normal']++;
              _totalData['need_n']++;
              needFlag++;
            } else {
              _totalData['level5_c_up']++;
              _totalData['need_w']++;
              if (needFlag > 0) {
                needFlag--;
              }
            }
            _totalData['level5_c']++;
          }
        } else if (poolId == 2 || poolId == 11) {
          _totalData['num_w'] += stage['flag'];
          if (stage['qualityLevel'] == 5) {
            _totalData['level5_w']++;
          }
        } else {
          _totalData['num_n'] += stage['flag'];
          if (stage['qualityLevel'] == 5) {
            _totalData['level5_n']++;
          }
        }
      }
      if (needFlag > 0) {
        _totalData['need_w']++;
      }
    }
    debugPrint(_totalData.toString());
  }

  // 是否有抽卡设置
  bool showGachaSetting() {
    return !_gachaSetting.values.contains('');
  }

  // 处理单个池子的原始数据为带 flag 的列表
  List _processSinglePool(List rawItems) {
    _list = rawItems;
    _getGachaData();
    return _gachaList;
  }

  // 处理所有池子数据
  void _processAllPools(Map<int, List<Map<String, dynamic>>> poolData) {
    _allList = [];
    for (int i = 0; i < _visibleCardPoolType.length; i++) {
      final poolType = _visibleCardPoolType[i]['id'] as int;
      final rawItems = poolData[poolType] ?? [];
      debugPrint('[DEBUG] processAll $poolType rawItems=${rawItems.length}');
      final processedList = _processSinglePool(rawItems);
      debugPrint('[DEBUG] processAll $poolType processedList=${processedList.length} lastFlag=${processedList.isNotEmpty ? processedList.last['flag'] : '?'}');
      _allList.add({
        'name': _visibleCardPoolType[i]['name'],
        'poolId': poolType,
        'list': processedList,
      });
    }
    // 确保 _selected 是可见池子的有效 ID
    if (!_visibleCardPoolType.any((p) => p['id'] == _selected)) {
      _selected = _visibleCardPoolType.isNotEmpty
          ? _visibleCardPoolType[0]['id'] as int
          : 1;
    }
    _analysisData();
    if (mounted) setState(() {});
  }

  // 从本地加载数据
  Map<int, List<Map<String, dynamic>>> _loadLocalData() {
    final poolData = <int, List<Map<String, dynamic>>>{};
    for (final pool in _visibleCardPoolType) {
      final poolId = pool['id'] as int;
      poolData[poolId] = GachaStorage.loadPool(poolId);
    }
    return poolData;
  }

  /// pool ID → _allList 索引（在可见池子中的位置）
  int _poolIdToIndex(int poolId) {
    for (int i = 0; i < _visibleCardPoolType.length; i++) {
      if (_visibleCardPoolType[i]['id'] == poolId) return i;
    }
    return 0;
  }

  // 从 API 刷新所有池子数据并合并到本地
  Future<void> _refreshFromApi() async {
    if (!showGachaSetting()) return;
    setState(() => _isRefreshing = true);

    try {
      for (int i = 0; i < _visibleCardPoolType.length; i++) {
        _params['cardPoolType'] = _visibleCardPoolType[i]['id'];
        final Map data = await Wave.gachaRecord(
          _params,
          svrArea: _gachaSetting['svr_area'] ?? 'cn',
        );
        final poolId = _visibleCardPoolType[i]['id'] as int;
        final poolName = _visibleCardPoolType[i]['name'] as String;
        if (data['message'] == 'success') {
          final newItems = (data['data'] as List?) ?? [];
          debugPrint('[DEBUG] API $poolName(id=$poolId) 返回 ${newItems.length} 条');
          await GachaStorage.savePool(poolId, newItems);
          debugPrint('[DEBUG] $poolName(id=$poolId) 已保存 ${newItems.length} 条');
        }
      }
      // 重新加载合并后的数据
      final poolData = _loadLocalData();
      _processAllPools(poolData);
    } catch (e) {
      debugPrint('刷新抽卡数据失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  //  处理抽卡记录
  void _getGachaData() {
    int flag = 0;
    List level4 = [];
    _gachaList = [];
    for (int i = _list.length - 1; i >= 0; i--) {
      flag++;
      if (_list[i]['qualityLevel'] == 4) {
        level4.add(_list[i]);
      }
      if (_list[i]['qualityLevel'] == 5) {
        _gachaList.add({
          ..._list[i],
          'flag': flag,
        });
        flag = 0;
        level4 = [];
        debugPrint('${_list[i]['name']} ${_list[i]['resourceId']}');
      }
    }
    _gachaList.add({
      'qualityLevel': -1,
      'flag': flag,
    });
  }

  //  渲染进度条
  Widget renderProgress(int flag) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.only(right: 20),
        child: LinearProgressIndicator(
          backgroundColor: CupertinoColors.white.withOpacity(0),
          value: (flag >= 5 ? flag : 5) / 80,
          color: getColor(flag),
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // 获取进度条颜色
  CupertinoDynamicColor getColor(int flag) {
    if (flag >= 0 && flag < 50) {
      return CupertinoColors.activeGreen;
    } else if (flag >= 50 && flag < 70) {
      return CupertinoColors.systemYellow;
    } else {
      return CupertinoColors.systemRed;
    }
  }

  // 获取图片
  String? getImg(String name) {
    List list = imgs.where((ele) => ele['name'] == name).toList();
    return list.isNotEmpty ? list[0]['url'] : null;
  }

  // 是否是角色
  bool isCharacter() {
    return [1, 3, 5, 6, 8, 10].contains(_selected);
  }

  // 是否为武器
  bool isWeapon() {
    return [2, 4, 9, 11].contains(_selected);
  }

  // 渲染抽卡列表
  List<Widget> renderGachaCate() {
    List<Widget> list = [];
    for (int i = 0; i < _allList.length; i++) {
      List eleList = (_allList[i]['list'] as List).reversed.toList();
      list.add(
        CupertinoListSection.insetGrouped(
          children: eleList.isNotEmpty
              ? eleList.map((ele) {
                  return ele['flag'] == 0
                      ? const SizedBox.shrink()
                      : CupertinoListTile.notched(
                          leading: ele['qualityLevel'] > -1
                              ? getImg(ele['name']) != null
                                  ? Image.network(getImg(ele['name'])!)
                                  : null
                              : const Icon(CupertinoIcons.question_circle),
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.18,
                                child: Text(
                                  '${ele['qualityLevel'] > -1 ? ele['name'] : '已垫'}',
                                  style: ele['qualityLevel'] > -1
                                      ? const TextStyle(
                                          color: CupertinoColors.activeBlue,
                                          fontWeight: FontWeight.w500,
                                        )
                                      : null,
                                ),
                              ),
                              if (ele['qualityLevel'] > -1)
                                renderProgress(ele['flag']),
                              Row(
                                children: renderOtherTag(ele),
                              ),
                            ],
                          ),
                          subtitle: ele['qualityLevel'] > -1
                              ? Text(
                                  getGachaTime(ele['time'] as String),
                                )
                              : null,
                          additionalInfo: Text('${ele['flag']} 抽'),
                        );
                }).toList()
              : [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('暂无数据'),
                    ),
                  ),
                ],
        ),
      );
    }
    return list;
  }

  // 格式化抽卡时间
  String getGachaTime(String time) {
    String nowYear = DateTime.now().toString().split('-')[0];
    String gachaYear = time.split('-')[0];
    if (nowYear == gachaYear) {
      return time.split(' ')[0].split('$nowYear-')[1];
    } else {
      return time.split(' ')[0];
    }
  }

  // 获取tab items
  Map<int, Widget> renderGachaType() {
    Map<int, Widget> map = {};
    for (int i = 0; i < _visibleCardPoolType.length; i++) {
      final poolId = _visibleCardPoolType[i]['id'] as int;
      map[poolId] = Text(
        cardPoolTypeMap[poolId] as String,
        style: TextStyle(
          color: _selected == poolId ? CupertinoColors.white : null,
        ),
      );
    }
    return map;
  }

  // 渲染【欧】【歪】标识
  List<Widget> renderOtherTag(Map ele) {
    List<int> other = [];
    if (defaultFiveStar.contains(ele['resourceId']) && _selected == 1) {
      other.add(1);
    }
    if (ele['flag'] <= 10 && ele['qualityLevel'] > -1) {
      other.add(2);
    }
    return other.map((item) {
      return Padding(
        padding: const EdgeInsets.only(left: 5.0),
        child: Container(
          transform: Matrix4.rotationZ(45 * 3.14 / 360),
          decoration: BoxDecoration(
            border: Border.all(
              color: item == 1
                  ? CupertinoColors.systemRed
                  : CupertinoColors.activeGreen,
              width: 1,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(9),
            ),
          ),
          width: 18,
          height: 18,
          child: Text(
            item == 1 ? '歪' : '欧',
            style: TextStyle(
              color: item == 1
                  ? CupertinoColors.systemRed
                  : CupertinoColors.activeGreen,
              fontSize: 10,
              fontWeight: FontWeight.w200,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }).toList();
  }

  // 获取角色数据
  Future _getCharacterInfo() async {
    final Map data = await Wave.wikiInfo({
      "catalogueId": 1105,
      "page": 1,
      "limit": 1000,
    });
    final List list = (data['data']['results']['records'] as List).map((ele) {
      return {'name': ele['name'], 'url': ele['content']['contentUrl']};
    }).toList();
    imgs.addAll(list);
  }

  // 获取武器数据
  Future _getWeaponInfo() async {
    final Map data = await Wave.wikiInfo({
      "catalogueId": 1106,
      "page": 1,
      "limit": 1000,
    });
    final List list = (data['data']['results']['records'] as List).map((ele) {
      return {'name': ele['name'], 'url': ele['content']['contentUrl']};
    }).toList();
    imgs.addAll(list);
  }

  // 从设置页返回后重新加载
  void _reload() {
    _loadVisiblePools();
    _allList = List.generate(_visibleCardPoolType.length, (i) => {
      'name': _visibleCardPoolType[i]['name'],
      'poolId': _visibleCardPoolType[i]['id'],
      'list': <Map<String, dynamic>>[],
    });
    if (_visibleCardPoolType.isNotEmpty &&
        !_visibleCardPoolType.any((p) => p['id'] == _selected)) {
      _selected = _visibleCardPoolType[0]['id'] as int;
    }
    final poolData = _loadLocalData();
    if (poolData.values.any((list) => list.isNotEmpty)) {
      _processAllPools(poolData);
    } else {
      setState(() {});
    }
    if (showGachaSetting()) {
      _refreshFromApi();
    }
  }

  // 加载首页可见池子设置
  void _loadVisiblePools() {
    final raw = HiveData.setting.get(
      SettingKey.visiblePools,
      defaultValue: jsonEncode(cardPoolType.map((p) => p['id']).toList()),
    );
    final visibleIds = (jsonDecode(raw) as List).map((e) => e as int).toSet();
    _visibleCardPoolType =
        cardPoolType.where((p) => visibleIds.contains(p['id'])).toList();
  }

  @override
  void initState() {
    super.initState();
    // 加载用户选择的可见卡池
    _loadVisiblePools();
    // 预填充空池子占位
    _allList = List.generate(_visibleCardPoolType.length, (i) => {
      'name': _visibleCardPoolType[i]['name'],
      'poolId': _visibleCardPoolType[i]['id'],
      'list': <Map<String, dynamic>>[],
    });
    if (_visibleCardPoolType.isNotEmpty) {
      _selected = _visibleCardPoolType[0]['id'] as int;
    }
    _gachaSetting = jsonDecode(setting.get(
      SettingKey.gachaSetting,
      defaultValue: jsonEncode(gachaSetting),
    ));
    _params = {
      ..._params,
      "playerId": _gachaSetting['player_id'],
      "cardPoolId": _gachaSetting["resources_id"],
      "serverId": _gachaSetting["svr_id"],
      "recordId": _gachaSetting["record_id"],
      "languageCode": _gachaSetting['lang'] ?? 'zh-Hans',
    };

    // 1. 先从本地加载并立即显示
    final poolData = _loadLocalData();
    if (poolData.values.any((list) => list.isNotEmpty)) {
      _processAllPools(poolData);
    }

    // 2. 如果已配置，后台拉取 API 并合并
    if (showGachaSetting()) {
      _refreshFromApi();
      _getCharacterInfo();
      _getWeaponInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(WaveConfig.appName),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            Provider.of<ThemeModel>(context, listen: true).theme == 'light'
                ? CupertinoIcons.sun_max
                : CupertinoIcons.moon,
          ),
          onPressed: () {
            Provider.of<ThemeModel>(context, listen: false).toggleTheme();
          },
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.settings),
          onPressed: () async {
            await Navigator.of(context).pushNamed('/setting_page');
            _reload();
          },
        ),
      ),
      child: showGachaSetting()
          ? _allList.isNotEmpty
              ? Column(
                  children: [
                    AnalysisCard(
                      data: _totalData,
                      uid: _params['playerId'],
                      index: _selected,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                      child: CupertinoSlidingSegmentedControl(
                        groupValue: _selected,
                        thumbColor: CupertinoColors.activeBlue,
                        children: renderGachaType(),
                        onValueChanged: (value) {
                          setState(() {
                            _selected = value as int;
                          });
                        },
                      ),
                    ),
                    if (_isRefreshing)
                      const SizedBox(
                        height: 3,
                        child: LinearProgressIndicator(
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    Expanded(
                      child: ListView(
                        children: [
                          renderGachaCate()[_poolIdToIndex(_selected)],
                        ],
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: CupertinoActivityIndicator(
                    radius: 20.0,
                    color: CupertinoColors.activeBlue,
                  ),
                )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('请先配置抽卡信息'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CupertinoButton.filled(
                          child: const Text(
                            '去设置',
                            style: TextStyle(
                              color: CupertinoColors.white,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed('/setting_page');
                          }),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
