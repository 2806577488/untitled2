import 'package:flutter/material.dart';
import 'his_page_base_table.dart';
import 'his_page_project_dict.dart';
import 'his_page_combo_package.dart';

class HisPage extends StatefulWidget {
  final String userId;
  final String loginLocation;
  final String hospitalId;
  final String hisType;

  const HisPage({
    super.key, 
    required this.userId, 
    required this.loginLocation,
    required this.hospitalId,
    required this.hisType,
  });

  @override
  State<HisPage> createState() => _HisPageState();
}

class _HisPageState extends State<HisPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // 在initState中初始化_pages，以便能够访问widget参数
    _pages = [
      HisPageBaseTable(
        hospitalId: widget.hospitalId,
        hisType: widget.hisType,
      ),
      HisPageProjectDict(
        hospitalId: widget.hospitalId,
        hisType: widget.hisType,
      ),
    const HisPageComboPackage(),
  ];
  }

  // 创建带透明度的颜色
  static Color _withOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: AppBar(
          title: const Text('HIS 系统', style: TextStyle(color: Colors.white)),
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
            // 左侧菜单
            Container(
              width: 120,
              color: _withOpacity(Colors.grey.shade100, 0.2),
              child: ListView.builder(
                itemCount: _pages.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(
                    _getMenuItemTitle(index),
                    style: TextStyle(
                      color: index == _selectedIndex
                          ? Colors.white
                          : _withOpacity(Colors.white, 0.8),
                    ),
                  ),
                  selected: index == _selectedIndex,
                  selectedTileColor: _withOpacity(Colors.white, 0.2),
                  selectedColor: Colors.white,
                  onTap: () => setState(() => _selectedIndex = index),
                ),
              ),
            ),
            // 主内容区域
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _withOpacity(Colors.white, 0.9),
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
      case 0:
        return '基础表格';
      case 1:
        return '项目字典维护';
      case 2:
        return '组合套餐维护';
      default:
        return '未知菜单';
    }
  }
}