class Location {
  final String name;
  final String hospitalId;

  Location({required this.name, required this.hospitalId});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'] ?? '',
      hospitalId: json['hospitalId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hospitalId': hospitalId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Location &&
              runtimeType == other.runtimeType &&
              name == other.name &&
              hospitalId == other.hospitalId;

  @override
  int get hashCode => name.hashCode ^ hospitalId.hashCode;
}

class User {
  final String name;
  final String guid;
  final String sex;
  final String roleId;
  final String mobile;
  final bool isRecipe;
  final String hospitalName;
  final List<dynamic> lstTreeNodeTempate;
  final String hospitalPhone;
  final String hospPhoto;

  User({
    required this.name,
    required this.guid,
    required this.sex,
    required this.roleId,
    required this.mobile,
    required this.isRecipe,
    required this.hospitalName,
    required this.lstTreeNodeTempate,
    required this.hospitalPhone,
    required this.hospPhoto,
  });

  // 工厂构造函数，用于从地图数据创建 User 实例
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['Name'] ?? '',
      guid: json['GUID'] ?? '',
      sex: json['Sex'] ?? '',
      roleId: json['RoleId'] ?? '',
      mobile: json['Mobile'] ?? '',
      isRecipe: json['IsRecipe'] ?? false,
      hospitalName: json['HospitalName'] ?? '',
      lstTreeNodeTempate: json['lstTreeNodeTempate'] ?? [],
      hospitalPhone: json['HospitalPhone'] ?? '',
      hospPhoto: json['HospPhoto'] ?? '',
    );
  }

  // 将 User 实例转换为地图数据
  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'GUID': guid,
      'Sex': sex,
      'RoleId': roleId,
      'Mobile': mobile,
      'IsRecipe': isRecipe,
      'HospitalName': hospitalName,
      'lstTreeNodeTempate': lstTreeNodeTempate,
      'HospitalPhone': hospitalPhone,
      'HospPhoto': hospPhoto,
    };
  }

  @override
  String toString() {
    return '''
      User:
        Name: $name
        GUID: $guid
        Sex: $sex
        RoleId: $roleId
        Mobile: $mobile
        IsRecipe: $isRecipe
        HospitalName: $hospitalName
        lstTreeNodeTempate: $lstTreeNodeTempate
        HospitalPhone: $hospitalPhone
        HospPhoto: $hospPhoto
    ''';
  }
}