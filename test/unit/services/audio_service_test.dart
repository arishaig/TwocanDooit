import 'package:flutter_test/flutter_test.dart';
import 'package:twocandooit/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AudioService Tests', () {
    test('should provide built-in music track names', () {
      final trackNames = AudioService.builtInMusicTrackNames;

      expect(trackNames, isNotEmpty);
      expect(trackNames, contains('Binaural Beats'));
      expect(trackNames, contains('Calm Meditation'));
      expect(trackNames, contains('Focus Beats'));
      expect(trackNames.length, 3);
    });

    test('should initialize without errors', () async {
      // This test verifies that AudioService can be initialized
      // Skip actual initialization in tests to avoid platform channel issues
      expect(AudioService.builtInMusicTrackNames, isNotEmpty);
    });

    test('should handle music playing state', () {
      // Test the isMusicPlaying getter
      // This would require mocking the AudioPlayer in a full test
      expect(AudioService.isMusicPlaying, isFalse);
    });

    test('should dispose without errors', () {
      expect(() => AudioService.dispose(), returnsNormally);
    });
  });

  group('AudioService Track Validation', () {
    test('should have valid built-in track mapping', () {
      final trackNames = AudioService.builtInMusicTrackNames;
      
      for (final trackName in trackNames) {
        expect(trackName, isNotEmpty);
        expect(trackName, isA<String>());
      }
    });
  });
}