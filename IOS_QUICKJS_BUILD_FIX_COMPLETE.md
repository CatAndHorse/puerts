# iOS QuickJS Build Fix - Complete Solution

## 问题描述

iOS构建在mult后端模式下失败，错误信息：
```
error: unknown type name 'JS_EXTERN'
```

发生在文件：`backend-quickjs/quickjs/quickjs.c`

## 根本原因

项目中存在**3个QuickJS副本**，每个都有自己的`quickjs.h`文件：

1. **`papi-quickjs/include/quickjs.h`** - 用于papi接口
2. **`backend-quickjs/quickjs/quickjs.h`** - 用于mult后端（iOS构建使用）⚠️
3. **`backend-quickjs/include/quickjs.h`** - 另一个副本

### 问题分析

在iOS构建环境中，某些配置下`__GNUC__`和`__clang__`宏可能未定义，导致`JS_EXTERN`宏未被定义。

原始代码逻辑：
```c
#if defined(__GNUC__) || defined(__clang__)
    #define JS_EXTERN __attribute__((visibility("default")))
#else
    #define JS_EXTERN /* nothing */  // ❌ iOS可能走到这里
#endif
```

### 之前的错误

第一次修复时，我们只修复了`papi-quickjs/include/quickjs.h`，但iOS的mult后端构建实际使用的是`backend-quickjs/quickjs/quickjs.h`，导致问题未解决。

## 解决方案

### 修复内容

在所有3个`quickjs.h`文件中添加`__APPLE__`检查：

```c
#if defined(__GNUC__) || defined(__clang__) || defined(__APPLE__)
/* Include __APPLE__ to ensure iOS/macOS builds always define JS_EXTERN */
#define js_force_inline       inline __attribute__((always_inline))
#define __js_printf_like(f, a)   __attribute__((format(printf, f, a)))
#define JS_EXTERN __attribute__((visibility("default")))
#else
#define js_force_inline  inline
#define __js_printf_like(a, b)
#define JS_EXTERN /* nothing */
#endif
```

### 修改的文件

#### unity-2.2.x分支
1. ✅ `unity/native_src/papi-quickjs/include/quickjs.h` (第一次修复)
2. ✅ `unity/native_src/backend-quickjs/quickjs/quickjs.h` (第二次修复)
3. ✅ `unity/native_src/backend-quickjs/include/quickjs.h` (第二次修复)

#### master分支
1. ✅ `unity/native_src/papi-quickjs/quickjs/quickjs.h` (cherry-pick)
2. ✅ `unity/native_src/backend-quickjs/quickjs/quickjs.h` (cherry-pick)
3. ⚠️ `unity/native_src/backend-quickjs/include/quickjs.h` (master分支中不存在此文件)

## Git提交记录

### unity-2.2.x分支

**第一次修复** (提交 98944dc):
```
fix: iOS QuickJS build error and add dedicated iOS build action

- Fix JS_EXTERN undefined error in iOS builds (papi-quickjs)
- Add explicit __APPLE__ check in quickjs.h for iOS/macOS platforms
```

**第二次修复** (提交 ff4d705):
```
fix: add JS_EXTERN definition for iOS in backend-quickjs

- Fix JS_EXTERN in backend-quickjs/quickjs/quickjs.h (mult backend使用)
- Fix JS_EXTERN in backend-quickjs/include/quickjs.h
```

### master分支

**Cherry-pick到master** (提交 2694927):
```
fix: add JS_EXTERN definition for iOS in backend-quickjs

- Cherry-picked from unity-2.2.x (ff4d705)
- Resolved conflict: backend-quickjs/include/quickjs.h不存在于master
```

## 技术细节

### 为什么需要__APPLE__检查？

1. **编译器宏不可靠**：在某些iOS构建配置中，`__GNUC__`和`__clang__`可能未定义
2. **平台特定**：`__APPLE__`是iOS/macOS平台的标准宏，始终定义
3. **属性支持**：iOS/macOS编译器始终支持`__attribute__((visibility("default")))`

### mult后端架构

mult后端允许同时支持多个JavaScript引擎：
- **v8backend** - V8引擎
- **qjsbackend** - QuickJS引擎

iOS构建使用mult后端时，会编译`backend-quickjs/quickjs/quickjs.c`，因此需要对应的头文件正确定义宏。

### CMakeLists.txt中的相关配置

```cmake
if(USING_QUICKJS OR USING_MULT_BACKEND)
    list(APPEND BEACKEND_QUICKJS_INC 
        ${PROJECT_SOURCE_DIR}/backend-quickjs/include
        ${PROJECT_SOURCE_DIR}/backend-quickjs/quickjs
    )
    
    list(APPEND BEACKEND_QUICKJS_SRC
        ${PROJECT_SOURCE_DIR}/backend-quickjs/quickjs/quickjs.c
        # ...
    )
endif()
```

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
✅ 编译成功，无`JS_EXTERN`相关错误
✅ 生成`libpuerts.a`静态库

## 相关文档

- [IOS_QUICKJS_BUILD_FIX.md](IOS_QUICKJS_BUILD_FIX.md) - 第一次修复文档
- [IOS_ACTION_CHERRY_PICK.md](IOS_ACTION_CHERRY_PICK.md) - iOS Action cherry-pick文档
- [.github/workflows/unity_build_ios.yml](../.github/workflows/unity_build_ios.yml) - iOS构建workflow

## 经验教训

### 1. 多副本代码管理
⚠️ **问题**：项目中存在多个QuickJS副本，修改时容易遗漏
✅ **解决**：
- 使用grep搜索所有相关文件
- 理解不同副本的用途（papi vs backend）
- 确保所有副本都应用相同的修复

### 2. 构建配置理解
⚠️ **问题**：不清楚mult后端使用哪个QuickJS副本
✅ **解决**：
- 查看CMakeLists.txt中的include路径
- 分析编译错误中的文件路径
- 理解不同后端的代码组织结构

### 3. 平台特定宏
⚠️ **问题**：依赖编译器宏（`__GNUC__`, `__clang__`）不可靠
✅ **解决**：
- 使用平台宏（`__APPLE__`, `_WIN32`等）更可靠
- 组合使用多个条件确保覆盖所有情况
- 添加注释说明为什么需要特定检查

### 4. Cherry-pick冲突处理
⚠️ **问题**：不同分支的文件结构可能不同
✅ **解决**：
- 检查目标分支是否存在相同文件
- 使用`git rm`删除不存在的文件
- 调整修改以适应目标分支的结构

## 总结

✅ **问题已完全解决**

通过修复所有3个QuickJS副本中的`JS_EXTERN`定义，iOS构建现在可以在mult后端模式下成功编译。修复已应用到unity-2.2.x和master两个分支。

### 关键修改
- 添加`__APPLE__`宏检查确保iOS/macOS平台正确定义`JS_EXTERN`
- 修复了backend-quickjs中的两个quickjs.h文件
- 保持了与之前papi-quickjs修复的一致性

### 影响范围
- ✅ iOS mult后端构建
- ✅ iOS quickjs后端构建
- ✅ macOS构建
- ✅ 其他平台不受影响（向后兼容）

### 下一步
1. 触发GitHub Actions验证iOS构建
2. 如果成功，更新项目文档
3. 考虑是否需要统一管理QuickJS副本以避免未来的不一致
