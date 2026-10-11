import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/order_provider.dart';
import 'services/gemini_service.dart';
import 'screens/smarter_order_screen.dart';

void main() {
  runApp(const CafeCompanionApp());
}

class CafeCompanionApp extends StatelessWidget {
  const CafeCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => OrderProvider(
            // When running in production, inject apiKey via const String.fromEnvironment('GEMINI_API_KEY')
            geminiService: GeminiService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Cafe Companion - Smarter Ordering',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6F4E37), // Coffee warm tone
            primary: const Color(0xFF5D4037),
            secondary: const Color(0xFF8D6E63),
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const SmarterOrderScreen(),
      ),
    );
  }
}
