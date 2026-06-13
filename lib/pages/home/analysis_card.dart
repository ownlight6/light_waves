import 'package:flutter/cupertino.dart';

class AnalysisCard extends StatefulWidget {
  final String uid;
  final Map data;
  final int index;
  const AnalysisCard({
    super.key,
    required this.data,
    required this.uid,
    required this.index,
  });

  @override
  State<AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<AnalysisCard> {
  // 隐藏总体数据
  bool hideTotal = false;
  // 隐藏卡池数据
  bool hideCardPool = false;
  // 卡池类型（poolId → 显示名称）
  static const cardPool = {
    1: '限定池',
    2: '专武池',
    3: '常驻池',
    4: '常驻池',
    5: '常驻池',
    6: '常驻池',
    8: '新旅池',
    9: '新旅池',
    10: '联动池',
    11: '联动池',
  };

  @override
  Widget build(BuildContext context) {
    // 渲染卡池隐藏后额外标题
    Widget renderPoolHideOtherTitle() {
      String key = 'num_n';
      if (widget.index == 1 || widget.index == 10) {
        key = 'num_c';
      } else if (widget.index == 2 || widget.index == 11) {
        key = 'num_w';
      }
      return Text(
        '${widget.data[key].toString()} 抽',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.right,
      );
    }

    // 渲染卡池分析数据
    Widget renderPoolCard() {
      return CupertinoListSection.insetGrouped(
        header: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                cardPool[widget.index] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (!hideCardPool) Expanded(child: renderPoolHideOtherTitle()),
              GestureDetector(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    hideCardPool ? '隐藏' : '显示',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ),
                onTap: () {
                  setState(() {
                    hideCardPool = !hideCardPool;
                  });
                },
              ),
            ],
          ),
        ),
        children: hideCardPool
            ? [
                if (widget.index == 1 || widget.index == 10)
                  Column(
                    children: [
                      CupertinoListTile(
                        title: const Text('抽数'),
                        additionalInfo: Text(
                          widget.data['num_c'].toString(),
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text('五星唤取'),
                        additionalInfo: Text(
                          widget.data['level5_c'].toString(),
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text('UP 唤取'),
                        additionalInfo: Text(
                          widget.data['level5_c_up'].toString(),
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text('不歪概率'),
                        additionalInfo: Text(
                          ((widget.data['need_w'] - widget.data['need_n']) /
                                      widget.data['need_w'] *
                                      100)
                                  .toStringAsFixed(2) +
                              '%',
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text('UP 平均抽数'),
                        additionalInfo: Text(
                          (widget.data['num_c'] / widget.data['level5_c_up'])
                              .toStringAsFixed(2)
                              .toString(),
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text('UP 平均消耗星声'),
                        additionalInfo: Text(
                          (widget.data['num_c'] *
                                  160 /
                                  widget.data['level5_c_up'])
                              .toStringAsFixed(2)
                              .toString(),
                        ),
                      ),
                    ],
                  ),
                if (widget.index == 2 || widget.index == 11)
                  Column(
                    children: [
                      CupertinoListTile(
                        title: const Text('抽数'),
                        additionalInfo: Text(
                          widget.data['num_w'].toString(),
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text('五星唤取'),
                        additionalInfo: Text(
                          widget.data['level5_w'].toString(),
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text('平均抽数'),
                        additionalInfo: Text(
                          (widget.data['num_w'] / widget.data['level5_w'])
                              .toStringAsFixed(2)
                              .toString(),
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text('平均消耗星声'),
                        additionalInfo: Text(
                          (widget.data['num_w'] * 160 / widget.data['level5_w'])
                              .toStringAsFixed(2)
                              .toString(),
                        ),
                      ),
                    ],
                  ),
                if (![1, 2, 10, 11].contains(widget.index))
                  Column(
                    children: [
                      CupertinoListTile(
                        title: const Text('抽数'),
                        additionalInfo: Text(
                          widget.data['num_n'].toString(),
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text('五星唤取'),
                        additionalInfo: Text(
                          widget.data['level5_n'].toString(),
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text('平均抽数'),
                        additionalInfo: Text(
                          (widget.data['num_n'] / widget.data['level5_n'])
                              .toStringAsFixed(2)
                              .toString(),
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text('平均消耗星声'),
                        additionalInfo: Text(
                          (widget.data['num_n'] * 160 / widget.data['level5_n'])
                              .toStringAsFixed(2)
                              .toString(),
                        ),
                      ),
                    ],
                  ),
              ]
            : null,
      );
    }

    return Column(
      children: [
        CupertinoListSection.insetGrouped(
          header: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'UID ${widget.uid}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Expanded(
                  child: Text(
                    DateTime.now().toString().split(' ')[0],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      hideTotal ? '隐藏' : '显示',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      hideTotal = !hideTotal;
                    });
                  },
                ),
              ],
            ),
          ),
          children: hideTotal
              ? [
                  CupertinoListTile(
                    title: const Text('总抽数'),
                    additionalInfo: Text(widget.data['num'].toString()),
                  ),
                  CupertinoListTile(
                    title: const Text('消耗星声'),
                    additionalInfo: Text((widget.data['num'] * 160).toString()),
                  ),
                  CupertinoListTile(
                    title: const Text('五星唤取'),
                    additionalInfo: Text(
                      (widget.data['level5_c'] +
                              widget.data['level5_w'] +
                              widget.data['level5_n'])
                          .toString(),
                    ),
                  ),
                ]
              : null,
        ),
        renderPoolCard(),
      ],
    );
  }
}
