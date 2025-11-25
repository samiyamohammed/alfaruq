import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:al_faruk_app/generated/app_localizations.dart';

class QiblahPage extends StatefulWidget {
  const QiblahPage({super.key});

  @override
  State<QiblahPage> createState() => _QiblahPageState();
}

class _QiblahPageState extends State<QiblahPage> {
  final _qiblahStream = FlutterQiblah.qiblahStream;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showCalibrationWarning = false;
  String _locationName = "";

  static const Color _goldColor = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _locationName = "";
    _initializeQiblah();
    _getCurrentLocation();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCalibrationWarning = true;
        });
      }
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _errorMessage = "Location services are disabled.");
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _errorMessage = "Location permission denied.");
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(
          () => _errorMessage = "Location permissions are permanently denied.");
      return false;
    }
    return true;
  }

  Future<void> _getCurrentLocation() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _locationName =
              "Lat: ${position.latitude.toStringAsFixed(3)}, Lng: ${position.longitude.toStringAsFixed(3)}";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _locationName = "Location unavailable");
    }
  }

  Future<void> _initializeQiblah() async {
    try {
      final sensorSupport = await FlutterQiblah.androidDeviceSensorSupport();
      if (sensorSupport == false) {
        if (mounted)
          setState(() {
            _errorMessage = "Your device does not support compass sensor";
            _isLoading = false;
          });
        return;
      }
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (error) {
      if (mounted)
        setState(() {
          _errorMessage = "Failed to initialize Qiblah compass: $error";
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    String displayLocation = _locationName;
    if (displayLocation.isEmpty) displayLocation = l10n.locationFetching;
    if (displayLocation == "Location unavailable")
      displayLocation = l10n.locationUnavailable;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(l10n.qiblahTitle),
        backgroundColor: backgroundColor,
        foregroundColor: _goldColor,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              displayLocation,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _goldColor.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _goldColor))
          : _errorMessage != null
              ? _buildErrorWidget(_errorMessage!, l10n)
              : _buildQiblahCompass(
                  size, isDark, textColor, backgroundColor, l10n),
    );
  }

  Widget _buildQiblahCompass(Size size, bool isDark, Color textColor,
      Color bgColor, AppLocalizations l10n) {
    return StreamBuilder<QiblahDirection>(
      stream: _qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _goldColor));
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString(), l10n);
        }

        if (snapshot.hasData) {
          final qiblahDirection = snapshot.data!;
          final angle = (qiblahDirection.qiblah) * (math.pi / 180) * -1;

          return SingleChildScrollView(
            // --- FIX START: FORCE FULL WIDTH ---
            child: SizedBox(
              width: size
                  .width, // This forces the column to take full screen width
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Ensure items are centered
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      l10n.alignDevice,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Compass Container
                  Container(
                    width: size.width * 0.8,
                    height: size.width * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.black : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: _goldColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: _goldColor,
                        width: 3,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size(size.width * 0.8, size.width * 0.8),
                          painter: _CompassPainter(
                            lineColor:
                                isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        Transform.rotate(
                          angle: angle,
                          child: Icon(
                            Icons.navigation,
                            size: size.width * 0.35,
                            color: _goldColor,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: _goldColor.withOpacity(0.5),
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _goldColor,
                            boxShadow: [
                              BoxShadow(
                                color: _goldColor.withOpacity(0.7),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  Text(
                    "${l10n.qiblahDirection}: ${qiblahDirection.qiblah.toStringAsFixed(1)}°",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _goldColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_showCalibrationWarning)
                    Text(
                      l10n.calibrateWarning,
                      style: TextStyle(
                          color: textColor.withOpacity(0.6), fontSize: 12),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
            // --- FIX END ---
          );
        }

        return _buildErrorWidget(l10n.compassError, l10n);
      },
    );
  }

  Widget _buildErrorWidget(String errorMessage, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: _goldColor, size: 60),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                await _initializeQiblah();
                await _getCurrentLocation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _goldColor,
                foregroundColor: Colors.black,
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final Color lineColor;
  _CompassPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;

    for (int i = 0; i < 360; i += 5) {
      final double angle = i * math.pi / 180;
      final bool isMajor = i % 90 == 0;
      final bool isMinor = i % 30 == 0;

      final double lineLength = isMajor ? 20 : (isMinor ? 10 : 5);
      paint.strokeWidth = isMajor ? 3 : (isMinor ? 2 : 1);

      final double startX = centerX + (radius - lineLength) * math.cos(angle);
      final double startY = centerY + (radius - lineLength) * math.sin(angle);
      final double endX = centerX + radius * math.cos(angle);
      final double endY = centerY + radius * math.sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
