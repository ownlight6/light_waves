import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:window_manager/window_manager.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  // 是否置顶
  bool _alwaysOnTop = false;

  @override
  void initState() {
    super.initState();
    _initAlwaysOnTop();
  }

  void _initAlwaysOnTop() async {
    if (Platform.isWindows) {
      bool top = await windowManager.isAlwaysOnTop();
      setState(() {
        _alwaysOnTop = top;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('设置'),
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
            CupertinoListSection.insetGrouped(
              children: [
                if (Platform.isWindows)
                  CupertinoListTile.notched(
                    title: const Text('获取链接'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () async {
                      Navigator.of(context).pushNamed('/get_page');
                    },
                  ),
                CupertinoListTile.notched(
                  title: const Text('设置链接'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    Navigator.of(context).pushNamed('/gacha_page');
                  },
                ),
                if (Platform.isWindows)
                  CupertinoListTile.notched(
                    title: const Text('窗口置顶'),
                    additionalInfo: CupertinoSwitch(
                      value: _alwaysOnTop,
                      activeColor: CupertinoColors.activeBlue,
                      onChanged: (bool? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _alwaysOnTop = value;
                        });
                        windowManager.setAlwaysOnTop(value);
                      },
                    ),
                  ),
                CupertinoListTile.notched(
                  title: const Text('关于'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    Navigator.of(context).pushNamed('/about_page');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
