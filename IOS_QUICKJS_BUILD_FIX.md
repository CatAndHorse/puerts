# iOS QuickJS Build Fix & Dedicated iOS Action

## 问题描述

iOS构建在编译QuickJS时失败，错误信息：
```
error: unknown type name 'JS_EXTERN'
```

发生在 `quickjs.c:56214` 等多处使用 `JS_EXTERN` 宏的地方。

## 根本原因

在iOS的某些构建配置下，Xcode的Clang编译器可能不会定义 `__GNUC__` 或 `__clang__` 宏，导致 `quickjs.h` 中的条件编译逻辑无法正确定义 `JS_EXTERN` 宏：

```c
#if defined(__GNUC__) || defined(__clang__)
#define JS_EXTERN __attribute__((visibility("default")))
#else
#define JS_EXTERN /* nothing */  // iOS可能走到这里，导致JS_EXTERN未定义
#endif
```

## 解决方案

### 1. 修复 QuickJS 头文件

在 `unity/native_src/backend-quickjs/quickjs/quickjs.h` 中添加对 `__APPLE__` 的显式检查：

```c
#if defined(__GNUC__) || defined(__clang__)
#define js_force_inline       inline __attribute__((always_inline))
#define __js_printf_like(f, a)   __attribute__((format(printf, f, a)))
#define JS_EXTERN __attribute__((visibility("default")))
#elif defined(__APPLE__)
/* iOS/macOS may not define __GNUC__ or __clang__ in some build configurations */
#define js_force_inline  inline
#define __js_printf_like(a, b)
#define JS_EXTERN __attribute__((visibility("default")))
#else
#define js_force_inline  inline
#define __js_printf_like(a, b)
#define JS_EXTERN /* nothing */
#endif
```

**关键点**：
- 添加 `#elif defined(__APPLE__)` 分支
- 确保iOS/macOS平台始终定义 `JS_EXTERN` 为 `__attribute__((visibility("default")))`
- 这个宏对于导出符号到动态库是必需的

### 2. 创建专用的iOS构建Action

创建了新文件 `.github/workflows/unity_build_ios.yml`，提供：

**功能特性**：
- ✅ 支持所有后端：v8_9.4.146.24, v8_9.4, v8_10.6.194, quickjs, nodejs_16, mult
- ✅ 可配置WebSocket支持级别（0-3）
- ✅ 支持Debug/Release构建
- ✅ 仅手动触发（workflow_dispatch），避免不必要的自动构建
- ✅ 自动上传构建产物
- ✅ 生成构建摘要

**使用方法**：
1. 进入GitHub仓库的Actions页面
2. 选择 "Build iOS Plugins" workflow
3. 点击 "Run workflow"
4. 选择参数：
   - Backend: 选择JavaScript引擎（默认：mult）
   - WebSocket: 选择WebSocket支持级别（默认：2 - WolfSSL）
   - Config: 选择构建类型（默认：Release）
5. 点击 "Run workflow" 开始构建

### 3. 禁用Windows构建的自动触发

修改 `.github/workflows/unity_build_websocket_ssl.yml`：
- 注释掉 `push` 触发器
- 保留 `workflow_dispatch` 手动触发
- 避免每次push都触发Windows构建

## 技术细节

### JS_EXTERN 宏的作用

`JS_EXTERN` 宏用于控制符号的可见性：
- 在动态库中，需要显式标记哪些符号应该被导出
- `__attribute__((visibility("default")))` 确保符号在库外部可见
- 这对于iOS的静态库构建尤其重要

### iOS构建的特殊性

1. **静态链接**：iOS使用静态库（.a），不是动态库（.dylib）
2. **符号可见性**：即使是静态库，也需要正确的符号可见性设置
3. **编译器宏**：Xcode的构建配置可能影响预定义宏的存在

### 链接顺序问题（已在之前修复）

iOS静态链接时，WolfSSL必须在后端库之后链接（CMakeLists.txt第690行）：
```cmake
# Link WolfSSL after backend libraries for static linking (especially iOS)
if ( WITH_WEBSOCKET EQUAL 2 )
    target_link_libraries(puerts wolfssl)
endif()
```

## 验证步骤

构建成功后，检查以下内容：

1. **编译成功**：
   ```bash
   # 应该看到 libpuerts.a 生成
   ls -lh unity/native_src/build_ios_arm64_mult/Release-iphoneos/
   ```

2. **符号导出**：
   ```bash
   # 检查导出的符号
   nm -g libpuerts.a | grep JS_GetContextOpaque1
   ```

3. **Unity集成**：
   - 将生成的 `.a` 文件复制到Unity项目
   - 在iOS设备上测试WebSocket连接

## 相关文件

- `unity/native_src/backend-quickjs/quickjs/quickjs.h` - QuickJS头文件修复
- `.github/workflows/unity_build_ios.yml` - 新的iOS专用构建workflow
- `.github/workflows/unity_build_websocket_ssl.yml` - 禁用自动触发
- `unity/native_src/CMakeLists.txt` - 链接顺序配置（第690行）

## 提交信息

```
fix: iOS QuickJS build error and add dedicated iOS build action

1. Fix JS_EXTERN undefined error in iOS builds
   - Add explicit __APPLE__ check in quickjs.h for iOS/macOS platforms
   - Ensures JS_EXTERN is properly defined even when __GNUC__/__clang__ not detected

2. Create dedicated iOS build workflow (unity_build_ios.yml)
   - Supports all backends: v8, quickjs, nodejs, mult
   - Configurable WebSocket support (0-3)
   - Manual trigger only for better control

3. Disable auto-trigger for Windows WebSocket SSL builds
   - Comment out push trigger in unity_build_websocket_ssl.yml
   - Keep manual workflow_dispatch for on-demand builds
```

Commit: `98944dc`

## 后续工作

- [ ] 在iOS设备上测试WebSocket SSL连接
- [ ] 验证所有后端（v8, quickjs, mult）都能正常工作
- [ ] 更新Unity插件文档，说明iOS构建流程
- [ ] 考虑为Android/OHOS创建类似的专用构建workflow

## 参考资料

- [QuickJS官方文档](https://bellard.org/quickjs/)
- [iOS静态库符号可见性](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/DynamicLibraries/100-Articles/DynamicLibraryDesignGuidelines.html)
- [CMake iOS构建指南](https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html#cross-compiling-for-ios)
- [之前的iOS链接顺序修复文档](IOS_WOLFSSL_LINKING_FIX.md)
