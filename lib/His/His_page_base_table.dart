import 'package:flutter/material.dart';
import '../utils/tree_view.dart';
import 'His_page_data_table.dart';
import 'His_page_data.dart';
import '../utils/editable_table.dart'; // 添加导入

class HisPageBaseTable extends StatefulWidget {
  const HisPageBaseTable({super.key});

  @override
  State<HisPageBaseTable> createState() => _HisPageBaseTableState();
}

class _HisPageBaseTableState extends State<HisPageBaseTable> {
  bool _showData = true;
  Future<List<dynamic>>? _dataFuture;
  final List<TreeNode> _treeData = _createTreeData();

  @override
  void initState() {
    super.initState();
    _dataFuture = fetchProvinceData();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧树形菜单
          Container(
            width: 220,
            child: TreeView(
              nodes: _treeData,
              onNodeSelected: _handleNodeSelected,
            ),
          ),
          const SizedBox(width: 16),
          // 右侧内容
          Expanded(
            child: _buildDataContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataContent() {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height - 100,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _showData && _dataFuture != null
          ? FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          }
          return DataTableWidget(
            dataFuture: _dataFuture!,
            onEdit: _handleEdit,
            onDelete: _handleDelete,
            onSave: _handleSave,
            onAddNew: _handleAddNew,
          );
        },
      )
          : const Center(child: Text('请从左侧选择数据项')),
    );
  }

  void _handleNodeSelected(TreeNode node) {
    setState(() {
      _showData = node.title == "省份";
    });
  }

  // 修复类型：使用 TableRowData 而不是 dynamic
  void _handleEdit(TableRowData province) => print('编辑: ${province.name}');

  // 修复类型：使用 TableRowData 而不是 dynamic
  void _handleDelete(TableRowData province) => print('删除: ${province.name}');

  void _handleSave() => print('保存数据');

  // 修复类型：使用 TableRowData 而不是 dynamic
  void _handleAddNew(TableRowData newRow) => print('添加新行: ${newRow.name}');

  static List<TreeNode> _createTreeData() {
    return [
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
  }
}