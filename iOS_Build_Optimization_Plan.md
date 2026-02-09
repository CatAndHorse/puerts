# iOS构建产出物优化方案

## 问题分析

### 1. 当前产出物包含多平台文件（✅ 已修复）

**问题描述**：
- iOS构建Action产出物包含了Android、OpenHarmony、macOS、Windows、Linux等多个平台的库文件
- 期望：只包含iOS平台需要的运行库

**根本原因**：
- composite action上传路径为`./unity/Assets/core/upm/Plugins/**/*`（所有平台）
- 主workflow的上传步骤在Clean之后执行，导致目录为空

**解决方案**（✅ 已实施）：
- 修改`ios/action.yml`：上传路径改为`./unity/Assets/core/upm/Plugins/iOS/**/*`
- 删除主workflow中重复的上传步骤
- Commit: 126aa30

---

### 2. iOS mult backend静态库链接错误（✅ 已修复）

**问题描述**：
```
Undefined symbols for architecture arm64:
  "_wolfSSL_BIO_ctrl_pending", referenced from:
      puerts_asio::ssl::detail::engine::perform(...) in libv8backend.a[11](WebSocketImpl.o)
```

**根本原因**：
- iOS使用静态库构建，mult backend模式下创建了独立的`libv8backend.a`和`libqjsbackend.a`
- 这些backend库依赖WolfSSL，但静态库的依赖不会自动传递
- 链接时找不到WolfSSL符号

**解决方案**（✅ 已实施）：
- 修改CMakeLists.txt：iOS平台的mult backend模式下，将backend源码直接编译到`libpuerts.a`中
- 不再创建独立的backend静态库，避免静态库依赖传递问题
- Commit: fd71b53

---

## 2. 库文件数量优化（✅ 已实施）

### 当前iOS产出物分析

```
总大小：46MB
实际库文件（4个 → 2个）：
- libpuerts.a       ~16MB   # 主库（已包含v8backend + qjsbackend）
- libwee8.a         31.0MB  # Wee8（轻量级V8）

.meta文件（19个 → 2个）：
- 已清理没有对应.a文件的.meta文件
```

### 已实施方案：A + B-1（自动合并）

#### ✅ 方案A：清理多余的.meta文件

**实施**：
- 在iOS构建的composite action中添加后处理步骤
- 自动删除没有对应.a文件的.meta文件
- Commit: 72de726

**效果**：
- 从19个.meta文件减少到2个
- 产出物更清晰，没有多余文件

---

#### ✅ 方案B-1：自动合并静态库

**实施**：
- 修改CMakeLists.txt：iOS mult backend模式下，backend源码直接编译到libpuerts.a
- 不再创建独立的libv8backend.a和libqjsbackend.a
- Commit: fd71b53

**产出物对比**：

修复前（有问题）：
```
libpuerts.a       3.0MB
libqjsbackend.a   7.9MB
libv8backend.a    4.9MB   # 链接错误：缺少WolfSSL符号
libwee8.a        31.0MB
+ 19个多余的.meta文件
总计：46.8MB，4个库文件 + 19个.meta
```

修复后：
```
libpuerts.a      ~16MB   # 包含puerts + v8backend + qjsbackend
libwee8.a         31MB   # V8引擎
+ 2个.meta文件
总计：~47MB，2个库文件 + 2个.meta
```

**优点**：
- ✅ 解决了静态库链接错误
- ✅ 减少库文件数量（4个→2个）
- ✅ 简化Unity项目配置
- ✅ 减少链接步骤
- ✅ 清理了多余的.meta文件

---

#### 方案C：按需构建（灵活）

**目标**：根据backend参数只构建需要的库

**实施**：
- 如果backend=quickjs，只构建libpuerts.a + libqjsbackend.a
- 如果backend=v8_*，只构建libpuerts.a + libv8backend.a + libwee8.a
- 如果backend=mult，构建所有

**产出物示例**：

quickjs模式：
```
libpuerts.a       3.0MB
libqjsbackend.a   7.9MB
总计：10.9MB，2个文件
```

v8模式：
```
libpuerts.a       3.0MB
libv8backend.a    4.9MB
libwee8.a        31.0MB
总计：38.9MB，3个文件
```

mult模式：
```
libpuerts.a       3.0MB
libqjsbackend.a   7.9MB
libv8backend.a    4.9MB
libwee8.a        31.0MB
总计：46.8MB，4个文件
```

**优点**：
- 按需构建，减少不必要的库
- 灵活性高

**缺点**：
- 需要修改CMakeLists.txt和构建脚本
- 增加构建逻辑复杂度

---

## 推荐方案

### 短期（立即实施）：
**方案A + 方案B-1**
1. 清理多余的.meta文件
2. 合并libpuerts.a、libv8backend.a、libqjsbackend.a为libpuerts_mult.a
3. 保持libwee8.a独立（因为体积大，可能有些项目不需要）

**产出物**：
```
libpuerts_mult.a  15.8MB  # 主库 + 双后端
libwee8.a         31.0MB  # V8引擎
总计：2个文件
```

### 长期（可选）：
**方案C**
- 根据backend参数按需构建
- 提供更灵活的构建选项

---

## 实施计划

### 阶段1：清理.meta文件
- [ ] 修改构建脚本，只为实际存在的库生成.meta
- [ ] 测试验证

### 阶段2：合并静态库
- [ ] 在iOS构建脚本中添加libtool合并步骤
- [ ] 修改CMakeLists.txt（如需要）
- [ ] 测试验证合并后的库是否正常工作

### 阶段3：按需构建（可选）
- [ ] 修改CMakeLists.txt，支持条件编译
- [ ] 修改构建脚本，根据backend参数选择构建目标
- [ ] 测试各种backend组合

---

## 技术细节

### iOS静态库合并命令

```bash
# 使用libtool合并多个.a文件
libtool -static -o output.a input1.a input2.a input3.a

# 或使用ar命令
ar -x input1.a  # 解压
ar -x input2.a
ar -rcs output.a *.o  # 重新打包
```

### 验证合并后的库

```bash
# 查看库中的符号
nm -g libpuerts_mult.a | grep "T "

# 查看库的架构
lipo -info libpuerts_mult.a

# 查看库的大小
ls -lh libpuerts_mult.a
```

---

## 注意事项

1. **符号冲突**：合并时注意检查是否有重复的符号定义
2. **架构一致性**：确保所有库都是相同的架构（arm64）
3. **链接顺序**：合并后的库可能需要调整链接顺序
4. **Unity配置**：合并后需要更新Unity的插件配置

---

## 相关文件

- iOS构建workflow: `.github/workflows/unity_build_ios.yml`
- iOS构建composite: `.github/workflows/composites/unity-build-plugins/ios/action.yml`
- CMake配置: `unity/native_src/CMakeLists.txt`
- 构建脚本: `unity/cli/cmd.mjs`
