import 'package:flutter_test/flutter_test.dart';
import 'package:egg_toeic/data/models/user_progress_model.dart';

void main() {
  group('UserProgress', () {
    test('should create initial user progress', () {
      final progress = UserProgress.initial();

      expect(progress.totalQuestionsAnswered, 0);
      expect(progress.correctAnswers, 0);
      expect(progress.currentStreak, 0);
      expect(progress.longestStreak, 0);
      expect(progress.experiencePoints, 0);
      expect(progress.userLevel, 1);
      expect(progress.lastStudyDate, isNotNull);
    });

    test('should calculate overall accuracy correctly', () {
      final progress = UserProgress(
        totalQuestionsAnswered: 100,
        correctAnswers: 75,
      );

      expect(progress.overallAccuracy, 75.0);
    });

    test('should handle zero questions answered', () {
      final progress = UserProgress(
        totalQuestionsAnswered: 0,
        correctAnswers: 0,
      );

      expect(progress.overallAccuracy, 0.0);
    });

    test('should calculate XP to next level correctly', () {
      final progress = UserProgress(
        userLevel: 5,
        experiencePoints: 250,
      );

      expect(progress.xpToNextLevel, 600);
    });

    test('should provide correct character type and emoji for different levels', () {
      final eggLevel = UserProgress(userLevel: 3);
      expect(eggLevel.characterType, 'Egg');
      expect(eggLevel.characterEmoji, '🥚');

      final chickLevel = UserProgress(userLevel: 8);
      expect(chickLevel.characterType, 'Chick');
      expect(chickLevel.characterEmoji, '🐣');

      final birdLevel = UserProgress(userLevel: 15);
      expect(birdLevel.characterType, 'Bird');
      expect(birdLevel.characterEmoji, '🐦');

      final eagleLevel = UserProgress(userLevel: 25);
      expect(eagleLevel.characterType, 'Eagle');
      expect(eagleLevel.characterEmoji, '🦅');

      final phoenixLevel = UserProgress(userLevel: 35);
      expect(phoenixLevel.characterType, 'Phoenix');
      expect(phoenixLevel.characterEmoji, '🔥');
    });
  });
}