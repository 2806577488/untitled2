import 'package:flutter/material.dart';
import 'His_page_base_table.dart';
import 'His_page_project_dict.dart';
import 'His_page_combo_package.dart';

class HisPage extends StatefulWidget {
  final String userId;
  final String loginLocation;

  const HisPage({super.key, required this.userId, required this.loginLocation});

  @override
  State<HisPage> createState() => _HisPageState();
}

class _HisPageState extends State<HisPage> {
  int _selectedIndex = 0;
  final List<String> _menuItems = ['基础表格', '项目字典维护', '组合套餐维护'];
  final List<Widget> _pages = [
    HisPageBaseTable(),
    HisPageProjectDict(),
    HisPageComboPackage(),
  ];

  void _handleMenuTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HIS 系统'),
      ),
      body: Row(
        children: [
          // 左侧菜单
          Container(
            width: 200,
            color: Colors.grey.shade100,
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_menuItems[index]),
                selected: index == _selectedIndex,
                selectedTileColor: Colors.blue.shade50,
                selectedColor: Colors.blue.shade800,
                onTap: () => _handleMenuTap(index),
              ),
            ),
          ),
          // 主内容区域
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}