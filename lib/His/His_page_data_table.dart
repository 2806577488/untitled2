import 'package:flutter/material.dart';
import 'His_page_styles.dart';

class DataTableWidget extends StatefulWidget {
  final Future<List<dynamic>> dataFuture;
  final void Function(dynamic province) onEdit;
  final void Function(dynamic province) onDelete;
  final VoidCallback onSave;

  const DataTableWidget({
    super.key,
    required this.dataFuture,
    required this.onEdit,
    required this.onDelete,
    required this.onSave,
  });

  @override
  State<DataTableWidget> createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  List<dynamic>? _data;
  Map<int, bool> _rowEditing = {};
  Map<int, TextEditingController> _nameControllers = {};
  Map<int, TextEditingController> _codeControllers = {};
  Map<int, TextEditingController> _pyCodeControllers = {};
  Map<int, TextEditingController> _wbCodeControllers = {};
  final int _padding = 3;

  @override
  void initState() {
    super.initState();
    _nameControllers = {};
    _codeControllers = {};
    _pyCodeControllers = {};
    _wbCodeControllers = {};
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
        _data = snapshot.data;
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 200,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: widget.onSave,
                    child: const Text('保存'),
                  ),
                  const Divider(height: 20),
                  AppStyles.tableHeader,
                  const Divider(height: 20),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _data?.length ?? 0,
                      separatorBuilder: (_, __) => AppStyles.divider,
                      itemBuilder: (context, index) => _buildDataRow(index),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataRow(int index) {
    final province = _data![index];
    if (!_rowEditing.containsKey(index)) {
      _rowEditing[index] = false;
    }
    if (!_nameControllers.containsKey(index)) {
      _nameControllers[index] = TextEditingController(text: province['Name']);
    }
    if (!_codeControllers.containsKey(index)) {
      _codeControllers[index] = TextEditingController(text: province['Code']);
    }
    if (!_pyCodeControllers.containsKey(index)) {
      _pyCodeControllers[index] = TextEditingController(text: province['PyCode']);
    }
    if (!_wbCodeControllers.containsKey(index)) {
      _wbCodeControllers[index] = TextEditingController(text: province['WbCode'] ?? '');
    }
    final isEditing = _rowEditing[index]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                return isEditing
                    ? _buildEditableField(
                  controller: _nameControllers[index]!,
                  maxWidth: maxWidth,
                )
                    : Center(child: Text(province['Name']?.toString() ?? '-'));
              },
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                return isEditing
                    ? _buildEditableField(
                  controller: _codeControllers[index]!,
                  maxWidth: maxWidth,
                )
                    : Center(child: Text(province['Code']?.toString() ?? '-'));
              },
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                return isEditing
                    ? _buildEditableField(
                  controller: _pyCodeControllers[index]!,
                  maxWidth: maxWidth,
                )
                    : Center(child: Text(province['PyCode']?.toString() ?? '-'));
              },
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                return isEditing
                    ? _buildEditableField(
                  controller: _wbCodeControllers[index]!,
                  maxWidth: maxWidth,
                )
                    : Center(child: Text(province['WbCode']?.toString() ?? '-'));
              },
            ),
          ),
          Expanded(
            child: Center(
              child: Chip(
                label: Text((province['IsActive'] as bool?) == true ? '启用' : '禁用'),
                backgroundColor: (province['IsActive'] as bool?) == true
                    ? Colors.green.shade100
                    : Colors.red.shade100,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(isEditing ? Icons.check : Icons.edit),
                  onPressed: () {
                    setState(() {
                      _rowEditing[index] = !_rowEditing[index]!;
                      if (!_rowEditing[index]!) {
                        province['Name'] = _nameControllers[index]!.text;
                        province['Code'] = _codeControllers[index]!.text;
                        province['PyCode'] = _pyCodeControllers[index]!.text;
                        province['WbCode'] = _wbCodeControllers[index]!.text;
                      }
                    });
                    widget.onEdit(province);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => widget.onDelete(province),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required double maxWidth,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: controller.text, style: const TextStyle(fontSize: 14)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final textWidth = textPainter.size.width;
    final textFieldWidth = textWidth + 2 * _padding;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: textFieldWidth,
        maxWidth: maxWidth,
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.yellow.shade100,
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _nameControllers.values) {
      controller.dispose();
    }
    for (var controller in _codeControllers.values) {
      controller.dispose();
    }
    for (var controller in _pyCodeControllers.values) {
      controller.dispose();
    }
    for (var controller in _wbCodeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}