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

  final List<Widget> _pages = [
    const HisPageBaseTable(),
    const HisPageProjectDict(),
    const HisPageComboPackage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40), // 缩小表头高度
        child: AppBar(
          title: const Text('HIS 系统'),
          centerTitle: true,
          backgroundColor: const Color(0xFF1a2980),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a2980), Color(0xFF26d0ce)],
          ),
        ),
        child: Row(
          children: [
            // 左侧菜单 - 缩小宽度
            Container(
              width: 150,
              color: Colors.grey.shade100.withOpacity(0.2),
              child: ListView.builder(
                itemCount: _pages.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(
                    _getMenuItemTitle(index),
                    style: TextStyle(
                      color: index == _selectedIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.8),
                    ),
                  ),
                  selected: index == _selectedIndex,
                  selectedTileColor: Colors.white.withOpacity(0.2),
                  selectedColor: Colors.white,
                  onTap: () => setState(() => _selectedIndex = index),
                ),
              ),
            ),
            // 主内容区域 - 占满剩余空间
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _pages[_selectedIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMenuItemTitle(int index) {
    switch (index) {
      case 0: return '基础表格';
      case 1: return '项目字典维护';
      case 2: return '组合套餐维护';
      default: return '未知菜单';
    }
  }
}