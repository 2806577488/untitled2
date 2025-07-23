import 'package:flutter/material.dart';
import '../models/table_row_data.dart';
import '../models/table_column_config.dart';
import '../utils/editable_table.dart';
import '../tools/error.dart';
import 'his_page_data.dart';

class HisPageProjectDict extends StatefulWidget {
  const HisPageProjectDict({super.key});

  @override
  State<HisPageProjectDict> createState() => _HisPageProjectDictState();
}

class _HisPageProjectDictState extends State<HisPageProjectDict> {
  Map<int, List<TableRowData>> _allData = {};
  int _selectedCategory = 1;
  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = '正在加载项目分类数据...';
    });

    try {
      final data = await getAllBsItemData();
      if (mounted) {
        setState(() {
          _allData = data;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      if (mounted && context.mounted) {
        GlobalErrorHandler.logAndShowError(
          context: context,
          exception: e,
          stackTrace: stack,
          title: "项目分类数据加载失败",
          mounted: mounted,
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSingleCategory(int categoryId) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = '正在加载${ProjectCategories.getCategoryName(categoryId)}数据...';
    });

    try {
      final data = await getBsItemAllData(categoryId);
      if (mounted) {
        setState(() {
          _allData[categoryId] = data;
          _selectedCategory = categoryId;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      if (mounted && context.mounted) {
        GlobalErrorHandler.logAndShowError(
          context: context,
          exception: e,
          stackTrace: stack,
          title: "${ProjectCategories.getCategoryName(categoryId)}数据加载失败",
          mounted: mounted,
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目分类数据'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: '刷新所有数据',
          ),
        ],
      ),
      body: Column(
        children: [
          // 分类选择器
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('选择分类: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: ProjectCategories.categories.entries.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text('${entry.key}-${entry.value}'),
                      );
                    }).toList(),
                    onChanged: _isLoading ? null : (int? value) {
                      if (value != null) {
                        _loadSingleCategory(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '共 ${_allData[_selectedCategory]?.length ?? 0} 条数据',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // 加载指示器
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 16),
                  Text(_loadingMessage),
                ],
              ),
            ),
          
          // 数据表格
          Expanded(
            child: _allData[_selectedCategory]?.isNotEmpty == true
                ? EditableTable(
                    title: ProjectCategories.getCategoryName(_selectedCategory),
                    data: _allData[_selectedCategory]!,
                    columns: _getColumnsForCategory(_selectedCategory),
                    onAddNew: () {
                      // 添加新项目
                      GlobalErrorHandler.logDebug('添加新${ProjectCategories.getCategoryName(_selectedCategory)}项目');
                    },
                    onEdit: (int id) {
                      // 编辑项目
                      GlobalErrorHandler.logDebug('编辑项目ID: $id');
                    },
                    onDelete: (int id) {
                      // 删除项目
                      GlobalErrorHandler.logDebug('删除项目ID: $id');
                    },
                    onSave: (TableRowData row) {
                      // 保存项目
                      GlobalErrorHandler.logDebug('保存项目: ${row.values}');
                    },
                  )
                : Center(
                    child: Text(
                      _isLoading 
                          ? '正在加载数据...' 
                          : '暂无${ProjectCategories.getCategoryName(_selectedCategory)}数据',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig> _getColumnsForCategory(int categoryId) {
    // 根据分类返回不同的列配置
    switch (categoryId) {
      case 1: // 中成药
      case 2: // 西药
      case 3: // 中药
        return [
          TableColumnConfig(key: 'Name', title: '药品名称', hint: '请输入药品名称'),
          TableColumnConfig(key: 'Code', title: '编码', hint: '请输入编码'),
          TableColumnConfig(key: 'Spec', title: '规格', hint: '请输入规格'),
          TableColumnConfig(key: 'Unit', title: '单位', hint: '请输入单位'),
          TableColumnConfig(key: 'Price', title: '价格', hint: '请输入价格'),
          TableColumnConfig(key: 'Manufacturer', title: '生产厂家', hint: '请输入生产厂家'),
        ];
      case 4: // 检验
      case 5: // 检查
        return [
          TableColumnConfig(key: 'Name', title: '项目名称', hint: '请输入项目名称'),
          TableColumnConfig(key: 'Code', title: '编码', hint: '请输入编码'),
          TableColumnConfig(key: 'Price', title: '价格', hint: '请输入价格'),
          TableColumnConfig(key: 'Department', title: '执行科室', hint: '请输入执行科室'),
        ];
      case 6: // 手术
      case 7: // 治疗
        return [
          TableColumnConfig(key: 'Name', title: '项目名称', hint: '请输入项目名称'),
          TableColumnConfig(key: 'Code', title: '编码', hint: '请输入编码'),
          TableColumnConfig(key: 'Price', title: '价格', hint: '请输入价格'),
          TableColumnConfig(key: 'Duration', title: '时长', hint: '请输入时长'),
        ];
      default:
        return [
          TableColumnConfig(key: 'Name', title: '项目名称', hint: '请输入项目名称'),
          TableColumnConfig(key: 'Code', title: '编码', hint: '请输入编码'),
          TableColumnConfig(key: 'Price', title: '价格', hint: '请输入价格'),
          TableColumnConfig(key: 'Description', title: '描述', hint: '请输入描述'),
        ];
    }
  }
}