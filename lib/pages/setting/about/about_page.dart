import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:light_waves/config/config.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('关于'),
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
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage(WaveConfig.appLogo),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: CupertinoColors.activeBlue,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    WaveConfig.appName,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text('一款极简 Cupertino Design 鸣潮抽卡分析应用。'),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 30),
                      Divider(),
                      SizedBox(height: 10),
                      Text(
                        '版本：${WaveConfig.appVersion}',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "LOGO来源：https://www.pixiv.net/artworks/121032720（画师：DemonKing13）",
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "数据来源于网络，如有侵权，请联系管理员删除。",
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
