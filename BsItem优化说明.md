# BsItem查询性能优化方案

## 🎯 优化目标
解决 `GetListBylsRpTypeAndHospitalId` 方法查询缓慢的问题，提升系统整体性能。

## 📋 优化措施

### 1. 查询逻辑优化 (建议2)
**问题**: 原始查询可能执行全表扫描，字符串比较效率低
**解决方案**:
- 避免不必要的字符串转换
- 优化查询条件顺序
- 添加排序以提高性能
- 限制返回数量

```csharp
// 优化前
List<BsItem> lstBsItemDto = GetQList<BsItem>(x =>
(string.IsNullOrEmpty(lsRpType) || (x.LsRpType.ToString() == lsRpType)) &&
(x.HospitalId == hospitalId)).ToList();

// 优化后
IQueryable<BsItem> query = GetQList<BsItem>(x => x.HospitalId == hospitalId);
if (!string.IsNullOrEmpty(lsRpType))
{
    if (Enum.TryParse<LsRpTypeEnum>(lsRpType, out var lsRpTypeEnum))
    {
        query = query.Where(x => x.LsRpType == lsRpTypeEnum);
    }
    else if (int.TryParse(lsRpType, out var lsRpTypeInt))
    {
        query = query.Where(x => (int)x.LsRpType == lsRpTypeInt);
    }
    else
    {
        query = query.Where(x => x.LsRpType.ToString() == lsRpType);
    }
}
query = query.OrderBy(x => x.Id).Take(1000);
var lstBsItemDto = query.ToList();
```

### 2. 分页查询 (建议3)
**问题**: `ToList()` 强制加载所有数据到内存
**解决方案**:
- 实现分页查询机制
- 支持排序和过滤
- 返回分页元数据

```csharp
public ReturnValue<PagedResult<BsItem>> GetListBylsRpTypeAndHospitalIdPaged(
    string lsRpType, int hospitalId, int pageSize = 100, int pageNumber = 1)
{
    // 构建查询
    IQueryable<BsItem> query = GetQList<BsItem>(x => x.HospitalId == hospitalId);
    
    // 添加过滤条件
    if (!string.IsNullOrEmpty(lsRpType))
    {
        query = query.Where(x => x.LsRpType.ToString() == lsRpType);
    }
    
    // 获取总记录数
    int totalCount = query.Count();
    
    // 分页
    var items = query
        .Skip((pageNumber - 1) * pageSize)
        .Take(pageSize)
        .ToList();
    
    return new PagedResult<BsItem> { /* 分页结果 */ };
}
```

### 3. 数据类型优化 (建议5)
**问题**: 字符串比较效率低，`ToString()` 调用开销大
**解决方案**:
- 使用强类型比较
- 避免字符串转换
- 根据数据类型选择最优比较方式

```csharp
// 优化数据类型比较
if (!string.IsNullOrEmpty(lsRpType))
{
    // 方法1: 如果是枚举类型
    if (Enum.TryParse<LsRpTypeEnum>(lsRpType, out var lsRpTypeEnum))
    {
        query = query.Where(x => x.LsRpType == lsRpTypeEnum);
    }
    // 方法2: 如果是数字类型
    else if (int.TryParse(lsRpType, out var lsRpTypeInt))
    {
        query = query.Where(x => (int)x.LsRpType == lsRpTypeInt);
    }
    // 方法3: 如果是字符串类型
    else
    {
        query = query.Where(x => x.LsRpType.ToString() == lsRpType);
    }
}
```

## 🗄️ 数据库优化

### 索引优化
执行 `DatabaseIndexes.sql` 中的脚本：

```sql
-- 复合索引
CREATE NONCLUSTERED INDEX IX_BsItem_HospitalId_LsRpType 
ON BsItem (HospitalId, LsRpType)
INCLUDE (Id, Name, Code, Price, Unit, Spec, Manufacturer);

-- 单列索引
CREATE NONCLUSTERED INDEX IX_BsItem_HospitalId 
ON BsItem (HospitalId)
INCLUDE (Id, Name, Code, LsRpType, Price, Unit, Spec, Manufacturer);
```

### 统计信息更新
```sql
UPDATE STATISTICS BsItem WITH FULLSCAN;
```

## 📊 性能监控

### 添加性能日志
```csharp
var stopwatch = Stopwatch.StartNew();
// 执行查询
stopwatch.Stop();
_logger.LogInformation($"BsItem查询耗时: {stopwatch.ElapsedMilliseconds}ms, 返回记录数: {result?.Count ?? 0}");
```

### 性能测试
使用 `PerformanceTest.cs` 进行性能测试：

```csharp
var performanceTest = serviceProvider.GetService<BsItemPerformanceTest>();
await performanceTest.RunPerformanceTest();
await performanceTest.RunDataTypeOptimizationTest();
await performanceTest.RunStressTest(20, 50);
```

## 🚀 部署步骤

### 1. 代码更新
- 替换原有的 `GetListBylsRpTypeAndHospitalId` 方法
- 添加新的分页和数据类型优化方法
- 更新依赖注入配置

### 2. 数据库优化
- 执行索引创建脚本
- 更新统计信息
- 监控索引使用情况

### 3. 配置更新
```csharp
// Startup.cs
services.AddScoped<BsItemService>();
services.AddScoped<BsItemPerformanceTest>();
```

### 4. 性能测试
- 运行性能测试脚本
- 对比优化前后性能
- 监控内存使用情况

## 📈 预期性能提升

| 场景 | 优化前 | 优化后 | 提升幅度 |
|------|--------|--------|----------|
| 查询逻辑优化 | 2000ms | 1200ms | 40% |
| 分页查询 | 2000ms | 500ms | 75% |
| 数据类型优化 | 2000ms | 1000ms | 50% |
| 内存使用 | 100MB | 50MB | 50% |

## 🔧 使用示例

### 基本查询（查询逻辑优化）
```csharp
var result = bsItemService.GetListBylsRpTypeAndHospitalId("1", 1165);
```

### 分页查询
```csharp
var pagedResult = bsItemService.GetListBylsRpTypeAndHospitalIdPaged("1", 1165, 50, 1);
```

### 数据类型优化查询
```csharp
var optimizedResult = bsItemService.GetListBylsRpTypeAndHospitalIdOptimized("1", 1165);
```

### 获取优化建议
```csharp
bsItemService.SuggestDataTypeOptimization();
```

## 📊 数据类型优化详解

### 优化策略
1. **枚举类型**: 使用 `Enum.TryParse` 进行类型转换
2. **数字类型**: 使用 `int.TryParse` 避免字符串比较
3. **字符串类型**: 根据长度选择最优比较方式
4. **避免转换**: 减少 `ToString()` 调用

### 性能对比
```csharp
// 原始方法 - 总是字符串比较
x.LsRpType.ToString() == lsRpType

// 优化方法 - 根据数据类型选择
if (Enum.TryParse<LsRpTypeEnum>(lsRpType, out var lsRpTypeEnum))
{
    x.LsRpType == lsRpTypeEnum  // 枚举比较，最快
}
else if (int.TryParse(lsRpType, out var lsRpTypeInt))
{
    (int)x.LsRpType == lsRpTypeInt  // 数字比较，较快
}
else
{
    x.LsRpType.ToString() == lsRpType  // 字符串比较，最慢
}
```

## ⚠️ 注意事项

1. **数据类型确认**: 确保LsRpType的实际数据类型与优化策略匹配
2. **索引维护**: 定期更新统计信息，重建碎片化索引
3. **性能监控**: 持续监控查询性能，及时发现问题
4. **测试验证**: 在生产环境部署前进行充分测试

## 📞 技术支持

如有问题，请检查：
1. 数据库索引是否正确创建
2. LsRpType的数据类型是否与优化策略匹配
3. 性能日志是否正常输出
4. 内存使用是否合理