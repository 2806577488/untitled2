import 'package:flutter/material.dart';
import '../models/table_column_config.dart';
import '../models/table_row_data.dart';

class EditableTable extends StatefulWidget {
  final List<TableRowData> data;
  final Function(int id) onEdit;
  final Function(int id) onDelete;
  final Function(TableRowData row) onSave;
  final Function() onAddNew;
  final String title;
  final List<TableColumnConfig> columns;
  final Color? headerColor;
  final Color? footerColor;

  const EditableTable({
    Key? key,
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onSave,
    required this.onAddNew,
    required this.title,
    required this.columns,
    this.headerColor,
    this.footerColor,
  }) : super(key: key);

  @override
  _EditableTableState createState() => _EditableTableState();
}

class _EditableTableState extends State<EditableTable> {
  final Map<int, Map<String, TextEditingController>> _controllers = {};

  // 创建带透明度的颜色
  static Color _withOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var row in widget.data) {
      _initRowControllers(row);
    }
  }

  void _initRowControllers(TableRowData row) {
    _controllers[row.id] = {};
    for (final column in widget.columns) {
      _controllers[row.id]![column.key] = TextEditingController(
          text: row.getValue(column.key).toString()
      );
    }
  }

  @override
  void didUpdateWidget(EditableTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 更新控制器
    for (var row in widget.data) {
      if (!_controllers.containsKey(row.id)) {
        _initRowControllers(row);
      } else {
        // 更新现有行的控制器值
        for (final column in widget.columns) {
          final controller = _controllers[row.id]![column.key];
          if (controller != null &&
              controller.text != row.getValue(column.key).toString()) {
            controller.text = row.getValue(column.key).toString();
          }
        }
      }
    }

    // 移除不再存在的行的控制器
    final currentIds = widget.data.map((r) => r.id).toSet();
    final toRemove = _controllers.keys.where((id) => !currentIds.contains(id))
        .toList();
    for (var id in toRemove) {
      _removeRowControllers(id);
    }
  }

  void _removeRowControllers(int id) {
    if (_controllers.containsKey(id)) {
      for (var controller in _controllers[id]!.values) {
        controller.dispose();
      }
      _controllers.remove(id);
    }
  }

  @override
  void dispose() {
    for (var controllers in _controllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    _controllers.clear();
    super.dispose();
  }

  Widget _buildCell({
    required bool isEditing,
    required String controllerKey,
    required String hintText,
    required String value,
    required int rowId,
    double? width,
  }) {
    final controller = _controllers[rowId]?[controllerKey];

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFe0e0e0),
          width: 1,
        ),
      ),
      child: isEditing
          ? TextField(
        controller: controller,
        decoration: InputDecoration.collapsed(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
        style: const TextStyle(fontSize: 16),
      )
          : Text(
        value,
        style: const TextStyle(fontSize: 16),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = widget.headerColor ?? const Color(0xFF1a2980);
    final footerColor = widget.footerColor ?? const Color(0xFF1a2980);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 表格标题
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2980),
                ),
              ),
            ),

            // 表头区域
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: _withOpacity(headerColor, 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // 配置列
                  for (final column in widget.columns)
                    _buildHeaderCell(column),

                  // 状态列
                  const Expanded(
                    child: Text(
                      '状态',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),

                  // 操作列
                  const SizedBox(
                    width: 140,
                    child: Text(
                      '操作',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 数据行
            Expanded(
              child: ListView.builder(
                itemCount: widget.data.length,
                itemBuilder: (context, index) {
                  final row = widget.data[index];
                  final isEditing = row.isEditing;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isEditing
                          ? const Color(0xFFfffacd)
                          : const Color(0xFFf8f9fa),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isEditing
                            ? const Color(0xFFffcc00)
                            : const Color(0xFFe0e0e0),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // 配置列
                          for (final column in widget.columns)
                            _buildDataCell(column, row),

                          // 状态列
                          _buildStatusCell(row),

                          // 操作列
                          _buildActionCell(row),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 底部区域
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: _withOpacity(footerColor, 0.9),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '共 ${widget.data.length} 行数据',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: widget.onAddNew,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('添加新行'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(TableColumnConfig column) {
    return column.width != null
        ? SizedBox(
      width: column.width,
      child: Text(
        column.title,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold
        ),
      ),
    )
        : Expanded(
      flex: 1,
      child: Text(
        column.title,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  Widget _buildDataCell(TableColumnConfig column, TableRowData row) {
    return column.width != null
        ? SizedBox(
      width: column.width,
      child: _buildCell(
        isEditing: row.isEditing && column.isEditable,
        controllerKey: column.key,
        hintText: column.hint,
        value: row.getValue(column.key).toString(),
        rowId: row.id,
        width: column.width,
      ),
    )
        : Expanded(
      flex: 1,
      child: _buildCell(
        isEditing: row.isEditing && column.isEditable,
        controllerKey: column.key,
        hintText: column.hint,
        value: row.getValue(column.key).toString(),
        rowId: row.id,
      ),
    );
  }

  Widget _buildStatusCell(TableRowData row) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            row.isActive = !row.isActive;
            widget.onSave(row);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: row.isActive ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              row.isActive ? '启用' : '禁用',
              style: TextStyle(
                  color: row.isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCell(TableRowData row) {
    return SizedBox(
      width: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 编辑/保存按钮
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3498db), Color(0xFF2980b9)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _withOpacity(Colors.blue, 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                row.isEditing ? Icons.save : Icons.edit,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                if (row.isEditing) {
                  // 保存时更新所有字段的值
                  for (final column in widget.columns) {
                    final controller = _controllers[row.id]![column.key];
                    if (controller != null) {
                      row.setValue(column.key, controller.text);
                    }
                  }
                  widget.onSave(row);
                } else {
                  widget.onEdit(row.id);
                }
              },
            ),
          ),

          const SizedBox(width: 8),

          // 删除按钮
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFe74c3c), Color(0xFFc0392b)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _withOpacity(Colors.red, 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white, size: 20),
              onPressed: () => widget.onDelete(row.id),
            ),
          ),
        ],
      ),
    );
  }
}