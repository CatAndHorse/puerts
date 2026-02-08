# 🚀 快速启动指南

## 5 分钟快速编译 Puerts WebSocket SSL 插件

### 步骤 1：触发构建

1. 访问 GitHub 仓库：`https://github.com/YOUR_USERNAME/puerts`
2. 点击顶部的 **Actions** 标签
3. 在左侧选择 **"Build Puerts Unity Plugin with WebSocket SSL Support"**
4. 点击右侧的 **"Run workflow"** 按钮

### 步骤 2：配置参数

使用以下推荐配置（适合大多数场景）：

```yaml
JavaScript Backend: v8_9.4.146.24  # 稳定版本
Target Platform: windows            # 或选择 all 编译所有平台
Build Configuration: Release        # 发布版本
SSL Backend: wolfssl                # 推荐使用 WolfSSL
```

### 步骤 3：等待构建完成

- ⏱️ Windows: 约 10-15 分钟
- ⏱️ Linux: 约 15-20 分钟
- ⏱️ macOS: 约 15-20 分钟
- ⏱️ All Platforms: 约 20-30 分钟

### 步骤 4：下载构建产物

1. 构建完成后，滚动到页面底部的 **Artifacts** 部分
2. 下载对应平台的压缩包：
   - `puerts-windows-x64-websocket-ssl-v8_9.4.146.24-wolfssl.zip`

### 步骤 5：部署到 Unity

```bash
# 1. 解压下载的文件
unzip puerts-windows-x64-websocket-ssl-v8_9.4.146.24-wolfssl.zip

# 2. 复制到 Unity 项目
cp *.dll YourUnityProject/Assets/Plugins/Windows/x86_64/

# 3. 打开 Unity 编辑器，等待导入完成
```

### 步骤 6：测试功能

在 Unity 中创建测试脚本：

```csharp
using UnityEngine;
using Puerts;

public class QuickTest : MonoBehaviour
{
    void Start()
    {
        var jsEnv = new JsEnv();
        jsEnv.Eval(@"
            const WebSocket = require('ws');
            const wss = new WebSocket('wss://echo.websocket.org');
            wss.on('open', () => console.log('✅ WSS Connected!'));
        ");
    }
}
```

运行游戏，如果控制台输出 `✅ WSS Connected!`，说明配置成功！

---

## 🆘 遇到问题？

### 问题：构建失败

**检查清单**：
- [ ] 确认 V8 后端文件存在于 `.backends/` 目录
- [ ] 检查 GitHub Actions 日志中的错误信息
- [ ] 尝试使用 `v8` 而不是具体版本号

### 问题：Unity 中无法加载 DLL

**检查清单**：
- [ ] 确认 DLL 文件放在正确的目录（`Assets/Plugins/Windows/x86_64/`）
- [ ] 在 Unity Inspector 中检查 DLL 的平台设置
- [ ] 确认所有依赖的 DLL 都已复制（v8.dll, wolfssl.dll 等）

### 问题：WebSocket 连接失败

**检查清单**：
- [ ] 确认使用了正确的 SSL 后端编译
- [ ] 检查防火墙设置
- [ ] 尝试使用 `ws://` 测试基本连接

---

## 📖 更多信息

- 详细文档：[README.md](./README.md)
- 故障排查：[README.md#故障排查](./README.md#🐛-故障排查)
- 测试示例：[README.md#测试](./README.md#🧪-测试-websocket-ssl-功能)

---

**提示**：首次使用建议选择 `wolfssl` 作为 SSL 后端，它配置简单且性能优秀！
