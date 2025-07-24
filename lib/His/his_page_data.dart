import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/table_row_data.dart';
import '../tools/error.dart';

/// 应用级数据预加载管理器
class AppDataPreloader {
  static bool _isPreloading = false;
  static bool _isPreloaded = false;
  
  /// 应用启动时预加载数据
  static void preloadOnAppStart() {
    if (_isPreloading || _isPreloaded) return;
    
    _isPreloading = true;
    GlobalErrorHandler.logDebug('应用启动，预加载已准备就绪');
    
    // 数据预加载将在登录成功后由main.dart触发
    // 不在应用启动时进行预加载，因为此时还没有登录信息
    _isPreloading = false;
    GlobalErrorHandler.logDebug('等待登录成功后进行数据预加载');
  }
  
  /// 检查是否已预加载
  static bool get isPreloaded => _isPreloaded;
  
  /// 重置预加载状态
  static void resetPreloadStatus() {
    _isPreloaded = false;
    _isPreloading = false;
  }
}

/// 数据缓存管理器
class DataCacheManager {
  static final Map<String, List<TableRowData>> _memoryCache = {};
  static final Map<String, Map<int, List<TableRowData>>> _mapMemoryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 30); // 缓存30分钟
  
  /// 检查缓存是否有效
  static bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }
  
  /// 获取缓存数据
  static List<TableRowData>? getCachedData(String key) {
    if (_isCacheValid(key)) {
      GlobalErrorHandler.logDebug('使用缓存数据: $key');
      return _memoryCache[key];
    }
    return null;
  }
  
  /// 设置缓存数据
  static void setCachedData(String key, List<TableRowData> data) {
    _memoryCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    GlobalErrorHandler.logDebug('缓存数据已更新: $key (${data.length} 条)');
  }
  
  /// 获取缓存Map数据
  static Map<int, List<TableRowData>>? getCachedMapData(String key) {
    if (_isCacheValid(key)) {
      GlobalErrorHandler.logDebug('使用缓存Map数据: $key');
      return _mapMemoryCache[key];
    }
    return null;
  }

  /// 设置缓存Map数据
  static void setCachedMapData(String key, Map<int, List<TableRowData>> data) {
    _mapMemoryCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    GlobalErrorHandler.logDebug('缓存Map数据已更新: $key (${data.length} 个分类)');
  }
  
  /// 清除缓存
  static void clearCache(String? key) {
    if (key != null) {
      _memoryCache.remove(key);
      _mapMemoryCache.remove(key);
      _cacheTimestamps.remove(key);
      GlobalErrorHandler.logDebug('清除缓存: $key');
    } else {
      _memoryCache.clear();
      _mapMemoryCache.clear();
      _cacheTimestamps.clear();
      GlobalErrorHandler.logDebug('清除所有缓存');
    }
  }
  
  /// 获取缓存状态
  static Map<String, dynamic> getCacheStatus() {
    return {
      'cachedKeys': [..._memoryCache.keys, ..._mapMemoryCache.keys],
      'cacheSizes': {
        ..._memoryCache.map((key, value) => MapEntry(key, value.length)),
        ..._mapMemoryCache.map((key, value) => MapEntry(key, '${value.length} 个分类')),
      },
      'timestamps': _cacheTimestamps,
    };
  }
}

/// 项目分类常量定义
class ProjectCategories {
  static const Map<int, String> categories = {
    1: '中成药',
    2: '西药',
    3: '中药',
    4: '检验',
    5: '检查',
    6: '手术',
    7: '治疗',
    8: '床位',
    9: '材料',
    10: '物资',
    11: '设备',
    12: '后勤',
    13: '其它',
    14: '毒麻',
    15: '食品',
  };

  /// 根据分类ID获取分类名称
  static String getCategoryName(int categoryId) {
    return categories[categoryId] ?? '未知分类';
  }

  /// 根据分类名称获取分类ID
  static int? getCategoryId(String categoryName) {
    for (var entry in categories.entries) {
      if (entry.value == categoryName) {
        return entry.key;
      }
    }
    return null;
  }

  /// 获取所有分类列表
  static List<Map<String, dynamic>> getAllCategories() {
    return categories.entries.map((entry) => {
      'id': entry.key,
      'name': entry.value,
    }).toList();
  }
}

/// 智能数据加载器 - 支持缓存和预加载
class SmartDataLoader {
  static final Map<String, Future<List<TableRowData>>> _loadingTasks = {};
  static final Map<String, Future<Map<int, List<TableRowData>>>> _mapLoadingTasks = {};
  
  /// 智能加载数据 - 优先使用缓存，后台更新
  static Future<List<TableRowData>> smartLoad(
    String cacheKey,
    Future<List<TableRowData>> Function() loader,
    {bool forceRefresh = false}
  ) async {
    // 如果正在加载，返回现有的加载任务
    if (_loadingTasks.containsKey(cacheKey)) {
      GlobalErrorHandler.logDebug('数据正在加载中，等待现有任务: $cacheKey');
      return await _loadingTasks[cacheKey]!;
    }
    
    // 检查缓存
    if (!forceRefresh) {
      final cachedData = DataCacheManager.getCachedData(cacheKey);
      if (cachedData != null) {
        // 后台刷新缓存
        _backgroundRefresh(cacheKey, loader);
        return cachedData;
      }
    }
    
    // 开始加载
    final loadingTask = _loadDataWithRetry(loader);
    _loadingTasks[cacheKey] = loadingTask;
    
    try {
      final result = await loadingTask;
      DataCacheManager.setCachedData(cacheKey, result);
      return result;
    } finally {
      _loadingTasks.remove(cacheKey);
    }
  }
  
  /// 智能加载Map数据 - 支持项目分类批量数据的缓存
  static Future<Map<int, List<TableRowData>>> smartLoadMap(
    String cacheKey,
    Future<Map<int, List<TableRowData>>> Function() loader,
    {bool forceRefresh = false}
  ) async {
    // 如果正在加载，返回现有的加载任务
    if (_mapLoadingTasks.containsKey(cacheKey)) {
      GlobalErrorHandler.logDebug('Map数据正在加载中，等待现有任务: $cacheKey');
      return await _mapLoadingTasks[cacheKey]!;
    }
    
    // 检查缓存 - 从DataCacheManager获取Map缓存
    if (!forceRefresh) {
      final cachedMapData = DataCacheManager.getCachedMapData(cacheKey);
      if (cachedMapData != null) {
        // 后台刷新缓存
        _backgroundRefreshMap(cacheKey, loader);
        return cachedMapData;
      }
    }
    
    // 开始加载
    final loadingTask = _loadMapDataWithRetry(loader);
    _mapLoadingTasks[cacheKey] = loadingTask;
    
    try {
      final result = await loadingTask;
      DataCacheManager.setCachedMapData(cacheKey, result);
      return result;
    } finally {
      _mapLoadingTasks.remove(cacheKey);
    }
  }
  
  /// 后台刷新数据
  static void _backgroundRefresh(
    String cacheKey,
    Future<List<TableRowData>> Function() loader,
  ) {
    Future(() async {
      try {
        GlobalErrorHandler.logDebug('后台刷新数据: $cacheKey');
        final freshData = await _loadDataWithRetry(loader);
        DataCacheManager.setCachedData(cacheKey, freshData);
        GlobalErrorHandler.logDebug('后台刷新完成: $cacheKey');
      } catch (e) {
        GlobalErrorHandler.logDebug('后台刷新失败: $cacheKey - $e');
      }
    });
  }
  
  /// 后台刷新Map数据
  static void _backgroundRefreshMap(
    String cacheKey,
    Future<Map<int, List<TableRowData>>> Function() loader,
  ) {
    Future(() async {
      try {
        GlobalErrorHandler.logDebug('后台刷新Map数据: $cacheKey');
        final freshData = await _loadMapDataWithRetry(loader);
        DataCacheManager.setCachedMapData(cacheKey, freshData);
        GlobalErrorHandler.logDebug('后台刷新Map数据完成: $cacheKey');
      } catch (e) {
        GlobalErrorHandler.logDebug('后台刷新Map数据失败: $cacheKey - $e');
      }
    });
  }
  
  /// 带重试的数据加载
  static Future<List<TableRowData>> _loadDataWithRetry(
    Future<List<TableRowData>> Function() loader,
  ) async {
    const maxRetries = 2;
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await loader();
      } catch (e) {
        GlobalErrorHandler.logDebug('数据加载失败 (尝试 ${i + 1}/$maxRetries): $e');
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: 1 + i));
      }
    }
    return [];
  }
  
  /// 带重试的Map数据加载
  static Future<Map<int, List<TableRowData>>> _loadMapDataWithRetry(
    Future<Map<int, List<TableRowData>>> Function() loader,
  ) async {
    const maxRetries = 2;
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await loader();
      } catch (e) {
        GlobalErrorHandler.logDebug('Map数据加载失败 (尝试 ${i + 1}/$maxRetries): $e');
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: 1 + i));
      }
    }
    return {};
  }
  
  /// 预加载所有数据
  static void preloadAllData({required String hisType, required String hospitalId}) {
    GlobalErrorHandler.logDebug('开始预加载所有数据... (hisType: $hisType, hospitalId: $hospitalId)');
    
    // 预加载省份数据
    SmartDataLoader.smartLoad(
      'province_data_${hisType}_$hospitalId',
      () => fetchProvinceData(hisType: hisType, hospitalId: hospitalId),
    );
    
    // 预加载用法数据
    SmartDataLoader.smartLoad(
      'usage_data_${hisType}_$hospitalId',
      () => getUsage(hisType: hisType, hospitalId: hospitalId),
    );
    
    // 预加载所有项目分类数据
    SmartDataLoader.smartLoadMap(
      'all_categories_${hisType}_$hospitalId',
      () => getAllBsItemData(hisType: hisType, hospitalId: hospitalId),
    );
    
    GlobalErrorHandler.logDebug('预加载任务已启动');
  }
  
  /// 清除所有加载任务
  static void clearLoadingTasks() {
    _loadingTasks.clear();
    _mapLoadingTasks.clear();
    GlobalErrorHandler.logDebug('清除所有加载任务');
  }
}

Future<List<TableRowData>> fetchProvinceData({required String hisType, required String hospitalId}) async {
  try {
    GlobalErrorHandler.logDebug('开始请求省份数据...');
    
    final response = await http.post(
      Uri.parse('https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'tokencode': '8ab6c803f9a380df2796315cad1b4280',
        'DocumentElement': 'GetBsAreaProvinceAll',
        "hospitalId": hospitalId,
        "histype": hisType,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      GlobalErrorHandler.logDebug('省份接口响应状态: ${response.statusCode}');
      
        final returnsData = data['Returns'];
      GlobalErrorHandler.logDebug('Returns 类型: ${returnsData.runtimeType}');
      GlobalErrorHandler.logDebug('Returns 内容: $returnsData');
        
        if (returnsData is List) {
        final result = returnsData.map<TableRowData>((item) {
          return TableRowData(
            id: (item['ID'] ?? 0) is int ? (item['ID'] ?? 0) : int.tryParse((item['ID'] ?? '0').toString()) ?? 0,
            values: {
              'name': item['Name'] ?? '',
              'code': item['Code'] ?? '',
            },
          );
        }).toList();
        GlobalErrorHandler.logDebug('解析后的省份数据: ${result.length} 条');
          return result;
      } else if (returnsData is Map<String, dynamic> && returnsData.containsKey('ReturnT')) {
        final returnT = returnsData['ReturnT'] as List;
        final result = returnT.map<TableRowData>((item) {
          return TableRowData(
            id: (item['ID'] ?? 0) is int ? (item['ID'] ?? 0) : int.tryParse((item['ID'] ?? '0').toString()) ?? 0,
            values: {
              'name': item['Name'] ?? '',
              'code': item['Code'] ?? '',
            },
          );
        }).toList();
        GlobalErrorHandler.logDebug('从 ReturnT 解析的省份数据: ${result.length} 条');
            return result;
      } else {
        GlobalErrorHandler.logDebug('警告: 无法解析省份数据，返回空列表');
        return [];
      }
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  } catch (e) {
    GlobalErrorHandler.logErrorOnly(e, StackTrace.current);
    rethrow;
  }
}

Future<void> saveBsUsageToServer(List<Map<String, dynamic>> bsUsageData, {required String hisType, required String hospitalId}) async {
  try {
    GlobalErrorHandler.logDebug('开始保存用法数据: $bsUsageData');
    
    final response = await http.post(
      Uri.parse('https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'tokencode': '8ab6c803f9a380df2796315cad1b4280',
        'DocumentElement': 'SaveBsUsage',
        'hospitalId': hospitalId,
        'histype': hisType,
        'bsUsageData': jsonEncode(bsUsageData),
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      GlobalErrorHandler.logDebug('保存用法接口响应状态: ${response.statusCode}');
      
      
      // 检查是否有嵌套的 Returns 字段
      Map<String, dynamic>? actualResult;
      if (data.containsKey('Returns') && data['Returns'] is Map<String, dynamic>) {
        actualResult = data['Returns'] as Map<String, dynamic>;
        GlobalErrorHandler.logDebug('发现嵌套的 Returns 字段: $actualResult');
      } else {
        actualResult = data;
      }
      
      // 使用实际的结果数据
      if (actualResult['IsSuccess'] == true) {
        GlobalErrorHandler.logDebug('用法数据保存成功');
        return;
      } else {
        // API 返回失败，提供详细的错误信息
        final errorMsg = actualResult['Message']?.toString() ?? actualResult['ErrorMsg']?.toString() ?? actualResult['ShowMsg']?.toString() ?? '';
        final warningMsg = actualResult['WarningMsg']?.toString() ?? '';
        final errorCode = actualResult['ErrorCode']?.toString() ?? '';
        final warningCode = actualResult['WarningCode']?.toString() ?? '';
        
        GlobalErrorHandler.logDebug('错误信息: $errorMsg');
        GlobalErrorHandler.logDebug('警告信息: $warningMsg');
        GlobalErrorHandler.logDebug('错误码: $errorCode');
        GlobalErrorHandler.logDebug('警告码: $warningCode');
        
        // 构建错误消息
        String fullErrorMsg = '保存失败';
        
        // 如果有具体的错误消息，优先显示
        if (errorMsg.isNotEmpty) {
          fullErrorMsg = errorMsg;
        } else if (warningMsg.isNotEmpty) {
          fullErrorMsg = '警告: $warningMsg';
        } else if (errorCode != '0' && errorCode.isNotEmpty) {
          fullErrorMsg = '错误码: $errorCode';
        } else if (warningCode != '0' && warningCode.isNotEmpty) {
          fullErrorMsg = '警告码: $warningCode';
        } else {
          fullErrorMsg = '保存失败，请检查数据格式';
        }
        
        throw Exception(fullErrorMsg);
      }
    } else {
    throw Exception('请求失败: ${response.statusCode}');
    }
  } catch (e) {
    GlobalErrorHandler.logErrorOnly(e, StackTrace.current);
    rethrow;
  }
}

Future<List<TableRowData>> getUsage({required String hisType, required String hospitalId}) async {
  try {
    final response = await http.post(
      Uri.parse('https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'tokencode': '8ab6c803f9a380df2796315cad1b4280',
        'DocumentElement': 'GetBsUsageAll',
        "hospitalId": hospitalId,
        "histype": hisType,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      // 检查 'Returns' 字段
      if (data.containsKey('Returns')) {
        final returnsData = data['Returns'];

        // 处理两种可能的返回结构
        if (returnsData is List) {
          // 直接是列表的情况
          return returnsData.map((item) {
            return TableRowData.fromJson(item);
          }).toList();
        } else if (returnsData is Map) {
          // 检查 'ReturnT' 字段
          if (returnsData.containsKey('ReturnT') && returnsData['ReturnT'] is List) {
            final List<dynamic> rawList = returnsData['ReturnT'];
            return rawList.map((item) {
              return TableRowData.fromJson(item);
            }).toList();
          }
        }
      }

      return [];
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  } catch (e, stack) {
    GlobalErrorHandler.logErrorOnly(e, stack);
    throw Exception('用法数据加载失败: $e');
  }
}

/// 根据LSRPTYPE获取bsitem数据
/// [lsrptype] 项目分类ID (1-15)
/// [hisType] HIS系统类型，必须传入
/// [hospitalId] 医院ID，必须传入
Future<List<TableRowData>> getBsItemAllData(
  int lsrptype, {
  required String hisType,
  required String hospitalId,
}) async {
  final startTime = DateTime.now();
  try {
    // 验证lsrptype参数
    if (lsrptype < 1 || lsrptype > 15) {
      throw Exception('无效的项目分类ID: $lsrptype，有效范围为1-15');
    }

    final categoryName = ProjectCategories.getCategoryName(lsrptype);
    GlobalErrorHandler.logDebug('开始获取$categoryName数据，分类ID: $lsrptype');

    final response = await http.post(
      Uri.parse('https://doctor.xyhis.com/Api/NewYLTBackstage/PostCallInterface'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'lsrptype': lsrptype.toString(),
        'hospitalId': hospitalId,
        'histype': hisType,
        'tokencode': '8ab6c803f9a380df2796315cad1b4280',
        'DocumentElement': 'GetListBylsRpTypeAndHospitalId',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      GlobalErrorHandler.logDebug('$categoryName接口响应: ${response.statusCode}');

      final returnsData = data['Returns'];
      if (returnsData == null) {
        GlobalErrorHandler.logDebug('$categoryName数据为空');
        return [];
      }

      List<dynamic> itemList;
      if (returnsData is List) {
        itemList = returnsData;
      } else if (returnsData is Map && returnsData.containsKey('ReturnT')) {
        itemList = returnsData['ReturnT'] as List? ?? [];
      } else {
        GlobalErrorHandler.logDebug('$categoryName数据格式异常: $returnsData');
        return [];
      }

      final result = itemList.map<TableRowData>((item) {
        return TableRowData.fromJson(item);
      }).toList();

      // 计算并记录耗时
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      GlobalErrorHandler.logDebug('$categoryName数据加载完成: ${result.length} 条，耗时: ${duration}ms');
      
      return result;
    } else {
      throw Exception('$categoryName数据请求失败: ${response.statusCode}');
    }
  } catch (e, stack) {
    GlobalErrorHandler.logErrorOnly(e, stack);
    final categoryName = ProjectCategories.getCategoryName(lsrptype);
    throw Exception('$categoryName数据加载失败: $e');
  }
}

/// 获取所有项目分类的数据
/// [hisType] HIS系统类型，必须传入
/// [hospitalId] 医院ID，必须传入
Future<Map<int, List<TableRowData>>> getAllBsItemData({
  required String hisType,
  required String hospitalId,
}) async {
  final Map<int, List<TableRowData>> allData = {};
  
  try {
    GlobalErrorHandler.logDebug('开始获取所有项目分类数据...');
    
    // 第一步：优先获取中成药数据（分类1）
    GlobalErrorHandler.logDebug('优先获取中成药数据...');
    try {
      final categoryOneData = await getBsItemAllData(1, hisType: hisType, hospitalId: hospitalId);
      allData[1] = categoryOneData;
      GlobalErrorHandler.logDebug('中成药数据获取完成: ${categoryOneData.length} 条');
    } catch (e) {
      GlobalErrorHandler.logErrorOnly(e, StackTrace.current);
      allData[1] = [];
      GlobalErrorHandler.logDebug('中成药数据获取失败，设为空');
    }
    
    // 第二步：后台并行获取剩下的14个分类
    GlobalErrorHandler.logDebug('开始后台并行获取剩余14个分类...');
    final futures = <Future<void>>[];
    
    for (int categoryId = 2; categoryId <= 15; categoryId++) {
      futures.add(
        getBsItemAllData(categoryId, hisType: hisType, hospitalId: hospitalId)
            .then((data) {
          allData[categoryId] = data;
        }).catchError((e) {
          GlobalErrorHandler.logErrorOnly(e, StackTrace.current);
          allData[categoryId] = [];
        }),
      );
    }
    
    // 等待剩余14个分类全部完成
    await Future.wait(futures);
    
    GlobalErrorHandler.logDebug('所有项目分类数据获取完成');
    return allData;
  } catch (e, stack) {
    GlobalErrorHandler.logErrorOnly(e, stack);
    throw Exception('获取所有项目分类数据失败: $e');
  }
}
