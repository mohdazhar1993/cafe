import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/order_provider.dart';
import '../services/gesture_service.dart';
import '../models/gesture_action.dart';
import '../widgets/landmark_painter.dart';

class SignLanguageScreen extends StatefulWidget {
  final bool isEmbedded;

  const SignLanguageScreen({super.key, this.isEmbedded = false});

  @override
  State<SignLanguageScreen> createState() => _SignLanguageScreenState();
}

class _SignLanguageScreenState extends State<SignLanguageScreen> {
  final GestureService _gestureService = GestureService();
  DetectedGesture _candidateGesture = DetectedGesture.none;
  DetectedGesture _confirmedGesture = DetectedGesture.none;
  double _holdProgress = 0.0;
  Timer? _frameTimer;
  Timer? _holdTicker;
  int _simulationStep = 0;
  List<LandmarkPoint> _currentLandmarks = [];
  bool _isCameraActive = true;
  bool _hasStartedDetection = false;

  @override
  void initState() {
    super.initState();
    // Do not trigger immediately on camera load - require deliberate detection start
    _initHoldTicker();
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _holdTicker?.cancel();
    super.dispose();
  }

  void _initHoldTicker() {
    _holdTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || !_isCameraActive) return;
      setState(() {
        _holdProgress = _gestureService.holdProgress;
      });
    });
  }

  /// Start camera frame recognition stream
  void _startCameraStream() {
    setState(() {
      _hasStartedDetection = true;
    });

    _frameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || !_isCameraActive) return;

      final rawGesture = _gestureService.classifyHandLandmarks(_currentLandmarks);
      setState(() {
        _candidateGesture = rawGesture;
      });

      // Update hold timer: must be held for 1.5 seconds continuously
      final isHoldComplete = _gestureService.updateAndCheckHold(rawGesture.type);
      if (isHoldComplete && rawGesture.type != GestureActionType.unknown) {
        setState(() {
          _confirmedGesture = rawGesture;
        });
        Provider.of<OrderProvider>(context, listen: false).updateActiveGesture(rawGesture);
      }
    });
  }

  void _cycleNextGesturePattern(int step) {
    setState(() {
      _simulationStep = step;
      _currentLandmarks = _generateLandmarkPatternForStep(step);
      _gestureService.resetHold();
      _confirmedGesture = DetectedGesture.none;
    });
  }

  /// Synthesizes 21-point hand landmark geometries representing distinct signs
  List<LandmarkPoint> _generateLandmarkPatternForStep(int step) {
    // Base palm wrist at bottom center
    final wrist = const LandmarkPoint(x: 0.5, y: 0.85);

    switch (step) {
      case 0: // Thumbs Up
        return [
          wrist,
          const LandmarkPoint(x: 0.45, y: 0.70),
          const LandmarkPoint(x: 0.42, y: 0.55),
          const LandmarkPoint(x: 0.40, y: 0.42),
          const LandmarkPoint(x: 0.38, y: 0.25), // Thumb Tip high up
          // Index curled
          const LandmarkPoint(x: 0.48, y: 0.55),
          const LandmarkPoint(x: 0.48, y: 0.62),
          const LandmarkPoint(x: 0.48, y: 0.68),
          const LandmarkPoint(x: 0.48, y: 0.72), // Index tip down
          // Middle curled
          const LandmarkPoint(x: 0.52, y: 0.55),
          const LandmarkPoint(x: 0.52, y: 0.62),
          const LandmarkPoint(x: 0.52, y: 0.68),
          const LandmarkPoint(x: 0.52, y: 0.72),
          // Ring curled
          const LandmarkPoint(x: 0.56, y: 0.56),
          const LandmarkPoint(x: 0.56, y: 0.63),
          const LandmarkPoint(x: 0.56, y: 0.69),
          const LandmarkPoint(x: 0.56, y: 0.73),
          // Pinky curled
          const LandmarkPoint(x: 0.60, y: 0.58),
          const LandmarkPoint(x: 0.60, y: 0.64),
          const LandmarkPoint(x: 0.60, y: 0.70),
          const LandmarkPoint(x: 0.60, y: 0.74),
        ];

      case 1: // Open Palm (Clear Order)
        return [
          wrist,
          const LandmarkPoint(x: 0.38, y: 0.68),
          const LandmarkPoint(x: 0.32, y: 0.58),
          const LandmarkPoint(x: 0.28, y: 0.48),
          const LandmarkPoint(x: 0.24, y: 0.38), // Thumb extended
          // Index extended
          const LandmarkPoint(x: 0.44, y: 0.55),
          const LandmarkPoint(x: 0.42, y: 0.40),
          const LandmarkPoint(x: 0.40, y: 0.30),
          const LandmarkPoint(x: 0.39, y: 0.20),
          // Middle extended
          const LandmarkPoint(x: 0.50, y: 0.54),
          const LandmarkPoint(x: 0.50, y: 0.38),
          const LandmarkPoint(x: 0.50, y: 0.26),
          const LandmarkPoint(x: 0.50, y: 0.16),
          // Ring extended
          const LandmarkPoint(x: 0.56, y: 0.56),
          const LandmarkPoint(x: 0.58, y: 0.42),
          const LandmarkPoint(x: 0.59, y: 0.30),
          const LandmarkPoint(x: 0.60, y: 0.22),
          // Pinky extended
          const LandmarkPoint(x: 0.62, y: 0.60),
          const LandmarkPoint(x: 0.65, y: 0.48),
          const LandmarkPoint(x: 0.68, y: 0.38),
          const LandmarkPoint(x: 0.70, y: 0.30),
        ];

      case 2: // One finger ("1") -> Coffee
        return [
          wrist,
          const LandmarkPoint(x: 0.42, y: 0.70),
          const LandmarkPoint(x: 0.45, y: 0.66),
          const LandmarkPoint(x: 0.48, y: 0.66),
          const LandmarkPoint(x: 0.50, y: 0.68), // Thumb tucked
          // Index pointing UP
          const LandmarkPoint(x: 0.48, y: 0.56),
          const LandmarkPoint(x: 0.48, y: 0.40),
          const LandmarkPoint(x: 0.48, y: 0.28),
          const LandmarkPoint(x: 0.48, y: 0.16),
          // Middle curled
          const LandmarkPoint(x: 0.54, y: 0.58),
          const LandmarkPoint(x: 0.54, y: 0.65),
          const LandmarkPoint(x: 0.54, y: 0.70),
          const LandmarkPoint(x: 0.54, y: 0.74),
          // Ring curled
          const LandmarkPoint(x: 0.58, y: 0.60),
          const LandmarkPoint(x: 0.58, y: 0.66),
          const LandmarkPoint(x: 0.58, y: 0.71),
          const LandmarkPoint(x: 0.58, y: 0.75),
          // Pinky curled
          const LandmarkPoint(x: 0.62, y: 0.62),
          const LandmarkPoint(x: 0.62, y: 0.68),
          const LandmarkPoint(x: 0.62, y: 0.72),
          const LandmarkPoint(x: 0.62, y: 0.76),
        ];

      case 3: // Peace Sign ("2") -> Tea
        return [
          wrist,
          const LandmarkPoint(x: 0.42, y: 0.70),
          const LandmarkPoint(x: 0.45, y: 0.66),
          const LandmarkPoint(x: 0.48, y: 0.66),
          const LandmarkPoint(x: 0.50, y: 0.68),
          // Index UP
          const LandmarkPoint(x: 0.46, y: 0.56),
          const LandmarkPoint(x: 0.44, y: 0.40),
          const LandmarkPoint(x: 0.42, y: 0.28),
          const LandmarkPoint(x: 0.40, y: 0.18),
          // Middle UP
          const LandmarkPoint(x: 0.52, y: 0.56),
          const LandmarkPoint(x: 0.54, y: 0.40),
          const LandmarkPoint(x: 0.56, y: 0.28),
          const LandmarkPoint(x: 0.58, y: 0.18),
          // Ring curled
          const LandmarkPoint(x: 0.58, y: 0.60),
          const LandmarkPoint(x: 0.58, y: 0.66),
          const LandmarkPoint(x: 0.58, y: 0.71),
          const LandmarkPoint(x: 0.58, y: 0.75),
          // Pinky curled
          const LandmarkPoint(x: 0.62, y: 0.62),
          const LandmarkPoint(x: 0.62, y: 0.68),
          const LandmarkPoint(x: 0.62, y: 0.72),
          const LandmarkPoint(x: 0.62, y: 0.76),
        ];

      case 4: // OK Sign ("O") -> Oat Milk
        return [
          wrist,
          // Thumb touching index tip
          const LandmarkPoint(x: 0.45, y: 0.60),
          const LandmarkPoint(x: 0.42, y: 0.48),
          const LandmarkPoint(x: 0.42, y: 0.38),
          const LandmarkPoint(x: 0.45, y: 0.35), // Thumb Tip
          // Index touching thumb tip
          const LandmarkPoint(x: 0.48, y: 0.56),
          const LandmarkPoint(x: 0.48, y: 0.46),
          const LandmarkPoint(x: 0.47, y: 0.38),
          const LandmarkPoint(x: 0.46, y: 0.35), // Index Tip
          // Middle extended
          const LandmarkPoint(x: 0.54, y: 0.56),
          const LandmarkPoint(x: 0.55, y: 0.40),
          const LandmarkPoint(x: 0.56, y: 0.26),
          const LandmarkPoint(x: 0.57, y: 0.15),
          // Ring extended
          const LandmarkPoint(x: 0.59, y: 0.58),
          const LandmarkPoint(x: 0.61, y: 0.44),
          const LandmarkPoint(x: 0.62, y: 0.32),
          const LandmarkPoint(x: 0.63, y: 0.22),
          // Pinky extended
          const LandmarkPoint(x: 0.64, y: 0.62),
          const LandmarkPoint(x: 0.67, y: 0.50),
          const LandmarkPoint(x: 0.69, y: 0.40),
          const LandmarkPoint(x: 0.71, y: 0.30),
        ];

      default: // Closed Fist -> Sugar Free
        return [
          wrist,
          const LandmarkPoint(x: 0.46, y: 0.66),
          const LandmarkPoint(x: 0.48, y: 0.64),
          const LandmarkPoint(x: 0.50, y: 0.64),
          const LandmarkPoint(x: 0.52, y: 0.66),
          // All 4 curled
          const LandmarkPoint(x: 0.46, y: 0.60),
          const LandmarkPoint(x: 0.46, y: 0.68),
          const LandmarkPoint(x: 0.46, y: 0.72),
          const LandmarkPoint(x: 0.46, y: 0.76),

          const LandmarkPoint(x: 0.50, y: 0.60),
          const LandmarkPoint(x: 0.50, y: 0.68),
          const LandmarkPoint(x: 0.50, y: 0.72),
          const LandmarkPoint(x: 0.50, y: 0.76),

          const LandmarkPoint(x: 0.54, y: 0.60),
          const LandmarkPoint(x: 0.54, y: 0.68),
          const LandmarkPoint(x: 0.54, y: 0.72),
          const LandmarkPoint(x: 0.54, y: 0.76),

          const LandmarkPoint(x: 0.58, y: 0.62),
          const LandmarkPoint(x: 0.58, y: 0.69),
          const LandmarkPoint(x: 0.58, y: 0.73),
          const LandmarkPoint(x: 0.58, y: 0.77),
        ];
    }
  }

  void _dispatchGestureToOrder(DetectedGesture gesture) {
    if (gesture.translatedCommand.isEmpty) return;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.submitUserInput(gesture.translatedCommand);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ Gesture sent to Gemini: "${gesture.translatedCommand}"'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.brown.shade800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: widget.isEmbedded ? BorderRadius.circular(16) : BorderRadius.zero,
      ),
      child: Stack(
        children: [
          // Simulated Camera Video Viewfinder with scanlines & landmark canvas
          Positioned.fill(
            child: ClipRRect(
              borderRadius: widget.isEmbedded ? BorderRadius.circular(16) : BorderRadius.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF2A2D3E),
                          const Color(0xFF11131F),
                        ],
                        radius: 1.0,
                      ),
                    ),
                  ),

                  // Real-time Landmark Skeleton Overlay
                  CustomPaint(
                    painter: LandmarkPainter(
                      landmarks: _currentLandmarks,
                      pointColor: Colors.amberAccent,
                      lineColor: Colors.tealAccent,
                    ),
                  ),

                  // Viewfinder Grid Overlay
                  Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24, width: 2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Status Pill
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ML Kit Hand Landmark Tracker',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isCameraActive ? Icons.videocam : Icons.videocam_off,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isCameraActive = !_isCameraActive;
                    });
                  },
                ),
              ],
            ),
          ),

          // Bottom Gesture Action HUD with Hold Progress Indicator
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_hasStartedDetection) ...[
                    Row(
                      children: [
                        const Icon(Icons.touch_app_rounded, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Hold sign steady for 1.5 seconds to register',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startCameraStream,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Gesture Recognition'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent.shade700,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gesture_rounded, color: Colors.amberAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _confirmedGesture.type != GestureActionType.unknown
                                  ? '✅ ${_confirmedGesture.label}'
                                  : (_candidateGesture.type != GestureActionType.unknown
                                      ? 'Holding ${_candidateGesture.label}...'
                                      : 'Show a clear hand sign'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_candidateGesture.type != GestureActionType.unknown)
                          Text(
                            '${(_holdProgress * 1.5).toStringAsFixed(1)}s / 1.5s',
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),

                    // Visual hold progress indicator
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _holdProgress,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _holdProgress >= 1.0 ? Colors.greenAccent : Colors.amberAccent,
                        ),
                        minHeight: 6,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      _confirmedGesture.type != GestureActionType.unknown
                          ? 'Action: "${_confirmedGesture.translatedCommand}"'
                          : 'Hold hand pose steady for 1.5 seconds to confirm',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _cycleNextGesturePattern((_simulationStep + 1) % 6),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                            ),
                            child: const Text('Test Next Sign', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _confirmedGesture.type != GestureActionType.unknown
                                ? () => _dispatchGestureToOrder(_confirmedGesture)
                                : null,
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text('Send to Order'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amberAccent.shade700,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
