import 'package:flutter/material.dart';
import '../models/table_row_data.dart';
import '../models/table_column_config.dart';
import '../utils/editable_table.dart';

class DataTableWidget extends StatelessWidget {
  final List<TableRowData> data;
  final String title;
  final List<TableColumnConfig> columns;
  final Function(int id) onEdit;
  final Function(int id) onDelete;
  final Function(TableRowData row) onSave;
  final Function() onAddNew;

  const DataTableWidget({
    super.key,
    required this.data,
    required this.title,
    required this.columns,
    required this.onEdit,
    required this.onDelete,
    required this.onSave,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return EditableTable(
      data: data,
      title: title,
      columns: columns,
      onEdit: onEdit,
      onDelete: onDelete,
      onSave: onSave,
      onAddNew: onAddNew,
    );
  }
}