import 'package:flutter/material.dart';
import '../models/table_column_config.dart';
import '../models/table_row_data.dart';
import '../utils/tree_view.dart' show TreeView, TreeNode;
import '../utils/editable_table.dart';
import '../tools/error.dart';
import 'his_page_data.dart';

class HisPageBaseTable extends StatefulWidget {
  const HisPageBaseTable({super.key});

  @override
  State<HisPageBaseTable> createState() => _HisPageBaseTableState();
}

class _HisPageBaseTableState extends State<HisPageBaseTable> {
  final Map<int, GlobalKey> _rowKeys = {};
  int? _newlyInsertedId;
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
      GlobalErrorHandler.logDebug('开始加载数据...');
      
      final province = await fetchProvinceData();
      GlobalErrorHandler.logDebug('省份数据加载完成: ${province.length} 条');
      
      final usage = await getUsage();
      GlobalErrorHandler.logDebug('用法数据加载完成: ${usage.length} 条');
      
      if (mounted) {
        setState(() {
          _provinceData = province;
          _usageData = usage;

          // 安全处理空列表
          final allIds = [
            ..._provinceData.map((e) => e.id),
            ..._usageData.map((e) => e.id)
          ];
          if (allIds.isNotEmpty) {
            _nextId = allIds.reduce((a, b) => a > b ? a : b) + 1;
          } else {
            _nextId = 1;
          }
          
          GlobalErrorHandler.logDebug('数据加载完成 - 省份: ${_provinceData.length} 条, 用法: ${_usageData.length} 条');
        });
      }
    } catch (e, stack) {
      if (mounted && context.mounted) {
        GlobalErrorHandler.logAndShowError(
          context: context,
          exception: e,
          stackTrace: stack,
          title: "数据加载失败",
          mounted: mounted,
        );
      }
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
    TableColumnConfig(key: "Name", title: "用法名称", hint: "请输入用法名称", width: 120),
    TableColumnConfig(key: "Code", title: "编码", hint: "请输入编码"),
    TableColumnConfig(key: "PyCode", title: "拼音码", hint: "请输入拼音码"),
    TableColumnConfig(key: "WbCode", title: "五笔码", hint: "请输入五笔码"),
    TableColumnConfig(key: "PrintName", title: "简称", hint: "请输入简称"),
    TableColumnConfig(
      key: "LsUseArea",
      title: "可用范围",
      hint: "请选择可用范围",
      valueMap: {
        '1': '门诊',
        '2': '住院',
        '3': '共用',
      },
    ),
    TableColumnConfig(
      key: "LsPrnFormType",
      title: "药房分类单打印类别",
      hint: "请指定口服/注射打印",
      valueMap: {
        '1': '口服药单',
        '2': '针剂汇总单',
      },
    ),
    TableColumnConfig(
      key: "IsPrintLabel",
      title: "是否打印瓶签",
      isBooleanColumn: true,
      hint: '',
    ),
    TableColumnConfig(
      key: "IsPrintReject",
      title: "是否打印注射单",
      isBooleanColumn: true,
      hint: '',
    ),
    TableColumnConfig(
      key: "IsPrintDrug",
      title: "是否打印口服药单",
      isBooleanColumn: true,
      hint: '',
    ),
    TableColumnConfig(
      key: "IsPrintAst",
      title: "是否打印肝功能化验单",
      isBooleanColumn: true,
      hint: '',
    ),
    TableColumnConfig(
      key: "IsPrintCure",
      title: "是否打印治疗单",
      isBooleanColumn: true,
      hint: '',
    ),
    TableColumnConfig(
      key: "IsPrintNurse",
      title: "是否打印护理单",
      isBooleanColumn: true,
      hint: '',
    ),
    TableColumnConfig(
      key: "IsPrintExternal",
      title: "是否打印外用单",
      isBooleanColumn: true,
      hint: '',
    ),
    TableColumnConfig(
      key: "IsPrintPush",
      title: "是否打印静推单",
      isBooleanColumn: true,
      hint: '',
    ),
    TableColumnConfig(
      key: "IsPrintRejSkin",
      title: "是否打印皮下注射单",
      isBooleanColumn: true,
      hint: '',
    ),
    TableColumnConfig(
      key: "IsPrintDietetic",
      title: "是否打印饮食单",
      isBooleanColumn: true,
      hint: '',
    ),
    TableColumnConfig(
      key: "IsMzDrop",
      title: "是否打印门诊输液单",
      isBooleanColumn: true,
      hint: '',
    ),
    TableColumnConfig(
      key: "IsMzReject",
      title: "是否打印门诊注射单",
      isBooleanColumn: true,
      hint: '',
    ),
    TableColumnConfig(
      key: "IsMzCure",
      title: "是否打印门诊治疗单",
      isBooleanColumn: true,
      hint: '',
    ),
    TableColumnConfig(
      key: "IsPrintAtomization",
      title: "是否打印雾化单",
      isBooleanColumn: true,
      hint: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
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

  // 创建树形数据
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

  // 处理节点选择
  void _handleNodeSelected(TreeNode node) {
    setState(() => _selectedNodeTitle = node.title);
  }

  // 构建数据内容区域
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
            color: _withOpacity(Colors.black, 0.1),
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

  // 创建带透明度的颜色
  static Color _withOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  // 构建数据表格
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
    return EditableTable(
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
    return EditableTable(
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
    GlobalErrorHandler.logErrorOnly('删除行: $id', StackTrace.current);
  }

  void _handleSaveProvince(TableRowData row) {
    GlobalErrorHandler.logErrorOnly('保存省份数据: ${row.values}', StackTrace.current);
    setState(() => row.isEditing = false);
  }

  void _handleSaveUsage(TableRowData row) async {
    if (row.values.containsKey('LsUseArea')) {
      final value = row.values['LsUseArea'];
      if (value is String && value.contains('-')) {
        row.values['LsUseArea'] = value.split('-').first;
      }
    }
    
    try {
      final List<Map<String, dynamic>> usageData = [row.values];
      await saveBsUsageToServer(usageData);
      
      // 保存成功
      if (mounted && context.mounted) {
        GlobalErrorHandler.showSuccess(
          context: context,
          message: '用法数据保存成功',
          mounted: mounted,
        );
      }
    } catch (e, stack) {
      if (mounted && context.mounted) {
        GlobalErrorHandler.logAndShowError(
          context: context,
          exception: e,
          stackTrace: stack,
          title: '保存用法数据失败',
          mounted: mounted,
        );
      }
      return; // 保存失败时不关闭编辑状态
    }
    
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
    final hasUnsaved = _usageData.any((row) => row.isEditing);
    if (hasUnsaved) {
      if (mounted && context.mounted) {
        GlobalErrorHandler.showSimpleError(
          context: context,
          message: '请先保存当前编辑的行',
          title: '提示',
          mounted: mounted,
        );
      }
      return;
    }

    final newId = _nextId++;

    setState(() {
      _rowKeys[newId] = GlobalKey();
      _usageData.add(TableRowData(
        id: newId,
        values: {},
        isEditing: true,
      ));
      _newlyInsertedId = newId;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _rowKeys[_newlyInsertedId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }
} 