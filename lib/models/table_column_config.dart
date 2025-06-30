class TableColumnConfig {
  final String key;
  final String title;
  final String hint;
  final double? width;
  final bool isEditable;
  final Type valueType; // 添加字段类型
  final List<String>? dropdownItems; // 新增下拉框选项
  final Map<String, String>? valueMap; // 值映射表
  final bool isBooleanColumn;
  String getDisplayValue(String rawValue) {
    if (valueMap != null && valueMap!.containsKey(rawValue)) {
      return valueMap![rawValue]!;
    }
    return rawValue;
  }

  const TableColumnConfig({
    required this.key,
    required this.title,
    required this.hint,
    this.width,
    this.isEditable = true,
    this.valueType=String,
    this.dropdownItems, // 新增
    this.valueMap,
    this.isBooleanColumn = false, // 默认是 false
  });
}