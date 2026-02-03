# CentOS-Compatible QuickJS Backend Build Action

这个 Action 用于构建兼容 CentOS 的 QuickJS Backend 和 PuerTS Linux 插件。

## 功能说明

1. 从 [backend-quickjs](https://github.com/puerts/backend-quickjs.git) 仓库克隆源代码
2. 使用 GCC 12 编译 QuickJS Backend（兼容 CentOS 7+）
3. 使用编译好的 QuickJS Backend 构建 PuerTS Linux 插件（开启 WebSocket 支持）
4. 归档产物：
   - `puerts_linux_quickjs_centos`: PuerTS Linux 插件（含 WebSocket 支持）

**注意**：QuickJS Backend 只是构建过程中的中间产物，不单独归档。

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

## 为什么使用 GCC 12？

虽然为了兼容 CentOS，我们最初考虑使用 GCC 7，但实践证明：

1. **GCC 12 更稳定**：GCC 7 版本较老，可能缺少现代 C++ 特性支持
2. **与生产环境一致**：生产环境使用 GCC 12，使用相同版本可避免 ABI 兼容性问题
3. **CentOS 7+ 兼容性**：GCC 12 编译的二进制在 CentOS 7+ 上运行良好
4. **V8 预编译库兼容**：V8 预编译库通常使用较新版本的 GCC 编译，使用相同编译器家族链接可避免 ABI 问题

## CentOS 兼容性说明

使用 GCC 12 编译的二进制文件：
- ✅ 兼容 CentOS 7+
- ✅ 兼容 CentOS 8 / Stream
- ✅ 兼容 RHEL 7+
- ✅ 兼容其他主流 Linux 发行版

## 编译选项

- **GCC 版本**: GCC 12（兼容 CentOS 7+）
- **平台**: Linux x64
- **WebSocket**: 启用（使用 OpenSSL）
- **配置**: Release

## 输出产物

| Artifact 名称 | 内容 |
|--------------|------|
| `puerts_linux_quickjs_centos` | PuerTS Linux 插件（包含所有必需的库文件） |

**说明**：QuickJS Backend（`libquickjs.a`）只在构建过程中使用，不单独归档。

## Backend 配置

在 `unity/cli/backends.json` 中添加了 `qjs_centos` backend 配置：

```json
"qjs_centos": {
    "url": "",
    "config": {
        "definition": [
            "V8_94_OR_NEWER",
            "WITH_QUICKJS",
            "WITHOUT_INSPECTOR"
        ],
        "include": [],
        "link-libraries": {
            "linux": {
                "x64": [
                    "libquickjs.a"
                ]
            }
        }
    }
}
```

## 注意事项

1. 此 Action 仅构建 Linux x64 平台的版本
2. 编译时间可能较长，因为需要从源码编译 QuickJS
3. WebSocket 功能已启用，使用 OpenSSL 作为加密库
