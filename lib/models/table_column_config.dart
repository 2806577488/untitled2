class TableColumnConfig {
  final String key;
  final String title;
  final String hint;
  final double? width;
  final bool isEditable;
  final Type valueType; // 添加字段类型

  const TableColumnConfig({
    required this.key,
    required this.title,
    required this.hint,
    this.width,
    this.isEditable = true,
    this.valueType=String,
  });
}