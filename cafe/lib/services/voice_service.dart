import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/order.dart';
import 'gemini_service.dart';

/// Service responsible for Voice Input and Speech-to-Text transcription.
/// Ensures that raw speech transcripts are NEVER directly added as orders,
/// but are passed through Gemini's conversational intent parser first.
class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final GeminiService _geminiService;

  bool _isAvailable = false;
  bool _isListening = false;
  String _lastTranscribedWords = '';

  bool get isListening => _isListening;
  String get lastTranscribedWords => _lastTranscribedWords;

  VoiceService({GeminiService? geminiService})
      : _geminiService = geminiService ?? GeminiService();

  /// Initialize microphone permissions and STT engine
  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) => debugPrint('STT Error: $val'),
        onStatus: (val) => debugPrint('STT Status: $val'),
      );
    } catch (e) {
      _isAvailable = false;
    }
    return _isAvailable;
  }

  /// Start listening to user voice.
  /// Explicitly defaults listening locale to system locale or 'en_US'.
  /// Does NOT force foreign translation on English input.
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    String? localeId,
  }) async {
    if (_isListening) return;

    if (!_isAvailable) {
      await initialize();
    }

    if (_isAvailable) {
      _isListening = true;
      _lastTranscribedWords = '';

      // Determine appropriate listening locale: prefer provided or system locale, default to 'en_US'
      String targetLocale = localeId ?? 'en_US';
      try {
        final systemLocale = await _speech.systemLocale();
        if (localeId == null && systemLocale != null && systemLocale.localeId.isNotEmpty) {
          targetLocale = systemLocale.localeId;
        }
      } catch (_) {
        targetLocale = 'en_US';
      }

      await _speech.listen(
        localeId: targetLocale,
        onResult: (result) {
          // Preserve the exact transcribed text string from SpeechToText
          _lastTranscribedWords = result.recognizedWords;
          onResult(result.recognizedWords, result.finalResult);
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  /// Stop microphone listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Parse the transcribed voice transcript strictly through Gemini.
  /// Only returns parsed items if Gemini explicitly detects menu item keywords.
  /// Greetings like "hello" or sounds return intent: "CONVERSATION" with 0 items.
  Future<Map<String, dynamic>> parseVoiceTranscript(String transcript) async {
    final cleaned = transcript.trim();
    if (cleaned.isEmpty) {
      return {
        'detected_language': 'English',
        'customer_reply': 'I did not catch that. Please speak or tap to order.',
        'intent': 'CONVERSATION',
        'items': <Map<String, dynamic>>[],
        'consolidated_dietary_tags': <String>[],
        'staff_notes_english': '',
      };
    }

    return await _geminiService.parseOrderInput(cleaned);
  }
}
