import 'package:flutter/material.dart';
import '../models/table_column_config.dart';
import '../models/table_row_data.dart';
import '../utils/tree_view.dart' show TreeView, TreeNode; // 显式导入 TreeNode
import 'His_page_data.dart';
import 'His_page_data_table.dart';

class HisPageBaseTable extends StatefulWidget {
  const HisPageBaseTable({super.key});

  @override
  State<HisPageBaseTable> createState() => _HisPageBaseTableState();
}

class _HisPageBaseTableState extends State<HisPageBaseTable> {
  String? _selectedNodeTitle;
  List<TableRowData> _provinceData = [];
  List<TableRowData> _usageData = [];
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final province = await fetchProvinceData();
      final usage = await getUsage();
      setState(() {
        _provinceData = province;
        _usageData = usage;

        // 安全处理空列表
        final allIds = [..._provinceData.map((e) => e.id), ..._usageData.map((e) => e.id)];
        if (allIds.isNotEmpty) {
          _nextId = allIds.reduce((a, b) => a > b ? a : b) + 1;
        } else {
          _nextId = 1;
        }
      });
    } catch (e) {
      print('加载数据错误: $e');
    }
  }

  // 省份列配置
  final List<TableColumnConfig> _provinceColumns = [
    TableColumnConfig(key: "Name", title: "省份名称", hint: "请输入省份名称"),
    TableColumnConfig(key: "Code", title: "编码", hint: "请输入编码"),
    TableColumnConfig(key: "PyCode", title: "拼音码", hint: "请输入拼音码"),
    TableColumnConfig(key: "WbCode", title: "五笔码", hint: "请输入五笔码"),
  ];

  // 用法列配置
  final List<TableColumnConfig> _usageColumns = [
    TableColumnConfig(key: "Name", title: "用法名称", hint: "请输入用法名称"),
    TableColumnConfig(key: "Code", title: "编码", hint: "请输入编码"),
    TableColumnConfig(key: "PyCode", title: "拼音码", hint: "请输入拼音码"),
    TableColumnConfig(key: "WbCode", title: "五笔码", hint: "请输入五笔码"),
    TableColumnConfig(key: "PrintName", title: "简称", hint: "请输入简称"),
    TableColumnConfig(key: "LsUseArea",title: "使用范围",hint: "")
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 220,
            child: TreeView(
              nodes: _createTreeData(),
              onNodeSelected: _handleNodeSelected,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _buildDataContent()),
        ],
      ),
    );
  }

  // 添加缺失的树数据创建方法
  List<TreeNode> _createTreeData() {
    return [
      TreeNode(title: "用户信息基本表", children: [
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
      ]),
      TreeNode(title: "项目维护", children: [
        TreeNode(title: "用法")
      ]),
    ];
  }

  // 添加缺失的节点选择处理方法
  void _handleNodeSelected(TreeNode node) {
    setState(() => _selectedNodeTitle = node.title);
  }

  // 添加缺失的数据内容构建方法
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
      child: _selectedNodeTitle != null
          ? _buildDataTable()
          : const Center(child: Text('请从左侧选择数据项')),
    );
  }

  // 添加缺失的数据表格构建方法
  Widget _buildDataTable() {
    switch (_selectedNodeTitle) {
      case "省份":
        return _buildProvinceTable();
      case "用法":
        return _buildUsageTable();
      default:
        return const Center(child: Text('该节点暂无数据'));
    }
  }

  Widget _buildProvinceTable() {
    return DataTableWidget(
      data: _provinceData,
      title: "省份数据",
      columns: _provinceColumns,
      onEdit: (id) => _handleEdit(id, _provinceData),
      onDelete: (id) => _handleDelete(id, _provinceData),
      onSave: _handleSaveProvince,
      onAddNew: _handleAddNewProvince,
    );
  }

  Widget _buildUsageTable() {
    return DataTableWidget(
      data: _usageData,
      title: "用法数据",
      columns: _usageColumns,
      onEdit: (id) => _handleEdit(id, _usageData),
      onDelete: (id) => _handleDelete(id, _usageData),
      onSave: _handleSaveUsage,
      onAddNew: _handleAddNewUsage,
    );
  }

  void _handleEdit(int id, List<TableRowData> dataList) {
    setState(() {
      final row = dataList.firstWhere((row) => row.id == id);
      row.isEditing = true;
    });
  }

  void _handleDelete(int id, List<TableRowData> dataList) {
    setState(() => dataList.removeWhere((row) => row.id == id));
    print('删除行: $id');
  }

  void _handleSaveProvince(TableRowData row) {
    print('保存省份数据: ${row.values}');
    setState(() => row.isEditing = false);
  }

  void _handleSaveUsage(TableRowData row) {
    print('保存用法数据: ${row.values}');
    setState(() => row.isEditing = false);
  }

  void _handleAddNewProvince() {
    setState(() {
      _provinceData.add(TableRowData(
        id: _nextId++,
        values: {"Name": "新省份"},
        isEditing: true,
      ));
    });
  }

  void _handleAddNewUsage() {
    setState(() {
      _usageData.add(TableRowData(
        id: _nextId++,
        values: {"UsageName": "新用法"},
        isEditing: true,
      ));
    });
  }
}