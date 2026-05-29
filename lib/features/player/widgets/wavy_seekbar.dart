import 'dart:math' as math;
import 'package:flutter/material.dart';

class WavySeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final bool isPlaying;

  const WavySeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onChanged,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.isPlaying,
  });

  @override
  State<WavySeekBar> createState() => _WavySeekBarState();
}

class _WavySeekBarState extends State<WavySeekBar> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.isPlaying) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(WavySeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double maxVal = widget.duration.inMilliseconds.toDouble();
    final double currentVal = _dragValue ?? widget.position.inMilliseconds.toDouble().clamp(0.0, maxVal > 0 ? maxVal : 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            _updateDragValue(details.localPosition.dx, width, maxVal);
          },
          onHorizontalDragUpdate: (details) {
            _updateDragValue(details.localPosition.dx, width, maxVal);
          },
          onHorizontalDragEnd: (details) {
            if (_dragValue != null) {
              widget.onChanged(Duration(milliseconds: _dragValue!.toInt()));
              setState(() {
                _dragValue = null;
              });
            }
          },
          onTapDown: (details) {
            _updateDragValue(details.localPosition.dx, width, maxVal);
            if (_dragValue != null) {
              widget.onChanged(Duration(milliseconds: _dragValue!.toInt()));
              setState(() {
                _dragValue = null;
              });
            }
          },
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(double.infinity, 32),
                painter: _WavySeekBarPainter(
                  value: currentVal,
                  max: maxVal > 0 ? maxVal : 1.0,
                  activeColor: widget.activeColor,
                  inactiveColor: widget.inactiveColor,
                  thumbColor: widget.thumbColor,
                  phase: _animationController.value * 2 * math.pi,
                  isPlaying: widget.isPlaying,
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _updateDragValue(double dx, double width, double maxVal) {
    final double percent = (dx / width).clamp(0.0, 1.0);
    setState(() {
      _dragValue = percent * maxVal;
    });
    widget.onChanged(Duration(milliseconds: (_dragValue ?? 0.0).toInt()));
  }
}

class _WavySeekBarPainter extends CustomPainter {
  final double value;
  final double max;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final double phase;
  final bool isPlaying;

  _WavySeekBarPainter({
    required this.value,
    required this.max,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.phase,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;
    final double progress = value / max;
    final double thumbX = progress * size.width;

    if (thumbX < size.width) {
      final Paint inactivePaint = Paint()
        ..color = inactiveColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(thumbX, centerY),
        Offset(size.width, centerY),
        inactivePaint,
      );
    }

    if (thumbX > 0) {
      final Paint activePaint = Paint()
        ..color = activeColor
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final Path activePath = Path();
      activePath.moveTo(0, centerY);

      const double wavelength = 40.0;
      final double maxAmplitude = isPlaying ? 4.5 : 1.0;

      for (double x = 0; x <= thumbX; x += 2.0) {

        double factor = 1.0;
        if (x < 20) {
          factor = x / 20;
        } else if (thumbX - x < 20) {
          factor = (thumbX - x) / 20;
        }

        final double y = centerY + factor * maxAmplitude * math.sin((x / wavelength) * 2 * math.pi - phase);
        activePath.lineTo(x, y);
      }

      canvas.drawPath(activePath, activePaint);
    }

    final Paint thumbGlow = Paint()
      ..color = activeColor.withAlpha(40)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(thumbX, centerY), 11, thumbGlow);

    final Paint thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(thumbX, centerY), 6, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _WavySeekBarPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.max != max ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.thumbColor != thumbColor ||
        oldDelegate.phase != phase ||
        oldDelegate.isPlaying != isPlaying;
  }
}
