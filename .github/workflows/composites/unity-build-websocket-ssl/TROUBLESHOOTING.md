# 🔍 故障排查检查清单

## 编译前检查（Pre-Build Checklist）

在开始编译之前，请确认以下事项：

### ✅ 环境检查

- [ ] **CMake 版本** >= 3.15
  ```bash
  cmake --version
  ```

- [ ] **Git 已安装**
  ```bash
  git --version
  ```

- [ ] **Node.js 已安装** (>= 14.x)
  ```bash
  node --version
  npm --version
  ```

### ✅ 代码仓库检查

- [ ] **V8 后端文件存在**
  ```bash
  ls unity/native_src/.backends/v8_9.4.146.24/
  # 应该看到 Inc/ 和 Lib/ 目录
  ```

- [ ] **CMakeLists.txt 存在**
  ```bash
  ls unity/native_src/CMakeLists.txt
  ```

- [ ] **分支正确**
  ```bash
  git branch
  # 应该在 unity-2.2.x 或相关分支
  ```

---

## 编译时检查（Build-Time Checklist）

### ✅ CMake 配置阶段

运行 CMake 配置后，检查以下内容：

- [ ] **配置成功完成**
  ```
  -- Configuring done
  -- Generating done
  ```

- [ ] **WITH_WEBSOCKET 参数正确**
  ```bash
  grep "WITH_WEBSOCKET" CMakeCache.txt
  # 应该输出：WITH_WEBSOCKET:STRING=2 (或 3)
  ```

- [ ] **JS_ENGINE 参数正确**
  ```bash
  grep "JS_ENGINE" CMakeCache.txt
  # 应该输出：JS_ENGINE:STRING=v8_9.4.146.24
  ```

- [ ] **WolfSSL 下载成功**（如果使用 WolfSSL）
  ```bash
  ls _deps/wolfssl-src/
  # 应该看到 wolfssl 源码目录
  ```

- [ ] **生成器正确**
  ```bash
  grep "CMAKE_GENERATOR" CMakeCache.txt
  # Windows: Visual Studio 17 2022
  # Linux/macOS: Unix Makefiles
  ```

### ✅ 编译阶段

- [ ] **编译无错误**
  - 警告可以忽略，但不应有 `error` 关键字

- [ ] **WolfSSL 编译成功**（如果使用）
  ```
  wolfssl.vcxproj -> .../wolfssl.lib
  ```

- [ ] **Puerts 编译成功**
  ```
  puerts.vcxproj -> .../puerts.dll
  ```

### ✅ 输出文件检查

- [ ] **主插件文件存在**
  ```bash
  # Windows
  ls Release/puerts.dll
  
  # Linux
  ls libpuerts.so
  
  # macOS
  ls libpuerts.dylib
  ```

- [ ] **SSL 库文件存在**（如果使用）
  ```bash
  # WolfSSL
  ls Release/wolfssl.dll  # 或 wolfssl.lib
  
  # OpenSSL
  ls Release/libssl.dll
  ```

- [ ] **V8 库文件存在**
  ```bash
  ls Release/v8*.dll
  # 应该看到：v8.dll, v8_libplatform.dll, v8_libbase.dll
  ```

---

## 常见错误及解决方案

### ❌ 错误 1：CMake 找不到 V8 后端

**错误信息**：
```
CMake Error: Could not find V8 backend
```

**检查步骤**：
1. [ ] 确认 V8 后端目录存在
   ```bash
   ls unity/native_src/.backends/
   ```

2. [ ] 尝试使用自动检测
   ```bash
   cmake .. -DJS_ENGINE=v8  # 不指定具体版本
   ```

3. [ ] 手动下载 V8 后端
   ```bash
   cd unity/native_src/.backends/
   # 从官方仓库下载对应版本
   ```

**解决方案**：
```bash
# 清理后重新配置
rm -rf build_*
mkdir build_win_x64_v8_ws_wolfssl
cd build_win_x64_v8_ws_wolfssl
cmake .. -G "Visual Studio 17 2022" -A x64 -DJS_ENGINE=v8 -DWITH_WEBSOCKET=2
```

---

### ❌ 错误 2：WITH_WEBSOCKET 参数未生效

**症状**：
- CMakeCache.txt 中没有 `WITH_WEBSOCKET` 条目
- 编译后没有 wolfssl.dll

**检查步骤**：
1. [ ] 检查 CMake 命令是否正确
   ```bash
   # 错误示例（有空格）
   cmake .. -D WITH_WEBSOCKET=2  # ❌
   
   # 正确示例（无空格）
   cmake .. -DWITH_WEBSOCKET=2   # ✅
   ```

2. [ ] 检查 CMakeCache.txt
   ```bash
   cat CMakeCache.txt | grep WITH_WEBSOCKET
   ```

3. [ ] 检查生成的项目文件
   ```bash
   # Windows
   cat puerts.vcxproj | grep "WITH_WEBSOCKET"
   
   # Linux/macOS
   cat CMakeFiles/puerts.dir/flags.make | grep "WITH_WEBSOCKET"
   ```

**解决方案**：
```bash
# 完全清理后重新配置
rm -rf *
cmake .. \
  -G "Visual Studio 17 2022" -A x64 \
  -DJS_ENGINE=v8_9.4.146.24 \
  -DWITH_WEBSOCKET=2 \
  -DUSING_MULT_BACKEND=OFF

# 立即验证
grep WITH_WEBSOCKET CMakeCache.txt
```

---

### ❌ 错误 3：WolfSSL 下载失败

**错误信息**：
```
Failed to download wolfssl repository
fatal: unable to access 'https://github.com/wolfSSL/wolfssl.git/'
```

**检查步骤**：
1. [ ] 检查网络连接
   ```bash
   ping github.com
   ```

2. [ ] 检查 Git 代理设置
   ```bash
   git config --global --get http.proxy
   git config --global --get https.proxy
   ```

3. [ ] 尝试手动克隆
   ```bash
   git clone --depth 1 --branch v5.7.2-stable https://github.com/wolfSSL/wolfssl.git
   ```

**解决方案 A：配置代理**
```bash
# 设置代理（如果需要）
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# 重新运行 CMake
```

**解决方案 B：手动下载**
```bash
cd build_win_x64_v8_ws_wolfssl
mkdir -p _deps/wolfssl-src
cd _deps/wolfssl-src
git clone --depth 1 --branch v5.7.2-stable https://github.com/wolfSSL/wolfssl.git .

# 返回构建目录继续编译
cd ../..
cmake --build . --config Release
```

**解决方案 C：切换到 OpenSSL**
```bash
# 使用 OpenSSL 代替 WolfSSL
cmake .. -G "Visual Studio 17 2022" -A x64 -DJS_ENGINE=v8 -DWITH_WEBSOCKET=3
```

---

### ❌ 错误 4：链接错误（LNK2019）

**错误信息**：
```
error LNK2019: unresolved external symbol "public: class v8::Local..."
```

**检查步骤**：
1. [ ] 检查 V8 库文件是否存在
   ```bash
   ls .backends/v8_9.4.146.24/Lib/Win64/
   # 应该看到 v8.dll.lib 等文件
   ```

2. [ ] 检查链接器设置
   ```bash
   cat puerts.vcxproj | grep "AdditionalDependencies"
   ```

3. [ ] 检查库路径
   ```bash
   cat puerts.vcxproj | grep "AdditionalLibraryDirectories"
   ```

**解决方案**：
```bash
# 完全清理后重新配置
cd unity/native_src
rm -rf build_*
mkdir build_win_x64_v8_ws_wolfssl
cd build_win_x64_v8_ws_wolfssl

# 使用自动检测
cmake .. \
  -G "Visual Studio 17 2022" -A x64 \
  -DJS_ENGINE=v8 \
  -DWITH_WEBSOCKET=2 \
  -DUSING_MULT_BACKEND=OFF

cmake --build . --config Release
```

---

### ❌ 错误 5：只生成了 .lib 没有 .dll

**症状**：
- `Release/` 目录中只有 `puerts.lib` 和 `puerts.exp`
- 没有 `puerts.dll`

**检查步骤**：
1. [ ] 检查编译日志
   ```bash
   # 查找错误信息
   cmake --build . --config Release 2>&1 | grep -i "error"
   ```

2. [ ] 检查链接器输出
   ```bash
   # 查找链接步骤
   cmake --build . --config Release 2>&1 | grep -i "link"
   ```

3. [ ] 检查 CMake 配置
   ```bash
   grep "BUILD_SHARED_LIBS" CMakeCache.txt
   ```

**解决方案**：
```bash
# 清理后重新配置，确保生成动态库
rm -rf *
cmake .. \
  -G "Visual Studio 17 2022" -A x64 \
  -DJS_ENGINE=v8_9.4.146.24 \
  -DWITH_WEBSOCKET=2 \
  -DUSING_MULT_BACKEND=OFF \
  -DBUILD_SHARED_LIBS=ON

cmake --build . --config Release --verbose
```

---

### ❌ 错误 6：Unity 中无法加载 DLL

**错误信息**：
```
DllNotFoundException: Unable to load DLL 'puerts'
```

**检查步骤**：
1. [ ] 确认 DLL 文件位置
   ```
   Assets/Plugins/Windows/x86_64/puerts.dll
   ```

2. [ ] 检查 Unity Inspector 设置
   - Platform Settings > Any Platform: 取消勾选
   - Platform Settings > Windows: 勾选
   - Platform Settings > Windows > CPU: x86_64

3. [ ] 检查依赖 DLL
   ```bash
   # 使用 Dependency Walker 或 dumpbin
   dumpbin /dependents puerts.dll
   ```

4. [ ] 确认所有依赖都已复制
   - v8.dll
   - v8_libplatform.dll
   - v8_libbase.dll
   - zlib.dll
   - wolfssl.dll

**解决方案**：
```bash
# 复制所有依赖 DLL
cd unity/native_src/build_win_x64_v8_ws_wolfssl/Release
cp *.dll YourUnityProject/Assets/Plugins/Windows/x86_64/

# 在 Unity 中重新导入
# Assets > Reimport All
```

---

## 验证清单（Verification Checklist）

### ✅ 编译成功验证

运行以下命令验证编译结果：

```bash
cd unity/native_src/build_win_x64_v8_ws_wolfssl/Release

# 1. 检查文件大小
ls -lh puerts.dll
# 应该 > 1MB

# 2. 检查依赖
dumpbin /dependents puerts.dll | grep -E "v8|wolfssl"

# 3. 检查导出符号
dumpbin /exports puerts.dll | grep -i "websocket"

# 4. 验证 SSL 支持
strings puerts.dll | grep -i "ssl\|tls"
```

### ✅ Unity 集成验证

1. [ ] DLL 文件已复制到正确位置
2. [ ] Unity Inspector 设置正确
3. [ ] 控制台无加载错误
4. [ ] 测试脚本运行成功

### ✅ 功能验证

```csharp
// 在 Unity 中运行此测试
var jsEnv = new JsEnv();
jsEnv.Eval(@"
    const WebSocket = require('ws');
    
    // 测试 wss://
    const wss = new WebSocket('wss://echo.websocket.org');
    wss.on('open', () => console.log('✅ WSS OK'));
    wss.on('error', (e) => console.error('❌ WSS Failed:', e));
");
```

---

## 🆘 仍然无法解决？

如果以上步骤都无法解决问题，请：

1. **收集信息**：
   - CMake 完整输出日志
   - 编译完整输出日志
   - CMakeCache.txt 文件
   - 错误截图

2. **提交 Issue**：
   - 访问：https://github.com/Tencent/puerts/issues
   - 使用模板创建新 Issue
   - 附上收集的信息

3. **社区求助**：
   - Puerts 官方 QQ 群
   - GitHub Discussions

---

**提示**：90% 的问题都是由于 CMake 参数传递错误或 V8 后端缺失导致的。请优先检查这两项！
