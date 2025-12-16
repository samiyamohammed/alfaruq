import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';

class QiblahCompassView extends StatefulWidget {
  const QiblahCompassView({super.key});

  @override
  State<QiblahCompassView> createState() => _QiblahCompassViewState();
}

class _QiblahCompassViewState extends State<QiblahCompassView> {
  final _qiblahStream = FlutterQiblah.qiblahStream;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          "QIBLA FINDER",
          style: TextStyle(
            color: Color(0xFFCFB56C),
            fontSize: 22, // Slightly smaller to save space
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Align the golden beam with Qibla direction",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 10),

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSmallButton("Sync Qibla"),
            const SizedBox(width: 16),
            _buildSmallButton("Retry Compass"),
          ],
        ),

        const SizedBox(height: 10),

        // Compass (Expanded + LayoutBuilder for responsiveness)
        Expanded(
          child: StreamBuilder<QiblahDirection>(
            stream: _qiblahStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFCFB56C)));
              }

              if (!snapshot.hasData) {
                return const Center(
                    child: Text("Compass not available",
                        style: TextStyle(color: Colors.white)));
              }

              final qiblahDirection = snapshot.data!;
              final angle = (qiblahDirection.qiblah * (math.pi / 180) * -1);

              // Use LayoutBuilder to determine how much space we actually have
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate the smaller dimension (width or height) minus padding
                  final double size =
                      math.min(constraints.maxWidth, constraints.maxHeight) -
                          20;
                  // Ensure we don't go negative or too small
                  final double compassSize = size > 0 ? size : 200;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Circle (Dark Background)
                      Container(
                        width: compassSize,
                        height: compassSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF151E32),
                          border: Border.all(color: Colors.white10, width: 1),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 20),
                          ],
                        ),
                      ),

                      // Rotating Compass Image/Painter
                      Transform.rotate(
                        angle: angle,
                        child: SizedBox(
                          width: compassSize - 20,
                          height: compassSize - 20,
                          child: CustomPaint(
                            painter: _CompassPainter(),
                          ),
                        ),
                      ),

                      // N Direction Indicator
                      Transform.rotate(
                        angle: angle,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("N",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(
                                height:
                                    (compassSize / 2) - 30), // Dynamic spacer
                          ],
                        ),
                      ),

                      // GOLDEN NEEDLE (The Beam)
                      Transform.rotate(
                        angle: (qiblahDirection.qiblah * (math.pi / 180) * -1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFCFB56C),
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Text("QIBLA",
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              width: 4,
                              height: (compassSize / 2) -
                                  40, // Dynamic needle length
                              decoration: BoxDecoration(
                                  color: const Color(0xFFCFB56C),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFFCFB56C)
                                            .withOpacity(0.5),
                                        blurRadius: 10)
                                  ]),
                            ),
                            SizedBox(
                                height: (compassSize / 2) - 40), // Pivot spacer
                          ],
                        ),
                      ),

                      // Center Dot
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSmallButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF151E32),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 360; i += 30) {
      final angle = i * math.pi / 180;
      // Start slightly inwards
      final start = Offset(
        center.dx + (radius - 15) * math.cos(angle),
        center.dy + (radius - 15) * math.sin(angle),
      );
      // End at edge
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
