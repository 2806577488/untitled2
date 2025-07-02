class TableRowData {
  final int id;
  Map<String, dynamic> values;
  bool isEditing;
  bool isActive;

  TableRowData({
    required this.id,
    required this.values,
    this.isEditing = false, // 默认不在编辑状态
    this.isActive = true,   // 默认激活状态
  });

  // 添加工厂构造函数
  factory TableRowData.fromJson(Map<String, dynamic> json) {
    // 使用 GUID 的哈希值作为 ID（或使用其他唯一标识）
    final String? guid = json['GUID'] as String?;
    final int id = guid?.hashCode ?? json.hashCode;

    return TableRowData(
      id: id,
      values: Map<String, dynamic>.from(json),
    );
  }

  dynamic getValue(String key) {
    return values.containsKey(key) && values[key] != null ? values[key] : '';
  }

  void setValue(String key, dynamic value) {
    values[key] = value;
  }
}