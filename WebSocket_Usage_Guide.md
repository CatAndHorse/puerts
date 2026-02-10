# WebSocket 使用说明

Puerts提供了WebSocket支持，适用于一般平台（Unity、Unreal）和Wasm平台。WebSocket API完全兼容标准浏览器WebSocket API，方便开发者快速集成WebSocket功能。

---

## 📋 目录

1. [平台支持](#平台支持)
2. [快速开始](#快速开始)
3. [API参考](#api参考)
4. [事件处理](#事件处理)
5. [数据类型](#数据类型)
6. [平台差异](#平台差异)
7. [最佳实践](#最佳实践)
8. [常见问题](#常见问题)

---

## 🌍 平台支持

| 平台 | 支持状态 | SSL/TLS支持 | 说明 |
|------|---------|------------|------|
| Unity (Windows/Mac/Linux) | ✅ | ✅ | 使用WebSocketPP库 |
| Unity (iOS/Android) | ✅ | ✅ | 使用WebSocketPP库 |
| Unreal Engine | ✅ | ✅ | 使用WebSocketPP库 |
| Wasm (浏览器) | ✅ | ✅ | 使用浏览器原生WebSocket |

---

## 🚀 快速开始

### 基本示例

```javascript
// 创建WebSocket连接
const ws = new WebSocket('ws://localhost:8080');

// 监听连接建立事件
ws.addEventListener('open', (event) => {
    console.log('WebSocket连接已建立');
    // 发送文本消息
    ws.send('Hello, Server!');
});

// 监听消息事件
ws.addEventListener('message', (event) => {
    console.log('收到消息:', event.data);
});

// 监听关闭事件
ws.addEventListener('close', (event) => {
    console.log('连接已关闭:', event.code, event.reason);
});

// 监听错误事件
ws.addEventListener('error', (event) => {
    console.error('WebSocket错误:', event.data);
});

// 主动关闭连接
ws.close(1000, '正常关闭');
```

### SSL/TLS连接

```javascript
// 创建安全的WebSocket连接
const ws = new WebSocket('wss://example.com:443');
```

---

## 📖 API参考

### 构造函数

```javascript
new WebSocket(url)
new WebSocket(url, protocols)
```

**参数**：
- `url` (String): WebSocket服务器地址，格式为 `ws://` 或 `wss://`
- `protocols` (可选): 不支持此参数，传入会抛出错误

**示例**：
```javascript
const ws = new WebSocket('ws://localhost:8080');
const wsSecure = new WebSocket('wss://example.com:443');
```

---

### 属性

#### readyState

返回WebSocket的当前连接状态。

```javascript
console.log(ws.readyState);
```

**可能的值**：
- `WebSocket.CONNECTING` (0): 正在连接
- `WebSocket.OPEN` (1): 连接已打开，可以通信
- `WebSocket.CLOSING` (2): 正在关闭
- `WebSocket.CLOSED` (3): 连接已关闭

#### url

返回WebSocket连接的URL。

```javascript
console.log(ws.url); // "ws://localhost:8080"
```

---

### 方法

#### send(data)

发送数据到服务器。

```javascript
ws.send(data);
```

**参数**：
- `data` (String | ArrayBuffer | ArrayBufferView): 要发送的数据

**数据类型**：
- **String**: 发送文本消息
- **ArrayBuffer**: 发送二进制数据
- **ArrayBufferView** (如Uint8Array): 发送二进制数据

**示例**：
```javascript
// 发送文本
ws.send('Hello, Server!');

// 发送二进制数据 (ArrayBuffer)
const buffer = new ArrayBuffer(1024);
ws.send(buffer);

// 发送二进制数据 (Uint8Array)
const uint8Array = new Uint8Array([0x01, 0x02, 0x03]);
ws.send(uint8Array);

// 发送二进制数据 (DataView)
const dataView = new DataView(buffer);
ws.send(dataView);
```

**注意**：
- 如果连接未打开（readyState !== OPEN），会触发error事件
- 发送失败也会触发error事件

---

#### close(code, reason)

关闭WebSocket连接。

```javascript
ws.close(code, reason);
```

**参数**：
- `code` (Number, 可选): 关闭状态码，默认1000（正常关闭）
- `reason` (String, 可选): 关闭原因

**常用状态码**：
- `1000`: 正常关闭
- `1001`: 端点离开
- `1002`: 协议错误
- `1003`: 不支持的数据类型
- `1006`: 异常关闭（连接丢失）

**示例**：
```javascript
// 正常关闭
ws.close(1000, '正常关闭');

// 主动断开
ws.close(1001, '客户端离开');
```

---

#### addEventListener(type, callback)

添加事件监听器。

```javascript
ws.addEventListener(type, callback);
```

**参数**：
- `type` (String): 事件类型（'open', 'message', 'close', 'error'）
- `callback` (Function): 事件回调函数

**示例**：
```javascript
ws.addEventListener('open', (event) => {
    console.log('连接已打开');
});
```

---

#### removeEventListener(type, callback)

移除事件监听器。

```javascript
ws.removeEventListener(type, callback);
```

**参数**：
- `type` (String): 事件类型
- `callback` (Function): 要移除的回调函数

**示例**：
```javascript
const handler = (event) => {
    console.log('消息:', event.data);
};

ws.addEventListener('message', handler);
ws.removeEventListener('message', handler);
```

---

## 🎯 事件处理

### open事件

连接成功建立时触发。

```javascript
ws.addEventListener('open', (event) => {
    console.log('WebSocket连接已建立');
    console.log('readyState:', ws.readyState); // WebSocket.OPEN (1)
});
```

---

### message事件

收到服务器消息时触发。

```javascript
ws.addEventListener('message', (event) => {
    console.log('收到消息:', event.data);
    console.log('来源:', event.origin);
    
    // 处理不同类型的数据
    if (typeof event.data === 'string') {
        // 文本消息
        console.log('文本消息:', event.data);
    } else if (event.data instanceof ArrayBuffer) {
        // 二进制消息
        const uint8Array = new Uint8Array(event.data);
        console.log('二进制消息长度:', uint8Array.length);
    }
});
```

---

### close事件

连接关闭时触发。

```javascript
ws.addEventListener('close', (event) => {
    console.log('连接已关闭');
    console.log('状态码:', event.code);
    console.log('原因:', event.reason);
    console.log('readyState:', ws.readyState); // WebSocket.CLOSED (3)
    
    // 根据状态码处理不同的关闭情况
    if (event.code === 1000) {
        console.log('正常关闭');
    } else if (event.code === 1006) {
        console.log('异常关闭，可能需要重连');
    }
});
```

---

### error事件

发生错误时触发。

```javascript
ws.addEventListener('error', (event) => {
    console.error('WebSocket错误:', event.data);
});
```

**常见错误**：
- 连接失败（服务器未启动、网络问题）
- 发送数据时连接未打开
- SSL/TLS证书验证失败

---

## 💾 数据类型

### 文本数据（String）

```javascript
// 发送文本
ws.send('Hello, World!');
ws.send(JSON.stringify({ type: 'greeting', message: '你好' }));

// 接收文本
ws.addEventListener('message', (event) => {
    if (typeof event.data === 'string') {
        const text = event.data;
        const json = JSON.parse(event.data);
    }
});
```

---

### 二进制数据（ArrayBuffer）

```javascript
// 发送二进制数据
const buffer = new ArrayBuffer(1024);
const view = new Uint8Array(buffer);
view[0] = 0x48; // 'H'
view[1] = 0x65; // 'e'
view[2] = 0x6C; // 'l'
view[3] = 0x6C; // 'l'
view[4] = 0x6F; // 'o'
ws.send(buffer);

// 接收二进制数据
ws.addEventListener('message', (event) => {
    if (event.data instanceof ArrayBuffer) {
        const uint8Array = new Uint8Array(event.data);
        console.log('接收到的字节:', uint8Array);
    }
});
```

---

### 二进制数据（ArrayBufferView）

```javascript
// 发送TypedArray
const uint8Array = new Uint8Array([0x48, 0x65, 0x6C, 0x6C, 0x6F]);
ws.send(uint8Array);

// 发送Int16Array
const int16Array = new Int16Array([1000, 2000, 3000]);
ws.send(int16Array);

// 发送Float32Array
const float32Array = new Float32Array([3.14, 2.71, 1.41]);
ws.send(float32Array);

// 发送DataView
const buffer = new ArrayBuffer(8);
const dataView = new DataView(buffer);
dataView.setInt16(0, 1000);
dataView.setFloat32(2, 3.14);
ws.send(dataView);
```

---

## 🔍 平台差异

### 一般平台（Unity/Unreal）

**特点**：
- 使用WebSocketPP库实现
- 需要定期调用`poll()`方法处理网络事件
- 自动处理SSL/TLS（使用WolfSSL）
- 事件处理使用轮询机制

**注意事项**：
- 连接创建后会自动启动轮询（1ms间隔）
- 不需要手动调用poll()方法
- 事件回调中不要抛出异常

**底层实现**：
```javascript
// 内部自动处理poll
this._tid = setInterval(() => this._poll(), 1);

_poll() {
    if (this._pendingEvents.length === 0 && this._readyState != WebSocket.CLOSING) {
        this._raw.poll();
    }
    const ev = this._pendingEvents.shift();
    if (ev) this.dispatchEvent(ev);
}
```

---

### Wasm平台

**特点**：
- 使用浏览器原生WebSocket API
- 事件驱动，无需轮询
- 完全兼容浏览器标准

**使用方法**：
```javascript
// Wasm平台使用方式与一般平台完全相同
const ws = new WebSocket('ws://localhost:8080');
ws.addEventListener('message', (event) => {
    console.log(event.data);
});
```

**配置**：
需要在`modules.json`中配置：
```json
{
    "WasmMain": {
        "LinkCategory": 0,
        "GlobalNameInTs": "WasmMain"
    }
}
```

---

## 💡 最佳实践

### 1. 连接状态检查

发送数据前检查连接状态：

```javascript
function sendSafely(ws, data) {
    if (ws.readyState === WebSocket.OPEN) {
        ws.send(data);
    } else {
        console.error('WebSocket未打开，无法发送数据');
    }
}
```

---

### 2. 自动重连

实现自动重连机制：

```javascript
class ReconnectingWebSocket {
    constructor(url, maxRetries = 5, retryDelay = 3000) {
        this.url = url;
        this.maxRetries = maxRetries;
        this.retryDelay = retryDelay;
        this.retryCount = 0;
        this.ws = null;
        this.connect();
    }
    
    connect() {
        this.ws = new WebSocket(this.url);
        
        this.ws.addEventListener('open', () => {
            console.log('连接成功');
            this.retryCount = 0;
        });
        
        this.ws.addEventListener('close', (event) => {
            console.log('连接关闭:', event.code);
            
            if (this.retryCount < this.maxRetries && event.code !== 1000) {
                this.retryCount++;
                console.log(`${this.retryDelay}ms后尝试重连 (${this.retryCount}/${this.maxRetries})`);
                setTimeout(() => this.connect(), this.retryDelay);
            }
        });
        
        this.ws.addEventListener('error', (event) => {
            console.error('连接错误:', event.data);
        });
    }
    
    send(data) {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(data);
        }
    }
    
    close(code, reason) {
        this.retryCount = this.maxRetries; // 停止自动重连
        this.ws.close(code, reason);
    }
}

// 使用
const rws = new ReconnectingWebSocket('ws://localhost:8080');
```

---

### 3. 心跳保活

实现心跳机制保持连接活跃：

```javascript
class HeartbeatWebSocket {
    constructor(url, interval = 30000) {
        this.url = url;
        this.interval = interval;
        this.ws = new WebSocket(url);
        this.timer = null;
        
        this.ws.addEventListener('open', () => {
            console.log('连接已建立');
            this.startHeartbeat();
        });
        
        this.ws.addEventListener('message', (event) => {
            console.log('收到消息:', event.data);
            // 重置心跳计时器
            this.resetHeartbeat();
        });
        
        this.ws.addEventListener('close', () => {
            this.stopHeartbeat();
        });
    }
    
    startHeartbeat() {
        this.resetHeartbeat();
    }
    
    resetHeartbeat() {
        if (this.timer) {
            clearInterval(this.timer);
        }
        
        this.timer = setInterval(() => {
            if (this.ws.readyState === WebSocket.OPEN) {
                this.ws.send(JSON.stringify({ type: 'ping', timestamp: Date.now() }));
            }
        }, this.interval);
    }
    
    stopHeartbeat() {
        if (this.timer) {
            clearInterval(this.timer);
            this.timer = null;
        }
    }
}

// 使用
const hws = new HeartbeatWebSocket('ws://localhost:8080', 30000);
```

---

### 4. 消息队列

在连接未建立时缓存消息：

```javascript
class QueuedWebSocket {
    constructor(url) {
        this.url = url;
        this.ws = new WebSocket(url);
        this.queue = [];
        this.connected = false;
        
        this.ws.addEventListener('open', () => {
            console.log('连接已建立');
            this.connected = true;
            this.flushQueue();
        });
    }
    
    send(data) {
        if (this.connected) {
            this.ws.send(data);
        } else {
            console.log('连接未建立，消息已加入队列');
            this.queue.push(data);
        }
    }
    
    flushQueue() {
        while (this.queue.length > 0) {
            const data = this.queue.shift();
            this.ws.send(data);
        }
    }
}

// 使用
const qws = new QueuedWebSocket('ws://localhost:8080');
qws.send('缓存的消息'); // 连接建立前发送
```

---

### 5. 错误处理

完善的错误处理机制：

```javascript
const ws = new WebSocket('ws://localhost:8080');

ws.addEventListener('error', (event) => {
    console.error('WebSocket错误:', event.data);
    
    // 根据错误类型处理
    if (event.data.includes('could not create connection')) {
        console.error('无法创建连接，请检查服务器是否运行');
    } else if (event.data.includes('send')) {
        console.error('发送失败，请检查连接状态');
    }
});

ws.addEventListener('close', (event) => {
    console.log('连接关闭:', event.code, event.reason);
    
    // 根据关闭码处理
    switch (event.code) {
        case 1000:
            console.log('正常关闭');
            break;
        case 1006:
            console.error('异常关闭，建议重连');
            break;
        default:
            console.error('未知关闭码:', event.code);
    }
});
```

---

## ❓ 常见问题

### Q1: 为什么我的WebSocket连接一直失败？

**可能原因**：
1. WebSocket服务器未启动
2. URL格式错误（应该使用`ws://`或`wss://`）
3. 端口被防火墙阻止
4. SSL/TLS证书问题（wss://）

**解决方法**：
```javascript
ws.addEventListener('error', (event) => {
    console.error('连接失败:', event.data);
});

// 检查连接状态
console.log('readyState:', ws.readyState);
```

---

### Q2: 发送数据时为什么会触发error事件？

**可能原因**：
1. 连接未打开（readyState !== OPEN）
2. 数据类型不支持
3. 底层发送失败

**解决方法**：
```javascript
function sendSafely(ws, data) {
    if (ws.readyState === WebSocket.OPEN) {
        try {
            ws.send(data);
        } catch (e) {
            console.error('发送失败:', e);
        }
    } else {
        console.error('连接未打开');
    }
}
```

---

### Q3: 如何发送二进制数据？

**方法1：使用ArrayBuffer**
```javascript
const buffer = new ArrayBuffer(1024);
ws.send(buffer);
```

**方法2：使用TypedArray**
```javascript
const uint8Array = new Uint8Array([0x01, 0x02, 0x03]);
ws.send(uint8Array);
```

**方法3：使用DataView**
```javascript
const buffer = new ArrayBuffer(8);
const dataView = new DataView(buffer);
dataView.setInt16(0, 1000);
ws.send(dataView);
```

---

### Q4: 如何处理二进制消息？

```javascript
ws.addEventListener('message', (event) => {
    if (event.data instanceof ArrayBuffer) {
        // 转换为Uint8Array
        const uint8Array = new Uint8Array(event.data);
        console.log('字节数组:', Array.from(uint8Array));
        
        // 转换为字符串
        const decoder = new TextDecoder();
        const text = decoder.decode(event.data);
        console.log('字符串:', text);
    }
});
```

---

### Q5: 一般平台和Wasm平台有什么区别？

| 特性 | 一般平台 | Wasm平台 |
|------|---------|---------|
| 实现方式 | WebSocketPP库 | 浏览器原生 |
| 事件处理 | 轮询机制 | 事件驱动 |
| poll() | 内部自动调用 | 不需要 |
| SSL/TLS | WolfSSL | 浏览器提供 |
| 使用方式 | 完全相同 | 完全相同 |

**结论**：API使用方式完全相同，无需关心平台差异。

---

### Q6: 如何调试WebSocket连接？

```javascript
const ws = new WebSocket('ws://localhost:8080');

// 监听所有事件
ws.addEventListener('open', (event) => {
    console.log('[OPEN] 连接已建立');
    console.log('readyState:', ws.readyState);
});

ws.addEventListener('message', (event) => {
    console.log('[MESSAGE]', event.data);
    console.log('类型:', typeof event.data);
    console.log('是否ArrayBuffer:', event.data instanceof ArrayBuffer);
});

ws.addEventListener('close', (event) => {
    console.log('[CLOSE]', event.code, event.reason);
    console.log('readyState:', ws.readyState);
});

ws.addEventListener('error', (event) => {
    console.error('[ERROR]', event.data);
});

// 定期检查状态
setInterval(() => {
    console.log('State:', ws.readyState, 'URL:', ws.url);
}, 5000);
```

---

### Q7: 如何关闭WebSocket连接？

**方法1：正常关闭**
```javascript
ws.close(1000, '正常关闭');
```

**方法2：主动断开**
```javascript
ws.close(1001, '客户端离开');
```

**注意**：关闭后，readyState会变为CLOSED，不能再发送数据。

---

## 📚 完整示例

### Echo客户端

```javascript
class EchoClient {
    constructor(url) {
        this.url = url;
        this.ws = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 3000;
        
        this.connect();
    }
    
    connect() {
        this.ws = new WebSocket(this.url);
        
        this.ws.addEventListener('open', () => {
            console.log('✓ Echo客户端已连接');
            this.reconnectAttempts = 0;
        });
        
        this.ws.addEventListener('message', (event) => {
            console.log('← 收到:', event.data);
        });
        
        this.ws.addEventListener('close', (event) => {
            console.log('✗ 连接已关闭:', event.code, event.reason);
            this.reconnect();
        });
        
        this.ws.addEventListener('error', (event) => {
            console.error('✗ 错误:', event.data);
        });
    }
    
    reconnect() {
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
            this.reconnectAttempts++;
            console.log(`⏳ ${this.reconnectDelay}ms后尝试重连 (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
            setTimeout(() => this.connect(), this.reconnectDelay);
        }
    }
    
    send(data) {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            console.log('→ 发送:', data);
            this.ws.send(data);
        } else {
            console.warn('⚠ 连接未打开');
        }
    }
    
    sendBinary(data) {
        const buffer = new ArrayBuffer(data.length);
        const uint8Array = new Uint8Array(buffer);
        for (let i = 0; i < data.length; i++) {
            uint8Array[i] = data[i];
        }
        this.send(buffer);
    }
    
    close() {
        if (this.ws) {
            this.reconnectAttempts = this.maxReconnectAttempts;
            this.ws.close(1000, '正常关闭');
        }
    }
}

// 使用
const echoClient = new EchoClient('ws://localhost:8080');

// 发送文本
echoClient.send('Hello, Echo Server!');

// 发送JSON
echoClient.send(JSON.stringify({ type: 'ping', timestamp: Date.now() }));

// 发送二进制
echoClient.sendBinary([0x48, 0x65, 0x6C, 0x6C, 0x6F]);

// 关闭连接
// echoClient.close();
```

---

## 🔗 相关资源

- [WebSocket RFC 6455](https://tools.ietf.org/html/rfc6455)
- [MDN WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)
- [WebSocketPP库](https://github.com/zaphoyd/websocketpp)

---

## 📝 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0 | 2026-02-10 | 初始版本 |

---

**文档作者**: Puerts Team  
**最后更新**: 2026-02-10
