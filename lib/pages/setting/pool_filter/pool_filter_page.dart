import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:light_waves/config/hive.dart';
import 'package:light_waves/constant/common.dart';

class PoolFilterPage extends StatefulWidget {
  const PoolFilterPage({super.key});

  @override
  State<PoolFilterPage> createState() => _PoolFilterPageState();
}

class _PoolFilterPageState extends State<PoolFilterPage> {
  late Set<int> _visiblePoolIds;

  @override
  void initState() {
    super.initState();
    final raw = HiveData.setting.get(
      SettingKey.visiblePools,
      defaultValue: jsonEncode(cardPoolType.map((p) => p['id']).toList()),
    );
    _visiblePoolIds = (jsonDecode(raw) as List).map((e) => e as int).toSet();
  }

  Future<void> _save() async {
    final list = cardPoolType
        .map((p) => p['id'] as int)
        .where((id) => _visiblePoolIds.contains(id))
        .toList();
    await HiveData.setting.put(
      SettingKey.visiblePools,
      jsonEncode(list),
    );
  }

  void _toggle(int poolId) {
    setState(() {
      if (_visiblePoolIds.contains(poolId)) {
        _visiblePoolIds.remove(poolId);
      } else {
        _visiblePoolIds.add(poolId);
      }
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('首页显示卡池'),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text(
                '首页显示的卡池',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
              ),
              children: cardPoolType.map((pool) {
                final poolId = pool['id'] as int;
                final name = pool['name'] as String;
                final label = cardPoolTypeMap[poolId] ?? name;
                return CupertinoListTile.notched(
                  title: Text('$label（$name）'),
                  additionalInfo: CupertinoSwitch(
                    value: _visiblePoolIds.contains(poolId),
                    activeColor: CupertinoColors.activeBlue,
                    onChanged: (_) => _toggle(poolId),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
