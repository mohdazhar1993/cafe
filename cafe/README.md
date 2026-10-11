# Cafe Companion - Smarter Ordering Module

A cross-platform Flutter application built with Google Cloud & AI services to enable non-speaking, hard-of-hearing, and multi-lingual cafe guests to order seamlessly via **Text**, **Voice**, and **Hand Signs / Gestures**.

---

## 🚀 Key Features

1. **Multi-lingual AI Parsing (Gemini 1.5/2.0 via `google_generative_ai`)**:
   - Auto-detects input language (Spanish, Hindi, Japanese, French, Arabic, German, English, etc.).
   - Generates natural, empathetic responses in the customer's native language.
   - Outputs standardized English tickets for kitchen and barista staff with consolidated dietary tags (`Vegan`, `Dairy-Free`, `Sugar-Free`, `Gluten-Free`).

2. **Google ML Kit Hand & Pose Landmark Detection**:
   - Camera-based gesture classification:
     - 👍 **Thumbs Up**: Confirm and place order.
     - ✋ **Open Palm**: Clear / reset order.
     - ☝️ **Index Finger ("1")**: Order Coffee.
     - ✌️ **Peace / Two Fingers ("2")**: Order Tea.
     - 👌 **OK / "O" Sign**: Oat Milk modifier.
     - ✊ **Closed Fist**: Sugar-free modifier.
     - 🤏 **Pinch**: Less sweetness / size option.

3. **Accessible UI**:
   - 3 mode toggles: `[Text Chat]`, `[Voice Input]`, `[Hand Signs]`.
   - Live visual confirmation card with real-time tax calculation and dietary tags.
   - Dual-view receipt dialog: Customer Native Language + Standard English Barista Ticket.

---

## 📁 Clean Architecture Directory Structure

```
c:\Users\mohda\Downloads\cafe\
├── pubspec.yaml                                # Dependencies: google_generative_ai, camera, mlkit, provider
├── lib/
│   ├── main.dart                              # Application bootstrap with MultiProvider & Material 3 Theme
│   ├── models/
│   │   ├── menu_item.dart                     # MenuItem model and cafe catalog
│   │   ├── order.dart                         # OrderItem, OrderOption, and OrderReceipt models
│   │   └── gesture_action.dart                # GestureActionType enum & DetectedGesture model
│   ├── services/
│   │   ├── gemini_service.dart                # Gemini API multi-language auto-detection & receipt builder
│   │   └── gesture_service.dart               # Landmark classification engine (Thumbs-up, Palm, Shapes)
│   ├── state/
│   │   └── order_provider.dart                # Central state manager for cart, modes, totals, and receipts
│   ├── screens/
│   │   ├── smarter_order_screen.dart          # Accessibility ordering kiosk screen
│   │   └── sign_language_screen.dart          # Camera HUD with live landmark skeleton overlay
│   └── widgets/
│       ├── landmark_painter.dart              # CustomPainter for 21-point hand skeleton rendering
│       ├── order_summary_card.dart            # Confirmation card with dietary tags, subtotal, and total
│       ├── order_receipt_modal.dart           # Dual Customer & English Barista ticket modal
│       ├── quick_sign_legend.dart             # Accessible gesture quick-reference bar
│       └── chat_bubble.dart                   # Multi-lingual chat bubble with staff note preview
├── test/
│   ├── gemini_service_test.dart               # Flutter test suite for multi-lingual intent parsing
│   ├── gesture_service_test.dart              # Flutter test suite for landmark geometry recognition
│   └── run_verification.js                   # Node test runner for verification of parsing & geometry
└── web/
    ├── index.html                             # Web client for Chrome testing
    └── server.js                              # Local test server (http://localhost:8080)
```

---

## 🧪 Running Unit Tests

Run the verification test suite:

```powershell
node test\run_verification.js
```

Or when Flutter CLI is installed on PATH:

```powershell
flutter test test/gemini_service_test.dart test/gesture_service_test.dart
```

---

## 📱 Running the App

### Option A: Local Chrome Preview
```powershell
node web\server.js
# Open http://localhost:8080 in Google Chrome
```

### Option B: Flutter App (Mobile / Desktop / Web)
```powershell
flutter pub get
flutter run -d chrome
# or
flutter run -d emulator
```
