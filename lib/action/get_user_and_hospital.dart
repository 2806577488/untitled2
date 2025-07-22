import 'dart:convert';
import 'package:http/http.dart' as http;

import '../public.dart';
import '../tools/error.dart';

/// 用户与医院信息服务工具类
class UserAndHospitalService {
  static const String _baseUrl = 'https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface';
  static const String _tokenCode = '8ab6c803f9a380df2796315cad1b4280';

  /// 通过工号验证并获取医院信息
  /// [userCode] 用户工号
  /// [context] 用于错误处理的上下文（可选）
  static Future<List<Location>> validateUserCode(
      String userCode,
      ) async {
    try {
      GlobalErrorHandler.logErrorOnly('验证工号: $userCode', StackTrace.current);
      
      final response = await _postRequest(
        'GetBsHospitalByUserCode',
        {'Code': userCode},
      );

      if (response.statusCode != 200) {
        throw Exception('请求失败 (${response.statusCode})');
      }

      GlobalErrorHandler.logErrorOnly('医院信息响应: ${response.body}', StackTrace.current);
      
      return _parseHospitalResponse(response.body);
    } catch (e) {
      throw Exception('工号验证失败: ${e.toString()}');
    }
  }

  /// 解析医院信息响应
  /// [responseBody] HTTP响应内容
  static List<Location> _parseHospitalResponse(String responseBody) {
    try {
      final data = json.decode(responseBody);
      final hospitalResponse = HospitalResponse.fromJson(data);

      if (hospitalResponse.returns.isEmpty) {
        throw Exception("编码不存在对应用户");
      }

      // 添加调试信息
      for (var hospital in hospitalResponse.returns) {
        GlobalErrorHandler.logErrorOnly('医院信息: Name=${hospital.name}, HospitalId=${hospital.hospitalId}, ID=${hospital.id}', StackTrace.current);
      }

      return hospitalResponse.returns.map<Location>((returnItem) {
        return Location(
          name: returnItem.name,
          hospitalId: returnItem.id, // 使用真正的医院ID
        );
      }).toList();
    } catch (e) {
      throw Exception("医院信息解析失败: ${e.toString()}");
    }
  }

  /// 用户登录验证
  /// [userCode] 用户工号
  /// [password] 登录密码
  /// [hospitalId] 医院ID
  /// [hisType] HIS系统类型
  static Future<User> userLogin(
      String userCode,
      String password,
      String hospitalId,
      String hisType,
      ) async {
    try {
      // 添加调试信息
      GlobalErrorHandler.logErrorOnly('登录参数: userCode=$userCode, hospitalId=$hospitalId, hisType=$hisType', StackTrace.current);
      
      final response = await _postRequest(
        'GetUserYLTLogin',
        {
          'codename': userCode,
          'Password': password,
          'hospitalId': hospitalId,
          'hisType': hisType,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('请求失败 (${response.statusCode})');
      }

      // 添加响应调试信息
      GlobalErrorHandler.logErrorOnly('登录响应: ${response.body}', StackTrace.current);
      
      return _parseLoginResponse(response.body);
    } catch (e) {
      throw Exception('用户登录失败: ${e.toString()}');
    }
  }

  /// 解析登录响应
  /// [responseBody] HTTP响应内容
  static User _parseLoginResponse(String responseBody) {
    try {
      final data = json.decode(responseBody);

      if (data['Returns'] == null || data['Returns'].isEmpty) {
        final message = data['Message'] ?? "返回为空";
        throw Exception(message);
      }

      // 假设 data['Returns'] 是一个包含用户信息的对象
      final userJson = data['Returns'];

      // 创建 User 对象
      User userInfo = User.fromJson(userJson);

      // 检查用户信息是否有效
      if (userInfo.name.isEmpty) {
        throw Exception("用户信息无效");
      }

      return userInfo; // 返回解析后的用户信息
    } catch (e) {
      throw Exception("登录响应解析失败: ${e.toString()}");
    }
  }

  /// 通用POST请求方法
  static Future<http.Response> _postRequest(
      String documentElement,
      Map<String, String> params,
      ) async {
    final bodyParams = {
      'tokencode': _tokenCode,
      'DocumentElement': documentElement,
      ...params.map((key, value) => MapEntry(key, Uri.encodeComponent(value))),
    };

    return await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mozilla/5.0 (...) Chrome/120.0.0.0 Safari/537.36',
      },
      body: bodyParams.entries.map((e) => '${e.key}=${e.value}').join('&'),
    ).timeout(const Duration(seconds: 10));
  }
}

/// 医院响应数据模型
class HospitalResponse {
  final List<HospitalReturn> returns;

  HospitalResponse({required this.returns});

  factory HospitalResponse.fromJson(Map<String, dynamic> json) {
    final returnsList = (json['Returns'] as List)
        .map((item) => HospitalReturn.fromJson(item))
        .toList();
    return HospitalResponse(returns: returnsList);
  }
}

/// 医院返回项模型
class HospitalReturn {
  final String name;
  final String hospitalId; // 这个字段值为0，不是真正的医院ID
  final String id; // 真正的医院ID

  HospitalReturn({
    required this.name,
    required this.hospitalId,
    required this.id,
  });

  factory HospitalReturn.fromJson(Map<String, dynamic> json) {
    return HospitalReturn(
      name: json['Name'] ?? '',
      hospitalId: (json['HospitalId'] ?? '').toString(),
      id: (json['ID'] ?? '').toString(), // 真正的医院ID
    );
  }
} 