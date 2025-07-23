import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'action/get_user_and_hospital.dart';
import 'model/user_repository.dart';
import 'public.dart';
import 'tools/error.dart';
import 'utils/shader_warmup.dart';

class LoginScreen extends StatefulWidget {
  final Function(String, String, String) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
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
  bool _isValidating = false;
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

  /// 加载上次保存的背景图片路径
  ///
  /// 该方法用于在应用启动时恢复用户上次选择的背景图片，主要流程：
  /// 1. 从本地持久化存储(SharedPreferences)中读取保存的图片路径
  /// 2. 验证该路径对应的图片文件是否仍然存在
  /// 3. 根据验证结果更新状态或清理无效存储
  ///
  /// 注意：
  /// - 使用异步操作访问文件系统，需等待结果
  /// - 如果文件已被删除，会自动清理无效记录
  /// - 触发setState会更新UI显示最新图片
  Future<void> _loadLastImagePath() async {
    // 获取共享偏好实例
    final prefs = await SharedPreferences.getInstance();

    // 尝试读取上次保存的图片路径
    final savedPath = prefs.getString('lastImagePath');

    if (savedPath != null) {
      // 验证文件是否存在（防止文件被外部删除）
      final fileExists = await File(savedPath).exists();

      if (fileExists) {
        // 有效路径：更新状态显示图片
        setState(() => _selectedImagePath = savedPath);
      } else {
        // 无效路径：清理无效记录
        await prefs.remove('lastImagePath');
      }
    }
    // 无保存路径时不做任何操作
  }

  void _initSystemUI() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
  }

  void _onUserCodeFocusChange() {
    if (!_userCodeFocusNode.hasFocus) {
      _debounceTimer?.cancel(); // 取消上一个计时器

      // 延迟500ms进行验证，确保用户输入停止一段时间
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted && _userId.isNotEmpty && !_isValidating) {
          _validateUserCode(_userId);  // 调用校验方法
        }
      });
    } else {
      _debounceTimer?.cancel();  // 焦点获取时取消当前计时器，避免在输入中断时校验
    }
  }

  /// 统一的错误处理方法
  void _handleError(dynamic error, StackTrace stack, String title) {
    if (!mounted) return;
    final errorMsg = logAndShowError(
      context: context,
      exception: error,
      stackTrace: stack,
      title: title,
      mounted: mounted,
    );
    setState(() => _apiError = errorMsg);
  }

  Future<void> _validateUserCode(String userCode) async {
    if (!mounted) return;

    setState(() {
      _apiError = null;
      _loginLocation = [];
      _selectedLocation = null;
      _isValidating = true;
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
      _handleError(e, stack, '操作失败');
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }


    Future<User?> _getUserYLTLogin(
      String userCode,
      String password,
      String hospitalId,
      String hisType,
      ) async {
    if (!mounted) return null;

    setState(() => _apiError = null);

    try {
      final userInfo = await UserAndHospitalService.userLogin(
        userCode,
        password,
        hospitalId,
        hisType,
      );
      return userInfo;
    } catch (e, stack) {
      _handleError(e, stack, "用户登录错误");
      return null;
    }
  }

  Future<bool> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) {
      return false;
    }

    try {
      setState(() => _isSubmitting = true);
      final userInfo = await _getUserYLTLogin(
        _userId,
        _password,
        _selectedLocation!.hospitalId,
        _selectedLocation!.hisType, // 从医院信息中获取hisType
      );

      if (userInfo != null) {
        try {
          if (!context.mounted) return false;
          final currentContext = context;
          final repo = currentContext.read<UserRepository>();
          repo.updateUser('basic', userInfo);
          widget.onLogin(_userId, _password, _selectedLocation!.name);
          return true;
        } catch (e, stack) {
          if (mounted && context.mounted) {
            _handleError(e, stack, "解析用户信息错误");
          }
          return false;
        }
      }
      return false;
    } catch (e, stack) {
      if (mounted && context.mounted) {
        _handleError(e, stack, "验证用户错误");
      }
      return false;
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
                          //if (_apiError != null) return _apiError;
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
                        validator: (value) {
                          if (_isSubmitting) {
                            if (value?.isEmpty ?? true) {
                              return '请输入密码';
                            }
                          }
                          return null;
                        },
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
                           await _submit();
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