import 'dart:convert';
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
  // 快捷方式地址（手动模式）
  String _path = '';
  // 是否正在扫描
  bool _isScanning = false;

  // 用于扫描的游戏目录关键词（不区分大小写）
  static final _keywordRegex = RegExp(
    r'(wuthering\s?waves|鸣潮)',
    caseSensitive: false,
  );

  /// 解密 Client.log 文件
  /// 游戏对日志做了 XOR 加密：
  /// - 前 3 字节保持不变
  /// - 第 4 字节起：奇数 XOR 0xA5，偶数 XOR 0xEF
  Uint8List _decryptLog(Uint8List bytes) {
    if (bytes.length < 4) return bytes;

    final result = Uint8List(bytes.length);
    result[0] = bytes[0];
    result[1] = bytes[1];
    result[2] = bytes[2];

    for (int i = 3; i < bytes.length; i++) {
      if (bytes[i] % 2 == 1) {
        result[i] = bytes[i] ^ 0xA5;
      } else {
        result[i] = bytes[i] ^ 0xEF;
      }
    }
    return result;
  }

  /// 从日志文件中提取抽卡链接，返回 null 表示未找到
  Future<String?> _extractUrlFromLog(String logPath) async {
    final file = File(logPath);
    final encryptedBytes = await file.readAsBytes();
    final decryptedBytes = _decryptLog(encryptedBytes);
    final content = utf8.decode(decryptedBytes);

    final urlRegex = RegExp(r'"url":"(https?://[^"]+)"');
    final allMatches = urlRegex.allMatches(content).toList();
    final allUrls = allMatches
        .map((m) => m.group(1)?.toString() ?? '')
        .where((u) => u.isNotEmpty)
        .toList();

    // 取最后一条包含 /gacha/ 的抽卡链接（最新）
    return allUrls.cast<String?>().lastWhere(
          (u) => u!.contains('/gacha/'),
          orElse: () => null,
        );
  }

  /// 递归搜索日志文件
  Future<String?> _searchForLog(String dirPath) async {
    try {
      // 检查当前目录是否直接包含 Client/Saved/Logs/Client.log
      final directLog = path.join(dirPath, 'Client/Saved/Logs/Client.log');
      if (File(directLog).existsSync()) return directLog;

      // 查找 Client 子目录
      final clientDir = Directory(path.join(dirPath, 'Client'));
      if (await clientDir.exists()) {
        final logInClient =
            path.join(clientDir.path, 'Saved/Logs/Client.log');
        if (File(logInClient).existsSync()) return logInClient;
        // 找到 Client 目录但无日志，不再深入
        return null;
      }

      // 递归进入匹配关键词的子目录
      final entries = Directory(dirPath).listSync(followLinks: false);
      for (final entry in entries) {
        if (entry is! Directory) continue;
        if (_keywordRegex.hasMatch(path.basename(entry.path))) {
          final result = await _searchForLog(entry.path);
          if (result != null) return result;
        }
      }
    } catch (_) {
      // 无权限访问等，跳过
    }
    return null;
  }

  /// 自动扫描所有盘符，查找日志文件路径
  Future<String?> _autoFindLogPath() async {
    // 获取所有可用盘符
    final drives = <String>[];
    for (int i = 65; i <= 90; i++) {
      final drive = '${String.fromCharCode(i)}:\\';
      if (Directory(drive).existsSync()) drives.add(drive);
    }

    for (final drive in drives) {
      try {
        final entries = Directory(drive).listSync(followLinks: false);
        for (final entry in entries) {
          if (entry is! Directory) continue;

          // 第一层：目录本身匹配关键词
          if (_keywordRegex.hasMatch(path.basename(entry.path))) {
            final logPath = await _searchForLog(entry.path);
            if (logPath != null) return logPath;
          }

          // 第二层：检查子目录是否匹配关键词
          // 处理 D:\App\Wuthering Waves 这类嵌套安装
          try {
            final subEntries =
                Directory(entry.path).listSync(followLinks: false);
            for (final subEntry in subEntries) {
              if (subEntry is! Directory) continue;
              if (_keywordRegex.hasMatch(path.basename(subEntry.path))) {
                final logPath = await _searchForLog(subEntry.path);
                if (logPath != null) return logPath;
              }
            }
          } catch (_) {
            // 子目录无权限，跳过
          }
        }
      } catch (_) {
        // 跳过无权限的盘符
      }
    }
    return null;
  }

  /// 自动扫描模式
  Future<void> _autoGet() async {
    setState(() => _isScanning = true);

    try {
      final logPath = await _autoFindLogPath();
      if (logPath == null) {
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('未找到游戏目录'),
              content: const Text(
                '自动扫描未找到《鸣潮》日志文件。\n请确保游戏已安装，\n或使用下方的"手动输入"方式。',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
        return;
      }

      final url = await _extractUrlFromLog(logPath);
      if (url != null && url.isNotEmpty) {
        setState(() => _gachaUrl = url);
      } else {
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('未解析到链接'),
              content: const Text(
                '未在日志中找到抽卡链接。\n请确认已在游戏中打开过唤取记录页面。',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error auto get: $e');
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('获取失败'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() => _isScanning = false);
    }
  }

  /// 手动输入模式（从快捷方式地址解析）
  Future<void> _readFile() async {
    // 解析快捷方式目标地址
    final separator = _path.contains('\\') ? r'\' : '/';
    final escapedSep = separator == r'\' ? r'\\' : '/';
    final quotePrefix = _path[0] == '"' ? '"' : '';
    final regex = RegExp('^$quotePrefix(.*)$escapedSep[^$escapedSep]+\$');
    final match = regex.firstMatch(_path);
    final gamePath =
        match?.group(1)?.replaceAll(r'\', '/') ?? '';

    if (gamePath.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('快捷方式地址无效'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      final logPath = path.join(
        '$gamePath/Wuthering Waves Game/Client/Saved/Logs/',
        'Client.log',
      );
      final url = await _extractUrlFromLog(logPath);
      if (url != null && url.isNotEmpty) {
        setState(() => _gachaUrl = url);
      } else {
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('未解析到链接'),
              content: const Text(
                '未在日志中找到抽卡链接。\n请确认已在游戏中打开过唤取记录页面。',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      }
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
                onPressed: () => Navigator.of(context).pop(),
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
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    });
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 自动获取按钮
            if (_gachaUrl.isEmpty)
              CupertinoButton(
                color: CupertinoColors.activeBlue,
                onPressed:
                    _isScanning ? null : () => _autoGet(),
                child: _isScanning
                    ? const CupertinoActivityIndicator()
                    : const Text(
                        '自动获取',
                        style: TextStyle(color: CupertinoColors.white),
                      ),
              ),
            if (_isScanning)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '正在扫描磁盘，查找游戏日志...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                ),
              ),

            // 分隔
            if (_gachaUrl.isEmpty) ...[
              const SizedBox(height: 30),
              const Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 0.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: CupertinoColors.separator,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '或手动输入',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 0.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: CupertinoColors.separator,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 手动输入区域
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
              const SizedBox(height: 12),
              CupertinoButton(
                color: CupertinoColors.activeBlue,
                onPressed: _path.isEmpty ? null : () => _readFile(),
                child: const Text(
                  '手动获取',
                  style: TextStyle(color: CupertinoColors.white),
                ),
              ),
            ],

            // 结果展示
            if (_gachaUrl.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(_gachaUrl),
              const SizedBox(height: 20),
              CupertinoButton(
                color: CupertinoColors.activeBlue,
                onPressed: () => _copyToClipboard(context),
                child: const Text(
                  '复制',
                  style: TextStyle(color: CupertinoColors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
