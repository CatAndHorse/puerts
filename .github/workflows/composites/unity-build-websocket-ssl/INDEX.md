# 📖 文档导航

欢迎使用 Puerts Unity WebSocket SSL 构建系统！

## 🚀 快速开始

**如果你是第一次使用，请从这里开始：**

👉 **[5 分钟快速启动指南](./QUICKSTART.md)**

---

## 📚 完整文档

### 📘 [完整使用文档](./README.md)

详细的使用说明、配置参数、部署指南和测试示例。

**适合以下情况**：
- 需要了解所有功能和配置选项
- 需要自定义构建参数
- 需要了解构建流程细节
- 需要部署到 Unity 项目

**包含内容**：
- 功能特性说明
- 使用方法（手动/自动触发）
- 构建产物说明
- 配置参数详解
- 构建流程图
- 部署到 Unity 指南
- 功能测试代码

---

### 🔍 [故障排查清单](./TROUBLESHOOTING.md)

系统化的问题诊断和解决方案。

**适合以下情况**：
- 编译失败需要诊断问题
- 按步骤排查错误原因
- 验证构建结果是否正确
- 解决 Unity 集成问题

**包含内容**：
- 编译前检查清单
- 编译时检查清单
- 6 个常见错误及解决方案
- 验证清单
- 求助指南

---

### 🔧 [关键修复：V8 头文件找不到问题](./CRITICAL_FIX_V8_HEADERS.md) ⭐ **重要**

详细记录了 GitHub Actions 中 V8 头文件找不到问题的完整解决过程。

**适合以下情况**：
- 遇到 `Cannot open include file: 'v8.h'` 错误
- V8 Backend 下载成功但编译失败
- 需要了解 CMakeLists.txt 路径拼接问题
- 需要了解 Git Bash 路径转换问题

**包含内容**：
- 问题症状和根本原因分析
- 完整的问题排查过程（5 次尝试）
- CMakeLists.txt 修复方案
- Git Bash 路径转换问题说明
- 验证修复的方法
- 关键教训总结

---

### 📊 [项目总结](./PROJECT_SUMMARY.md)

项目概览、技术细节和维护指南。

**适合以下情况**：
- 需要了解项目整体架构
- 需要维护或扩展构建系统
- 需要了解技术实现细节
- 需要贡献代码

**包含内容**：
- 项目概述
- 文件结构说明
- 技术细节和改进点
- 构建矩阵
- 维护指南
- 性能指标

---

## 🎯 根据场景选择文档

### 场景 1：我想快速编译一个插件

👉 阅读 **[QUICKSTART.md](./QUICKSTART.md)**

只需 5 分钟，6 个简单步骤即可完成。

---

### 场景 2：我需要自定义编译配置

👉 阅读 **[README.md](./README.md)** 的"配置说明"部分

了解所有可用的配置参数和它们的作用。

---

### 场景 3：编译失败了，不知道哪里出错

👉 阅读 **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**

按照检查清单逐步排查问题。

---

### 场景 3.1：遇到 "Cannot open include file: 'v8.h'" 错误

👉 阅读 **[CRITICAL_FIX_V8_HEADERS.md](./CRITICAL_FIX_V8_HEADERS.md)** ⭐

这是一个已知问题，文档中有详细的解决方案。

---

### 场景 4：我想了解这个系统是如何工作的

👉 阅读 **[PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)**

了解技术架构和实现细节。

---

### 场景 5：我想部署到 Unity 项目

👉 阅读 **[README.md](./README.md)** 的"部署到 Unity"部分

详细的部署步骤和配置说明。

---

### 场景 6：我想测试 WebSocket SSL 功能

👉 阅读 **[README.md](./README.md)** 的"测试 WebSocket SSL 功能"部分

包含 JavaScript 和 C# 测试代码示例。

---

## 🔗 快速链接

### 核心文件

- 🎬 [GitHub Actions 工作流](../../../unity_build_websocket_ssl.yml)
- 📋 [快速启动指南](./QUICKSTART.md)
- 📖 [完整文档](./README.md)
- 🔍 [故障排查](./TROUBLESHOOTING.md)
- 🔧 [关键修复：V8 头文件](./CRITICAL_FIX_V8_HEADERS.md) ⭐
- 📊 [项目总结](./PROJECT_SUMMARY.md)

### 外部资源

- 🏠 [Puerts 官方仓库](https://github.com/Tencent/puerts)
- 📚 [Puerts 文档](https://github.com/Tencent/puerts/tree/master/doc)
- 🔧 [GitHub Actions 文档](https://docs.github.com/en/actions)
- 🔐 [WolfSSL 文档](https://www.wolfssl.com/documentation/)
- 🔐 [OpenSSL 文档](https://www.openssl.org/docs/)

---

## 📝 文档结构

```
unity-build-websocket-ssl/
├── INDEX.md                    # 本文件 - 文档导航
├── QUICKSTART.md               # 5 分钟快速启动
├── README.md                   # 完整使用文档
├── TROUBLESHOOTING.md          # 故障排查清单
├── CRITICAL_FIX_V8_HEADERS.md  # 关键修复：V8 头文件问题 ⭐
└── PROJECT_SUMMARY.md          # 项目总结
```

---

## 💡 使用建议

### 新手路径

```
1. INDEX.md (本文件)
   ↓
2. QUICKSTART.md (快速上手)
   ↓
3. 如果遇到问题 → TROUBLESHOOTING.md
   ↓
4. 需要更多功能 → README.md
```

### 高级用户路径

```
1. INDEX.md (本文件)
   ↓
2. README.md (了解所有功能)
   ↓
3. PROJECT_SUMMARY.md (了解技术细节)
   ↓
4. 自定义和扩展
```

---

## 🆘 需要帮助？

### 1. 查看文档

按照上面的场景选择合适的文档。

### 2. 搜索 Issues

访问 [Puerts Issues](https://github.com/Tencent/puerts/issues) 搜索类似问题。

### 3. 提交新 Issue

如果找不到解决方案，创建新的 Issue 并提供：
- 详细的错误信息
- CMake 配置日志
- 编译输出日志
- 环境信息（操作系统、CMake 版本等）

### 4. 社区讨论

加入 Puerts 社区：
- GitHub Discussions
- QQ 群（见官方文档）

---

## 🎉 开始使用

准备好了吗？

👉 **[点击这里开始 5 分钟快速启动](./QUICKSTART.md)**

---

**提示**：建议将本页面加入书签，方便随时查阅！

---

**最后更新**：2026-02-08  
**版本**：1.1.0
