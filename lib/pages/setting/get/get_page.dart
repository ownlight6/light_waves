import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class GetPage extends StatefulWidget {
  const GetPage({super.key});

  @override
  State<GetPage> createState() => _GetPageState();
}

class _GetPageState extends State<GetPage> {
  // 抽卡链接
  String _gachaUrl = '';
  //  快捷方式地址
  String _path = '';

  // 读取文件内容并提取url字段
  Future<void> _readFile() async {
    String gamePath = '';
    // "D:\App\Wuthering Waves\launcher.exe"
    RegExp regExp = _path[0] == '"'
        ? RegExp(r'^"(.*)\\[^\\]+$')
        : RegExp(r'^(.*)\\[^\\]+$');
    Match? match = regExp.firstMatch(_path);
    gamePath = match?.group(1)!.toString().replaceAll(r'\', '/') ?? '';
    if (gamePath.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('快捷方式地址无效'),
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
      return;
    }
    try {
      // 指定文件路径 D:/App/Wuthering Waves/Wuthering Waves Game/Client/Saved/Logs
      String filePath = path.join(
        '$gamePath/Wuthering Waves Game/Client/Saved/Logs/',
        'Client.log',
      );
      File file = File(filePath);
      // 读取文件内容
      String content = await file.readAsString();
      // 正则表达式提取url字段（日志中可能包含多个URL：公告链接、抽卡链接等）
      final regex = RegExp(r',"url":"(.*?)","transparent":true');
      // 使用 allMatches 找到所有URL，过滤出抽卡记录链接（包含 /gacha/ 路径）
      final allMatches = regex.allMatches(content).toList();
      final allUrls = allMatches
          .map((m) => m.group(1)?.toString() ?? '')
          .where((u) => u.isNotEmpty)
          .toList();
      // 只取抽卡链接（包含 /gacha/），排除公告链接（/announcement/）
      final gachaUrl = allUrls.cast<String?>().firstWhere(
            (u) => u!.contains('/gacha/'),
            orElse: () => null,
          ) ??
          '';

      if (gachaUrl.isEmpty) {
        final message = allUrls.isEmpty
            ? '未在日志中找到任何链接，请确认已在游戏中打开过唤取记录页面'
            : '日志中找到的是公告链接，请重新打开游戏的唤取记录页面后重试';
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('未解析到链接'),
              content: Text(message),
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
        return;
      }
      setState(() {
        _gachaUrl = gachaUrl;
      });
    } catch (e) {
      debugPrint('Error reading file: $e');
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('获取失败'),
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

  // 复制链接到剪切板
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _gachaUrl)).then((_) {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('已复制到剪切板'),
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
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('获取链接'),
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
          padding: const EdgeInsets.all(20),
          children: [
            CupertinoTextField(
              placeholder: '请输入鸣潮桌面快捷方式目标地址',
              onChanged: (value) {
                setState(() {
                  _path = value;
                });
              },
            ),
            const SizedBox(height: 5),
            const Text(
              '示例："D:\\App\\Wuthering Waves\\launcher.exe"\n'
              '1、首先在游戏中打开【唤取记录】\n'
              '2、鼠标右键点击桌面【鸣潮】快捷方式图标\n'
              '3、在弹出的菜单中选择【属性】\n'
              '4、在弹出的属性窗口中，找到【快捷方式】标签页\n'
              '5、在【快捷方式】标签页中，找到【目标】文本框\n'
              '6、复制【目标】文本框中的内容，粘贴到上面的输入框中',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            if (_gachaUrl.isEmpty)
              CupertinoButton(
                color: CupertinoColors.activeBlue,
                onPressed: _path.isEmpty ? null : () => _readFile(),
                child: const Text(
                  '获取',
                  style: TextStyle(
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            Text(_gachaUrl),
            const SizedBox(height: 20),
            if (_gachaUrl.isNotEmpty)
              CupertinoButton(
                color: CupertinoColors.activeBlue,
                onPressed: () => _copyToClipboard(context),
                child: const Text(
                  '复制',
                  style: TextStyle(
                    color: CupertinoColors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
