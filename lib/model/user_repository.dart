// user_repository.dart
import '../public.dart';

class UserRepository {
  // 使用 Map 存储多份 User 数据，key 为自定义标识符
  final Map<String, User> _users = {};

  // 添加/更新用户数据
  void updateUser(String key, User user) {
    _users[key] = user;
  }

  // 获取用户数据
  User? getUser(String key) => _users[key];

  // 清除所有数据（退出登录时调用）
  void clear() => _users.clear();
}