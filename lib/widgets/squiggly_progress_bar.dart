import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Android 13 / M3 Expressive 风格的波浪进度条。
/// 已播放部分为正弦波并持续流动，未播放部分为直线，
/// 播放头前一小段振幅平滑衰减到 0。
class SquigglyProgressBar extends StatefulWidget {
  /// 进度 0.0 ~ 1.0
  final double value;

  /// 轨道高度（波浪的峰谷总高度）
  final double height;

  final Color activeColor;
  final Color inactiveColor;

  /// 是否流动。false 时波浪静止。
  final bool animated;

  /// 一个波长周期滚动所需时间
  final Duration period;

  const SquigglyProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.activeColor = Colors.indigo,
    this.inactiveColor = const Color(0x3D49454F),
    this.animated = true,
    this.period = const Duration(milliseconds: 700),
  });

  @override
  State<SquigglyProgressBar> createState() => _SquigglyProgressBarState();
}

class _SquigglyProgressBarState extends State<SquigglyProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);
    if (widget.animated) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant SquigglyProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.period != oldWidget.period) {
      _controller.duration = widget.period;
    }
    if (widget.animated && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animated && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SquigglyPainter(
              progress: widget.value.clamp(0.0, 1.0),
              phase: _controller.value,
              height: widget.height,
              activeColor: widget.activeColor,
              inactiveColor: widget.inactiveColor,
            ),
          );
        },
      ),
    );
  }
}

class _SquigglyPainter extends CustomPainter {
  final double progress;
  final double phase;
  final double height;
  final Color activeColor;
  final Color inactiveColor;

  _SquigglyPainter({
    required this.progress,
    required this.phase,
    required this.height,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final strokeWidth = height * 0.6;
    final radius = strokeWidth / 2;

    // 1. 未播放段：直线
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(radius, cy),
      Offset(size.width - radius, cy),
      inactivePaint,
    );

    if (progress <= 0) return;

    // 2. 已播放段：正弦波
    final activeWidth = size.width * progress;
    final amplitude = (height - strokeWidth) / 2;
    const wavelength = 22.0;
    const fadeLength = 18.0;
    final phaseOffset = phase * wavelength;

    final path = Path();
    bool first = true;
    for (double x = radius; x <= activeWidth; x += 2) {
      final distanceToEdge = activeWidth - x;
      final fade = distanceToEdge < fadeLength
          ? (distanceToEdge / fadeLength).clamp(0.0, 1.0)
          : 1.0;
      final y = cy +
          amplitude *
              fade *
              math.sin((x + phaseOffset) / wavelength * 2 * math.pi);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, activePaint);

    // 3. 播放头：小圆点
    final headY = cy;
    canvas.drawCircle(
      Offset(activeWidth, headY),
      strokeWidth * 0.9,
      Paint()..color = activeColor,
    );
  }

  @override
  bool shouldRepaint(covariant _SquigglyPainter old) {
    return old.progress != progress ||
        old.phase != phase ||
        old.height != height ||
        old.activeColor != activeColor ||
        old.inactiveColor != inactiveColor;
  }
}