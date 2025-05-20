import 'package:flutter/material.dart';

class AppStyles {
  // 颜色
  static const Color primaryColor = Colors.blue;
  static const Color textColor = Colors.grey;
  static const Color selectedColor = Colors.lightBlue;

  // 字体大小
  static const double fontSizeLarge = 16.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeSmall = 12.0;

  // 边距和间距
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: 12.0);
  static const EdgeInsets allPadding = EdgeInsets.all(8.0);

  // 分割线样式
  static const Divider divider = Divider(
    height: 1.0,
    color: Colors.grey,
    indent: 16.0,
    endIndent: 16.0,
  );

  // 表头样式
  static PreferredSizeWidget tableHeader = PreferredSize(
    preferredSize: const Size.fromHeight(48.0),
    child: Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('省份', textAlign: TextAlign.center)),
          Expanded(child: Text('编码', textAlign: TextAlign.center)),
          Expanded(child: Text('拼音码', textAlign: TextAlign.center)),
          Expanded(child: Text('五笔码', textAlign: TextAlign.center)), // 添加五笔码列
          Expanded(child: Text('状态', textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('操作', textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}