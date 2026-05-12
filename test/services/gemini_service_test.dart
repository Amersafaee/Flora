// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_conservatory/services/gemini_service.dart';

void main() {
  group('Gemini Service Tests', () {
    test('GeminiService can be instantiated without throwing', () {
      expect(() => GeminiService(), returnsNormally);
    });

    test('API key is not empty and not equal to the placeholder "PASTE_YOUR_KEY_HERE"', () {
      expect(GeminiService.geminiApiKey, isNotEmpty);
      expect(GeminiService.geminiApiKey, isNot('PASTE_YOUR_KEY_HERE'));
    });

    test('Model name is set to a non-empty string', () {
      final service = GeminiService();
      expect(service.modelName, isNotEmpty);
    });

    test('Integration: askFlora with a simple message', () async {
      final service = GeminiService();
      final response = await service.askFlora([], 'Reply with exactly the word PONG and nothing else');
      print('Flora response: $response');
      expect(response, isNotEmpty);
      expect(response.toLowerCase(), contains('pong'));
    }, tags: ['integration']);
  });
}
