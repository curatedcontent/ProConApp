import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'query_parser.dart';

class SpeechService {
  late stt.SpeechToText _speech;
  bool _available = false;
  bool _listening = false;
  Function(String)? _onResult;
  Function(String)? _onPartialResult;
  Function(QueryIntent)? _onVoiceTrigger;

  bool get isListening => _listening;
  bool get isAvailable => _available;

  Future<void> init() async {
    _speech = stt.SpeechToText();
    _available = await _speech.initialize(
      onError: (error) {
        print('Speech error: $error');
        // Don't treat temporary errors as failures
        if (error.permanent) {
          _listening = false;
        }
      },
      onStatus: (status) {
        _listening = status == 'listening';
        print('Speech status: $status');
      },
      debugLogging: true,
    );
    print('Speech available: $_available');
  }

  Future<bool> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    Function(QueryIntent)? onVoiceTrigger,
  }) async {
    if (!_available) {
      print('Speech not available, trying to reinitialize...');
      await init();
      if (!_available) return false;
    }

    if (_listening) {
      await stopListening();
    }

    _onResult = onResult;
    _onPartialResult = onPartialResult;
    _onVoiceTrigger = onVoiceTrigger;

    try {
      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          print('Speech recognized: "$text" (final: ${result.finalResult})');
          if (result.finalResult) {
            _onResult?.call(text);
            // Check for voice triggers
            final intent = QueryParser.parseQuery(text);
            if (intent != null && intent.intent == 'show_results') {
              _onVoiceTrigger?.call(intent);
            }
          } else {
            _onPartialResult?.call(text);
          }
        },
        listenFor: const Duration(minutes: 2), // Listen longer
        pauseFor: const Duration(seconds: 5), // Wait longer for pauses
        partialResults: true,
        localeId: 'en_US',
        listenMode: stt.ListenMode.dictation, // Better for continuous speech
        cancelOnError: false, // Don't cancel on temporary errors
        onSoundLevelChange: (level) {
          // Can use this for visual feedback
        },
      );
      _listening = true;
      return true;
    } catch (e) {
      print('Error starting speech recognition: $e');
      return false;
    }
  }

  Future<void> stopListening() async {
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }
  }

  Future<void> cancel() async {
    if (_listening) {
      await _speech.cancel();
      _listening = false;
    }
  }

  Future<List<stt.LocaleName>> get availableLocales async => _speech.locales();
}
