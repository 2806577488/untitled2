import 'package:flutter/material.dart';

class SalesPage extends StatelessWidget {
  final String userId;
  final String loginLocation;

  const SalesPage({
    super.key,
    required this.userId,
    required this.loginLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('销售系统')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('用户 ID: $userId'),
            Text('登录地点: $loginLocation'),
            const Text('这是销售系统界面'),
          ],
        ),
      ),
    );
  }
}