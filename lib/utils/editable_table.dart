import 'package:flutter/material.dart';

class TableRowData {
  final int id;
  String name;
  String code;
  String pyCode;
  String wbCode;
  bool isActive;
  bool isEditing;
  Map<String, String> originalValues;

  TableRowData({
    required this.id,
    required this.name,
    required this.code,
    required this.pyCode,
    required this.wbCode,
    this.isActive = true,
    this.isEditing = false,
    Map<String, String>? originalValues,
  }) : originalValues = originalValues ?? {
    'name': name,
    'code': code,
    'pyCode': pyCode,
    'wbCode': wbCode,
  };
}

class EditableTable extends StatefulWidget {
  final List<TableRowData> data;
  final Function(int id) onEdit;
  final Function(int id) onDelete;
  final Function(int id, String name, String code, String pyCode, String wbCode, bool isActive) onSave;
  final Function() onAddNew;
  final String title;

  const EditableTable({
    Key? key,
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onSave,
    required this.onAddNew,
    required this.title,
  }) : super(key: key);

  @override
  _EditableTableState createState() => _EditableTableState();
}

class _EditableTableState extends State<EditableTable> {
  final Map<int, Map<String, TextEditingController>> _controllers = {};

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
    _controllers[row.id] = {
      'name': TextEditingController(text: row.name),
      'code': TextEditingController(text: row.code),
      'pyCode': TextEditingController(text: row.pyCode),
      'wbCode': TextEditingController(text: row.wbCode),
    };
  }

  @override
  void didUpdateWidget(EditableTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    for (var row in widget.data) {
      if (!_controllers.containsKey(row.id)) {
        _initRowControllers(row);
      }
    }

    final currentIds = widget.data.map((r) => r.id).toSet();
    final toRemove = _controllers.keys.where((id) => !currentIds.contains(id)).toList();
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
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
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
          controller: _controllers[rowId]![controllerKey],
          decoration: InputDecoration.collapsed(
            hintText: hintText,
          ),
        )
            : Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                widget.title,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a2980)),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1a2980).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                        '省份',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text(
                        '编码',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text(
                        '拼音码',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text(
                        '五笔码',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text(
                        '状态',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '操作',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

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
                          _buildCell(
                            isEditing: isEditing,
                            controllerKey: 'name',
                            hintText: '输入省份',
                            value: row.name,
                            rowId: row.id,
                            flex: 2,
                          ),

                          const SizedBox(width: 12),

                          _buildCell(
                            isEditing: isEditing,
                            controllerKey: 'code',
                            hintText: '输入编码',
                            value: row.code,
                            rowId: row.id,
                          ),

                          const SizedBox(width: 12),

                          _buildCell(
                            isEditing: isEditing,
                            controllerKey: 'pyCode',
                            hintText: '输入拼音码',
                            value: row.pyCode,
                            rowId: row.id,
                          ),

                          const SizedBox(width: 12),

                          _buildCell(
                            isEditing: isEditing,
                            controllerKey: 'wbCode',
                            hintText: '输入五笔码',
                            value: row.wbCode,
                            rowId: row.id,
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  row.isActive = !row.isActive;
                                  widget.onSave(
                                      row.id,
                                      row.name,
                                      row.code,
                                      row.pyCode,
                                      row.wbCode,
                                      row.isActive
                                  );
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
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 修改/保存按钮 - 修复位置参数问题
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF3498db), Color(0xFF2980b9)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      isEditing ? Icons.save : Icons.edit,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      if (isEditing) {
                                        widget.onSave(
                                            row.id,
                                            _controllers[row.id]!['name']!.text,
                                            _controllers[row.id]!['code']!.text,
                                            _controllers[row.id]!['pyCode']!.text,
                                            _controllers[row.id]!['wbCode']!.text,
                                            row.isActive
                                        );
                                      } else {
                                        widget.onEdit(row.id);
                                      }
                                    },
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // 删除按钮 - 修复位置参数问题
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFe74c3c), Color(0xFFc0392b)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.white),
                                    onPressed: () => widget.onDelete(row.id),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1a2980).withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
}