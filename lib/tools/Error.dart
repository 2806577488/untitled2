import 'package:flutter/cupertino.dart';
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
/// 独立函数：记录错误并显示对话框
String logAndShowError({
  required BuildContext context,
  required Object exception,
  required StackTrace stackTrace,
  required String title,
  required bool mounted, // 由调用方传入当前组件的 mounted 状态
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

// 独立错误处理函数
ErrorDetails logError(Object error, StackTrace stackTrace) {
  final chain = Chain.forTrace(stackTrace);
  final parsedFrames = chain.traces.expand((trace) => trace.frames).toList();

  String? filePath;
  int? lineNumber;
  int? columnNumber;

  for (final frame in parsedFrames) {
    if (frame is! Frame) continue;

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
      break;
    }
  }

  return ErrorDetails(
    errorType: error.runtimeType,
    errorMessage: error.toString(),
    filePath: filePath,
    lineNumber: lineNumber,
    columnNumber: columnNumber,
    stackTrace: chain.toString(),
  );
}
