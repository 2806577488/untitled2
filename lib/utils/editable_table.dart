// ==================================================
// 导入区域开始
// ==================================================
import 'package:flutter/material.dart';
import '../models/table_column_config.dart';
import '../models/table_row_data.dart';
// ==================================================
// 导入区域结束
// ==================================================

// ==================================================
// EditableTable 组件定义开始
// ==================================================
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
  final Map<int, GlobalKey>? rowKeys;

  const EditableTable({
    super.key,
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onSave,
    required this.onAddNew,
    required this.title,
    required this.columns,
    this.headerColor,
    this.footerColor, this.rowKeys,
  });

  @override
  _EditableTableState createState() => _EditableTableState();
}
// ==================================================
// EditableTable 组件定义结束
// ==================================================

// ==================================================
// 自定义下拉框组件开始
// ==================================================
class _CustomDropdown extends StatefulWidget {
  final String? value;
  final List<DropdownMenuItem<String>>? items;
  final ValueChanged<String?>? onChanged;

  const _CustomDropdown({
    this.value,
    this.items,
    this.onChanged,
  });

  @override
  __CustomDropdownState createState() => __CustomDropdownState();
}

class __CustomDropdownState extends State<_CustomDropdown> {
  // 用于存储最大文本宽度
  double _maxTextWidth = 0;

  @override
  void initState() {
    super.initState();
    // 在下一帧计算最大文本宽度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateMaxTextWidth();
    });
  }

  // 计算所有选项文本的最大宽度
  void _calculateMaxTextWidth() {
    double maxWidth = 0;
    final textStyle = const TextStyle(fontSize: 16);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    if (widget.items != null) {
      for (final item in widget.items!) {
        if (item.child is Text) {
          final text = (item.child as Text).data ?? '';
          textPainter.text = TextSpan(text: text, style: textStyle);
          textPainter.layout();
          if (textPainter.width > maxWidth) {
            maxWidth = textPainter.width;
          }
        }
      }
    }

    // 添加一些内边距 (左右各16像素)
    setState(() {
      _maxTextWidth = maxWidth + 32;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用计算的最大宽度，但不超过可用空间
        final double width = _maxTextWidth > 0
            ? _maxTextWidth.clamp(0, constraints.maxWidth)
            : constraints.maxWidth;

        return SizedBox(
          width: width,
          child: DropdownButton<String>(
            value: widget.value,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            iconEnabledColor: Colors.grey,
            underline: Container(),
            style: const TextStyle(fontSize: 16, color: Colors.black, height: 1.0),
            onChanged: widget.onChanged,
            items: widget.items,
            selectedItemBuilder: (BuildContext context) {
              return widget.items!.map((item) {
                String text = '';
                if (item.child is Text) {
                  text = (item.child as Text).data ?? '';
                }
                return SizedBox(
                  height: 36,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 16, height: 1.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList();
            },
          ),
        );
      },
    );
  }
}
// ==================================================
// 自定义下拉框组件结束
// ==================================================

// ==================================================
// 状态类定义开始
// ==================================================
class _EditableTableState extends State<EditableTable> {
  // 文本控制器映射 [rowId: [columnKey: controller]]
  final Map<int, Map<String, TextEditingController>> _controllers = {};
  // ==================================================
  // 颜色工具方法开始
  // ==================================================
  static Color _withOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }
  // ==================================================
  // 颜色工具方法结束
  // ==================================================

  // ==================================================
  // 生命周期方法开始
  // ==================================================
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(EditableTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateControllers();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }
  // ==================================================
  // 生命周期方法结束
  // ==================================================

  // ==================================================
  // 控制器管理开始
  // ==================================================
  void _initializeControllers() {
    for (var row in widget.data) {
      _initRowControllers(row);
    }
  }

  void _initRowControllers(TableRowData row) {
    _controllers[row.id] = {};
    for (final column in widget.columns) {
      _controllers[row.id]![column.key] = TextEditingController(
        text: row.getValue(column.key).toString(),
      );
    }
  }

  void _updateControllers() {
    // 更新现有行的控制器值
    for (var row in widget.data) {
      if (!_controllers.containsKey(row.id)) {
        _initRowControllers(row);
      } else {
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
    final toRemove =
    _controllers.keys.where((id) => !currentIds.contains(id)).toList();
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

  void _disposeControllers() {
    for (var controllers in _controllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    _controllers.clear();
  }
  // ==================================================
  // 控制器管理结束
  // ==================================================

  // ==================================================
// 单元格构建开始
// ==================================================
  Widget _buildCell({
    required bool isEditing,
    required TableColumnConfig column,
    required String value,
    required int rowId,
  }) {
    final controller = _controllers[rowId]?[column.key];
    final displayValue = column.getDisplayValue(value);

    return Container(

      width: column.width,
      height: 36, // 统一高度为48dp
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFe0e0e0), width: 1),
      ),
      // 使用Center确保内容垂直居中
      child: Center(
        child: column.isBooleanColumn
            ? _buildBooleanField(column, value, rowId)
            : isEditing && column.isEditable
            ? _buildEditableField(column, controller, value, rowId)
            : _buildDisplayField(column, displayValue),
      ),
    );
  }
  Widget _buildBooleanField(
      TableColumnConfig column,
      String value,
      int rowId,
      ) {
    final bool currentValue = value.toLowerCase() == 'true';
    final rowIndex = widget.data.indexWhere((r) => r.id == rowId);
    final row = widget.data[rowIndex];
    final isEditing = row.isEditing;

    return GestureDetector(
      onTap: isEditing
          ? () {
        final newValue = !currentValue;

        // 更新 controller
        final controller = _controllers[rowId]?[column.key];
        controller?.text = newValue.toString();

        // 更新数据模型
        row.setValue(column.key, newValue.toString());

        setState(() {});
      }
          : null, // 非编辑状态不响应点击
      child: Icon(
        currentValue ? Icons.check : Icons.clear,
        color: currentValue ? Colors.green : Colors.red,
        size: 20, // 尽量小巧美观
      ),
    );
  }



  Widget _buildEditableField(
      TableColumnConfig column,
      TextEditingController? controller,
      String value,
      int rowId,
      ) {
    if (controller == null) return const SizedBox();
    if (column.isBooleanColumn) {
      bool currentValue = value.toLowerCase() == 'true'; // 根据传入值判断 true 或 false

      return Row(
        children: [
          Row(
            children: [
              // 单选按钮: true
              Radio<bool>(
                value: true,
                groupValue: currentValue,
                onChanged: (bool? newValue) {
                  if (newValue != null) {
                    // 1. 更新控制器值
                    controller.text = newValue.toString();
                    // 2. 找到当前行
                    final rowIndex = widget.data.indexWhere((r) => r.id == rowId);
                    if (rowIndex != -1) {
                      final row = widget.data[rowIndex];

                      // 3. 更新行数据
                      row.setValue(column.key, newValue.toString());

                      // 4. 刷新UI
                      setState(() {});
                    }
                  }
                },
              ),
              const Text('True'), // 可以显示 True 的标签
            ],
          ),
          Row(
            children: [
              // 单选按钮: false
              Radio<bool>(
                value: false,
                groupValue: currentValue,
                onChanged: (bool? newValue) {
                  if (newValue != null) {
                    // 1. 更新控制器值
                    controller.text = newValue.toString();
                    // 2. 找到当前行
                    final rowIndex = widget.data.indexWhere((r) => r.id == rowId);
                    if (rowIndex != -1) {
                      final row = widget.data[rowIndex];

                      // 3. 更新行数据
                      row.setValue(column.key, newValue.toString());

                      // 4. 刷新UI
                      setState(() {});
                    }
                  }
                },
              ),
              const Text('False'), // 显示 False 的标签
            ],
          ),
        ],
      );
    }
    if (column.valueMap != null && column.valueMap!.isNotEmpty) {
      String? safeValue = value;
      if (!column.valueMap!.containsKey(value)) {
        safeValue = column.valueMap!.keys.first;
        controller.text = safeValue;
      }

      return SizedBox(
        height: 36,
        child: _CustomDropdown(
          value: controller.text,  // 修改为 `controller.text`，直接绑定文本框的值
          items: column.valueMap!.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: const TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              // 1. 更新控制器值
              controller.text = newValue;

              // 2. 找到当前行
              final rowIndex = widget.data.indexWhere((r) => r.id == rowId);
              if (rowIndex != -1) {
                final row = widget.data[rowIndex];

                // 3. 更新行数据
                row.setValue(column.key, newValue);

                // 4. 调用保存回调
                // widget.onSave(row);
              }

              // 5. 刷新UI
              setState(() {});
            }
          },
        ),
      );
    }


    // 完美居中的文本框
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: column.hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        // 关键：精确控制内边距实现居中
       // contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      style: const TextStyle(fontSize: 16),
      // 关键：确保文本垂直居中
      textAlignVertical: TextAlignVertical.center,
    );
  }

  Widget _buildDisplayField(TableColumnConfig column, String displayValue) {
    // 显示文本也使用相同高度
    return SizedBox(
      height: 36, // 与编辑状态相同高度
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          displayValue.isNotEmpty ? displayValue : column.hint,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
// ==================================================
// 单元格构建结束
// ==================================================

  // ==================================================
  // 表头构建开始
  // ==================================================
  Widget _buildHeaderCell(TableColumnConfig column) {
    return column.width != null
        ? SizedBox(
      width: column.width,
      child: Text(
        column.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    )
        : Expanded(
      flex: 1,
      child: Text(
        column.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  // ==================================================
  // 表头构建结束
  // ==================================================

  // ==================================================
  // 数据单元格构建开始
  // ==================================================
  Widget _buildDataCell(TableColumnConfig column, TableRowData row) {
    return column.width != null
        ? SizedBox(
      width: column.width,
      child: _buildCell(
        isEditing: row.isEditing,
        column: column,
        value: row.getValue(column.key).toString(),
        rowId: row.id,
      ),
    )
        : Expanded(
      flex: 1,
      child: _buildCell(
        isEditing: row.isEditing,
        column: column,
        value: row.getValue(column.key).toString(),
        rowId: row.id,
      ),
    );
  }
  // ==================================================
  // 数据单元格构建结束
  // ==================================================

  // ==================================================
  // 状态单元格构建开始
  // ==================================================
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
  // ==================================================
  // 状态单元格构建结束
  // ==================================================

  // ==================================================
  // 操作单元格构建开始
  // ==================================================
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
                    final controller = _controllers[row.id]?[column.key];
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
  // ==================================================
  // 操作单元格构建结束
  // ==================================================

  // ==================================================
  // 主构建方法开始
  // ==================================================
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
            color: Colors.black.withValues(alpha: (0.2 * 255).toInt().toDouble()),
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
                  for (final column in widget.columns) _buildHeaderCell(column),

                  // 状态列
                  const Expanded(
                    child: Text(
                      '状态',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // 数据行构建开始
            // ==================================================
            Expanded(
              child: ListView.builder(
                itemCount: widget.data.length,
                itemBuilder: (context, index) {
                  final row = widget.data[index];
                  final isEditing = row.isEditing;

                  return Container(
                    key: widget.rowKeys?[row.id],
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
                          color: Colors.black.withValues(alpha: (0.2 * 255).toDouble()),
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
            // ==================================================
            // 数据行构建结束
            // ==================================================

            // ==================================================
            // 底部区域构建开始
            // ==================================================
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: _withOpacity(footerColor, 0.9),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 18,
                      ),
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
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            )
            // ==================================================
            // 底部区域构建结束
            // ==================================================
          ],
        ),
      ),
    );
  }
// ==================================================
// 主构建方法结束
// ==================================================
}
// ==================================================
// 状态类定义结束
// ==================================================