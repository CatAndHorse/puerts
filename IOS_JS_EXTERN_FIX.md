# iOS构建问题修复：JS_EXTERN未定义

## 问题描述

在iOS构建过程中，编译`quickjs.c`文件时出现以下错误：

```
/Users/runner/work/puerts/puerts/unity/native_src/backend-quickjs/quickjs/quickjs.c:56214:1: error: unknown type name 'JS_EXTERN'
JS_EXTERN void *JS_GetContextOpaque1(JSContext *ctx)
^
```

## 根本原因

1. `quickjs.h`文件在开头（第40-49行）定义了`JS_EXTERN`宏：
   ```c
   #if defined(__GNUC__) || defined(__clang__) || defined(__APPLE__)
   #define JS_EXTERN __attribute__((visibility("default")))
   #else
   #define JS_EXTERN /* nothing */
   #endif
   ```

2. 但是在文件末尾（第1105行）有`#undef JS_EXTERN`，取消了这个宏的定义

3. `quickjs.c`文件包含了`quickjs.h`，所以在`quickjs.c`中，`JS_EXTERN`被取消定义了

4. `quickjs.c`文件的第56214行等地方定义了一些需要导出的函数，使用了`JS_EXTERN`宏：
   ```c
   JS_EXTERN void *JS_GetContextOpaque1(JSContext *ctx)
   JS_EXTERN void JS_SetContextOpaque1(JSContext *ctx, void *opaque)
   JS_EXTERN void *JS_GetRuntimeOpaque1(JSRuntime *rt)
   JS_EXTERN void JS_SetRuntimeOpaque1(JSRuntime *rt, void *opaque)
   ```

5. 由于`JS_EXTERN`已被取消定义，编译器无法识别这个宏，导致编译错误

## 解决方案

注释掉`quickjs.h`文件末尾的`#undef JS_EXTERN`，使`JS_EXTERN`宏在`quickjs.c`中仍然有效：

```c
/*-------end fuctions for v8 api---------*/

/* Keep JS_EXTERN defined for functions in quickjs.c that need it */
/* #undef JS_EXTERN */

#ifdef __cplusplus
} /* extern "C" { */
#endif
```

## 修复提交

- Commit: c827af4
- 文件: `unity/native_src/backend-quickjs/quickjs/quickjs.h`
- 修改: 注释掉`#undef JS_EXTERN`

## 影响范围

这个修复确保了`quickjs.c`中需要导出的函数能够正确使用`JS_EXTERN`宏，使这些函数在iOS平台上具有正确的符号可见性。

## 相关问题

- 之前的修复尝试在`quickjs.h`中添加了`__APPLE__`检查，但这不是根本问题
- 真正的问题是`#undef JS_EXTERN`导致宏在`quickjs.c`中不可用
