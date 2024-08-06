import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:light_waves/config/api.dart';
import 'package:light_waves/config/config.dart';
import 'package:light_waves/config/hive.dart';
import 'package:light_waves/constant/common.dart';
import 'package:light_waves/provider/theme.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Box setting = HiveData.setting;
  // 抽卡设置
  Map<String, dynamic> _gachaSetting = {...gachaSetting};
  // 请求参数
  Map<String, dynamic> _params = {...defaultRequest};
  List _list = [];
  List _gachaList = [];
  int _selected = 1;
  final List _allList = [];
  final List _others = [1405, 1301, 1203, 1503, 1104];
  List imgs = [];
  // 主题

  // 是否有抽卡设置
  bool showGachaSetting() {
    return !_gachaSetting.values.contains('');
  }

  void _getGachaData() async {
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
          // 'level4': level4,
        });
        flag = 0;
        level4 = [];
        print('${_list[i]['name']} ${_list[i]['resourceId']}');
      }
    }
    _gachaList.add({
      'qualityLevel': -1,
      'flag': flag,
    });
  }

  Future _getData() async {
    final Map data = await Wave.gachaRecord(_params);
    if (data['message'] == 'success') {
      setState(() {
        _list = data['data'];
      });
    }
    _getGachaData();
  }

  void _getAllData() async {
    for (int i = 0; i < cardPoolType.length; i++) {
      _params['cardPoolType'] = cardPoolType[i]['id'];
      await _getData();
      _allList.add({
        'name': cardPoolType[i]['name'],
        'list': _gachaList,
      });
    }
  }

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

  CupertinoDynamicColor getColor(int flag) {
    if (flag >= 0 && flag < 50) {
      return CupertinoColors.activeGreen;
    } else if (flag >= 50 && flag < 70) {
      return CupertinoColors.systemYellow;
    } else {
      return CupertinoColors.systemRed;
    }
  }

  String? getImg(String name) {
    List list = imgs.where((ele) => ele['name'] == name).toList();
    return list.isNotEmpty ? list[0]['url'] : null;
  }

  bool isCharacter() {
    return [1, 3, 5, 6].contains(_selected);
  }

  bool isWeapon() {
    return [2, 4].contains(_selected);
  }

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

  String getGachaTime(String time) {
    String nowYear = DateTime.now().toString().split('-')[0];
    String gachaYear = time.split('-')[0];
    if (nowYear == gachaYear) {
      return time.split(' ')[0].split('$nowYear-')[1];
    } else {
      return time.split(' ')[0];
    }
  }

  Map<int, Widget> renderGachaType() {
    Map<int, Widget> map = {};
    for (int i = 0; i < cardPoolType.length; i++) {
      map[cardPoolType[i]['id']] = Text(
        cardPoolTypeMap[cardPoolType[i]['id']] as String,
        style: TextStyle(
          color:
              _selected == cardPoolType[i]['id'] ? CupertinoColors.white : null,
        ),
      );
    }
    return map;
  }

  List<Widget> renderOtherTag(Map ele) {
    List<int> other = [];
    if (_others.contains(ele['resourceId']) && _selected == 1) {
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

  @override
  void initState() {
    super.initState();
    _gachaSetting = jsonDecode(setting.get(
      SettingKey.gachaSetting,
      defaultValue: jsonEncode(gachaSetting),
    ));
    setState(() {
      _params = {
        ..._params,
        "playerId": _gachaSetting['player_id'],
        "cardPoolId": _gachaSetting["resources_id"],
        "serverId": _gachaSetting["svr_id"],
        "recordId": _gachaSetting["record_id"],
      };
    });
    if (showGachaSetting()) {
      _getAllData();
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
          onPressed: () {
            Navigator.of(context).pushNamed('/setting_page');
          },
        ),
      ),
      child: showGachaSetting()
          ? _allList.isNotEmpty
              ? ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                    renderGachaCate()[_selected - 1],
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
