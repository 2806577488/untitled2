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

Future<List<dynamic>> getbsitemalldata() async
{
  try {
    final response = await http.post(
      Uri.parse('https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'hospitalId':'1165',
        'tokencode': '8ab6c803f9a380df2796315cad1b4280',
        'DocumentElement': 'GetBsItemByKey',
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