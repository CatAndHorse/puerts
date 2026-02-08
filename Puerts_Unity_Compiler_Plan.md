# Puerts Unity 插件编译计划文档

> 目标：编译支持 wss:// (WebSocket Secure) 的 Puerts.dll 独立版本

---

## 一、需求说明

### 1.1 核心需求
- ✅ 支持普通 WebSocket 连接 (`ws://`)
- ✅ 支持 TLS/SSL 加密 WebSocket 连接 (`wss://`)
- ✅ 生成独立的 `puerts.dll` 文件（不依赖其他 Puerts 组件）
- ✅ 使用 V8 引擎作为 JavaScript 引擎

### 1.2 编译环境
- **操作系统**: Windows x64
- **编译器**: Visual Studio 2017 (MSVC 19.16.27051.0)
- **CMake 版本**: 3.15+
- **目标平台**: Windows x64 (Win64)

---

## 二、技术方案对比

| 方案 | WITH_WEBSOCKET | SSL库实现 | 优点 | 缺点 | 推荐度 |
|------|----------------|----------|------|------|--------|
| **方案 A** | `=1` | 无 | 最简单，无额外依赖 | ❌ **不支持 wss://** | ❌ 不满足需求 |
| **方案 B** | `=2` | WolfSSL | 自动下载编译，配置简单 | 编译时间稍长 | ⭐⭐⭐⭐⭐ **强烈推荐** |
| **方案 C** | `=3` | OpenSSL (源码) | 使用官方 OpenSSL | 需要安装 NASM/Perl，配置复杂 | ⭐⭐⭐ |
| **方案 D** | `=2` | WolfSSL (预编译) | 快速 | 需要手动准备库 | ⭐⭐⭐ |

---

## 三、推荐方案：使用 WolfSSL 自动编译

### 3.1 方案优势
- ✅ CMake 自动处理依赖，无需手动下载
- ✅ WolfSSL 兼容 OpenSSL API，代码无需修改
- ✅ 体积小，性能好
- ✅ 跨平台支持好
- ✅ 开源许可友好（GPLv2+ 商业可选）

### 3.2 依赖库列表

编译完成后需要部署的 DLL 文件：

```
puerts.dll                    ← 主插件（目标输出）
v8.dll                        ← V8 引擎
v8_libplatform.dll            ← V8 平台库
v8_libbase.dll                ← V8 基础库
zlib.dll                      ← 压缩库
wolfssl.dll                   ← SSL/TLS 加密库（仅方案 B/C）
```

### 3.3 编译宏定义

| 宏定义 | 值 | 说明 |
|--------|---|------|
| `JS_ENGINE` | `v8` 或 `v8_9.4.146.24` | 指定 JS 引擎 |
| `WITH_WEBSOCKET` | `2` | 启用 WebSocket + WolfSSL |
| `USING_MULT_BACKEND` | `OFF` | 单后端模式 |
| `CMAKE_BUILD_TYPE` | `Release` | 发布模式 |

---

## 四、详细编译步骤

### 4.1 准备工作

#### 1. 检查环境
```bash
# 检查 CMake 版本
cmake --version  # 需要 >= 3.15

# 检查 Visual Studio 2017 是否安装
where cl.exe
```

#### 2. 设置 Git 仓库
```bash
cd F:/puerts/unity/native_src
git checkout unity-2.2.x
git pull origin unity-2.2.x
```

### 4.2 编译命令

```bash
# 1. 进入项目目录
cd F:/puerts/unity/native_src

# 2. 创建构建目录
mkdir -p build_win_x64_v8_ws_wolfssl
cd build_win_x64_v8_ws_wolfssl

# 3. 配置 CMake (使用 VS2017 生成器)
cmake .. \
  -G "Visual Studio 15 2017 Win64" \
  -DJS_ENGINE=v8 \
  -DWITH_WEBSOCKET=2 \
  -DUSING_MULT_BACKEND=OFF

# 4. 编译
cmake --build . --config Release -- -m
```

### 4.3 预期输出

```
-- Auto-detected V8 backend: v8_9.4.146.24
-- Configuring done
-- Generating done
-- Build files have been written to: F:/puerts/unity/native_src/build_win_x64_v8_ws_wolfssl

[编译过程...]

 wolfssl.vcxproj -> F:\puerts\unity\native_src\build_win_x64_v8_ws_wolfssl\_deps\wolfssl-build\Release\wolfssl.lib
 puerts.vcxproj -> F:\puerts\unity\native_src\build_win_x64_v8_ws_wolfssl\Release\puerts.dll
```

### 4.4 输出文件位置

编译完成后，所有需要的 DLL 文件位于：

```
F:\puerts\unity\native_src\build_win_x64_v8_ws_wolfssl\Release\
├── puerts.dll               ← 主插件
├── v8.dll
├── v8_libplatform.dll
├── v8_libbase.dll
├── zlib.dll
└── wolfssl.dll              ← SSL 支持
```

---

## 五、常见问题排查

### 5.1 编译时找不到 V8 头文件

**错误信息**:
```
fatal error C1083: 无法打开包括文件: "v8.h": No such file or directory
```

**原因**: V8 后端目录未正确配置

**解决方法**:
```bash
# 检查 V8 后端是否存在
ls F:/puerts/unity/native_src/.backends/v8*

# 确保使用了自动检测或显式指定
cmake .. -G "Visual Studio 15 2017 Win64" -DJS_ENGINE=v8_9.4.146.24
```

### 5.2 WolfSSL 下载失败

**错误信息**:
```
Failed to download wolfssl repository
```

**解决方法**:
```bash
# 设置 Git 代理（如需）
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# 或手动下载后放到指定目录
# F:/puerts/unity/native_src/build_win_x64_v8_ws_wolfssl/_deps/wolfssl-src/
```

### 5.3 链接错误：无法解析的外部符号

**错误信息**:
```
error LNK2019: 无法解析的外部符号 "public: class v8::Local..."
```

**原因**: V8 库未正确链接

**解决方法**:
```bash
# 清理后重新配置
rm -rf *
cmake .. -G "Visual Studio 15 2017 Win64" -DJS_ENGINE=v8 -DWITH_WEBSOCKET=2 -DUSING_MULT_BACKEND=OFF
cmake --build . --config Release -- -m
```

### 5.4 WolfSSL 编译警告

**警告信息**:
```
warning C4100: 未引用的形参
warning C4701: 使用了未初始化的局部变量
```

**说明**: WolfSSL 的静态分析警告，可以忽略，不影响功能

---

## 六、验证方法

### 6.1 文件完整性检查

```bash
cd F:\puerts\unity\native_src\build_win_x64_v8_ws_wolfssl\Release

# 检查所有必需文件
dir *.dll

# 应该看到：
# puerts.dll
# v8.dll
# v8_libplatform.dll
# v8_libbase.dll
# zlib.dll
# wolfssl.dll
```

### 6.2 功能测试代码

在 Unity 中创建测试脚本：

```csharp
using UnityEngine;
using Puerts;

public class WebSocketTest : MonoBehaviour
{
    void Start()
    {
        // 创建 JavaScript 环境
        var jsEnv = new JsEnv(new DefaultLoader());
        
        // 测试代码
        jsEnv.ExecuteModule("test.js");
    }
    
    void Update()
    {
        // 更新 JS 环境（处理异步回调）
    }
    
    void OnDestroy()
    {
        // 清理
        jsEnv.Dispose();
    }
}
```

JavaScript 测试代码 (`test.js`):

```javascript
const WebSocket = require('ws');

// 测试普通 ws:// 连接
const ws1 = new WebSocket('ws://echo.websocket.org');
ws1.on('open', () => console.log('ws:// connected!'));
ws1.on('message', (data) => console.log('received:', data));

// 测试 wss:// 连接（需要 SSL 支持）
const wss1 = new WebSocket('wss://echo.websocket.org');
wss1.on('open', () => console.log('wss:// connected!'));
wss1.on('message', (data) => console.log('secure received:', data));
```

---

## 七、部署到 Unity

### 7.1 文件放置结构

```
Assets/
└── Plugins/
    └── x86_64/
        ├── puerts.dll           ← 主插件
        ├── v8.dll
        ├── v8_libplatform.dll
        ├── v8_libbase.dll
        ├── zlib.dll
        └── wolfssl.dll          ← SSL 支持
```

### 7.2 Unity 设置

1. 打开 Unity 编辑器
2. 选择 `Assets > Plugins` 文件夹
3. 选中所有 DLL 文件
4. 在 Inspector 中确保：
   - **Platform Settings > Any Platform** 勾选
   - **Platform Settings > Windows > CPU** 设置为 `x86_64`

---

## 八、附录

### 8.1 CMake 配置说明

| 参数 | 可选值 | 默认值 | 说明 |
|------|--------|--------|------|
| `JS_ENGINE` | `v8`, `quickjs`, `mult` | `v8` | JavaScript 引擎 |
| `WITH_WEBSOCKET` | `0`, `1`, `2`, `3` | `0` | WebSocket 支持 |
| `USING_MULT_BACKEND` | `ON`, `OFF` | `OFF` | 多后端模式 |
| `WITH_SYMBOLS` | `ON`, `OFF` | `OFF` | 生成调试符号 |

### 8.2 相关文档链接

- [Puerts 官方仓库](https://github.com/Tencent/puerts)
- [WebSocket++ 文档](https://github.com/zaphoyd/websocketpp)
- [WolfSSL 文档](https://www.wolfssl.com/documentation/manuals/wolfssl/)
- [CMake 官方文档](https://cmake.org/documentation/)

### 8.3 版本信息

- **Puerts 版本**: unity-2.2.x
- **V8 版本**: 9.4.146.24
- **WolfSSL 版本**: 5.7.2-stable
- **文档日期**: 2026-02-07

---

## 九、FAQ

### Q: 为什么不使用已安装的 OpenSSL？
A: 当前 CMakeLists.txt 中 OpenSSL 方案（`WITH_WEBSOCKET=3`）需要从源码编译，配置较为复杂，需要额外安装 NASM 和 Perl。WolfSSL 方案更简单且功能相当。

### Q: 可以使用预编译的 WolfSSL 吗？
A: 可以，但需要修改 CMakeLists.txt，手动指定 `wolfssl_SOURCE_DIR` 和链接库。目前自动编译方式更简单。

### Q: 编译后的 puerts.dll 大小是多少？
A: 预计约 3-5 MB（未压缩），Release 模式下体积会更小。

### Q: 支持 iOS 和 Android 吗？
A: 支持，需要使用相应的编译器和工具链，本文档仅针对 Windows 平台。

---

## 十、自动化构建系统 🆕

### 10.1 GitHub Actions 自动编译

**不想手动编译？** 我们提供了完整的 GitHub Actions 自动化构建系统！

👉 **[查看自动化构建文档](.github/workflows/composites/unity-build-websocket-ssl/INDEX.md)**

#### 主要优势

- ✅ **一键触发**：无需配置本地环境
- ✅ **多平台支持**：Windows、Linux、macOS 同时编译
- ✅ **自动验证**：自动检查配置和输出
- ✅ **产物管理**：自动打包和上传
- ✅ **详细文档**：完整的使用指南和故障排查

#### 快速开始

1. 访问 GitHub 仓库的 **Actions** 标签页
2. 选择 **"Build Puerts Unity Plugin with WebSocket SSL Support"**
3. 点击 **"Run workflow"**
4. 选择配置参数（推荐使用默认值）
5. 等待编译完成（约 10-15 分钟）
6. 下载构建产物

#### 相关文档

- 📖 [文档导航](.github/workflows/composites/unity-build-websocket-ssl/INDEX.md)
- 🚀 [5分钟快速启动](.github/workflows/composites/unity-build-websocket-ssl/QUICKSTART.md)
- 📘 [完整使用文档](.github/workflows/composites/unity-build-websocket-ssl/README.md)
- 🔍 [故障排查清单](.github/workflows/composites/unity-build-websocket-ssl/TROUBLESHOOTING.md)
- � [关键修复：V8 头文件找不到问题](.github/workflows/composites/unity-build-websocket-ssl/CRITICAL_FIX_V8_HEADERS.md) ⭐ **重要**
- �📊 [项目总结](.github/workflows/composites/unity-build-websocket-ssl/PROJECT_SUMMARY.md)

#### 推荐使用场景

- ✅ 不想配置本地编译环境
- ✅ 需要编译多个平台
- ✅ 需要可重复的构建过程
- ✅ 团队协作开发

#### 常见问题

**Q1: GitHub Actions 编译失败，提示找不到 v8.h 头文件？**

A: 这是因为 V8 后端没有被正确下载。确保工作流中包含以下步骤：

```yaml
- name: Download V8 Backend
  run: |
    cd unity
    node cli/cmd.mjs backend download v8_9.4.146.24
```

该步骤会自动从 GitHub Releases 下载并解压 V8 后端到 `unity/native_src/.backends/` 目录。

**Q2: GitHub Actions 提示 \"error: unknown command 'download'\"？**

A: 这是命令格式错误。正确的命令格式是：

```bash
# ❌ 错误
node cli/cmd.mjs download v8_9.4.146.24

# ✅ 正确
node cli/cmd.mjs backend download v8_9.4.146.24
```

注意需要在 `download` 前面加上 `backend` 子命令。

**Q2.1: GitHub Actions 提示 \"invalid puerts native_src directory\"？**

A: 这是因为脚本需要在 `native_src` 目录下运行（它会检查 `CMakeLists.txt` 是否存在）。正确的命令应该是：

```yaml
# ❌ 错误 - 在 unity 目录下运行
- name: Download V8 Backend
  run: |
    cd unity
    node cli/cmd.mjs backend download v8_9.4.146.24

# ✅ 正确 - 在 native_src 目录下运行
- name: Download V8 Backend
  run: |
    cd unity/native_src
    node ../cli/cmd.mjs backend download v8_9.4.146.24
```

**原因**：`backend.mjs` 脚本会检查当前目录是否包含 `CMakeLists.txt`，如果不存在则抛出错误。

**Q2.2: GitHub Actions 编译时找不到 v8.h 头文件？**

A: 这通常是因为 V8 Backend 下载步骤失败或未正确执行。解决方法：

1. **检查下载步骤日志**：确认是否有 "✅ v8.h header file found" 输出
2. **验证 .backends 目录**：确保 `unity/native_src/.backends/v8_9.4.146.24/Inc/v8.h` 存在
3. **检查工作流版本**：确保使用的是最新的工作流文件（不是缓存的旧版本）
4. **检查 CMakeLists.txt 中的 BACKEND_ROOT 路径**：确保路径正确

**常见路径错误**：

```cmake
# ❌ 错误 - 多余的 ../native_src/
set(BACKEND_ROOT ${PROJECT_SOURCE_DIR}/../native_src/.backends/${JS_ENGINE})

# ✅ 正确 - PROJECT_SOURCE_DIR 已经是 native_src 目录
set(BACKEND_ROOT ${PROJECT_SOURCE_DIR}/.backends/${JS_ENGINE})
```

**症状**：
- V8 Backend 下载成功（日志显示 "✅ v8.h header file found"）
- 但编译时仍然报错：`error C1083: Cannot open include file: 'libplatform/libplatform.h'`
- 这说明 CMake 在错误的路径中查找头文件

**解决方法**：修复 `unity/native_src/CMakeLists.txt` 第 52 行的路径

**详细验证步骤**：

```yaml
- name: Download V8 Backend
  shell: bash
  run: |
    cd unity/native_src
    node ../cli/cmd.mjs backend download v8_9.4.146.24
    
    # 验证下载结果
    if [ -f ".backends/v8_9.4.146.24/Inc/v8.h" ]; then
      echo "✅ V8 backend downloaded successfully"
    else
      echo "❌ ERROR: V8 backend download failed!"
      exit 1
    fi
```

**如果问题持续**：
- 清除 GitHub Actions 缓存
- 手动触发新的工作流运行
- 检查网络连接（V8 backend 从 GitHub Releases 下载）

**Q2.3: 如何验证 CMake 是否正确找到 V8 头文件？**

A: 查看 "Configure CMake" 步骤的日志，应该看到：

```
-- BACKEND_ROOT: D:/a/puerts/puerts/unity/native_src/.backends/v8_9.4.146.24
-- V8 include directory: D:/a/puerts/puerts/unity/native_src/.backends/v8_9.4.146.24/Inc
```

如果路径中包含 `/../native_src/.backends/`（多余的部分），则说明 CMakeLists.txt 需要修复。

**Q2.4: CMake 警告 "Target puerts requests linking to directory"？**

A: 这是因为 CMake 配置时缺少了 `BACKEND_INC_NAMES`、`BACKEND_LIB_NAMES` 和 `BACKEND_DEFINITIONS` 参数。

**错误症状**：
```
CMake Warning at CMakeLists.txt:675 (target_link_libraries):
  Target "puerts" requests linking to directory
  "D:/a/puerts/puerts/unity/native_src/.backends/v8_9.4.146.24".  Targets may
  link only to libraries.  CMake is dropping the item.
```

**根本原因**：
- V8 Backend 下载成功
- 但 CMake 不知道如何链接 V8 库，因为缺少必要的参数
- 导致编译时找不到 V8 头文件和库文件

**解决方法**：

在 CMake 配置命令中添加以下参数：

```bash
# Windows
cmake .. \
  -G "Visual Studio 17 2022" -A x64 \
  -DJS_ENGINE=v8_9.4.146.24 \
  -DBACKEND_INC_NAMES=/Inc \
  -DBACKEND_LIB_NAMES=/Lib/Win64/wee8.lib \
  -DBACKEND_DEFINITIONS=V8_94_OR_NEWER \
  -DWITH_WEBSOCKET=2 \
  -DUSING_MULT_BACKEND=OFF \
  -DCMAKE_BUILD_TYPE=Release

# Linux
cmake .. \
  -G "Unix Makefiles" \
  -DJS_ENGINE=v8_9.4.146.24 \
  -DBACKEND_INC_NAMES=/Inc \
  -DBACKEND_LIB_NAMES=/Lib/Linux/libwee8.a \
  -DBACKEND_DEFINITIONS=V8_94_OR_NEWER \
  -DWITH_WEBSOCKET=2 \
  -DUSING_MULT_BACKEND=OFF \
  -DCMAKE_BUILD_TYPE=Release

# macOS
cmake .. \
  -G "Unix Makefiles" \
  -DJS_ENGINE=v8_9.4.146.24 \
  -DBACKEND_INC_NAMES=/Inc \
  -DBACKEND_LIB_NAMES=/Lib/macOS/libwee8.a \
  -DBACKEND_DEFINITIONS=V8_94_OR_NEWER \
  -DWITH_WEBSOCKET=2 \
  -DUSING_MULT_BACKEND=OFF \
  -DCMAKE_BUILD_TYPE=Release
```

**验证修复**：

配置成功后，检查 `CMakeCache.txt`：

```bash
grep -E "BACKEND" CMakeCache.txt
```

应该看到：
```
BACKEND_DEFINITIONS:UNINITIALIZED=V8_94_OR_NEWER
BACKEND_INC_NAMES:UNINITIALIZED=/Inc
BACKEND_LIB_NAMES:UNINITIALIZED=/Lib/Win64/wee8.lib  # 或对应平台的路径
```

**常见错误**：

1. **重复的配置步骤**：如果工作流中有多个 "Configure CMake (WolfSSL)" 步骤，只有第一个会执行。确保第一个步骤包含所有必要的参数。

2. **条件判断冲突**：避免使用重复的条件判断，例如：
   ```yaml
   # ❌ 错误 - 这两个条件是重复的
   if: github.event.inputs.ssl_backend == 'wolfssl' || github.event.inputs.ssl_backend == ''
   if: github.event.inputs.ssl_backend != 'openssl'
   ```

3. **Git Bash 路径转换问题** ⚠️ **重要**：
   
   在 Windows 的 Git Bash 中，以 `/` 开头的路径会被自动转换为绝对路径：
   
   ```yaml
   # ❌ 错误 - Git Bash 会将 /Inc 转换为 C:/Program Files/Git/Inc
   -DBACKEND_INC_NAMES=/Inc
   -DBACKEND_LIB_NAMES=/Lib/Win64/wee8.lib
   
   # ✅ 正确 - 使用相对路径
   -DBACKEND_INC_NAMES=Inc
   -DBACKEND_LIB_NAMES=Lib/Win64/wee8.lib
   ```
   
   **症状**：CMakeCache.txt 中显示：
   ```
   BACKEND_INC_NAMES:UNINITIALIZED=C:/Program Files/Git/Inc
   BACKEND_LIB_NAMES:UNINITIALIZED=C:/Program Files/Git/Lib/Win64/wee8.lib
   ```
   
   **解决方法**：使用相对路径（不以 `/` 开头）

4. **CMakeLists.txt 路径拼接问题** ⚠️ **已修复**：
   
   **问题**：CMakeLists.txt 在拼接 `BACKEND_ROOT` 和 `BACKEND_INC_NAMES` 时，如果参数不以 `/` 开头，会导致路径错误：
   
   ```cmake
   # 错误的拼接结果
   BACKEND_ROOT = .../v8_9.4.146.24
   BACKEND_INC_NAMES = Inc
   结果 = .../v8_9.4.146.24Inc  ❌ 缺少 /
   ```
   
   **症状**：编译时报错 `error C1083: Cannot open include file: 'v8.h'`，即使 V8 后端已正确下载。
   
   **解决方法**：已在 CMakeLists.txt 中添加自动路径分隔符处理（Commit `32d36d4`）：
   ```cmake
   # 自动添加 / 如果参数不以 / 开头
   if(NOT BACKEND_INC_NAMES MATCHES "^/")
       set(BACKEND_INC_NAMES "/${BACKEND_INC_NAMES}")
   endif()
   ```
   
   现在两种格式都支持：
   - `-DBACKEND_INC_NAMES=Inc` ✅
   - `-DBACKEND_INC_NAMES=/Inc` ✅（但在 Git Bash 中会被转换，不推荐）

**Q3: 如何验证 V8 后端是否正确下载？**

A: 检查以下目录是否存在：
- `unity/native_src/.backends/v8_9.4.146.24/Inc/v8.h`
- `unity/native_src/.backends/v8_9.4.146.24/Lib/Win64/`

**Q4: 如何配置自动触发构建？**

A: 工作流已配置为在推送到 `unity-2.2.x` 分支时自动触发，监控以下路径的变更：
- `unity/native_src/**`
- `.github/workflows/unity_build_websocket_ssl.yml`
- `.github/workflows/composites/unity-build-websocket-ssl/**`

**自动触发行为**：
- ✅ **Push 触发时默认编译 Windows x64 平台**（最常用的平台）
- ✅ 使用默认配置：V8 9.4.146.24 + WolfSSL + Release 模式
- ✅ 手动触发时可以选择任意平台（Windows/Linux/macOS/All）

**为什么只自动编译 Windows？**
- Windows 是最常用的开发和部署平台
- 减少 CI 资源消耗和构建时间
- Linux 和 macOS 可以通过手动触发按需编译

---

**文档结束**
