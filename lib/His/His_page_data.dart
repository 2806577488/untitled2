import 'dart:convert';
import 'package:http/http.dart' as http;

//获取省份数据
Future<List<dynamic>> fetchProvinceData() async {
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
      final data = jsonDecode(response.body);
      return data['Returns'] as List? ?? [];
    }
    throw Exception('请求失败: ${response.statusCode}');
  } catch (e) {
    throw Exception('数据加载失败: $e');
  }
}

Future<List<dynamic>> getUsage() async {
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
      final data = jsonDecode(response.body);

      // 检查 'Returns' 字段是否存在并且是 Map 类型
      if (data.containsKey('Returns') && data['Returns'] is Map) {
        // 提取需要的数据
        final returnsData = data['Returns'] as Map<String, dynamic>;
        // 假设我们需要提取 'ReturnT' 列表
        if (returnsData.containsKey('ReturnT') && returnsData['ReturnT'] is List) {
          return returnsData['ReturnT'] as List;
        } else {
          // 如果 'ReturnT' 不存在或不是列表，返回空列表
          return [];
        }
      } else {
        // 如果 'Returns' 不存在或不是 Map，返回空列表
        return [];
      }
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('数据加载失败: $e');
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
