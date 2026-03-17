import 'package:flutter/material.dart';
import 'dart:math' as math;

class TankWidget extends StatelessWidget {
  final String name;
  final double capacity;
  final String type;
  final double currentVolume;

  const TankWidget({
    super.key,
    required this.name,
    required this.capacity,
    required this.type,
    required this.currentVolume,
  });

  @override
  Widget build(BuildContext context) {
    final double fillPercent = (currentVolume / capacity).clamp(0.0, 1.0);
    final Color liquidColor = type.toLowerCase() == 'essence' 
        ? Colors.redAccent 
        : Colors.amber;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            // Cuve Cylindrique
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 70,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.grey[200]!, Colors.grey[50]!, Colors.grey[200]!],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(35), bottom: Radius.circular(35)),
                          border: Border.all(color: Colors.blueGrey[100]!.withOpacity(0.5), width: 1),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: fillPercent),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return FractionallySizedBox(
                            heightFactor: value,
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [liquidColor.withOpacity(0.7), liquidColor.withOpacity(0.5), liquidColor.withOpacity(0.7)],
                                ),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: const Radius.circular(33),
                                  bottomRight: const Radius.circular(33),
                                  topLeft: Radius.circular(value > 0.9 ? 33 : 3),
                                  topRight: Radius.circular(value > 0.9 ? 33 : 3),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(33),
                                child: _WaveAnimation(color: liquidColor),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // MODIFICATION : Volume affiché en LITRES (L)
            Text(
              "${currentVolume.toInt()} L",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              "Max: ${capacity.toInt()}L",
              style: TextStyle(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveAnimation extends StatefulWidget {
  final Color color;
  const _WaveAnimation({required this.color});

  @override
  State<_WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<_WaveAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(painter: _WavePainter(_controller.value, widget.color), child: Container()),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  _WavePainter(this.animationValue, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.25);
    final path = Path();
    for (int j = 0; j < 2; j++) {
      path.reset();
      final double waveHeight = 2.0 + (j * 1.0);
      final double offset = j * math.pi;
      path.moveTo(0, waveHeight);
      for (double i = 0; i <= size.width; i++) {
        path.lineTo(i, waveHeight + math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi) + offset) * waveHeight);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
