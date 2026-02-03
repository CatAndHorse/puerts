# CentOS-Compatible QuickJS Backend Build Action

这个 Action 用于构建兼容 CentOS 的 PuerTS QuickJS Linux 插件。

## 功能说明

1. 从 [backend-quickjs](https://github.com/puerts/backend-quickjs.git) 仓库克隆源代码
2. 将 `backend-quickjs` 放置到 `unity/native_src` 目录，CMake 会直接编译其中的 QuickJS 源代码
3. 使用 GCC 12 编译 PuerTS Linux 插件（兼容 CentOS 7+，开启 WebSocket 支持）
4. 归档产物：
   - `puerts_linux_quickjs_centos`: PuerTS Linux 插件（含 WebSocket 支持）

**工作原理**：`backend-quickjs` 不是一个需要单独编译的项目，它包含 QuickJS 的源代码和适配层。CMake 会直接编译 `backend-quickjs/quickjs/` 下的 `.c` 文件来生成 QuickJS 引擎。

## 使用方法

### 方法 1: 直接运行 Workflow

在 GitHub Actions 页面手动触发 `Build CentOS-Compatible QuickJS Backend and PuerTS` workflow。

### 方法 2: 在其他 Workflow 中调用

```yaml
jobs:
  my-job:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build CentOS-Compatible QuickJS
        uses: ./.github/workflows/composites/unity-build-centos-quickjs/
        with:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Download PuerTS artifacts
        uses: actions/download-artifact@v4
        with:
          name: puerts_linux_quickjs_centos
          path: ./output
```

## 为什么需要 CentOS 兼容？

CentOS 7 默认使用的 GCC 版本较旧（GCC 4.8.x），这可能导致：

1. 新版 GCC 编译的库使用了 CentOS 7 不支持的符号版本
2. 二进制兼容性问题：`GLIBCXX_3.4.21` 等符号在 CentOS 7 中不存在
3. 运行时错误：`version 'GLIBCXX_3.4.21' not found`

通过使用 GCC 12 编译，可以确保二进制库在 CentOS 7 及以上版本中正常运行。

## 为什么使用 GCC 12？

1. **与生产环境一致**：生产环境使用 GCC 12，使用相同版本可避免 ABI 兼容性问题
2. **V8 预编译库兼容**：V8 预编译库通常使用较新版本的 GCC 编译，使用相同编译器家族链接可避免 ABI 问题
3. **CentOS 7+ 兼容性**：GCC 12 编译的二进制在 CentOS 7+ 上运行良好
4. **现代 C++ 特性支持**：GCC 12 更稳定，支持更多现代 C++ 特性

## CentOS 兼容性说明

使用 GCC 12 编译的二进制文件：
- ✅ 兼容 CentOS 7+
- ✅ 兼容 CentOS 8 / Stream
- ✅ 兼容 RHEL 7+
- ✅ 兼容其他主流 Linux 发行版

## 编译选项

- **GCC 版本**: GCC 12（兼容 CentOS 7+）
- **平台**: Linux x64
- **Backend**: QuickJS（从 `backend-quickjs` 源码编译）
- **WebSocket**: 启用（使用 OpenSSL）
- **配置**: Release

## 输出产物

| Artifact 名称 | 内容 |
|--------------|------|
| `puerts_linux_quickjs_centos` | PuerTS Linux x64 QuickJS 插件（包含所有必需的库文件） |

## Backend 编译流程

`backend-quickjs` 包含以下内容：

```
backend-quickjs/
├── include/          # PuerTS 适配头文件
├── quickjs/          # QuickJS 源代码
│   ├── quickjs.c
│   ├── cutils.c
│   ├── libbf.c
│   ├── libregexp.c
│   └── libunicode.c
└── src/
    └── v8-impl.cc    # V8 API 到 QuickJS 的适配层
```

CMake 会将 QuickJS 源代码直接编译进 `libpuerts.so`，无需单独编译 `libquickjs.a`。

## 注意事项

1. 此 Action 仅构建 Linux x64 平台的版本
2. 编译时间可能较长，因为需要从源码编译 QuickJS
3. WebSocket 功能已启用，使用 OpenSSL 作为加密库
4. `backend-quickjs` 的源代码会直接被 CMake 编译，不需要预先编译
