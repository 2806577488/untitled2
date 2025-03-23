import 'package:flutter/material.dart';

class DataPage extends StatelessWidget {
  final String userId;
  final String loginLocation;

  const DataPage({
    super.key,
    required this.userId,
    required this.loginLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据系统')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('用户 ID: $userId'),
            Text('登录地点: $loginLocation'),
            const Text('这是数据系统界面'),
          ],
        ),
      ),
    );
  }
}