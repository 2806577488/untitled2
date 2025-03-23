import 'package:flutter/material.dart';

class PacsPage extends StatelessWidget {
  final String userId;
  final String loginLocation;

  const PacsPage({
    super.key,
    required this.userId,
    required this.loginLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PACS 系统')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('用户 ID: $userId'),
            Text('登录地点: $loginLocation'),
            const Text('这是 PACS 系统界面'),
          ],
        ),
      ),
    );
  }
}