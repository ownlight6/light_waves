import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:light_waves/config/hive.dart';
import 'package:light_waves/pages/home/home_page.dart';
import 'package:light_waves/pages/setting/about/about_page.dart';
import 'package:light_waves/pages/setting/gacha/gacha_page.dart';
import 'package:light_waves/pages/setting/get/get_page.dart';
import 'package:light_waves/pages/setting/pool_filter/pool_filter_page.dart';
import 'package:light_waves/pages/setting/setting_page.dart';
import 'package:light_waves/provider/theme.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(400, 800),
      minimumSize: Size(400, 800),
      maximumSize: Size(400, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'LIGHT WAVE 鸣潮',
      alwaysOnTop: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  // 竖屏向上
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await HiveData.init();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ThemeModel()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context, listen: true).theme;
    return CupertinoApp(
      title: 'LIGHT WAVE',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: themeModel == 'light' ? Brightness.light : Brightness.dark,
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        barBackgroundColor: CupertinoColors.systemGroupedBackground,
        textTheme: const CupertinoTextThemeData(
          textStyle: TextStyle(
            fontSize: 16,
            color: CupertinoColors.label,
            fontFamily: 'PingFangSC-Regular',
          ),
        ),
      ),
      home: const HomePage(),
      routes: {
        '/home_page': (context) => const HomePage(),
        '/setting_page': (context) => const SettingPage(),
        '/gacha_page': (context) => const GachaPage(),
        '/about_page': (context) => const AboutPage(),
        '/get_page': (context) => const GetPage(),
        '/pool_filter_page': (context) => const PoolFilterPage(),
      },
    );
  }
}
