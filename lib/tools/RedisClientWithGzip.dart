import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:redis/redis.dart';
import 'package:path/path.dart' as path show join;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';

// 自定义 TreeNode 类
class TreeNode {
  String? id;
  String title;
  List<TreeNode> children;

  TreeNode({required this.title, this.id, this.children = const []});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }
}

class RedisClientWithGzip {
  final Logger _logger = Logger();
  final String host;
  final int port;
  final String? password;
  final bool useCompression;
  final Duration timeout;
  late RedisConnection _connection;
  late Command _command;
  late bool _isConnected;
  int _retryCount = 0;

  RedisClientWithGzip._internal({
    required this.host,
    required this.port,
    required this.password,
    required this.useCompression,
    required this.timeout,
  }) {
    _isConnected = false;
    _autoConnect();
  }

  static final RedisClientWithGzip _instance = RedisClientWithGzip._internal(
    host: '139.9.202.207', // 内置主机地址
    port: 8057, // 内置端口
    password: 'Xyhis@#Xyhis', // 内置密码
    useCompression: true, // 内置是否使用压缩
    timeout: const Duration(seconds: 10), // 内置超时时间
  );

  factory RedisClientWithGzip() {
    return _instance;
  }

  Future<void> _autoConnect() async {
    try {
      _connection = RedisConnection();
      final conn = await _connection.connect(host, port).timeout(timeout);

      _command = Command(conn);
      _isConnected = true;
      _retryCount = 0;
      _logger.i('Redis connected to $host:$port');
    } catch (e) {
      _retryCount++;
      final waitTime = Duration(seconds: _retryCount * 2);
      _logger.e('Redis connection failed ($_retryCount): $e. Retrying in ${waitTime.inSeconds}s');
      await Future.delayed(waitTime);
      await _autoConnect();
    }
  }

  Future<void> _ensureConnected() async {
    if (!_isConnected) await _autoConnect();
  }

  // 压缩数据
  Uint8List _compressData(dynamic data) {
    if (!useCompression) {
      if (data is Uint8List) {
        return data;
      } else {
        return Uint8List.fromList(utf8.encode(data.toString()));
      }
    }

    final bytes = data is Uint8List ? data : Uint8List.fromList(utf8.encode(jsonEncode(data)));
    final encoder = GZipEncoder();
    final compressed = encoder.encode(bytes);

    if (compressed == null) {
      throw Exception('GZIP compression failed');
    }

    return Uint8List.fromList(compressed); // 确保返回 Uint8List
  }

  // 解压数据
  dynamic _decompressData(Uint8List compressed) {
    try {
      final decoder = GZipDecoder();
      final decompressed = decoder.decodeBytes(compressed);
      return Uint8List.fromList(decompressed);
    } catch (e) {
      _logger.w('Decompression failed, returning raw data: $e');
      return compressed;
    }
  }

  // 执行 Redis 命令（带自动重连）
  Future<dynamic> _executeCommand(List<String> args) async {
    await _ensureConnected();

    try {
      final result = await _command.send_object(args);
      return result;
    } catch (e) {
      _logger.e('Redis command failed: $e. Reconnecting...');
      _isConnected = false;
      await _autoConnect();
      return await _command.send_object(args);
    }
  }

  // 存储数据（自动压缩）
  Future<void> set(String key, dynamic value, {Duration? ttl}) async {
    final compressed = _compressData(value);
    var args = ['SET', key, base64.encode(compressed)];

    if (ttl != null) {
      args.addAll(['EX', ttl.inSeconds.toString()]);
    }

    await _executeCommand(args);
  }

  // 获取数据（自动解压）
  Future<dynamic> get(String key) async {
    final result = await _executeCommand(['GET', key]);

    if (result == null) return null;

    if (result is String) {
      final compressed = base64.decode(result);
      final decompressed = _decompressData(Uint8List.fromList(compressed));

      try {
        return jsonDecode(utf8.decode(decompressed));
      } catch (e) {
        return decompressed;
      }
    }

    return result;
  }

  // 存储二进制文件（带压缩）
  Future<void> setFile(String key, File file) async {
    final bytes = await file.readAsBytes();
    final compressed = useCompression ? _compressData(bytes) : bytes;
    await _executeCommand(['SET', key, base64.encode(compressed)]);
  }

  // 获取二进制文件（带解压）
  Future<File> getFile(String key) async {
    final result = await _executeCommand(['GET', key]);

    if (result == null) throw Exception('Key not found: $key');

    final compressed = base64.decode(result as String);
    final bytes = useCompression
        ? _decompressData(Uint8List.fromList(compressed))
        : Uint8List.fromList(compressed);

    final dir = await getTemporaryDirectory();
    final file = File(path.join(dir.path, 'redis_cache_${key.hashCode}.tmp'));
    await file.writeAsBytes(bytes);

    return file;
  }

  // 批量存储树形数据
  Future<void> saveTreeData(List<TreeNode> treeData) async {
    final timestamp = DateTime.now().toIso8601String();

    // 存储整个树结构
    await set('tree_data:all', treeData);

    // 创建管道并开始事务
    _command.pipe_start();

    // 存储每个节点
    for (final node in treeData) {
      _saveTreeNode(node);
    }

    // 存储元数据
    await set('tree_data:meta', {
      'last_updated': timestamp,
      'node_count': treeData.length,
      'checksum': _calculateChecksum(treeData),
    });

    // 提交管道事务
    final results = _command.pipe_end(); // pipe_end 返回 void
    _logger.i('Pipeline executed');
  }

  // 递归保存树节点
  Future<void> _saveTreeNode(TreeNode node, {String? parentId}) async {
    final nodeId = node.id ?? md5.convert(utf8.encode(node.title)).toString();
    node.id = nodeId;

    // 发送 HSET 命令到管道
    _command.send_object([
      'HSET',
      'tree_nodes',
      nodeId,
      jsonEncode(node.toJson()),
    ]);

    if (parentId != null) {
      // 发送 SADD 命令到管道
      _command.send_object([
        'SADD',
        'node_children:$parentId',
        nodeId,
      ]);
    }

    // 递归处理子节点
    for (final child in node.children) {
      await _saveTreeNode(child, parentId: nodeId);
    }
  }
  // 计算树数据校验和
  String _calculateChecksum(List<TreeNode> treeData) {
    final data = treeData.map((n) => n.toJson()).toList();
    final jsonString = jsonEncode(data);
    return md5.convert(utf8.encode(jsonString)).toString();
  }

  // 关闭连接
  Future<void> disconnect() async {
    if (_isConnected) {
      await _connection.close();
      _isConnected = false;
      _logger.i('Redis connection closed');
    }
  }
}