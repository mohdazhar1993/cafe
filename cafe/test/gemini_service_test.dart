import 'package:flutter_test/flutter_test.dart';
import 'package:cafe_companion/services/gemini_service.dart';
import 'package:cafe_companion/models/order.dart';

void main() {
  group('GeminiService Order Parser & Multi-Language Tests', () {
    late GeminiService geminiService;

    setUp(() {
      // Instantiated without API key to test the deterministic parsing heuristics and schema builders
      geminiService = GeminiService();
    });

    test('Parses Spanish order with oat milk modifier and outputs English receipt', () async {
      final input = 'Quiero un café con leche con avena y sin azúcar por favor';
      final parsed = await geminiService.parseOrderInput(input);

      expect(parsed['detected_language'], equals('Spanish'));
      expect(parsed['intent'], equals('ORDER_ITEMS'));
      expect(parsed['items'], isNotEmpty);

      final firstItem = parsed['items'][0];
      expect(firstItem['name'], equals('Caffe Latte'));
      expect(firstItem['options'], contains('Oat Milk'));
      expect(firstItem['options'], contains('Sugar-Free'));

      // Verify consolidated dietary tags
      final dietaryTags = List<String>.from(parsed['consolidated_dietary_tags']);
      expect(dietaryTags, contains('Dairy-Free'));
      expect(dietaryTags, contains('Sugar-Free'));

      // Build OrderReceipt and verify English barista ticket
      final receipt = geminiService.buildReceiptFromParsedJson(parsed);
      expect(receipt.customerLanguage, equals('Spanish'));
      expect(receipt.items.first.item.name, equals('Caffe Latte'));
      expect(receipt.total, greaterThan(0));
    });

    test('Parses Japanese order for Matcha latte with oat milk', () async {
      final input = '抹茶ラテをオーツミルクでお願いします';
      final parsed = await geminiService.parseOrderInput(input);

      expect(parsed['detected_language'], equals('Japanese'));
      expect(parsed['customer_reply'], contains('ご注文を承りました'));

      final items = parsed['items'] as List<dynamic>;
      expect(items.first['name'], equals('Matcha Green Tea Latte'));
      expect(items.first['options'], contains('Oat Milk'));
    });

    test('Parses Hindi order for Masala Chai without sugar', () async {
      final input = 'मुझे एक मसाला चाय चाहिए बिना चीनी के';
      final parsed = await geminiService.parseOrderInput(input);

      expect(parsed['detected_language'], equals('Hindi'));
      expect(parsed['customer_reply'], contains('आपका ऑर्डर'));

      final items = parsed['items'] as List<dynamic>;
      expect(items.first['name'], equals('Spiced Chai Latte'));
      expect(items.first['options'], contains('Sugar-Free'));
    });

    test('Handles Thumbs-up gesture command to confirm order', () async {
      final input = 'Confirm and place my cafe order';
      final parsed = await geminiService.parseOrderInput(input);

      expect(parsed['intent'], equals('CONFIRM_ORDER'));
      expect(parsed['staff_notes_english'], contains('Order finalized'));
    });

    test('Handles Open palm gesture command to clear order', () async {
      final input = 'Clear current order and reset';
      final parsed = await geminiService.parseOrderInput(input);

      expect(parsed['intent'], equals('CLEAR_ORDER'));
      expect(parsed['items'], isEmpty);
    });

    test('Greeting "hello" returns CONVERSATION intent and does not add items', () async {
      final parsed = await geminiService.parseOrderInput('hello');

      expect(parsed['intent'], equals('CONVERSATION'));
      expect(parsed['items'], isEmpty);
      expect(parsed['customer_reply'], contains('What would you like to order today?'));
    });

    test('Greeting "hola" returns CONVERSATION intent with warm Spanish reply', () async {
      final parsed = await geminiService.parseOrderInput('hola');

      expect(parsed['detected_language'], equals('Spanish'));
      expect(parsed['intent'], equals('CONVERSATION'));
      expect(parsed['items'], isEmpty);
      expect(parsed['customer_reply'], contains('¿Qué le gustaría ordenar hoy?'));
    });

    test('Recommendation question "what do you recommend?" returns INQUIRY intent without adding items', () async {
      final parsed = await geminiService.parseOrderInput('what do you recommend?');

      expect(parsed['intent'], equals('INQUIRY'));
      expect(parsed['items'], isEmpty);
      expect(parsed['customer_reply'], contains('We recommend'));
    });

    test('Generic coffee request presents options list without adding items to cart', () async {
      final parsed = await geminiService.parseOrderInput('Hello, I would like a coffee');

      expect(parsed['intent'], equals('INQUIRY'));
      expect(parsed['items'], isEmpty);
      expect(parsed['customer_reply'], contains('Which coffee type would you prefer?'));
      expect(parsed['customer_reply'], contains('Espresso'));
      expect(parsed['customer_reply'], contains('Flat White'));
      expect(parsed['customer_reply'], contains('Cold Brew'));
    });

    test('Specific coffee selection "Make it a Flat White" explicitly adds item to cart', () async {
      final parsed = await geminiService.parseOrderInput('Make it a Flat White');

      expect(parsed['intent'], equals('ORDER_ITEMS'));
      expect(parsed['items'], isNotEmpty);
      expect(parsed['items'][0]['name'], equals('Flat White'));
      expect(parsed['items'][0]['unit_price'], equals(4.95));
    });

    test('Specific coffee selection "I would like an Americano" adds Americano to cart', () async {
      final parsed = await geminiService.parseOrderInput('I would like an Americano');

      expect(parsed['intent'], equals('ORDER_ITEMS'));
      expect(parsed['items'], isNotEmpty);
      expect(parsed['items'][0]['name'], equals('Americano'));
      expect(parsed['items'][0]['unit_price'], equals(3.75));
    });
  });
}
