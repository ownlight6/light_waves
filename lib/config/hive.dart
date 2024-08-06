import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveData {
  // 设置相关
  static late final Box<dynamic> setting;

  static Future<void> init() async {
    final Directory dir = await getApplicationSupportDirectory();
    final String path = dir.path;
    await Hive.initFlutter('$path/hive');
    debugPrint('Hive path: $path/hive');
    setting = await Hive.openBox('setting');
    debugPrint('Hive init success');
  }

  static Future<void> close() async {
    setting.compact();
    setting.close();
  }
}

class SettingKey {
  // 抽卡链接
  static const String gachaUrl = 'gachaUrl';
  // 抽卡设置
  static const String gachaSetting = 'gachaSetting';
  // 深色主题
  static const String theme = 'theme';
}
