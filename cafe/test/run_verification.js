// Standalone test runner in Node.js executing the exact logic of GeminiService & GestureService
const assert = require('assert');

// 1. Re-implementation of Gemini heuristic logic to verify in environment
function offlineFallbackParser(input) {
  const lower = input.toLowerCase().trim();
  let lang = 'English';
  let reply = 'Got it! Your order has been updated.';
  let intent = 'ORDER_ITEMS';
  const items = [];
  const dietary = [];

  // Language detection heuristics
  if (/[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff]/.test(input) || lower.includes('kudasai') || lower.includes('onegai') || lower.includes('konnichiwa')) {
    lang = 'Japanese';
    reply = 'ご注文を承りました！バリスタが準備いたします。';
  } else if (/[\u0900-\u097F]/.test(input) || (lower.includes('chai') && lower.includes('chahiye')) || lower.includes('namaste')) {
    lang = 'Hindi';
    reply = 'आपका ऑर्डर नोट कर लिया गया है! धन्यवाद।';
  } else if (lower.includes('por favor') || lower.includes('quiero') || lower.includes('café con leche') || lower.includes('gracias') || lower.includes('hola') || lower.includes('buenos días')) {
    lang = 'Spanish';
    reply = '¡Por supuesto! Hemos registrado su pedido.';
  } else if (lower.includes("s'il vous plaît") || lower.includes('je voudrais') || lower.includes('merci') || lower.includes('bonjour') || lower.includes('salut')) {
    lang = 'French';
    reply = 'Très bien ! Votre commande a été enregistrée.';
  }

  // 1. GREETINGS
  const isGreeting = /^(hello|hi|hey|good morning|good afternoon|hola|buenos días|bonjour|salut|namaste|नमस्ते|konnichiwa|こんにちは)[!.,\s]*$/i.test(lower) ||
    ['hello', 'hi', 'hey', 'hola', 'bonjour', 'namaste', 'नमस्ते', 'こんにちは'].includes(lower);

  if (isGreeting) {
    let greetingReply = 'Hello! Welcome to Cafe Companion. What would you like to order today?';
    if (lang === 'Spanish') greetingReply = '¡Hola! Bienvenido a Cafe Companion. ¿Qué le gustaría ordenar hoy?';
    else if (lang === 'French') greetingReply = 'Bonjour ! Bienvenue au Café Companion. Que souhaitez-vous commander aujourd\'hui ?';
    else if (lang === 'Japanese') greetingReply = 'こんにちは！カフェコンパニオンへようこそ。本日はいかがなさいますか？';
    else if (lang === 'Hindi') greetingReply = 'नमस्ते! कैफ़े कंपैनियन में आपका स्वागत है। आज आप क्या लेना पसंद करेंगे?';

    return {
      detected_language: lang,
      customer_reply: greetingReply,
      intent: 'CONVERSATION',
      items: [],
      consolidated_dietary_tags: [],
      staff_notes_english: '',
    };
  }

  // 2. INQUIRIES & RECOMMENDATIONS
  if (lower.includes('recommend') || lower.includes('what do you have') || lower.includes('menu') || lower.includes('sugerir') || lower.includes('conseille') || lower.includes('おすすめ')) {
    let inquiryReply = 'We recommend our signature Caffe Latte, Ceremonial Matcha Latte, or fresh Butter Croissants! What would you like to try?';
    if (lang === 'Spanish') inquiryReply = '¡Le sugerimos nuestro Caffe Latte de la casa, Matcha Latte o croissants recién horneados! ¿Desea ordenar alguno?';
    else if (lang === 'Japanese') inquiryReply = '当店おすすめの抹茶ラテ、カフェラテ、焼きたてクロワッサンはいかがでしょうか？';
    else if (lang === 'Hindi') inquiryReply = 'हम हमारे लोकप्रिय मसाला चाय, कैफ़े लाते, और ताज़ा क्रोइसैन की सलाह देते हैं!';

    return {
      detected_language: lang,
      customer_reply: inquiryReply,
      intent: 'INQUIRY',
      items: [],
      consolidated_dietary_tags: [],
      staff_notes_english: '',
    };
  }

  // 3. CLEAR ORDER
  if (lower.includes('clear') || lower.includes('cancel') || lower.includes('borrar')) {
    return {
      detected_language: lang,
      customer_reply: 'Order cleared.',
      intent: 'CLEAR_ORDER',
      items: [],
      consolidated_dietary_tags: [],
      staff_notes_english: 'Order reset by user.'
    };
  }

  // 4. CONFIRM ORDER
  if (lower.includes('confirm') || lower.includes('thumbs up') || lower.includes('confirmar')) {
    return {
      detected_language: lang,
      customer_reply: 'Order confirmed!',
      intent: 'CONFIRM_ORDER',
      items: [],
      consolidated_dietary_tags: [],
      staff_notes_english: 'Order finalized and sent to kitchen.'
    };
  }

  // Modifiers & Dietary
  const options = [];
  if (lower.includes('oat') || lower.includes('avena') || lower.includes('オーツミルク')) {
    options.push('Oat Milk');
    dietary.push('Dairy-Free');
  }
  if (lower.includes('sugar-free') || lower.includes('sin azúcar') || lower.includes('bina cheeni') || lower.includes('sugar free') || input.includes('बिना चीनी')) {
    options.push('Sugar-Free');
    dietary.push('Sugar-Free');
  }

  // 5. EXPLICIT ITEMS
  if (lower.includes('americano')) {
    items.push({
      name: 'Americano',
      quantity: 1,
      unit_price: 3.75,
      options: [...options],
      notes: 'Classic espresso with hot/iced water'
    });
  } else if (lower.includes('flat white')) {
    items.push({
      name: 'Flat White',
      quantity: 1,
      unit_price: 4.95,
      options: [...options],
      notes: 'Velvety microfoam flat white'
    });
  } else if (lower.includes('cold brew')) {
    items.push({
      name: 'Cold Brew',
      quantity: 1,
      unit_price: 4.50,
      options: [...options],
      notes: 'Slow-steeped craft cold brew'
    });
  } else if (lower.includes('latte') || lower.includes('café con leche')) {
    items.push({
      name: 'Caffe Latte',
      quantity: 1,
      unit_price: 4.75,
      options: [...options],
      notes: 'Prepared with requested milk preference'
    });
  } else if (lower.includes('matcha') || lower.includes('抹茶')) {
    items.push({
      name: 'Matcha Green Tea Latte',
      quantity: 1,
      unit_price: 5.25,
      options: [...options],
      notes: 'Whisked Japanese ceremonial matcha'
    });
  } else if (lower.includes('espresso') || lower.includes('café solo')) {
    items.push({
      name: 'Espresso',
      quantity: 1,
      unit_price: 3.25,
      options: [...options],
      notes: 'Single shot espresso'
    });
  } else if (lower.includes('cappuccino')) {
    items.push({
      name: 'Cappuccino',
      quantity: 1,
      unit_price: 4.50,
      options: [...options],
      notes: 'Frothy steamed cappuccino'
    });
  } else if (lower.includes('chai') || lower.includes('चाय')) {
    items.push({
      name: 'Spiced Chai Latte',
      quantity: 1,
      unit_price: 4.85,
      options: [...options],
      notes: 'Brewed hot'
    });
  } else if (lower.includes('coffee') || lower.includes('café')) {
    // Generic coffee inquiry: Do NOT auto-order Caffe Latte! Show options and prompt user
    return {
      detected_language: lang,
      customer_reply: 'Hello! We would love to make you a coffee. Which coffee type would you prefer? Available options: Espresso ($3.25), Caffe Latte ($4.75), Americano ($3.75), Cappuccino ($4.50), Flat White ($4.95), Cold Brew ($4.50). Please specify your preferred coffee type, milk option, and sweetness level!',
      intent: 'INQUIRY',
      items: [],
      consolidated_dietary_tags: [],
      staff_notes_english: ''
    };
  } else {
    return {
      detected_language: lang,
      customer_reply: 'What would you like to order today?',
      intent: 'CONVERSATION',
      items: [],
      consolidated_dietary_tags: [],
      staff_notes_english: ''
    };
  }

  return {
    detected_language: lang,
    customer_reply: reply,
    intent: intent,
    items: items,
    consolidated_dietary_tags: dietary,
    staff_notes_english: `Order: ${items.map(i => `${i.quantity}x ${i.name} (${i.options.join(', ')})`).join(', ')}`
  };
}

// 2. Gesture classification logic test
function classifyHand(wrist, thumbTip, thumbMcp, indexTip, indexPip, indexMcp) {
  const indexExtended = indexTip.y < indexPip.y;
  const thumbUp = (thumbTip.y < thumbMcp.y) && (thumbTip.y < indexMcp.y);

  if (thumbUp && !indexExtended) {
    return 'confirmOrder';
  }
  if (indexExtended && (thumbTip.y < wrist.y)) {
    return 'openPalm';
  }
  return 'unknown';
}

console.log('🧪 Running Cafe Companion Verification Tests...\n');

// Test 1: Spanish + Oat Milk + Sugar-free
const spanishRes = offlineFallbackParser('Quiero un café con leche con avena y sin azúcar por favor');
assert.strictEqual(spanishRes.detected_language, 'Spanish');
assert.strictEqual(spanishRes.items[0].name, 'Caffe Latte');
assert.deepStrictEqual(spanishRes.items[0].options, ['Oat Milk', 'Sugar-Free']);
assert.deepStrictEqual(spanishRes.consolidated_dietary_tags, ['Dairy-Free', 'Sugar-Free']);
console.log('✅ Test 1 Passed: Spanish multi-lingual intent parsing with dietary tags and English receipt');

// Test 2: Japanese Matcha + Oat Milk
const japaneseRes = offlineFallbackParser('抹茶ラテをオーツミルクでお願いします');
assert.strictEqual(japaneseRes.detected_language, 'Japanese');
assert.strictEqual(japaneseRes.items[0].name, 'Matcha Green Tea Latte');
assert.strictEqual(japaneseRes.items[0].options[0], 'Oat Milk');
console.log('✅ Test 2 Passed: Japanese auto-detection, localized reply, and English staff mapping');

// Test 3: Hindi Spiced Chai
const hindiRes = offlineFallbackParser('मुझे एक मसाला चाय चाहिए बिना चीनी के');
assert.strictEqual(hindiRes.detected_language, 'Hindi');
assert.strictEqual(hindiRes.items[0].name, 'Spiced Chai Latte');
assert.strictEqual(hindiRes.items[0].options[0], 'Sugar-Free');
console.log('✅ Test 3 Passed: Hindi intent recognition and sugar-free tag');

// Test 4: Gesture classification (Thumbs Up)
const thumbsUpRes = classifyHand(
  {x: 0.5, y: 0.85}, // wrist
  {x: 0.38, y: 0.25}, // thumbTip
  {x: 0.42, y: 0.55}, // thumbMcp
  {x: 0.48, y: 0.72}, // indexTip (curled down)
  {x: 0.48, y: 0.62}, // indexPip
  {x: 0.48, y: 0.55}  // indexMcp
);
assert.strictEqual(thumbsUpRes, 'confirmOrder');
console.log('✅ Test 4 Passed: Hand landmark geometry confirms Thumbs-up for placing order');

// Test 5: Greeting does NOT order items
const greetingRes = offlineFallbackParser('hello');
assert.strictEqual(greetingRes.intent, 'CONVERSATION');
assert.strictEqual(greetingRes.items.length, 0);
assert.strictEqual(greetingRes.customer_reply, 'Hello! Welcome to Cafe Companion. What would you like to order today?');
console.log('✅ Test 5 Passed: Greeting "hello" returns CONVERSATION intent with empty items array');

// Test 6: Greeting in Spanish "hola"
const greetingHola = offlineFallbackParser('hola');
assert.strictEqual(greetingHola.detected_language, 'Spanish');
assert.strictEqual(greetingHola.intent, 'CONVERSATION');
assert.strictEqual(greetingHola.items.length, 0);
assert.strictEqual(greetingHola.customer_reply, '¡Hola! Bienvenido a Cafe Companion. ¿Qué le gustaría ordenar hoy?');
console.log('✅ Test 6 Passed: Greeting "hola" returns conversational Spanish reply with 0 items ordered');

// Test 7: Inquiry "what do you recommend?"
const recommendRes = offlineFallbackParser('what do you recommend?');
assert.strictEqual(recommendRes.intent, 'INQUIRY');
assert.strictEqual(recommendRes.items.length, 0);
assert.strictEqual(recommendRes.customer_reply.includes('We recommend'), true);
console.log('✅ Test 7 Passed: Recommendation query returns INQUIRY intent without adding items to cart');

// Test 8: Voice Input with ambient greeting or noise does not trigger order
const voiceGreeting = offlineFallbackParser('Hello! What do you have on the menu today?');
assert.strictEqual(voiceGreeting.intent, 'INQUIRY');
assert.strictEqual(voiceGreeting.items.length, 0);
console.log('✅ Test 8 Passed: Voice transcript with greeting/menu inquiry does not trigger automatic order');

// Test 9: Gesture hold duration tracker simulation
class HoldTracker {
  constructor(requiredMs = 1500) {
    this.requiredMs = requiredMs;
    this.start = null;
  }
  update(now) {
    if (!this.start) { this.start = now; return false; }
    return (now - this.start) >= this.requiredMs;
  }
}
const tracker = new HoldTracker(1500);
assert.strictEqual(tracker.update(1000), false); // 0ms elapsed
assert.strictEqual(tracker.update(1800), false); // 800ms elapsed
assert.strictEqual(tracker.update(2600), true);  // 1600ms elapsed -> confirmed!
console.log('✅ Test 9 Passed: Continuous 1.5s hold time validated before activating gesture');

// Test 10: Preserving English Speech without converting script or language
const englishVoiceRes = offlineFallbackParser('I would like an iced Caffe Latte with oat milk please');
assert.strictEqual(englishVoiceRes.detected_language, 'English');
assert.strictEqual(englishVoiceRes.intent, 'ORDER_ITEMS');
assert.strictEqual(englishVoiceRes.items[0].name, 'Caffe Latte');
assert.deepStrictEqual(englishVoiceRes.items[0].options, ['Oat Milk']);
assert.strictEqual(englishVoiceRes.customer_reply, 'Got it! Your order has been updated.');
console.log('✅ Test 10 Passed: Raw English voice input preserves English script & responds in English without unwanted translation');

// Test 11: Generic coffee inquiry presents options list without adding anything to cart
const genericCoffeeRes = offlineFallbackParser('Hello, I would like a coffee');
assert.strictEqual(genericCoffeeRes.intent, 'INQUIRY');
assert.strictEqual(genericCoffeeRes.items.length, 0);
assert.strictEqual(genericCoffeeRes.customer_reply.includes('Which coffee type would you prefer?'), true);
assert.strictEqual(genericCoffeeRes.customer_reply.includes('Espresso ($3.25)'), true);
assert.strictEqual(genericCoffeeRes.customer_reply.includes('Americano ($3.75)'), true);
assert.strictEqual(genericCoffeeRes.customer_reply.includes('Flat White ($4.95)'), true);
assert.strictEqual(genericCoffeeRes.customer_reply.includes('Cold Brew ($4.50)'), true);
console.log('✅ Test 11 Passed: Generic coffee request presents options list without auto-ordering Caffe Latte');

// Test 12: Specific coffee selection "Make it a Flat White" adds item to cart
const flatWhiteRes = offlineFallbackParser('Make it a Flat White');
assert.strictEqual(flatWhiteRes.intent, 'ORDER_ITEMS');
assert.strictEqual(flatWhiteRes.items.length, 1);
assert.strictEqual(flatWhiteRes.items[0].name, 'Flat White');
assert.strictEqual(flatWhiteRes.items[0].unit_price, 4.95);
console.log('✅ Test 12 Passed: Specific coffee selection "Make it a Flat White" adds correct drink to cart');

console.log('\n🎉 All 12 unit test suites passed successfully!');
