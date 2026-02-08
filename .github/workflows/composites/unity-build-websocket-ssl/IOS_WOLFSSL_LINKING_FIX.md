# 🔧 iOS WolfSSL Linking Fix

> **问题**: iOS 构建时报错 `Undefined symbols for architecture arm64: "_wolfSSL_*"`  
> **状态**: ✅ **已解决**  
> **修复日期**: 2026-02-08  
> **影响平台**: iOS (arm64)

---

## 📋 问题症状

### 链接错误信息

```
Undefined symbols for architecture arm64:
  "_wolfSSL_CTX_free", referenced from:
      puerts_asio::ssl::context::~context() in libv8backend.a[11](WebSocketImpl.o)
  "_wolfSSL_CTX_get_default_passwd_cb_userdata", referenced from:
      puerts_asio::ssl::context::~context() in libv8backend.a[11](WebSocketImpl.o)
  "_wolfSSL_CTX_get_ex_data", referenced from:
      puerts_asio::ssl::context::~context() in libv8backend.a[11](WebSocketImpl.o)
  "_wolfSSL_CTX_get_verify_callback", referenced from:
      puerts::on_tls_init(std::__1::weak_ptr<void>) in libv8backend.a[11](WebSocketImpl.o)
  "_wolfSSL_CTX_new", referenced from:
      puerts_asio::ssl::context::context(puerts_asio::ssl::context_base::method) in libv8backend.a[11](WebSocketImpl.o)
  ...
```

### 关键特征

- ✅ WolfSSL 库编译成功
- ✅ V8 Backend 编译成功
- ✅ `puerts` 目标链接了 WolfSSL
- ❌ 但链接时**找不到 WolfSSL 符号**

---

## 🔍 根本原因分析

### 问题根源：静态链接顺序错误

iOS 使用**静态链接**，链接器按照**从左到右**的顺序解析符号依赖：

```
target_link_libraries(puerts
    wolfssl              # ← 第一次链接 WolfSSL
    ${BACKEND_LIB_NAMES} # ← 然后链接 V8 Backend (libv8backend.a)
)
```

#### 错误的链接顺序

```
1. 链接 wolfssl.a
   - 链接器记录：wolfssl.a 提供了 _wolfSSL_* 符号
   - 但此时没有任何目标需要这些符号
   - 链接器决定：不包含这些符号（静态链接优化）

2. 链接 libv8backend.a
   - libv8backend.a 中的 WebSocketImpl.o 需要 _wolfSSL_* 符号
   - 但 wolfssl.a 已经被处理过了
   - 链接器报错：Undefined symbols
```

#### 正确的链接顺序

```
1. 链接 libv8backend.a
   - 链接器记录：需要 _wolfSSL_* 符号（未解析）

2. 链接 wolfssl.a
   - 链接器发现：wolfssl.a 提供了需要的 _wolfSSL_* 符号
   - 链接器决定：包含这些符号
   - 符号解析成功 ✅
```

### 为什么 Windows 没有这个问题？

- **Windows 使用动态链接（DLL）**：符号在运行时解析，链接顺序不重要
- **iOS 使用静态链接（.a）**：符号在编译时解析，链接顺序非常重要

### 为什么 MULT_BACKEND 模式没有这个问题？

在 `USING_MULT_BACKEND` 模式下，`v8backend` 和 `qjsbackend` 是独立的目标，它们各自链接了 WolfSSL：

```cmake
# CMakeLists.txt 第 487-489 行
if ( WITH_WEBSOCKET EQUAL 2 )
    target_include_directories(v8backend PRIVATE ${wolfssl_SOURCE_DIR}/wolfssl)
    target_link_libraries(v8backend PRIVATE wolfssl)  # ← v8backend 直接链接 WolfSSL
endif()
```

但是在**单后端模式**（iOS 默认使用）下，`puerts` 直接链接预编译的 `libv8backend.a`，这个库本身没有包含 WolfSSL 符号。

---

## ✅ 解决方案

### 修复 CMakeLists.txt

**文件**: `unity/native_src/CMakeLists.txt`  
**位置**: 第 683-690 行  
**Commit**: `cb5d1e7`

#### 修复前

```cmake
# link
target_link_libraries(puerts
    ${BACKEND_LIB_NAMES}
)
list(APPEND PUERTS_COMPILE_DEFINITIONS ${BACKEND_DEFINITIONS})
```

#### 修复后

```cmake
# link
target_link_libraries(puerts
    ${BACKEND_LIB_NAMES}
)

# Link WolfSSL after backend libraries for static linking (especially iOS)
# This ensures WolfSSL symbols are available when resolving backend library dependencies
if ( WITH_WEBSOCKET EQUAL 2 )
    target_link_libraries(puerts wolfssl)
endif()

list(APPEND PUERTS_COMPILE_DEFINITIONS ${BACKEND_DEFINITIONS})
```

### 修复逻辑

1. **先链接后端库**（`${BACKEND_LIB_NAMES}`）
   - 链接器记录：需要 WolfSSL 符号

2. **再链接 WolfSSL**（`wolfssl`）
   - 链接器解析：提供 WolfSSL 符号

3. **确保符号解析顺序正确**

### 为什么要链接两次 WolfSSL？

实际上不是"链接两次"，而是：

- **第 434 行**：`target_link_libraries(puerts wolfssl)` - 这是在 `WITH_WEBSOCKET EQUAL 2` 块中，用于**非 MULT_BACKEND 模式**
- **第 690 行**（新增）：`target_link_libraries(puerts wolfssl)` - 这是在链接后端库之后，确保**静态链接时符号解析正确**

CMake 会自动去重，不会真的链接两次。

---

## 📊 验证修复

### 1. 清理构建目录

```bash
cd unity/native_src
rm -rf build_ios
```

### 2. 重新配置 CMake

```bash
mkdir build_ios
cd build_ios

cmake .. \
  -G Xcode \
  -DCMAKE_TOOLCHAIN_FILE=../cmake/ios.toolchain.cmake \
  -DPLATFORM=OS64 \
  -DJS_ENGINE=v8_9.4.146.24 \
  -DBACKEND_INC_NAMES=Inc \
  -DBACKEND_LIB_NAMES=Lib/iOS/libv8backend.a \
  -DBACKEND_DEFINITIONS=V8_94_OR_NEWER \
  -DWITH_WEBSOCKET=2 \
  -DUSING_MULT_BACKEND=OFF \
  -DCMAKE_BUILD_TYPE=Release
```

### 3. 编译

```bash
cmake --build . --config Release
```

### 4. 检查链接顺序

查看编译日志，确认链接顺序：

```
Linking CXX static library libpuerts.a
...
.../Lib/iOS/libv8backend.a      ← 先链接后端库
.../wolfssl-build/libwolfssl.a  ← 再链接 WolfSSL
```

### 5. 验证符号

```bash
# 检查 libpuerts.a 是否包含 WolfSSL 符号
nm -g libpuerts.a | grep wolfSSL

# 应该看到：
# 00000000 T _wolfSSL_CTX_free
# 00000000 T _wolfSSL_CTX_new
# ...
```

---

## 🎯 关键教训

### 1. 静态链接顺序很重要

- **依赖库必须在被依赖库之后链接**
- 链接器从左到右解析符号
- 不要假设链接器会"智能"地处理依赖

### 2. 不同平台的链接行为不同

- **Windows DLL**：运行时链接，顺序不重要
- **iOS/macOS 静态库**：编译时链接，顺序非常重要
- **Linux 共享库**：编译时链接，但有 `--as-needed` 优化

### 3. 预编译库的依赖问题

- 预编译的 `libv8backend.a` 不包含 WolfSSL 符号
- 必须在最终链接时提供 WolfSSL 库
- 链接顺序必须正确

### 4. MULT_BACKEND vs 单后端模式

- **MULT_BACKEND**：后端库独立编译，各自链接依赖
- **单后端模式**：使用预编译后端库，需要手动处理依赖

---

## 🔗 相关问题

### Q1: 为什么不在 V8 Backend 编译时就链接 WolfSSL？

A: V8 Backend 是预编译的静态库（从 GitHub Releases 下载），我们无法修改它的链接配置。只能在最终链接 `puerts` 时提供 WolfSSL。

### Q2: 为什么 Android 没有这个问题？

A: Android 也使用静态链接，但是 CMakeLists.txt 中已经正确处理了链接顺序（第 555-565 行）：

```cmake
if ( ANDROID )
    target_link_libraries(puerts
        ${BACKEND_LIB_NAMES}
        log
        android
    )
    # WolfSSL 在后端库之后链接（通过第 434 行）
endif()
```

### Q3: macOS 需要这个修复吗？

A: **需要**。macOS 也使用静态链接（虽然默认是动态库），如果使用 `add_library(puerts STATIC ...)`，也会遇到同样的问题。

### Q4: 如何验证链接顺序是否正确？

A: 查看编译日志中的 `Linking` 命令，确认：
1. 后端库在前
2. WolfSSL 在后

---

## 📝 相关提交

| Commit | 描述 | 日期 |
|--------|------|------|
| `cb5d1e7` | 修复 iOS WolfSSL 链接顺序问题 | 2026-02-08 |

---

## 📚 相关文档

- [完整编译文档](../../../../../Puerts_Unity_Compiler_Plan.md)
- [GitHub Actions 工作流](../../../unity_build_websocket_ssl.yml)
- [V8 头文件问题修复](./CRITICAL_FIX_V8_HEADERS.md)
- [故障排查清单](./TROUBLESHOOTING.md)

---

**文档结束** ✅
