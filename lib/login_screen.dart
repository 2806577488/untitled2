import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/optimized_dropdown.dart';

class LoginScreen extends StatefulWidget {
  final Function(String, String, String) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedImagePath;
  String _userId = '';
  String _password = '';
  String _loginLocation = '车间A';

  @override
  void initState() {
    super.initState();
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onLogin(_userId, _password, _loginLocation);
    }
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
                        return null;
                      },
                      onChanged: (value) => _userId = value,
                    ),
                    const SizedBox(height: 20),
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
                        if (value.length < 6) {
                          return '密码至少6位';
                        }
                        return null;
                      },
                      onChanged: (value) => _password = value,
                    ),
                    const SizedBox(height: 20),
                    //下拉框
                    OptimizedDropdown<String>(
                      value: _loginLocation,
                      items: const ['车间A', '车间B', '办公室', '仓库'],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _loginLocation = value);
                        }
                      },
                      hintText: '选择登入地点',
                      icon: const Icon(Icons.location_on),
                      menuMaxHeight: 180,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('登录'),
                      onPressed: _submit,
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