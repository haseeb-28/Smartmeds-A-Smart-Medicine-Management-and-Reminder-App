import 'package:flutter_tts/flutter_tts.dart';

/// Module 13's "Voice Feedback" — speaks short confirmations aloud when
/// Elderly Mode is on. Deliberately narrow scope: this speaks
/// confirmations for the few highest-value moments (dose taken/skipped,
/// medicine added) rather than trying to narrate the entire UI, which
/// would need a much larger screen-reader-style effort closer to full
/// platform accessibility support (TalkBack/VoiceOver) than a feature
/// this app can reasonably reimplement itself.
class VoiceFeedbackService {
  VoiceFeedbackService._();
  static final VoiceFeedbackService instance = VoiceFeedbackService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45); // slower than default — clarity over speed
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    await _ensureInitialized();
    await _tts.stop(); // don't queue/overlap if a previous phrase is still playing
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
