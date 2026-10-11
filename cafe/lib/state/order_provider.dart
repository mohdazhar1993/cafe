import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/gesture_action.dart';
import '../services/gemini_service.dart';

enum OrderingInputMode {
  voice,
  text,
  handSign,
}

class ChatMessage {
  final String sender; // 'user' | 'gemini' | 'system'
  final String text;
  final DateTime timestamp;
  final String? translatedReceiptPreview;
  final List<String> suggestionChips;

  ChatMessage({
    required this.sender,
    required this.text,
    this.translatedReceiptPreview,
    this.suggestionChips = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class OrderProvider extends ChangeNotifier {
  final GeminiService _geminiService;

  OrderProvider({GeminiService? geminiService})
      : _geminiService = geminiService ?? GeminiService();

  OrderingInputMode _currentMode = OrderingInputMode.text;
  OrderingInputMode get currentMode => _currentMode;

  final List<OrderItem> _cartItems = [];
  List<OrderItem> get cartItems => List.unmodifiable(_cartItems);

  final List<ChatMessage> _messages = [
    ChatMessage(
      sender: 'gemini',
      text: '☕ Welcome to Cafe Companion! Order using your voice, any language text, or hand signs.',
    ),
  ];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  OrderReceipt? _latestReceipt;
  OrderReceipt? get latestReceipt => _latestReceipt;

  DetectedGesture _activeGesture = DetectedGesture.none;
  DetectedGesture get activeGesture => _activeGesture;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get tax => subtotal * 0.0825;
  double get total => subtotal + tax;

  Set<String> get activeDietaryTags {
    final tags = <String>{};
    for (final item in _cartItems) {
      tags.addAll(item.item.dietaryTags);
      for (final opt in item.options) {
        if (opt.name.toLowerCase().contains('oat')) tags.add('Dairy-Free');
        if (opt.name.toLowerCase().contains('sugar-free')) tags.add('Sugar-Free');
      }
    }
    return tags;
  }

  void setInputMode(OrderingInputMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  void updateActiveGesture(DetectedGesture gesture) {
    _activeGesture = gesture;
    notifyListeners();
  }

  /// Processes customer input (voice, text, or gesture command) through Gemini AI
  Future<void> submitUserInput(String input) async {
    if (input.trim().isEmpty) return;

    _isLoading = true;
    _messages.add(ChatMessage(sender: 'user', text: input));
    notifyListeners();

    try {
      final parsed = await _geminiService.parseOrderInput(input);
      final intent = parsed['intent'] as String? ?? 'ORDER_ITEMS';

      if (intent == 'CLEAR_ORDER') {
        _cartItems.clear();
        _latestReceipt = null;
      } else if (intent == 'CONFIRM_ORDER') {
        if (_cartItems.isNotEmpty) {
          _latestReceipt = _geminiService.buildReceiptFromParsedJson({
            'detected_language': parsed['detected_language'] ?? 'English',
            'customer_reply': parsed['customer_reply'] ?? 'Order confirmed!',
            'staff_notes_english': 'Order finalized: ${_cartItems.length} items',
            'consolidated_dietary_tags': activeDietaryTags.toList(),
            'items': _cartItems.map((i) => {
              'name': i.item.name,
              'quantity': i.quantity,
              'unit_price': i.item.price,
              'options': i.options.map((o) => o.name).toList(),
            }).toList(),
          });
        }
      } else if (intent == 'ORDER_ITEMS') {
        final parsedItems = parsed['items'] as List<dynamic>? ?? [];
        if (parsedItems.isNotEmpty) {
          final receipt = _geminiService.buildReceiptFromParsedJson(parsed);
          _latestReceipt = receipt;
          for (final newItem in receipt.items) {
            _cartItems.add(newItem);
          }
        }
      }
      // If intent is 'CONVERSATION' or 'INQUIRY', we do NOT modify _cartItems or _latestReceipt

      final botReply = parsed['customer_reply'] as String? ?? 'Hello! What would you like to order today?';
      final List<String> chips = [];
      if (intent == 'INQUIRY' || botReply.toLowerCase().contains('coffee type') || botReply.toLowerCase().contains('tipo de café') || botReply.toLowerCase().contains('recommend')) {
        chips.addAll([
          'Espresso',
          'Caffe Latte',
          'Americano',
          'Cappuccino',
          'Flat White',
          'Cold Brew',
        ]);
      }

      _messages.add(ChatMessage(
        sender: 'gemini',
        text: botReply,
        translatedReceiptPreview: parsed['staff_notes_english'] as String?,
        suggestionChips: chips,
      ));
    } catch (e) {
      _messages.add(ChatMessage(
        sender: 'gemini',
        text: 'Sorry, I had trouble parsing that. Please try again or tap an item.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _latestReceipt = null;
    notifyListeners();
  }
}
