import 'package:flutter/material.dart';
import 'His_page_tree.dart';
import 'His_page_data.dart';
import 'His_page_data_table.dart';

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
  Future<List<dynamic>>? _dataFuture;
  bool _showData = false;
  bool _showTree = false;

  // 定义“基础表格”对应的树形数据
  final List<TreeNode> _basicTableTreeData = [
    TreeNode(
      title: "用户信息基本表",
      children: [
        TreeNode(title: "省份"),
        TreeNode(title: "区/县"),
        TreeNode(title: "学历"),
        TreeNode(title: "民族"),
        TreeNode(title: "用户类别"),
        TreeNode(title: "记帐类别"),
        TreeNode(title: "用户大类"),
        TreeNode(title: "既往史维护"),
        TreeNode(title: "市/县"),
        TreeNode(title: "开发渠道"),
        TreeNode(title: "媒体渠道"),
      ],
    ),
  ];

  late ValueNotifier<List<TreeNode>> _expandedNodes;

  @override
  void initState() {
    super.initState();
    _expandedNodes = ValueNotifier<List<TreeNode>>([]);
    // 加载页面时开始获取数据，并默认选中“基础表格”
    _dataFuture = fetchData();
    _handleMenuTap(0); // 默认选中“基础表格”
  }

  @override
  void dispose() {
    _expandedNodes.dispose();
    super.dispose();
  }

  void _handleEdit(dynamic province) => print('编辑: ${province['Name']}');
  void _handleDelete(dynamic province) => print('删除: ${province['Name']}');
  void _handleSave() => print('保存数据');

  void _handleMenuTap(int index) {
    setState(() {
      _selectedIndex = index;
      // 重置展开状态和显示状态
      _expandedNodes.value = [];
      _showTree = index == 0; // 只有“基础表格”显示树形结构
      if (index == 0) {
        // 展开“用户信息基本表”节点
        _expandedNodes.value = [..._expandedNodes.value, _basicTableTreeData[0]];
        // 默认显示“省份”数据
        _showData = true;
      } else {
        // 其他菜单项不显示数据
        _showData = false;
      }
    });
  }

  void _handleNodeSelected(TreeNode node) {
    if (node.title == "省份") {
      setState(() {
        _showData = true;
      });
    } else {
      setState(() {
        _showData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
      ),
      body: Row(
        children: [
          // 左侧菜单
          Container(
            width: 120,
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
          // 树形导航
          Container(
            width: 250,
            color: Colors.white,
            child: _showTree
                ? TreeListView(
              nodes: _basicTableTreeData,
              rootNodes: _basicTableTreeData,
              expandedNodes: _expandedNodes,
              onNodeSelected: _handleNodeSelected,
            )
                : Container(),
          ),
          // 主内容区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _showData && _dataFuture != null
                  ? DataTableWidget(
                dataFuture: _dataFuture!,
                onEdit: _handleEdit,
                onDelete: _handleDelete,
                onSave: _handleSave,
              )
                  : Container(),
            ),
          ),
        ],
      ),
    );
  }
}