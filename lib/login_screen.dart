import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:untitled2/model/HospitalResponse.dart';
import 'package:untitled2/tools/Error.dart';
import 'package:untitled2/utils/customDialog.dart';
import 'package:untitled2/utils/shader_warmup.dart';

class LoginScreen extends StatefulWidget {
  final Function(String, String, String) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class Location {
  final String name;

  Location(this.name);

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
  // 表单相关
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // 用户输入相关
  String _userId = '';
  String _password = '';
  String? _apiError;

  // 图片相关
  String? _selectedImagePath;

  // 登录地点相关
  late List<Location> _loginLocation = [];
  Location? _selectedLocation;

  // 焦点相关
  final FocusNode _userCodeFocusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initListeners();
    _loadLastImagePath();
    _initSystemUI();
  }

  @override
  void dispose() {
    _userCodeFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 初始化监听器
  void _initListeners() {
    _userCodeFocusNode.addListener(_onUserCodeFocusChange);
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
      await prefs.remove('lastImagePath');
    }
  }

  // 初始化系统UI
  void _initSystemUI() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
  }

  // 工号焦点改变时的处理
  void _onUserCodeFocusChange() {
    if (!_userCodeFocusNode.hasFocus) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        await _validateUserCode(_userId);
        _formKey.currentState?.validate();
      });
    } else {
      _debounceTimer?.cancel();
    }
  }

  // 验工号
  Future<void> _validateUserCode(String userCode) async {
    setState(() {
      _apiError = null;
      _loginLocation.clear();
    });

    try {
      final response = await _postRequest(
        'GetBsHospitalByUserCode',
        {'Code': userCode},
      );

      if (response.statusCode == 200) {
        final locations = _parseHospitalResponse(response.body);
        setState(() {
          _loginLocation = locations;
          _selectedLocation = locations.isNotEmpty ? locations.first : null;
        });
      } else {
        setState(() => _apiError = "请求失败 (${response.statusCode})");
      }
    } catch (e, stack) {
      final errorMsg = _logAndShowError(e, stack, "工号验证错误");
      setState(() => _apiError = errorMsg);
    }
  }

  // 用户登录
  Future<bool> _getUserYLTLogin(String userCode, String password, String hospitalId, String hisType) async {
    setState(() {
      _apiError = null;
      _loginLocation.clear();
    });

    try {
      final response = await _postRequest(
        'GetUserYLTLogin',
        {
          'Code': userCode,
          'Password': password,
          'hospitalId': hospitalId,
          'hisType': hisType,
        },
      );

      if (response.statusCode == 200) {
        final locations = _parseLoingUserAndPassword(response.body);
        setState(() {
          _loginLocation = locations;
          _selectedLocation = locations.isNotEmpty ? locations.first : null;
        });
        return true;
      } else {
        setState(() => _apiError = "请求失败 (${response.statusCode})");
        return false;
      }
    } catch (e) {
      setState(() => _apiError = e.toString());
      return false;
    }
  }

  // 提交表单
  Future<bool> _submit(String userCode, String password, String hospitalId, String hisType) async {
    try {
      if (_formKey.currentState!.validate() && _selectedLocation != null) {
        final result = await _getUserYLTLogin(userCode, password, hospitalId, hisType);
        if (result) {
          widget.onLogin(userCode, password, hospitalId);
        }
        return result;
      }
      return false;
    } catch (e,stack) {
    final errorMsg=_logAndShowError(e,stack,"验证用户错误");
    throw Exception(errorMsg);
    }
  }

  // 选择并保存图片路径
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      final path = result.files.single.path!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastImagePath', path);
      setState(() => _selectedImagePath = path);
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
          return Image.file(File(_selectedImagePath!), fit: BoxFit.cover);
        }
        return _buildDefaultPrompt();
      },
    );
  }

  // 检查图片是否存在
  Future<bool> _checkImageExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }

  // 构建默认提示
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

  // 发起POST请求
  Future<http.Response> _postRequest(String documentElement, Map<String, String> params) {
    final bodyParams = {
      'tokencode': '8ab6c803f9a380df2796315cad1b4280',
      'DocumentElement': documentElement,
      ...params.map((key, value) => MapEntry(key, Uri.encodeComponent(value))),
    };

    return http.post(
      Uri.parse('https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mozilla/5.0 (...) Chrome/120.0.0.0 Safari/537.36',
      },
      body: bodyParams.entries.map((e) => '${e.key}=${e.value}').join('&'),
    ).timeout(const Duration(seconds: 10));
  }

  // 解析医院信息响应
  List<Location> _parseHospitalResponse(String responseBody) {
    try {
      final data = json.decode(responseBody);
      final hospitalResponse = HospitalResponse.fromJson(data);

      if (hospitalResponse.returns.isEmpty) {
        throw Exception("编码不存在对应用户");
      }

      return hospitalResponse.returns.map<Location>((returnItem) {
        final name = returnItem.name;
        return Location(name);
      }).toList();
    } catch (e, stack) {
      final errorMsg = _logAndShowError(e, stack, "解析医院信息错误");
      throw Exception(errorMsg);
    }
  }

  // 解析用户登录信息响应
  List<Location> _parseLoingUserAndPassword(String responseBody) {
    try {
      final data = json.decode(responseBody);

      if (data['Returns'] == null || data['Returns'].isEmpty) {
        if (data['Message'] != null && data['Message'] is String && data['Message'].isNotEmpty) {
          throw Exception(data['Message']);
        }
        throw Exception("返回为空");
      }

      return (data['Returns'] as List).map<Location>((item) {
        final name = item['Name']?.toString() ?? '未知地点';
        return Location(name);
      }).toList();
    } catch (e) {
      throw Exception("JSON解析失败: $e");
    }
  }

  // 记录并显示错误
  String _logAndShowError(Object exception, StackTrace stackTrace, String title) {
    final errorDetails = logError(exception, stackTrace);
    if (mounted) {
      CustomDialog.show(
        context: context,
        title: title,
        content: errorDetails.toString(),
        buttonType: DialogButtonType.singleConfirm,
        onConfirm: () {},
      );
    }
    return errorDetails.toString();
  }

  @override
  Widget build(BuildContext context) {
    WarmUpTheShader.warmUp(context);
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    // 工号输入框
                    TextFormField(
                      focusNode: _userCodeFocusNode,
                      decoration: const InputDecoration(
                        labelText: '工号',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入工号';
                        }
                        if (_apiError != null) {
                         // return _apiError;
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _userId = value;
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
                    // 密码输入框
                    TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '密码',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        return null;
                      },
                      onChanged: (value) => _password = value,
                    ),
                    const SizedBox(height: 20),
                    // 登录地点选择
                    DropdownButtonFormField<Location>(
                      value: _selectedLocation,
                      hint: const Text('选择登入地点'),
                      icon: const Icon(Icons.location_on),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _loginLocation
                          .map<DropdownMenuItem<Location>>((Location location) {
                        return DropdownMenuItem<Location>(
                          value: location,
                          child: Text(location.name),
                        );
                      }).toList(),
                      onChanged: (Location? newValue) {
                        setState(() => _selectedLocation = newValue);
                      },
                    ),
                    const SizedBox(height: 30),
                    // 登录按钮
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('登录'),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                        setState(() => _isSubmitting = true);
                        final success = await _submit(_userId, _password, '1165', '0');

                        if (success) {
                          Navigator.pop(context);
                        }
                        else {
                          setState(() => _isSubmitting = false);
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
            ),
              ],
        ),
      ),
    );
  }
}