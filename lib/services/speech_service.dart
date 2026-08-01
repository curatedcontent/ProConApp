import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'query_parser.dart';

class SpeechService {
  late stt.SpeechToText _speech;
  bool _available = false;
  bool _listening = false;
  String? _lastError;
  Function(String)? _onResult;
  Function(String)? _onPartialResult;
  Function(QueryIntent)? _onVoiceTrigger;

  /// Fired for errors that happen mid-session (e.g. the browser denies
  /// microphone access after listening has already started).
  Function(String)? onError;

  bool get isListening => _listening;
  bool get isAvailable => _available;
  String? get lastError => _lastError;

  Future<void> init() async {
    _speech = stt.SpeechToText();
    try {
      _available = await _speech.initialize(
        onError: (error) {
          final message = _describeError(error.errorMsg);
          _lastError = message;
          if (error.permanent) {
            _listening = false;
          }
          onError?.call(message);
        },
        onStatus: (status) {
          _listening = status == 'listening';
        },
      );
    } catch (e) {
      _available = false;
    }
    if (!_available) {
      _lastError ??=
          "Voice input isn't supported in this browser. Try Chrome or Edge.";
    }
  }

  String _describeError(String errorMsg) {
    switch (errorMsg) {
      case 'error_no_permission':
      case 'error_permission_denied':
      case 'not-allowed':
        return 'Microphone access was denied. Please allow microphone access for this site (check your browser\'s address-bar/site settings) and try again.';
      case 'error_no_match':
        return "Didn't catch that - please try again.";
      case 'error_network':
        return 'Voice recognition needs an internet connection.';
      default:
        return 'Voice input error: $errorMsg';
    }
  }

  Future<bool> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    Function(QueryIntent)? onVoiceTrigger,
  }) async {
    _lastError = null;
    if (!_available) {
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
      );
      _listening = true;
      return true;
    } catch (e) {
      _lastError = 'Could not start listening: $e';
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
