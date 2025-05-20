import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'His/His_page_main.dart';
import 'model/user_repository.dart';
import 'pacs_page.dart';
import 'lis_page.dart';
import 'sales_page.dart';
import 'nursing_page.dart';
import 'data_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => UserRepository()), // 数据仓库
       // Provider(create: (_) => ApiService()),     // 网络服务
      ],
      child: const MyApp(),
    ),
  );
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
  bool _isLoggedIn = false;
  String _userId = '';
  String _loginLocation = '';
  String _currentModule = '首页';

  void handleLogin(String userId, String password, String location) {
    setState(() {
      _isLoggedIn = true;
      _userId = userId;
      _loginLocation = location;
    });
  }

  Widget _buildNavButton(IconData icon, String moduleName, Widget page) {
    final isSelected = _currentModule == moduleName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _currentModule = moduleName);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => page,
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.blue.withOpacity(0.2),
          hoverColor: Colors.blue.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Colors.blue.shade300, width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.blueGrey[700]),
                const SizedBox(width: 12),
                Text(moduleName,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSelected
                          ? Colors.blue.shade800
                          : Colors.blueGrey[800],
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoggedIn
          ? Row(
        children: [
          // 左侧导航栏
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              border: Border(
                  right: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(2, 0),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "欢迎，$_userId",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _loginLocation,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade300),
                // _buildNavButton(
                //   Icons.home,
                //   '首页',
                //   Container(), // 替换为实际首页组件
                // ),
                _buildNavButton(
                  Icons.local_hospital,
                  'HIS',
                  HisPage(
                    userId: _userId,
                    loginLocation: _loginLocation,
                  ),
                ),
                _buildNavButton(
                  Icons.image,
                  'PACS',
                  PacsPage(
                    userId: _userId,
                    loginLocation: _loginLocation,
                  ),
                ),
                _buildNavButton(
                  Icons.science,
                  'LIS',
                  LisPage(
                    userId: _userId,
                    loginLocation: _loginLocation,
                  ),
                ),
                _buildNavButton(
                  Icons.shopping_cart,
                  '销售',
                  SalesPage(
                    userId: _userId,
                    loginLocation: _loginLocation,
                  ),
                ),
                _buildNavButton(
                  Icons.accessible_forward,
                  '养老',
                  NursingPage(
                    userId: _userId,
                    loginLocation: _loginLocation,
                  ),
                ),
                _buildNavButton(
                  Icons.data_thresholding,
                  '数据',
                  DataPage(
                    userId: _userId,
                    loginLocation: _loginLocation,
                  ),
                ),
              ],
            ),
          ),
          // 右侧内容区域
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
              ),
              child: _currentModule == '首页'
                  ? const Center(child: Text('请选择功能模块'))
                  : null, // 根据当前模块显示对应内容
            ),
          ),
        ],
      )
          : LoginScreen(onLogin: handleLogin),
    );
  }
}