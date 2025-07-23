import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/table_row_data.dart';
import '../tools/error.dart';

Future<List<TableRowData>> fetchProvinceData({String hisType = '0'}) async {
  try {
    GlobalErrorHandler.logDebug('开始请求省份数据...');
    
    final response = await http.post(
      Uri.parse('https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'tokencode': '8ab6c803f9a380df2796315cad1b4280',
        'DocumentElement': 'GetBsAreaProvinceAll',
        "hospitalId": "1165",
        "histype": hisType, // 使用传入的hisType参数
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      GlobalErrorHandler.logDebug('省份接口响应状态: ${response.statusCode}');
      GlobalErrorHandler.logDebug('省份接口返回数据: $data');
      
      final returnsData = data['Returns'];
      GlobalErrorHandler.logDebug('Returns 类型: ${returnsData.runtimeType}');
      GlobalErrorHandler.logDebug('Returns 内容: $returnsData');
      
      if (returnsData is List) {
        final result = returnsData.map<TableRowData>((item) {
          return TableRowData(
            id: (item['ID'] ?? 0) is int ? (item['ID'] ?? 0) : int.tryParse((item['ID'] ?? '0').toString()) ?? 0,
            values: {
              'name': item['Name'] ?? '',
              'code': item['Code'] ?? '',
            },
          );
        }).toList();
        GlobalErrorHandler.logDebug('解析后的省份数据: ${result.length} 条');
        return result;
      } else if (returnsData is Map<String, dynamic> && returnsData.containsKey('ReturnT')) {
        final returnT = returnsData['ReturnT'] as List;
        final result = returnT.map<TableRowData>((item) {
          return TableRowData(
            id: (item['ID'] ?? 0) is int ? (item['ID'] ?? 0) : int.tryParse((item['ID'] ?? '0').toString()) ?? 0,
            values: {
              'name': item['Name'] ?? '',
              'code': item['Code'] ?? '',
            },
          );
        }).toList();
        GlobalErrorHandler.logDebug('从 ReturnT 解析的省份数据: ${result.length} 条');
        return result;
      } else {
        GlobalErrorHandler.logDebug('警告: 无法解析省份数据，返回空列表');
        return [];
      }
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  } catch (e) {
    GlobalErrorHandler.logErrorOnly(e, StackTrace.current);
    rethrow;
  }
}

Future<void> saveBsUsageToServer(List<Map<String, dynamic>> bsUsageData, {String hisType = '0'}) async {
  try {
    GlobalErrorHandler.logDebug('开始保存用法数据: $bsUsageData');
    
    final response = await http.post(
      Uri.parse('https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'tokencode': '8ab6c803f9a380df2796315cad1b4280',
        'DocumentElement': 'SaveBsUsage',
        'hospitalId': '1165',
        'histype': hisType, // 使用传入的hisType参数
        'bsUsageData': jsonEncode(bsUsageData),
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      GlobalErrorHandler.logDebug('保存用法接口响应状态: ${response.statusCode}');
      
      GlobalErrorHandler.logDebug('保存用法接口返回数据: $data');
      
      // 检查是否有嵌套的 Returns 字段
      Map<String, dynamic>? actualResult;
      if (data.containsKey('Returns') && data['Returns'] is Map<String, dynamic>) {
        actualResult = data['Returns'] as Map<String, dynamic>;
        GlobalErrorHandler.logDebug('发现嵌套的 Returns 字段: $actualResult');
      } else {
        actualResult = data;
      }
      
      // 使用实际的结果数据
      if (actualResult['IsSuccess'] == true) {
        GlobalErrorHandler.logDebug('用法数据保存成功');
        return;
      } else {
        // API 返回失败，提供详细的错误信息
        final errorMsg = actualResult['Message']?.toString() ?? actualResult['ErrorMsg']?.toString() ?? actualResult['ShowMsg']?.toString() ?? '';
        final warningMsg = actualResult['WarningMsg']?.toString() ?? '';
        final errorCode = actualResult['ErrorCode']?.toString() ?? '';
        final warningCode = actualResult['WarningCode']?.toString() ?? '';
        
        GlobalErrorHandler.logDebug('错误信息: $errorMsg');
        GlobalErrorHandler.logDebug('警告信息: $warningMsg');
        GlobalErrorHandler.logDebug('错误码: $errorCode');
        GlobalErrorHandler.logDebug('警告码: $warningCode');
        
        // 构建错误消息
        String fullErrorMsg = '保存失败';
        
        // 如果有具体的错误消息，优先显示
        if (errorMsg.isNotEmpty) {
          fullErrorMsg = errorMsg;
        } else if (warningMsg.isNotEmpty) {
          fullErrorMsg = '警告: $warningMsg';
        } else if (errorCode != '0' && errorCode.isNotEmpty) {
          fullErrorMsg = '错误码: $errorCode';
        } else if (warningCode != '0' && warningCode.isNotEmpty) {
          fullErrorMsg = '警告码: $warningCode';
        } else {
          fullErrorMsg = '保存失败，请检查数据格式';
        }
        
        throw Exception(fullErrorMsg);
      }
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  } catch (e) {
    GlobalErrorHandler.logErrorOnly(e, StackTrace.current);
    rethrow;
  }
}

Future<List<TableRowData>> getUsage({String hisType = '0'}) async {
  try {
    final response = await http.post(
      Uri.parse('https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'tokencode': '8ab6c803f9a380df2796315cad1b4280',
        'DocumentElement': 'GetBsUsageAll',
        "hospitalId": "1165",
        "histype": hisType, // 使用传入的hisType参数
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      // 检查 'Returns' 字段
      if (data.containsKey('Returns')) {
        final returnsData = data['Returns'];

        // 处理两种可能的返回结构
        if (returnsData is List) {
          // 直接是列表的情况
          return returnsData.map((item) {
            return TableRowData.fromJson(item);
          }).toList();
        } else if (returnsData is Map) {
          // 检查 'ReturnT' 字段
          if (returnsData.containsKey('ReturnT') && returnsData['ReturnT'] is List) {
            final List<dynamic> rawList = returnsData['ReturnT'];
            return rawList.map((item) {
              return TableRowData.fromJson(item);
            }).toList();
          }
        }
      }

      return [];
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  } catch (e, stack) {
    GlobalErrorHandler.logErrorOnly(e, stack);
    throw Exception('用法数据加载失败: $e');
  }
}

Future<List<dynamic>> getbsitemalldata(lsrptype) async {
  try {
    final response = await http.post(
      Uri.parse('https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'lsrptype': lsrptype,
        'hospitalId': 1165,
        'tokencode': '8ab6c803f9a380df2796315cad1b4280',
        'DocumentElement': 'GetListBylsRpTypeAndHospitalId',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['Returns'] as List? ?? [];
    }
    throw Exception('请求失败: ${response.statusCode}');
  } catch (e) {
    GlobalErrorHandler.logErrorOnly(e, StackTrace.current);
    throw Exception('数据加载失败: $e');
  }
}
