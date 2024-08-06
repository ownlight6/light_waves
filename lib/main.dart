import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:light_waves/config/hive.dart';
import 'package:light_waves/pages/home/home_page.dart';
import 'package:light_waves/pages/setting/setting_page.dart';
import 'package:light_waves/provider/theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      },
    );
  }
}
