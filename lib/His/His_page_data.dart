import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/table_row_data.dart';

//获取省份数据
Future<List<TableRowData>> fetchProvinceData() async {
  try {
    final response = await http.post(
      Uri.parse('https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'tokencode': '8ab6c803f9a380df2796315cad1b4280',
        'DocumentElement': 'GetBsAreaProvinceAll',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey('Returns') && data['Returns'] is List) {
        final List<dynamic> rawList = data['Returns'];

        // 将原始数据转换为 TableRowData 对象
        return rawList.map((item) {
          return TableRowData.fromJson(item);
        }).toList();
      } else {
        print('无效的 Returns 数据类型: ${data['Returns']?.runtimeType}');
        return [];
      }
    }
    throw Exception('请求失败: ${response.statusCode}');
  } catch (e) {
    print('数据加载失败: $e');
    throw Exception('数据加载失败: $e');
  }
}
Future<List<TableRowData>> getUsage() async {
  try {
    final response = await http.post(
      Uri.parse('https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'tokencode': '8ab6c803f9a380df2796315cad1b4280',
        'DocumentElement': 'GetBsUsageAll',
        "hospitalId": "1165",
        "histype": "0",
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      // 调试：打印完整响应
      print("用法接口完整响应: $data");

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

      // 如果所有检查都失败，打印警告并返回空列表
      print("警告: 无法解析用法数据，返回空列表");
      print("Returns 类型: ${data['Returns']?.runtimeType}");
      return [];
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  } catch (e) {
    print("用法数据加载异常: $e");
    throw Exception('用法数据加载失败: $e');
  }
}

Future<List<dynamic>> getbsitemalldata(lsrptype) async
{
  try {
    final response = await http.post(
      Uri.parse('https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'lsrptype':lsrptype,
        'hospitalId':1165,
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
    throw Exception('数据加载失败: $e');
  }
}
