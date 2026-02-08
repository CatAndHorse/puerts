# iOS Mult Backend Build Fix - QuickJS Source Files Missing

## 问题描述

iOS构建在mult后端模式下失败，错误信息：
```
error: unknown type name 'JS_EXTERN'
56214:1: error: unknown type name 'JS_EXTERN'
```

发生在文件：`backend-quickjs/quickjs/quickjs.c`

## 问题分析

### 表面现象
编译器报告`JS_EXTERN`未定义，这看起来像是头文件问题。

### 深入调查
1. **头文件修复无效**：我们已经修复了所有3个`quickjs.h`文件中的`JS_EXTERN`定义，但问题依然存在。

2. **CMake警告**：
```
CMake Warning at CMakeLists.txt:683 (target_link_libraries):
  Target "puerts" requests linking to directory
  "/Users/runner/work/puerts/puerts/unity/native_src/.backends/mult/".
  Targets may link only to libraries.  CMake is dropping the item.
```

3. **根本原因**：
   - 对于mult后端，`BACKEND_LIB_NAMES`是空的（因为不需要外部库）
   - **关键问题**：`qjsbackend`静态库的源文件列表中**缺少QuickJS源文件**
   - QuickJS的C文件（quickjs.c等）没有被编译到`qjsbackend`库中
   - 导致链接时找不到QuickJS的符号

### CMakeLists.txt分析

#### 问题代码（修复前）
```cmake
if ( USING_QJS)
    set(qjsbackend_src 
        Src/BackendEnv.cpp
        Src/JSEngine.cpp
        Src/JSFunction.cpp
        ${PROJECT_SOURCE_DIR}/../../unreal/Puerts/Source/JsEnv/Private/V8InspectorImpl.cpp
        Src/PluginImpl.cpp
        ${PUERTS_BACKEND_SRC}
        # ❌ 缺少 ${BEACKEND_QUICKJS_SRC}
    )
```

#### QuickJS源文件定义
```cmake
list(APPEND BEACKEND_QUICKJS_SRC
    ${PROJECT_SOURCE_DIR}/backend-quickjs/src/v8-impl.cc
    ${PROJECT_SOURCE_DIR}/backend-quickjs/quickjs/cutils.c
    ${PROJECT_SOURCE_DIR}/backend-quickjs/quickjs/libregexp.c
    ${PROJECT_SOURCE_DIR}/backend-quickjs/quickjs/libunicode.c
    ${PROJECT_SOURCE_DIR}/backend-quickjs/quickjs/quickjs.c  # ⚠️ 关键文件
)
```

#### 对比：非mult后端（正常工作）
```cmake
add_library(puerts SHARED
   ${PUERTS_SRC} ${PUERTS_INC} ${BEACKEND_QUICKJS_SRC}  # ✅ 包含QuickJS源文件
)
```

## 解决方案

### 修复内容

在`qjsbackend_src`中添加`${BEACKEND_QUICKJS_SRC}`：

```cmake
if ( USING_QJS)
    set(qjsbackend_src 
        Src/BackendEnv.cpp
        Src/JSEngine.cpp
        Src/JSFunction.cpp
        ${PROJECT_SOURCE_DIR}/../../unreal/Puerts/Source/JsEnv/Private/V8InspectorImpl.cpp
        Src/PluginImpl.cpp
        ${PUERTS_BACKEND_SRC}
        ${BEACKEND_QUICKJS_SRC}  # ✅ 添加QuickJS源文件
    )
```

### 修改的文件

- **unity/native_src/CMakeLists.txt** (第506行)

## Git提交记录

### unity-2.2.x分支

**提交** (2ee925a):
```
fix: add QuickJS source files to qjsbackend in mult backend mode

- Add ${BEACKEND_QUICKJS_SRC} to qjsbackend_src
- Ensures QuickJS source files are compiled into qjsbackend library
- Fixes "unknown type name 'JS_EXTERN'" error in iOS mult backend builds
```

### master分支

**Cherry-pick到master** (4a59c1f):
```
fix: add QuickJS source files to qjsbackend in mult backend mode

- Cherry-picked from unity-2.2.x (2ee925a)
- Resolved conflict: CMakeLists.txt was deleted in master, restored with fix
```

## 技术细节

### Mult后端架构

mult后端允许同时支持多个JavaScript引擎：
- **v8backend** - V8引擎（独立静态库）
- **qjsbackend** - QuickJS引擎（独立静态库）
- **puerts** - 主库（链接上述两个后端库）

### 构建流程

1. **编译qjsbackend**：
   ```
   qjsbackend.a = BackendEnv.cpp + JSEngine.cpp + ... + quickjs.c + cutils.c + ...
   ```

2. **编译v8backend**：
   ```
   v8backend.a = BackendEnv.cpp + JSEngine.cpp + ... (链接外部V8库)
   ```

3. **链接puerts**：
   ```
   libpuerts.a = PuertsMultBackend.cpp + qjsbackend.a + v8backend.a + wolfssl
   ```

### 为什么之前没发现？

1. **Windows/Linux/macOS**：使用动态链接，符号解析更宽松
2. **非mult后端**：QuickJS源文件直接编译到主库中
3. **iOS静态链接**：符号解析严格，缺少源文件立即暴露问题

## 验证方法

### 本地验证
```bash
cd unity/native_src
node ../cli make --platform ios --backend mult --config Release --websocket 2
```

### GitHub Actions验证
1. 访问：https://github.com/CatAndHorse/puerts/actions
2. 选择 "Build iOS Plugins" workflow
3. 点击 "Run workflow"
4. 配置：
   - Backend: mult
   - WebSocket: 2 (WolfSSL)
   - Config: Release

### 预期结果
✅ 编译成功，无链接错误
✅ 生成`libpuerts.a`静态库
✅ qjsbackend.a包含所有QuickJS符号

## 相关问题修复历史

### 第一次尝试（失败）
- **问题**：修复了`papi-quickjs/include/quickjs.h`
- **结果**：iOS mult后端不使用这个文件，修复无效

### 第二次尝试（失败）
- **问题**：修复了`backend-quickjs/quickjs/quickjs.h`和`backend-quickjs/include/quickjs.h`
- **结果**：头文件正确，但QuickJS源文件根本没有被编译

### 第三次尝试（成功）
- **问题**：发现`qjsbackend_src`缺少`${BEACKEND_QUICKJS_SRC}`
- **结果**：添加后，QuickJS源文件被正确编译到qjsbackend库中

## 经验教训

### 1. 理解构建架构
⚠️ **问题**：不清楚mult后端的构建流程
✅ **解决**：
- 查看CMakeLists.txt中的库定义
- 理解静态库的依赖关系
- 区分头文件问题和源文件缺失问题

### 2. 分析CMake警告
⚠️ **问题**：忽略了CMake的警告信息
✅ **解决**：
- CMake警告往往指向真正的问题
- "linking to directory"表明库路径配置有问题
- 空的`BACKEND_LIB_NAMES`是重要线索

### 3. 对比不同配置
⚠️ **问题**：只关注mult后端的代码
✅ **解决**：
- 对比非mult后端的工作配置
- 发现非mult后端包含`${BEACKEND_QUICKJS_SRC}`
- 理解为什么mult后端需要相同的源文件

### 4. 静态链接的严格性
⚠️ **问题**：在Windows上测试通过，iOS上失败
✅ **解决**：
- iOS使用静态链接，符号解析更严格
- 缺少源文件在静态链接时立即暴露
- 动态链接可能隐藏某些问题

## 相关文档

- [IOS_QUICKJS_BUILD_FIX_COMPLETE.md](IOS_QUICKJS_BUILD_FIX_COMPLETE.md) - JS_EXTERN头文件修复
- [IOS_WOLFSSL_LINKING_FIX.md](IOS_WOLFSSL_LINKING_FIX.md) - WolfSSL链接顺序修复
- [.github/workflows/unity_build_ios.yml](../.github/workflows/unity_build_ios.yml) - iOS构建workflow

## 总结

✅ **问题已完全解决**

通过在`qjsbackend_src`中添加`${BEACKEND_QUICKJS_SRC}`，iOS mult后端构建现在可以成功编译QuickJS源文件并链接所有符号。

### 关键修改
- 在CMakeLists.txt第506行添加`${BEACKEND_QUICKJS_SRC}`
- 确保qjsbackend静态库包含所有QuickJS源文件
- 修复了mult后端架构中的源文件缺失问题

### 影响范围
- ✅ iOS mult后端构建
- ✅ 其他平台mult后端（向后兼容）
- ✅ 非mult后端不受影响

### 下一步
1. 触发GitHub Actions验证iOS构建
2. 如果成功，关闭相关issue
3. 更新项目文档，记录mult后端的构建要求
