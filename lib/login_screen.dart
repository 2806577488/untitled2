import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:untitled2/model/HospitalResponse.dart';
import 'package:untitled2/tools/Error.dart';
import 'package:untitled2/utils/customDialog.dart';
import 'widgets/optimized_dropdown.dart';

class LoginScreen extends StatefulWidget {
  final Function(String, String, String) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class Location {
  final String name;
  Location(this.name);

  // 必须添加相等性判断
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _userId = '';
  String? _apiError;
  String? _selectedImagePath;
  String _password = '';
  late List<Location> _loginLocation = [];
  Location? _selectedLocation;
  bool _formSubmitted = false; // 新增表单提交状态标记
  //bool _isValidating = false;  // 新增验证加载状态
  bool _isSubmitting = false;

  // 解析医院信息响应
  List<Location> parseHospitalResponse(String responseBody) {
    try {
      final data = json.decode(responseBody);
      final hospitalResponse = HospitalResponse.fromJson(data);
      if (hospitalResponse.returns.isEmpty) {
        throw Exception("编码不存在对应用户");
      }

      return (hospitalResponse.returns as List).map<Location>((item) {
        final name = item['Name']?.toString() ?? '未知地点';
        return Location(name);
      }).toList();
    } on FormatException catch (e,stack) {
      final errorDetails = logError(e, stack);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('错误类型: ${errorDetails.errorType}'),
          content: SingleChildScrollView(
            child: Text(errorDetails.toString()),
          ),
        ),
      );
      throw Exception(errorDetails);
    }
  }

  // 解析用户相关信息
  List<Location> parseLoingUserAndPassword(String responseBody) {
    try {
      final Map<String, dynamic> data = json.decode(responseBody);

      if (data['Returns'].isEmpty) {
        if (!data['Message'].isEmpty) {
          throw Exception("返回为空");
        }
        throw Exception(data['Message']);
      }

      return (data['Returns'] as List).map<Location>((item) {
        final name = item['Name']?.toString() ?? '未知地点';
        return Location(name);
      }).toList();
    } on FormatException catch (e) {
      throw Exception("JSON解析失败: ${e.message}");
    }
  }

  // 用户验证
  Future<void> _validateUserCode(String userCode) async {
    setState(() {
      _apiError = null;
      _loginLocation.clear();
    });

    try {
      final response = await http
          .post(
            Uri.parse(
                'https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': 'Mozilla/5.0 (...) Chrome/120.0.0.0 Safari/537.36'
            },
            body: 'tokencode=8ab6c803f9a380df2796315cad1b4280'
                '&DocumentElement=GetBsHospitalByUserCode'
                '&Code=${Uri.encodeComponent(userCode)}',
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final locations = parseHospitalResponse(response.body);
        setState(() {
          _loginLocation = locations;
          _selectedLocation = locations.isNotEmpty ? locations.first : null;
        });
      } else {
        setState(() => _apiError = "请求失败 (${response.statusCode})");
      }
    } catch (e,stack) {
      final errorMsg = logError(e, stack);
      //final errorMsg = e.toString().replaceAll('Exception:', '').trim();

      // 显示错误对话框
      if (mounted) {
        CustomDialog.show(
          context: context, // 确保能访问有效的BuildContext
          title: "验证失败",
          content: "工号验证错误：$errorMsg",
          buttonType: DialogButtonType.singleConfirm,
          onConfirm: () => Navigator.of(context).pop(),
        );
      }

      setState(() => _apiError =e.toString());
    } finally {}
    return;
  }

  Future<bool> _getUserYLTLogin(String userCode, String password,
      String hospitalId, String hisType) async {
    bool loginstatus = false;
    setState(() {
      _apiError = null;
      _loginLocation.clear();
    });
    try {
      final response = await http
          .post(
            Uri.parse(
                'https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': 'Mozilla/5.0 (...) Chrome/120.0.0.0 Safari/537.36'
            },
            body: 'tokencode=8ab6c803f9a380df2796315cad1b4280'
                '&DocumentElement=GetUserYLTLogin'
                '&Code=${Uri.encodeComponent(userCode)}'
                '&Password=${Uri.encodeComponent(password)}'
                '&hospitalId=${Uri.encodeComponent(hospitalId)}'
                '&hisType=${Uri.encodeComponent(hisType)}',
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final locations = parseLoingUserAndPassword(response.body);
        setState(() {
          _loginLocation = locations;
          _selectedLocation = locations.isNotEmpty ? locations.first : null;
        });
        loginstatus = true;
      } else {
        setState(() => _apiError = "请求失败 (${response.statusCode})");
      }
    } catch (e) {
      setState(() => _apiError = e.toString());
    } finally {}
    return loginstatus;
  }

  @override
  void initState() {
    super.initState();
    _loginLocation = [];
    _loadLastImagePath();
  }

  // 加载上次保存的图片路径
  Future<void> _loadLastImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('lastImagePath');

    if (savedPath != null && await File(savedPath).exists()) {
      setState(() {
        _selectedImagePath = savedPath;
      });
    } else {
      // 清除无效路径
      await prefs.remove('lastImagePath');
    }
  }

  // 选择并保存图片路径
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      final path = result.files.single.path!;
      final prefs = await SharedPreferences.getInstance();

      // 保存新路径
      await prefs.setString('lastImagePath', path);

      setState(() {
        _selectedImagePath = path;
      });
    }
  }

  // 构建图片显示
  Widget _buildImagePreview() {
    if (_selectedImagePath == null) {
      return _buildDefaultPrompt();
    }

    return FutureBuilder<bool>(
      future: _checkImageExists(_selectedImagePath!),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!) {
          return Image.file(
            File(_selectedImagePath!),
            fit: BoxFit.cover,
          );
        }
        return _buildDefaultPrompt();
      },
    );
  }

  Future<bool> _checkImageExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }

  Widget _buildDefaultPrompt() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_a_photo, size: 40),
          SizedBox(height: 10),
          Text('点击选择背景图片'),
        ],
      ),
    );
  }

// 修改后的提交方法
  Future<bool> _submit(String userCode, String passWord, String hospitalId,
      String hisType) async {
    try {
      if (_formKey.currentState!.validate() && _selectedLocation != null) {
        final result =
            await _getUserYLTLogin(userCode, passWord, hospitalId, hisType);
        if (result) {
          widget.onLogin(userCode, passWord, hospitalId);
        }
        return result;
      }
      return false;
    } catch (e) {
      print('提交失败: $e');
      return false;
    }
  }

  Widget _buildLocationDropdown() {
    return OptimizedDropdown<Location>(
      value: _selectedLocation,
      hintText: '选择登入地点',
      icon: const Icon(Icons.location_on),
      menuMaxHeight: 180,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      items: _loginLocation,
      itemTextBuilder: (location) => location.name,
      onChanged: (Location? newValue) {
        setState(() => _selectedLocation = newValue);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户登录')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // 左侧图片区域
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // 右侧登录表单
            Expanded(
              flex: 3,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: '工号',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入工号';
                        }
                        // 显示异步验证错误
                        if (_apiError != null) {
                          return _apiError;
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _userId = value;
                        // 输入变化时清除错误
                        if (_apiError != null) {
                          setState(() => _apiError = null);
                        }
                      },
                      onFieldSubmitted: (value) async {
                        await _validateUserCode(value);

                        _formKey.currentState?.validate();
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '密码',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (_formSubmitted) {
                          if (value == null || value.isEmpty) {
                            return '请输入密码';
                          }
                        }
                        return null;
                      },
                      onChanged: (value) => _password = value,
                    ),
                    const SizedBox(height: 20),
                    _buildLocationDropdown(),
                    const SizedBox(height: 90),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('登录'),
                      onPressed: () async {
                        if (_isSubmitting) return; // 防止重复提交
                        setState(() => _isSubmitting = true);

                        final success = await _submit(_userId, _password,
                            _selectedLocation!.name, 'hisType');
                        setState(() => _isSubmitting = false);
                        if (success) {
                          return;
                        } else {

                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
