import 'package:flutter/material.dart';

class HisPage extends StatelessWidget {
  final String userId;
  final String loginLocation;

  const HisPage({
    super.key,
    required this.userId,
    required this.loginLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 横向排列并两端对齐
          children: [
            const Text('HIS系统'),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('用户：$userId',
                        style: TextStyle(fontSize: 14, color: Colors.white70)),
                    Text('地点：$loginLocation',
                        style: TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Placeholder(), // 替换实际内容
            ),
          ],
        ),
      ),
    );
  }
}