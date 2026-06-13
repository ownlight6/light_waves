import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveData {
  // 设置相关
  static late final Box<dynamic> setting;
  // 抽卡记录本地缓存
  static late final Box<dynamic> gachaRecords;

  static Future<void> init() async {
    final Directory dir = await getApplicationSupportDirectory();
    final String path = dir.path;
    await Hive.initFlutter('$path/hive');
    debugPrint('Hive path: $path/hive');
    setting = await Hive.openBox('setting');
    gachaRecords = await Hive.openBox('gachaRecords');
    debugPrint('Hive init success');
  }

  static Future<void> close() async {
    setting.compact();
    setting.close();
    gachaRecords.compact();
    gachaRecords.close();
  }
}

class SettingKey {
  // 抽卡链接
  static const String gachaUrl = 'gachaUrl';
  // 抽卡设置
  static const String gachaSetting = 'gachaSetting';
  // 深色主题
  static const String theme = 'theme';
  // 首页可见卡池列表（JSON encoded List<int>）
  static const String visiblePools = 'visiblePools';

  /// 根据 pool ID 返回稳定的 Hive key（池子名称，不随 ID 变动）
  static String gachaPoolKey(int poolId) {
    switch (poolId) {
      case 1: return 'pool_char_event';
      case 2: return 'pool_weapon_event';
      case 3: return 'pool_char_permanent';
      case 4: return 'pool_weapon_permanent';
      case 5: return 'pool_beginner';
      case 6: return 'pool_beginner_select';
      case 8: return 'pool_novice_char';
      case 9: return 'pool_novice_weapon';
      case 10: return 'pool_collab_char';
      case 11: return 'pool_collab_weapon';
      default: return 'pool_unknown_$poolId';
    }
  }
}
