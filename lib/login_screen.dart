import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/public.dart';
import 'package:untitled2/tools/Error.dart';
import 'package:untitled2/utils/shader_warmup.dart';
import 'action/getUserAndHospital.dart';

class LoginScreen extends StatefulWidget {
  final Function(String, String, String) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  _LoginScreenState createState() => _LoginScreenState();
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
  List<Location> _loginLocation = [];
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

  void _initListeners() {
    _userCodeFocusNode.addListener(_onUserCodeFocusChange);
  }

  Future<void> _loadLastImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('lastImagePath');

    if (savedPath != null && await File(savedPath).exists()) {
      setState(() => _selectedImagePath = savedPath);
    } else {
      await prefs.remove('lastImagePath');
    }
  }

  void _initSystemUI() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
  }

  void _onUserCodeFocusChange() {
    if (!_userCodeFocusNode.hasFocus) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted && _userId.isNotEmpty) {
          _validateUserCode(_userId);
          _formKey.currentState?.validate();
        }
      });
    } else {
      _debounceTimer?.cancel();
    }
  }

  Future<void> _validateUserCode(String userCode) async {
    if (!mounted) return;

    setState(() {
      _apiError = null;
      _loginLocation = [];
      _selectedLocation = null;
    });

    try {
      final locations = await UserAndHospitalService.validateUserCode(userCode);
      if (mounted) {
        setState(() {
          _loginLocation = locations;
          _selectedLocation = locations.isNotEmpty ? locations.first : null;
        });
      }
    } catch (e, stack) {
      if (!mounted) return;
      final errorMsg = logAndShowError(
        context: context,
        exception: e,
        stackTrace: stack,
        title: '操作失败',
        mounted: mounted,
      );
      setState(() => _apiError = errorMsg);
    }
  }

  Future<User?> _getUserYLTLogin(
      String userCode,
      String password,
      String hospitalId,
      String hisType,
      ) async {
    if (!mounted) return null;

    setState(() {
      _apiError = null;
    });

    try {
      final UserInfo = await UserAndHospitalService.userLogin(
        userCode,
        password,
        hospitalId,
        hisType,
      );
      return UserInfo;
    } catch (e, stack) {
      if (!mounted) return null;
      final errorMsg = logAndShowError(
        context: context,
        exception: e,
        stackTrace: stack,
        title: "用户登录错误",
        mounted: mounted,
      );
      setState(() => _apiError = errorMsg);
      return null;
    }
  }

  Future<bool> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) {
      return false;
    }

    try {
      setState(() => _isSubmitting = true);
      final userinfo = await _getUserYLTLogin(
        _userId,
        _password,
        '1165', // 应替换为实际hospitalId
        '7',    // 应替换为实际hisType
      );
      if (userinfo!=null) {
        widget.onLogin(_userId, _password, _selectedLocation!.name);
        return true;
      }
      return false;
    } catch (e, stack) {
      final errorMsg = logAndShowError(
        context: context,
        exception: e,
        stackTrace: stack,
        title: "验证用户错误",
        mounted: mounted,
      );
      throw Exception(errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    final path = result.files.single.path;
    if (path == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastImagePath', path);
    if (mounted) {
      setState(() => _selectedImagePath = path);
    }
  }

  Widget _buildImagePreview() {
    return FutureBuilder<bool>(
      future: _checkImageExists(_selectedImagePath ?? ''),
      builder: (context, snapshot) {
        final exists = snapshot.data ?? false;
        if (exists) {
          return Image.file(File(_selectedImagePath!), fit: BoxFit.cover);
        }
        return _buildDefaultPrompt();
      },
    );
  }

  Future<bool> _checkImageExists(String path) async {
    try {
      return await File(path).exists();
    } catch (_) {
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

  @override
  Widget build(BuildContext context) {
    WarmUpTheShader.warmUp(context);
    return Scaffold(
      appBar: AppBar(title: const Text('用户登录')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // 图片区域
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedImagePath != null
                      ? _buildImagePreview()
                      : _buildDefaultPrompt(),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // 登录表单
            Expanded(
              flex: 3,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        focusNode: _userCodeFocusNode,
                        decoration: const InputDecoration(
                          labelText: '工号',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return '请输入工号';
                          if (_apiError != null) return _apiError;
                          return null;
                        },
                        onChanged: (value) {
                          _userId = value;
                          if (_apiError != null) {
                            setState(() => _apiError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: '密码',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (value) =>
                        value?.isEmpty ?? true ? '请输入密码' : null,
                        onChanged: (value) => _password = value,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<Location>(
                        value: _selectedLocation,
                        hint: const Text('选择登入地点'),
                        items: _loginLocation
                            .map((loc) => DropdownMenuItem(
                          value: loc,
                          child: Text(loc.name),
                        ))
                            .toList(),
                        onChanged: (loc) =>
                            setState(() => _selectedLocation = loc),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: Text(_isSubmitting ? '登录中...' : '登录'),
                        onPressed: _isSubmitting ? null : () async {
                          final success = await _submit();
                          if (success) Navigator.pop(context);
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