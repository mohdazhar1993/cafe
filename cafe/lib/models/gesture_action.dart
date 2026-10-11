enum GestureActionType {
  confirmOrder,      // Thumbs Up
  clearOrder,        // Open Palm
  selectCoffee,      // Single Point / "1"
  selectTea,         // Peace / "2"
  addOatMilk,        // OK / 'O' shape
  makeSugarFree,     // Closed Fist
  lessSweetness,     // Pinch sign
  unknown,
}

class DetectedGesture {
  final GestureActionType type;
  final String label;
  final double confidence;
  final String translatedCommand;

  const DetectedGesture({
    required this.type,
    required this.label,
    required this.confidence,
    required this.translatedCommand,
  });

  static const DetectedGesture none = DetectedGesture(
    type: GestureActionType.unknown,
    label: 'None',
    confidence: 0.0,
    translatedCommand: '',
  );
}
