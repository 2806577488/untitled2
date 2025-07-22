import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stack_trace/stack_trace.dart';

import '../utils/customDialog.dart';

// 错误信息数据类
class ErrorDetails {
  final Type errorType;
  final String errorMessage;
  final String? filePath;
  final int? lineNumber;
  final int? columnNumber;
  final String stackTrace;

  ErrorDetails({
    required this.errorType,
    required this.errorMessage,
    this.filePath,
    this.lineNumber,
    this.columnNumber,
    required this.stackTrace,
  });

  @override
  String toString() {
    return '''

======= 错误报告 =======
错误类型: $errorType
错误信息: $errorMessage
文件路径: ${filePath ?? '未知'}
行号: ${lineNumber ?? '未知'}
列号: ${columnNumber ?? '未知'}
完整堆栈:
$stackTrace
=======================
''';
  }
}

/// 全局错误处理工具类
class GlobalErrorHandler {
  /// 记录错误并显示对话框
   static String logAndShowError({
    required BuildContext context,
    required Object exception,
    required StackTrace stackTrace,
    required String title,
    required bool mounted,
  }) {
    // 记录错误并获取详细信息
    final errorDetails = logError(exception, stackTrace);

    // 仅在组件未卸载时显示对话框
    if (mounted) {
      CustomDialog.show(
        context: context,
        title: title,
        content: errorDetails.toString(),
        buttonType: DialogButtonType.singleConfirm,
        onConfirm: () {}, // 空确认回调
      );
    }

    // 返回错误详细信息字符串
    return errorDetails.toString();
  }

  /// 记录错误但不显示对话框（用于非UI错误）
  static String logErrorOnly(Object error, StackTrace stackTrace) {
    final errorDetails = logError(error, stackTrace);
    print(errorDetails.toString());
    return errorDetails.toString();
  }

  /// 显示简单错误信息（用于用户友好的错误提示）
  static void showSimpleError({
    required BuildContext context,
    required String message,
    required String title,
    required bool mounted,
  }) {
    if (mounted) {
      CustomDialog.show(
        context: context,
        title: title,
        content: message,
        buttonType: DialogButtonType.singleConfirm,
        onConfirm: () {},
      );
    }
  }

  /// 显示成功信息
  static void showSuccess({
    required BuildContext context,
    required String message,
    required bool mounted,
  }) {
    if (mounted) {
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text('操作成功', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text("确定", style: TextStyle(color: Colors.green, fontSize: 16)),
            ),
          ],
        ),
      );
    }
  }

  /// 统一的调试输出函数
  static void debugPrint(String message) {
    print('🔍 DEBUG: $message');
  }
}

/// 独立函数：记录错误并显示对话框（保持向后兼容）
String logAndShowError({
  required BuildContext context,
  required Object exception,
  required StackTrace stackTrace,
  required String title,
  required bool mounted,
}) {
  return GlobalErrorHandler.logAndShowError(
    context: context,
    exception: exception,
    stackTrace: stackTrace,
    title: title,
    mounted: mounted,
  );
}

// 独立错误处理函数
ErrorDetails logError(Object error, StackTrace stackTrace) {
  // 提取最根本的错误信息
  final rootMessage = _extractRootMessage(error);
  
  final chain = Chain.forTrace(stackTrace);
  final parsedFrames = chain.traces.expand((trace) => trace.frames).toList();

  String? filePath;
  int? lineNumber;
  int? columnNumber;

  for (final frame in parsedFrames) {
    // 生产环境解析
    final frameStr = frame.toString();
    final pattern = RegExp(r'\((.*?):(\d+):(\d+)\)');
    final match = pattern.firstMatch(frameStr);

    if (match != null) {
      filePath = match.group(1);
      lineNumber = int.tryParse(match.group(2) ?? '');
      columnNumber = int.tryParse(match.group(3) ?? '');
      if (filePath != null) break;
    } else {
      filePath = frame.uri.path;
      lineNumber = frame.line;
      columnNumber = frame.column;
      if (filePath.isNotEmpty) break;
    }
  }

  return ErrorDetails(
    errorType: error.runtimeType,
    errorMessage: rootMessage,
    filePath: filePath,
    lineNumber: lineNumber,
    columnNumber: columnNumber,
    stackTrace: stackTrace.toString(),
  );
}

/// 提取最根本的错误消息
String _extractRootMessage(Object error) {
  final message = error.toString();
  
  // 如果消息包含嵌套的错误，提取最内层的错误信息
  if (message.contains('Exception: ')) {
    final parts = message.split('Exception: ');
    if (parts.length > 1) {
      // 返回最后一个 Exception 的消息部分
      return parts.last.trim();
    }
  }
  
  // 如果没有嵌套，直接返回原消息
  return message;
}
