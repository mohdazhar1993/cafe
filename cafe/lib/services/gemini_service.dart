import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/order.dart';

/// Gemini AI Service responsible for:
/// 1. Auto-detecting customer language (Spanish, Hindi, Japanese, French, etc.)
/// 2. Parsing intent (items, quantities, dietary needs, modifiers)
/// 3. Responding in the customer's native language with natural empathy
/// 4. Outputting a standardized English order receipt for kitchen & barista staff
class GeminiService {
  final String? apiKey;
  GenerativeModel? _model;

  GeminiService({this.apiKey}) {
    if (apiKey != null && apiKey!.isNotEmpty) {
      _initModel();
    }
  }

  void _initModel() {
    final systemInstruction = '''
You are the intelligent ordering assistant for "Cafe Companion", an inclusive cafe kiosk designed for non-speaking, hard-of-hearing, and multi-lingual guests.

CRITICAL INSTRUCTIONS:
1. PRESERVE INPUT LANGUAGE & AUTO-DETECTION:
   - If the user speaks or writes in ENGLISH, YOU MUST TRANSCRIBE AND RESPOND IN ENGLISH. NEVER convert English text, script, or phrases into another language.
   - Only switch output language if explicit non-English speech or text (e.g., Spanish, Hindi, Japanese, French, German) is distinctly recognized.
   - ALWAYS reply in the exact detected language of the user.
2. MAINTAIN A TRUE CONVERSATIONAL CONTEXT:
   - If the user says a greeting (e.g., "hello", "hi", "hey", "hola", "bonjour", "namaste", "konnichiwa"), reply warmly in that language and ask what they would like to order today (intent: "CONVERSATION").
   - When the user asks generally for coffee (e.g., "Hello, I would like a coffee", "What coffee do you have?", "I want a coffee", "Quiero un café", "coffee please"):
     * DO NOT place an order or add anything to the cart automatically (items MUST be empty []).
     * Set intent: "INQUIRY".
     * Reply conversationally with a friendly greeting and present a clear, formatted list of available coffee options:
       - Espresso (\$3.25)
       - Caffe Latte (\$4.75)
       - Americano (\$3.75)
       - Cappuccino (\$4.50)
       - Flat White (\$4.95)
       - Cold Brew (\$4.50)
     * Prompt the user to specify which coffee type, milk option (whole, oat, almond), and sweetness level (regular, low sugar, sugar-free) they prefer.
   - If the user asks a question or asks for recommendations (e.g. "what do you recommend?", "¿qué me recomiendas?"), answer helpfully with suggestions from the menu (intent: "INQUIRY").
   - ONLY set intent to "ORDER_ITEMS" and include items in the "items" list if the user EXPLICITLY specifies the exact coffee drink they want to order (e.g., "I'll take an Iced Americano", "Make it a Flat White", "Give me an Espresso", "Order a Caffe Latte with oat milk").
   - NEVER automatically add default items or assume an order on general coffee requests, greetings, or questions. The "items" list MUST be empty [] unless a specific drink type is named.
3. If the user explicitly confirms or places the order (e.g. "confirm order", "thumbs up", "place order"), set intent: "CONFIRM_ORDER".
4. If the user asks to clear or cancel (e.g. "clear order", "reset cart", "cancel"), set intent: "CLEAR_ORDER".
5. When items ARE ordered, extract them into a standardized English JSON receipt for the barista team, including options (Oat Milk, Sugar-Free, etc.) and dietary tags.
6. You MUST return ONLY valid, raw JSON matching this schema:
{
  "detected_language": "<Language Name>",
  "customer_reply": "<Warm reply in customer's exact language>",
  "intent": "<CONVERSATION | INQUIRY | ORDER_ITEMS | CONFIRM_ORDER | CLEAR_ORDER>",
  "items": [
    {
      "name": "<Standard English Item Name: Caffe Latte, Matcha Green Tea Latte, Espresso, Earl Grey Tea, Spiced Chai Latte, Butter Croissant, Blueberry Oat Muffin>",
      "quantity": 1,
      "unit_price": 4.75,
      "options": ["Oat Milk", "Sugar-Free"],
      "notes": "Barista note in English"
    }
  ],
  "consolidated_dietary_tags": ["Vegan", "Sugar-Free", "Gluten-Free", "Dairy-Free"],
  "staff_notes_english": "<English note for barista, or empty if conversational>"
}
Do NOT include markdown formatting quotes like ```json in your response, output pure JSON.
''';

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey!,
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );
  }

  /// Parses user order input (spoken transcript, typed text, or gesture description).
  Future<Map<String, dynamic>> parseOrderInput(String userInput) async {
    if (_model == null) {
      // Offline fallback heuristic parser for testing and development
      return _offlineFallbackParser(userInput);
    }

    try {
      final response = await _model!.generateContent([Content.text(userInput)]);
      final rawText = response.text?.trim() ?? '{}';
      final cleanJson = rawText.replaceAll(RegExp(r'^```json\s*|\s*```$'), '');
      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      // Graceful fallback if network fails
      return _offlineFallbackParser(userInput);
    }
  }

  /// Converts parsed response into an application [OrderReceipt]
  OrderReceipt buildReceiptFromParsedJson(Map<String, dynamic> parsed, {String? orderId}) {
    final itemsList = (parsed['items'] as List<dynamic>? ?? [])
        .map((item) => OrderItem.fromParsedJson(item as Map<String, dynamic>))
        .toList();

    final subtotal = itemsList.fold<double>(0.0, (sum, i) => sum + i.totalPrice);
    final tax = subtotal * 0.0825; // 8.25% sales tax
    final total = subtotal + tax;

    return OrderReceipt(
      orderId: orderId ?? 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      items: itemsList,
      subtotal: subtotal,
      tax: tax,
      total: total,
      customerLanguage: parsed['detected_language'] as String? ?? 'English',
      customerReply: parsed['customer_reply'] as String? ?? 'Thank you for your order!',
      staffNotesEnglish: parsed['staff_notes_english'] as String? ?? 'Order received.',
      consolidatedDietaryTags: List<String>.from(parsed['consolidated_dietary_tags'] ?? []),
    );
  }

  /// Deterministic local heuristic parser for unit tests, offline operation, and demo modes
  Map<String, dynamic> _offlineFallbackParser(String input) {
    final lower = input.toLowerCase().trim();
    String lang = 'English';
    String reply = 'Got it! Your order has been updated.';
    String intent = 'ORDER_ITEMS';
    final List<Map<String, dynamic>> items = [];
    final List<String> dietary = [];

    // Language detection heuristics
    if (RegExp(r'[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff]').hasMatch(input) || lower.contains('kudasai') || lower.contains('onegai') || lower.contains('konnichiwa')) {
      lang = 'Japanese';
      reply = 'ご注文を承りました！バリスタが準備いたします。';
    } else if (RegExp(r'[\u0900-\u097F]').hasMatch(input) || (lower.contains('chai') && lower.contains('chahiye')) || lower.contains('namaste')) {
      lang = 'Hindi';
      reply = 'आपका ऑर्डर नोट कर लिया गया है! धन्यवाद।';
    } else if (lower.contains('por favor') || lower.contains('quiero') || lower.contains('café con leche') || lower.contains('gracias') || lower.contains('hola') || lower.contains('buenos días')) {
      lang = 'Spanish';
      reply = '¡Por supuesto! Hemos registrado su pedido.';
    } else if (lower.contains('s\'il vous plaît') || lower.contains('je voudrais') || lower.contains('merci') || lower.contains('bonjour') || lower.contains('salut')) {
      lang = 'French';
      reply = 'Très bien ! Votre commande a été enregistrée.';
    }

    // 1. GREETINGS: Maintain true conversational context
    final isGreeting = RegExp(r'^(hello|hi|hey|good morning|good afternoon|hola|buenos días|bonjour|salut|namaste|नमस्ते|konnichiwa|こんにちは)[!.,\s]*$').hasMatch(lower) ||
        lower == 'hello' || lower == 'hi' || lower == 'hey' || lower == 'hola' || lower == 'bonjour' || lower == 'नमस्ते' || lower == 'こんにちは';

    if (isGreeting) {
      String greetingReply = 'Hello! Welcome to Cafe Companion. What would you like to order today?';
      if (lang == 'Spanish') {
        greetingReply = '¡Hola! Bienvenido a Cafe Companion. ¿Qué le gustaría ordenar hoy?';
      } else if (lang == 'French') {
        greetingReply = 'Bonjour ! Bienvenue au Café Companion. Que souhaitez-vous commander aujourd\'hui ?';
      } else if (lang == 'Japanese') {
        greetingReply = 'こんにちは！カフェコンパニオンへようこそ。本日はいかがなさいますか？';
      } else if (lang == 'Hindi') {
        greetingReply = 'नमस्ते! कैफ़े कंपैनियन में आपका स्वागत है। आज आप क्या लेना पसंद करेंगे?';
      }

      return {
        'detected_language': lang,
        'customer_reply': greetingReply,
        'intent': 'CONVERSATION',
        'items': <Map<String, dynamic>>[],
        'consolidated_dietary_tags': <String>[],
        'staff_notes_english': '',
      };
    }

    // 2. INQUIRIES & RECOMMENDATIONS
    if (lower.contains('recommend') || lower.contains('what do you have') || lower.contains('menu') || lower.contains('sugerir') || lower.contains('conseille') || lower.contains('おすすめ')) {
      String inquiryReply = 'We recommend our signature Caffe Latte, Ceremonial Matcha Latte, or fresh Butter Croissants! Would you like to try any of these?';
      if (lang == 'Spanish') {
        inquiryReply = '¡Le sugerimos nuestro Caffe Latte de la casa, Matcha Latte o croissants recién horneados! ¿Desea ordenar alguno?';
      } else if (lang == 'Japanese') {
        inquiryReply = '当店おすすめの抹茶ラテ、カフェラテ、焼きたてクロワッサンはいかがでしょうか？';
      } else if (lang == 'Hindi') {
        inquiryReply = 'हम हमारे लोकप्रिय मसाला चाय, कैफ़े लाते, और ताज़ा क्रोइसैन की सलाह देते हैं!';
      }

      return {
        'detected_language': lang,
        'customer_reply': inquiryReply,
        'intent': 'INQUIRY',
        'items': <Map<String, dynamic>>[],
        'consolidated_dietary_tags': <String>[],
        'staff_notes_english': '',
      };
    }

    // 3. CLEAR / RESET ORDER
    if (lower.contains('clear') || lower.contains('cancel') || lower.contains('borrar') || lower.contains('rétablir')) {
      return {
        'detected_language': lang,
        'customer_reply': lang == 'Spanish' ? 'Pedido cancelado.' : (lang == 'Japanese' ? '注文をクリアしました。' : 'Order cleared.'),
        'intent': 'CLEAR_ORDER',
        'items': <Map<String, dynamic>>[],
        'consolidated_dietary_tags': <String>[],
        'staff_notes_english': 'Order reset by user.',
      };
    }

    // 4. CONFIRM ORDER
    if (lower.contains('confirm') || lower.contains('thumbs up') || lower.contains('confirmar') || lower.contains('kakutei') || lower.contains('place order')) {
      return {
        'detected_language': lang,
        'customer_reply': lang == 'Spanish' ? '¡Pedido confirmado! En preparación.' : (lang == 'Japanese' ? '注文が確定しました！' : 'Order confirmed!'),
        'intent': 'CONFIRM_ORDER',
        'items': <Map<String, dynamic>>[],
        'consolidated_dietary_tags': <String>[],
        'staff_notes_english': 'Order finalized and sent to kitchen.',
      };
    }

    // Modifiers & Dietary detection
    final List<String> options = [];
    if (lower.contains('oat') || lower.contains('avena') || lower.contains('oat milk') || lower.contains('オーツミルク')) {
      options.add('Oat Milk');
      dietary.add('Dairy-Free');
    }
    if (lower.contains('sugar-free') || lower.contains('sin azúcar') || lower.contains('bina cheeni') || input.contains('बिना चीनी') || lower.contains('sugar free') || lower.contains('sans sucre') || lower.contains('砂糖なし')) {
      options.add('Sugar-Free');
      dietary.add('Sugar-Free');
    }

    // 5. EXPLICIT ITEM MATCHING ONLY
    if (lower.contains('americano')) {
      items.add({
        'name': 'Americano',
        'quantity': 1,
        'unit_price': 3.75,
        'options': List<String>.from(options),
        'notes': 'Classic espresso with hot/iced water',
      });
    } else if (lower.contains('flat white')) {
      items.add({
        'name': 'Flat White',
        'quantity': 1,
        'unit_price': 4.95,
        'options': List<String>.from(options),
        'notes': 'Velvety microfoam flat white',
      });
    } else if (lower.contains('cold brew')) {
      items.add({
        'name': 'Cold Brew',
        'quantity': 1,
        'unit_price': 4.50,
        'options': List<String>.from(options),
        'notes': 'Slow-steeped craft cold brew',
      });
    } else if (lower.contains('latte') || lower.contains('café con leche') || lower.contains('caffe latte') || lower.contains('カフェラテ')) {
      items.add({
        'name': 'Caffe Latte',
        'quantity': 1,
        'unit_price': 4.75,
        'options': List<String>.from(options),
        'notes': 'Prepared with requested milk preference',
      });
    } else if (lower.contains('matcha') || lower.contains('抹茶')) {
      items.add({
        'name': 'Matcha Green Tea Latte',
        'quantity': 1,
        'unit_price': 5.25,
        'options': List<String>.from(options),
        'notes': 'Whisked Japanese ceremonial matcha',
      });
    } else if (lower.contains('espresso') || lower.contains('café solo')) {
      items.add({
        'name': 'Espresso',
        'quantity': 1,
        'unit_price': 3.25,
        'options': List<String>.from(options),
        'notes': 'Single shot espresso',
      });
    } else if (lower.contains('cappuccino')) {
      items.add({
        'name': 'Cappuccino',
        'quantity': 1,
        'unit_price': 4.50,
        'options': List<String>.from(options),
        'notes': 'Frothy steamed cappuccino',
      });
    } else if (lower.contains('tea') || lower.contains('té') || lower.contains('chai') || lower.contains('चाय') || lower.contains('お茶')) {
      items.add({
        'name': lower.contains('chai') || lower.contains('चाय') ? 'Spiced Chai Latte' : 'Earl Grey Tea',
        'quantity': 1,
        'unit_price': lower.contains('chai') ? 4.85 : 3.75,
        'options': List<String>.from(options),
        'notes': 'Brewed hot',
      });
    } else if (lower.contains('croissant')) {
      items.add({
        'name': 'Butter Croissant',
        'quantity': 1,
        'unit_price': 3.95,
        'options': <String>[],
        'notes': 'Warmed up',
      });
    } else if (lower.contains('muffin')) {
      items.add({
        'name': 'Blueberry Oat Muffin',
        'quantity': 1,
        'unit_price': 4.25,
        'options': <String>[],
        'notes': 'Bakery item',
      });
    } else if (lower.contains('coffee') || lower.contains('café') || lower.contains('コーヒー')) {
      // General coffee request: DO NOT place an order or add anything to cart!
      // Return friendly formatted options list and prompt user to specify
      String coffeeOptionsReply =
          'Hello! We would love to make you a coffee. Which coffee type would you prefer?\n\n'
          '• Espresso (\$3.25)\n'
          '• Caffe Latte (\$4.75)\n'
          '• Americano (\$3.75)\n'
          '• Cappuccino (\$4.50)\n'
          '• Flat White (\$4.95)\n'
          '• Cold Brew (\$4.50)\n\n'
          'Please specify your preferred coffee type, milk option (whole/oat/almond), and sweetness level!';
      if (lang == 'Spanish') {
        coffeeOptionsReply =
            '¡Hola! Con mucho gusto le preparamos un café. ¿Cuál tipo prefiere?\n\n'
            '• Espresso (\$3.25)\n'
            '• Caffe Latte (\$4.75)\n'
            '• Americano (\$3.75)\n'
            '• Cappuccino (\$4.50)\n'
            '• Flat White (\$4.95)\n'
            '• Cold Brew (\$4.50)\n\n'
            '¡Por favor especifique el tipo de café, tipo de leche y nivel de azúcar!';
      } else if (lang == 'Japanese') {
        coffeeOptionsReply =
            'こんにちは！喜んでコーヒーをご用意いたします。どのコーヒーがよろしいですか？\n\n'
            '• エスプレッソ (\$3.25)\n'
            '• カフェラテ (\$4.75)\n'
            '• アメリカーノ (\$3.75)\n'
            '• カプチーノ (\$4.50)\n'
            '• フラットホワイト (\$4.95)\n'
            '• コールドブリュー (\$4.50)\n\n'
            'ご希望の種類、ミルクの変更、甘さをお知らせください！';
      }

      return {
        'detected_language': lang,
        'customer_reply': coffeeOptionsReply,
        'intent': 'INQUIRY',
        'items': <Map<String, dynamic>>[],
        'consolidated_dietary_tags': <String>[],
        'staff_notes_english': '',
      };
    } else {
      // General conversational phrase without any menu item named
      return {
        'detected_language': lang,
        'customer_reply': 'I hear you! What beverage or snack would you like to order from our menu?',
        'intent': 'CONVERSATION',
        'items': <Map<String, dynamic>>[],
        'consolidated_dietary_tags': <String>[],
        'staff_notes_english': '',
      };
    }

    return {
      'detected_language': lang,
      'customer_reply': reply,
      'intent': intent,
      'items': items,
      'consolidated_dietary_tags': dietary,
      'staff_notes_english': 'Order: ${items.map((i) => "${i['quantity']}x ${i['name']} (${(i['options'] as List).join(', ')})").join(', ')}',
    };
  }
}
