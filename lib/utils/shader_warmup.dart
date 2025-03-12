import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class WarmUpTheShader {
  static bool _warmedUp = false;

  static void warmUp(BuildContext context) {
    if (_warmedUp) return;
    _warmedUp = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      final startTime = DateTime.now().millisecondsSinceEpoch;

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final screenSize = MediaQuery.of(context).size;

      _warmUpDropdown(canvas, screenSize);
      _warmUpButtons(canvas);
      _warmUpText(canvas);

      recorder.endRecording().toImage(1, 1).then((_) {
        final cost = DateTime.now().millisecondsSinceEpoch - startTime;
        debugPrint('Shader预热完成，耗时${cost}ms');
      });
    });
  }

  static void _warmUpDropdown(Canvas canvas, Size size) {
    final paint = Paint();

    // 基础圆角矩形
    final baseRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 200, 40),
      const Radius.circular(8),
    );
    final basePath = _rrectToPath(baseRRect);

    // 绘制阴影
    canvas.drawShadow(
      basePath.shift(const Offset(0, 2)),
      Colors.black54,
      4.0,
      false,
    );

    // 绘制填充
    canvas.drawPath(basePath, paint..color = Colors.white);

    // 展开状态
    final expandedRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 200, 200),
      const Radius.circular(8),
    );
    final expandedPath = _rrectToPath(expandedRRect);

    canvas.saveLayer(expandedRRect.outerRect, paint);
    canvas.drawShadow(expandedPath, Colors.black54, 4.0, false);
    canvas.drawPath(expandedPath, paint..color = Colors.white);
    canvas.restore();
  }

  static Path _rrectToPath(RRect rrect) {
    final path = Path();

    // 左上角
    path.moveTo(rrect.left + rrect.tlRadiusX, rrect.top);
    path.arcTo(
      Rect.fromCircle(
        center: Offset(rrect.left + rrect.tlRadiusX, rrect.top + rrect.tlRadiusY),
        radius: rrect.tlRadiusX,
      ),
      -pi/2,
      pi/2,
      false,
    );

    // 右上角
    path.lineTo(rrect.right - rrect.trRadiusX, rrect.top);
    path.arcTo(
      Rect.fromCircle(
        center: Offset(rrect.right - rrect.trRadiusX, rrect.top + rrect.trRadiusY),
        radius: rrect.trRadiusX,
      ),
      0,
      pi/2,
      false,
    );

    // 右下角
    path.lineTo(rrect.right, rrect.bottom - rrect.brRadiusY);
    path.arcTo(
      Rect.fromCircle(
        center: Offset(rrect.right - rrect.brRadiusX, rrect.bottom - rrect.brRadiusY),
        radius: rrect.brRadiusX,
      ),
      pi/2,
      pi/2,
      false,
    );

    // 左下角
    path.lineTo(rrect.left + rrect.blRadiusX, rrect.bottom);
    path.arcTo(
      Rect.fromCircle(
        center: Offset(rrect.left + rrect.blRadiusX, rrect.bottom - rrect.blRadiusY),
        radius: rrect.blRadiusX,
      ),
      pi,
      pi/2,
      false,
    );

    path.close();
    return path;
  }

  static void _warmUpButtons(Canvas canvas) {
    const rect = Rect.fromLTWH(0,0,100,40);
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // 基础按钮
    final btnRRect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawPath(_rrectToPath(btnRRect), paint);

    // 悬停状态
    final hoverPaint = Paint()
      ..color = Colors.blue[700]!
      ..style = PaintingStyle.fill;
    canvas.drawPath(_rrectToPath(btnRRect), hoverPaint);
  }

  static void _warmUpText(Canvas canvas) {
    const styles = [
      TextStyle(fontSize: 14, color: Colors.black),
      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ];

    for (final style in styles) {
      final painter = TextPainter(
        text: TextSpan(text: 'Preview', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset.zero);
    }
  }
}