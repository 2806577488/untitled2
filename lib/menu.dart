import 'package:flutter/material.dart';

class Menu extends StatelessWidget {
  final String userId;
  final String loginLocation;
  final Function(String) onMessageUpdate;

  const Menu({
    super.key,
    required this.onMessageUpdate,
    required this.userId,
    required this.loginLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // 增加高度
      color: Colors.blue.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 16), // 添加水平边距
      child: Row(
        children: [
          // 左侧菜单按钮
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => onMessageUpdate("打开菜单"),
          ),

          // 中间用户信息（使用Expanded替代Spacer）
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '用户: $userId',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '地点: $loginLocation',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 右侧设置按钮
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => onMessageUpdate("打开设置"),
          ),
        ],
      ),
    );
  }
}
