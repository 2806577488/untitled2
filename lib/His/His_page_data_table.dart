import 'package:flutter/material.dart';
import '../utils/editable_table.dart';
class DataTableWidget extends StatefulWidget {
  final Future<List<dynamic>> dataFuture;
  final void Function(TableRowData province) onEdit; // 修复类型
  final void Function(TableRowData province) onDelete; // 修复类型
  final VoidCallback onSave;
  final Function(TableRowData newRow) onAddNew;

  const DataTableWidget({
    super.key,
    required this.dataFuture,
    required this.onEdit,
    required this.onDelete,
    required this.onSave,
    required this.onAddNew,
  });

  @override
  State<DataTableWidget> createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  List<TableRowData> _tableData = [];
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await widget.dataFuture;
    setState(() {
      _tableData = data.map((item) {
        return TableRowData(
          id: _nextId++,
          name: item['Name']?.toString() ?? '',
          code: item['Code']?.toString() ?? '',
          pyCode: item['PyCode']?.toString() ?? '',
          wbCode: item['WbCode']?.toString() ?? '',
          isActive: item['IsActive'] as bool? ?? true,
        );
      }).toList();
    });
  }

  void _handleEdit(int id) {
    setState(() {
      final row = _tableData.firstWhere((row) => row.id == id);
      row.isEditing = true;
    });
  }

  void _handleDelete(int id) {
    setState(() {
      final row = _tableData.firstWhere((row) => row.id == id);
      widget.onDelete(row);
      _tableData.removeWhere((row) => row.id == id);
    });
  }

  void _handleSave(int id, String name, String code, String pyCode, String wbCode, bool isActive) {
    setState(() {
      final row = _tableData.firstWhere((row) => row.id == id);
      row.name = name;
      row.code = code;
      row.pyCode = pyCode;
      row.wbCode = wbCode;
      row.isActive = isActive;
      row.isEditing = false;
      widget.onEdit(row);
    });
    widget.onSave();
  }

  void _handleAddNew() {
    setState(() {
      final newRow = TableRowData(
        id: _nextId++,
        name: '新省份',
        code: '',
        pyCode: '',
        wbCode: '',
        isEditing: true,
      );
      _tableData = [..._tableData, newRow];
      widget.onAddNew(newRow);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: widget.dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('错误: ${snapshot.error}'));
        }

        return EditableTable(
          data: _tableData,
          onEdit: _handleEdit,
          onDelete: _handleDelete,
          onSave: _handleSave,
          onAddNew: _handleAddNew,
          title: '省份数据管理',
        );
      },
    );
  }
}