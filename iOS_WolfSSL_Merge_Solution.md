# iOS WolfSSL合并方案

## 📋 背景

在iOS平台上，静态库（`.a`文件）不会自动包含其依赖库的符号。当`libpuerts.a`依赖`libwolfssl.a`时，Unity链接时会找不到WolfSSL符号，导致链接错误。

## ❌ 问题

```
Undefined symbols for architecture arm64:
  "_wolfSSL_BIO_ctrl_pending"
  "_wolfSSL_CTX_free"
  "_wolfSSL_CTX_new"
  ...
  referenced from: puerts_asio::ssl::... in libpuerts.a
```

## 🔧 解决方案演进

### 方案1：单独提供libwolfssl.a（已废弃）
- 将`libwolfssl.a`复制到Unity插件目录
- Unity链接时同时链接两个库
- **缺点**：增加库文件数量（mult: 4→3, v8: 2→3）

### 方案2：合并WolfSSL到libpuerts.a（✅ 当前方案）
- 使用CMake的`$<TARGET_OBJECTS:wolfssl>`将wolfssl的目标文件合并到libpuerts.a
- WolfSSL符号直接包含在libpuerts.a中
- **优点**：
  - ✅ 减少库文件数量（mult: 4→2, v8: 2→2）
  - ✅ 简化Unity项目配置
  - ✅ 符合iOS静态库最佳实践

## 💻 技术实现

### CMakeLists.txt修改

```cmake
if ( WITH_WEBSOCKET EQUAL 2 )
    # ... FetchContent配置 ...
    
    FetchContent_MakeAvailable(wolfssl)
    
    # For iOS: merge wolfssl object files into libpuerts.a
    if ( IOS )
        # Add wolfssl object files to puerts
        target_sources(puerts PRIVATE $<TARGET_OBJECTS:wolfssl>)
        # Include wolfssl headers
        target_include_directories(puerts PRIVATE ${wolfssl_SOURCE_DIR}/wolfssl)
    else()
        # For other platforms: link wolfssl as separate library
        target_link_libraries(puerts wolfssl)
        target_include_directories(puerts PRIVATE ${wolfssl_SOURCE_DIR}/wolfssl)
    endif()
endif()
```

### 关键技术点

1. **`$<TARGET_OBJECTS:wolfssl>`**：
   - CMake生成器表达式
   - 获取wolfssl目标的所有目标文件（.o文件）
   - 将这些目标文件添加到puerts库中

2. **iOS特殊处理**：
   - 只在iOS平台使用合并方案
   - 其他平台保持原有的链接方式
   - 不影响其他平台的构建

3. **mult backend支持**：
   - iOS mult backend模式下，backend源码已编译到libpuerts.a
   - WolfSSL也合并到libpuerts.a
   - 最终只有2个库文件：libpuerts.a + libwee8.a

## 📦 最终产出物

### mult backend模式
```
unity/Assets/core/upm/Plugins/iOS/
├── libpuerts.a         (~17.5MB) - 包含puerts + v8backend + qjsbackend + wolfssl
├── libpuerts.a.meta
├── libwee8.a           (31MB)    - V8引擎
└── libwee8.a.meta
```

### v8 backend模式
```
unity/Assets/core/upm/Plugins/iOS/
├── libpuerts.a         (~6.5MB)  - 包含puerts + wolfssl
├── libpuerts.a.meta
├── libwee8.a           (31MB)    - V8引擎
└── libwee8.a.meta
```

## ✅ 验证方法

### 1. 检查库文件数量
```bash
ls -lh unity/Assets/core/upm/Plugins/iOS/*.a
# 应该只有2个.a文件：libpuerts.a 和 libwee8.a
```

### 2. 检查WolfSSL符号
```bash
nm unity/Assets/core/upm/Plugins/iOS/libpuerts.a | grep wolfSSL
# 应该能看到wolfSSL相关的符号
```

### 3. Unity链接测试
- 在Unity项目中导入产出物
- 构建iOS项目
- 验证没有WolfSSL符号错误

### 4. 真机测试
- 在iOS设备上运行
- 测试WebSocket SSL功能

## 🎯 优势总结

| 项目 | 方案1（单独库） | 方案2（合并） |
|------|----------------|--------------|
| mult backend库数量 | 3个 | 2个 ✅ |
| v8 backend库数量 | 3个 | 2个 ✅ |
| Unity配置复杂度 | 中等 | 简单 ✅ |
| 符合iOS最佳实践 | 否 | 是 ✅ |
| 依赖传递问题 | 需要手动处理 | 自动解决 ✅ |

## 📚 参考资料

- [CMake Generator Expressions](https://cmake.org/cmake/help/latest/manual/cmake-generator-expressions.7.html)
- [CMake OBJECT Libraries](https://cmake.org/cmake/help/latest/command/add_library.html#object-libraries)
- [iOS Static Library Best Practices](https://developer.apple.com/library/archive/technotes/tn2435/_index.html)

---

**Commit**: 7139090  
**Date**: 2026-02-09  
**Author**: AI Assistant
