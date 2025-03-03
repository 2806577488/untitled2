import 'package:flutter/material.dart';
import 'menu.dart';
import 'button_bar.dart';
import 'main_content.dart';
import 'login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '模块化示例',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '模块化布局示例'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _message = "等待操作...";
  bool _isLoggedIn = false;
  String _userId = '';
  String _loginLocation = '';

  void _updateMessage(String message) {
    setState(() => _message = message);
  }

  void handleLogin(String userId, String password, String location) {
    setState(() {
      _isLoggedIn = true;
      _userId = userId;          // 正确赋值
      _loginLocation = location; // 正确赋值
    });
  }
  void _incrementCounter() {
    setState(() {
      _counter++;
      _message = "增加操作：当前值 $_counter";
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
      _message = "计数器已重置";
    });
  }

  Widget _buildMessageArea() {
    return Container(
      height: 40,
      color: Colors.amber.shade100,
      alignment: Alignment.center,
      child: Text(
        _message,
        style: const TextStyle(
          color: Colors.deepOrange,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoggedIn
          ? Column(
        children: [
          Menu(
            userId: _userId,
            loginLocation: _loginLocation,
            onMessageUpdate: _updateMessage,
          ),
          CustomButtonBar(
            onIncrement: _incrementCounter,
            onReset: _resetCounter,
            onShowInfo: _updateMessage,
          ),
          MainContent(counter: _counter),
          _buildMessageArea(),
        ],
      )
          : LoginScreen(onLogin: handleLogin), // 使用公共方法
    );
  }
}