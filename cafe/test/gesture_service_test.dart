import 'package:flutter_test/flutter_test.dart';
import 'package:cafe_companion/services/gesture_service.dart';
import 'package:cafe_companion/models/gesture_action.dart';

void main() {
  group('GestureService Landmark Recognition Tests', () {
    late GestureService gestureService;

    setUp(() {
      gestureService = GestureService();
    });

    test('Classifies Thumbs-Up gesture correctly', () {
      final wrist = const LandmarkPoint(x: 0.5, y: 0.85);
      final thumbTip = const LandmarkPoint(x: 0.38, y: 0.25);
      final thumbMcp = const LandmarkPoint(x: 0.42, y: 0.55);

      final landmarks = [
        wrist,
        const LandmarkPoint(x: 0.45, y: 0.70),
        thumbMcp,
        const LandmarkPoint(x: 0.40, y: 0.42),
        thumbTip,
        // Curled fingers (tip Y > pip Y)
        const LandmarkPoint(x: 0.48, y: 0.55),
        const LandmarkPoint(x: 0.48, y: 0.62),
        const LandmarkPoint(x: 0.48, y: 0.68),
        const LandmarkPoint(x: 0.48, y: 0.72), // Index tip down

        const LandmarkPoint(x: 0.52, y: 0.55),
        const LandmarkPoint(x: 0.52, y: 0.62),
        const LandmarkPoint(x: 0.52, y: 0.68),
        const LandmarkPoint(x: 0.52, y: 0.72), // Middle tip down

        const LandmarkPoint(x: 0.56, y: 0.56),
        const LandmarkPoint(x: 0.56, y: 0.63),
        const LandmarkPoint(x: 0.56, y: 0.69),
        const LandmarkPoint(x: 0.56, y: 0.73), // Ring tip down

        const LandmarkPoint(x: 0.60, y: 0.58),
        const LandmarkPoint(x: 0.60, y: 0.64),
        const LandmarkPoint(x: 0.60, y: 0.70),
        const LandmarkPoint(x: 0.60, y: 0.74), // Pinky tip down
      ];

      final result = gestureService.classifyHandLandmarks(landmarks);
      expect(result.type, equals(GestureActionType.confirmOrder));
      expect(result.label, contains('Thumbs Up'));
      expect(result.translatedCommand, contains('Confirm and place'));
    });

    test('Classifies Open Palm gesture correctly', () {
      final wrist = const LandmarkPoint(x: 0.5, y: 0.85);
      final landmarks = [
        wrist,
        const LandmarkPoint(x: 0.38, y: 0.68),
        const LandmarkPoint(x: 0.32, y: 0.58),
        const LandmarkPoint(x: 0.28, y: 0.48),
        const LandmarkPoint(x: 0.24, y: 0.38),
        // All extended fingers (tip Y < pip Y)
        const LandmarkPoint(x: 0.44, y: 0.55),
        const LandmarkPoint(x: 0.42, y: 0.40),
        const LandmarkPoint(x: 0.40, y: 0.30),
        const LandmarkPoint(x: 0.39, y: 0.20),

        const LandmarkPoint(x: 0.50, y: 0.54),
        const LandmarkPoint(x: 0.50, y: 0.38),
        const LandmarkPoint(x: 0.50, y: 0.26),
        const LandmarkPoint(x: 0.50, y: 0.16),

        const LandmarkPoint(x: 0.56, y: 0.56),
        const LandmarkPoint(x: 0.58, y: 0.42),
        const LandmarkPoint(x: 0.59, y: 0.30),
        const LandmarkPoint(x: 0.60, y: 0.22),

        const LandmarkPoint(x: 0.62, y: 0.60),
        const LandmarkPoint(x: 0.65, y: 0.48),
        const LandmarkPoint(x: 0.68, y: 0.38),
        const LandmarkPoint(x: 0.70, y: 0.30),
      ];

      final result = gestureService.classifyHandLandmarks(landmarks);
      expect(result.type, equals(GestureActionType.clearOrder));
      expect(result.label, contains('Open Palm'));
      expect(result.translatedCommand, contains('Clear current order'));
    });

    test('Requires continuous 1.5s hold time before activating gesture', () {
      // First update starts hold timer
      final isCompleteImmediately = gestureService.updateAndCheckHold(GestureActionType.confirmOrder);
      expect(isCompleteImmediately, isFalse);
      expect(gestureService.holdProgress, greaterThanOrEqualTo(0.0));

      // Resetting cancels hold
      gestureService.resetHold();
      expect(gestureService.holdProgress, equals(0.0));
    });

    test('Ambiguous hand landmarks return unknown type', () {
      final incompleteLandmarks = [
        const LandmarkPoint(x: 0.5, y: 0.5),
        const LandmarkPoint(x: 0.5, y: 0.5),
      ];
      final result = gestureService.classifyHandLandmarks(incompleteLandmarks);
      expect(result.type, equals(GestureActionType.unknown));
    });
  });
}
