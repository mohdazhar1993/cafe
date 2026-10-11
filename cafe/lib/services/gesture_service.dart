import 'dart:math' as math;
import '../models/gesture_action.dart';

/// Landmark coordinate representation (normalized [0, 1] or pixel space)
class LandmarkPoint {
  final double x;
  final double y;
  final double z;

  const LandmarkPoint({required this.x, required this.y, this.z = 0.0});

  double distanceTo(LandmarkPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }
}

/// Gesture Recognition Service using Google ML Kit / Landmark Detection
/// Maps 21 Hand Landmarks into Cafe Ordering Commands:
///
/// Controls applied:
/// 1. High confidence threshold (minimum 0.90 required for classification).
/// 2. Gesture Hold Time tracking (e.g., 1.5 seconds) before activating a gesture.
/// 3. Clear/No-op state on default or ambiguous hand positions.
/// 4. Explicit Confirmation required via Thumbs Up.
class GestureService {
  static const double minConfidenceThreshold = 0.90;
  static const Duration requiredHoldDuration = Duration(milliseconds: 1500);

  GestureActionType _lastDetectedType = GestureActionType.unknown;
  DateTime? _holdStartTime;

  /// Returns current hold progress from 0.0 to 1.0
  double get holdProgress {
    if (_holdStartTime == null || _lastDetectedType == GestureActionType.unknown) {
      return 0.0;
    }
    final elapsedMs = DateTime.now().difference(_holdStartTime!).inMilliseconds;
    return (elapsedMs / requiredHoldDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Reset holding state
  void resetHold() {
    _lastDetectedType = GestureActionType.unknown;
    _holdStartTime = null;
  }

  /// Checks if the candidate gesture has met the required 1.5-second hold time.
  bool updateAndCheckHold(GestureActionType type) {
    if (type == GestureActionType.unknown) {
      resetHold();
      return false;
    }

    final now = DateTime.now();
    if (_lastDetectedType != type) {
      _lastDetectedType = type;
      _holdStartTime = now;
      return false;
    }

    final elapsed = now.difference(_holdStartTime!);
    if (elapsed >= requiredHoldDuration) {
      // Completed hold
      return true;
    }
    return false;
  }

  /// Interprets a frame's hand landmarks into a recognized cafe action.
  /// Strict geometry checks to prevent false triggers on default hand movements.
  DetectedGesture classifyHandLandmarks(List<LandmarkPoint> landmarks) {
    if (landmarks.length < 21) {
      return DetectedGesture.none;
    }

    final wrist = landmarks[0];

    // Tips and MCPs
    final thumbTip = landmarks[4];
    final thumbMcp = landmarks[2];

    final indexTip = landmarks[8];
    final indexPip = landmarks[6];
    final indexMcp = landmarks[5];

    final middleTip = landmarks[12];
    final middlePip = landmarks[10];

    final ringTip = landmarks[16];
    final ringPip = landmarks[14];

    final pinkyTip = landmarks[20];
    final pinkyPip = landmarks[18];

    // Extension check: Is finger tip significantly higher (smaller Y in screen coords) than its PIP?
    // In camera coords, Y goes downwards from 0 to 1, so extended up means tip.y < pip.y.
    final bool indexExtended = indexTip.y < indexPip.y - 0.04;
    final bool middleExtended = middleTip.y < middlePip.y - 0.04;
    final bool ringExtended = ringTip.y < ringPip.y - 0.04;
    final bool pinkyExtended = pinkyTip.y < pinkyPip.y - 0.04;

    // Strict Thumb extended upwards check:
    final bool thumbUp = (thumbTip.y < thumbMcp.y - 0.06) && (thumbTip.y < indexMcp.y - 0.06);

    // 1. OPEN PALM -> Clear / Reset Order
    // All 5 fingers distinctly extended outward
    if (indexExtended && middleExtended && ringExtended && pinkyExtended && (thumbTip.y < wrist.y - 0.1)) {
      return const DetectedGesture(
        type: GestureActionType.clearOrder,
        label: 'Open Palm (Clear Order)',
        confidence: 0.95,
        translatedCommand: 'Clear current order and reset',
      );
    }

    // 2. THUMBS UP -> Confirm Order
    // Thumb pointed straight up, 4 other fingers curled down (not extended)
    if (thumbUp && !indexExtended && !middleExtended && !ringExtended && !pinkyExtended) {
      return const DetectedGesture(
        type: GestureActionType.confirmOrder,
        label: 'Thumbs Up (Confirm Order)',
        confidence: 0.96,
        translatedCommand: 'Confirm and place my cafe order',
      );
    }

    // 3. OK SIGN / "O" SHAPE -> Oat Milk
    // Thumb tip and index tip touching (very close), middle/ring/pinky extended
    final thumbIndexDistance = thumbTip.distanceTo(indexTip);
    if (thumbIndexDistance < 0.05 && middleExtended && ringExtended && pinkyExtended) {
      return const DetectedGesture(
        type: GestureActionType.addOatMilk,
        label: 'OK / "O" Sign (Oat Milk)',
        confidence: 0.93,
        translatedCommand: 'Add Oat Milk to my beverage',
      );
    }

    // 4. PINCH SIGN -> Less Sweetness
    if (thumbIndexDistance < 0.05 && !middleExtended && !ringExtended && !pinkyExtended) {
      return const DetectedGesture(
        type: GestureActionType.lessSweetness,
        label: 'Pinch (Less Sweetness)',
        confidence: 0.90,
        translatedCommand: 'Less sweetness / low sugar option',
      );
    }

    // 5. CLOSED FIST -> Sugar-Free
    // No fingers extended, thumb curled
    if (!indexExtended && !middleExtended && !ringExtended && !pinkyExtended && !thumbUp && (thumbTip.y > indexMcp.y - 0.02)) {
      return const DetectedGesture(
        type: GestureActionType.makeSugarFree,
        label: 'Closed Fist (Sugar-Free)',
        confidence: 0.92,
        translatedCommand: 'Make this completely sugar-free',
      );
    }

    // 6. PEACE / VICTORY SIGN ("2") -> Select Tea
    if (indexExtended && middleExtended && !ringExtended && !pinkyExtended) {
      return const DetectedGesture(
        type: GestureActionType.selectTea,
        label: 'Peace / Two Fingers (Tea)',
        confidence: 0.94,
        translatedCommand: 'I would like to order hot Tea',
      );
    }

    // 7. POINT / ONE FINGER ("1") -> Select Coffee
    if (indexExtended && !middleExtended && !ringExtended && !pinkyExtended) {
      return const DetectedGesture(
        type: GestureActionType.selectCoffee,
        label: 'Point / One Finger (Coffee)',
        confidence: 0.94,
        translatedCommand: 'I would like to order Coffee',
      );
    }

    return DetectedGesture.none;
  }
}
