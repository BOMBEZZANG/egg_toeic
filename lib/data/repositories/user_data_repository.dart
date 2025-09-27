import 'package:hive_flutter/hive_flutter.dart';
import 'package:egg_toeic/core/constants/hive_constants.dart';
import 'package:egg_toeic/data/models/user_progress_model.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/learning_session_model.dart';
import 'package:egg_toeic/data/models/achievement_model.dart';
import 'package:egg_toeic/data/repositories/base_repository.dart';

abstract class UserDataRepository extends BaseRepository {
  // User Progress
  Future<UserProgress> getUserProgress();
  Future<void> updateUserProgress(UserProgress progress);
  Future<void> incrementStreak();
  Future<void> addExperience(int xp);
  Future<void> incrementTotalQuestions({required bool isCorrect});

  // Wrong Answers
  Future<List<WrongAnswer>> getWrongAnswers();
  Future<void> addWrongAnswer(WrongAnswer wrongAnswer);
  Future<void> removeWrongAnswer(String wrongAnswerId);
  Future<void> markWrongAnswerAsResolved(String wrongAnswerId);
  Future<List<WrongAnswer>> getWrongAnswersNeedingReview();

  // Learning Sessions
  Future<List<LearningSession>> getLearningSessions();
  Future<LearningSession?> getCurrentSession();
  Future<void> startNewSession({int? difficultyLevel, String? sessionType});
  Future<void> endCurrentSession();
  Future<void> updateCurrentSession({
    int? questionsAnswered,
    int? correctAnswers,
    String? questionId,
    String? wrongAnswerId,
  });

  // Favorites
  Future<List<String>> getFavoriteQuestions();
  Future<void> toggleFavorite(String questionId);
  Future<bool> isFavorite(String questionId);

  // Achievements
  Future<List<Achievement>> getAchievements();
  Future<void> updateAchievement(Achievement achievement);
  Future<List<Achievement>> checkForNewAchievements();

  // Question Results
  Future<void> updateQuestionResult({
    required String questionId,
    required bool isCorrect,
    required int answerTime,
    required String mode,
  });
}

class UserDataRepositoryImpl implements UserDataRepository {
  Box<dynamic>? _progressBox;
  Box<dynamic>? _wrongAnswersBox;
  Box<dynamic>? _sessionsBox;
  Box<dynamic>? _favoritesBox;
  Box<dynamic>? _achievementsBox;

  LearningSession? _currentSession;

  // Fallback in-memory storage for when Hive fails
  UserProgress _userProgress = UserProgress.initial();
  List<WrongAnswer> _wrongAnswers = [];
  List<LearningSession> _sessions = [];
  List<String> _favorites = [];
  List<Achievement> _achievements = Achievement.getDefaultAchievements();

  bool _hiveInitialized = false;

  @override
  Future<void> initialize() async {
    try {
      await Hive.initFlutter();

      // Open boxes using JSON serialization for now
      _progressBox = await Hive.openBox<dynamic>(HiveConstants.userProgressBox);
      _wrongAnswersBox = await Hive.openBox<dynamic>(HiveConstants.wrongAnswersBox);
      _sessionsBox = await Hive.openBox<dynamic>(HiveConstants.sessionsBox);
      _favoritesBox = await Hive.openBox<dynamic>(HiveConstants.favoritesBox);
      _achievementsBox = await Hive.openBox<dynamic>('achievements_box');

      // Load existing data from Hive or initialize with defaults
      await _loadFromHive();

      _hiveInitialized = true;
      print('✅ Hive storage initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Hive storage: $e');
      print('📝 Using in-memory storage as fallback');
      _hiveInitialized = false;
    }
  }

  Future<void> _loadFromHive() async {
    try {
      // Load user progress
      final progressJson = _progressBox?.get('progress');
      if (progressJson != null) {
        _userProgress = UserProgress.fromJson(Map<String, dynamic>.from(progressJson));
      } else {
        _userProgress = UserProgress.initial();
        await _saveUserProgressToHive();
      }

      // Load wrong answers
      final wrongAnswersJson = _wrongAnswersBox?.get('wrongAnswers');
      if (wrongAnswersJson != null && wrongAnswersJson is List) {
        _wrongAnswers = wrongAnswersJson
            .map((json) => WrongAnswer.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      } else {
        _wrongAnswers = [];
      }

      // Load favorites
      final favoritesJson = _favoritesBox?.get('favorites');
      if (favoritesJson != null && favoritesJson is List) {
        _favorites = List<String>.from(favoritesJson);
      } else {
        _favorites = [];
      }

      // Load sessions
      final sessionsJson = _sessionsBox?.get('sessions');
      if (sessionsJson != null && sessionsJson is List) {
        _sessions = sessionsJson
            .map((json) => LearningSession.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      } else {
        _sessions = [];
      }

      // Load achievements
      final achievementsJson = _achievementsBox?.get('achievements');
      if (achievementsJson != null && achievementsJson is List) {
        _achievements = achievementsJson
            .map((json) => Achievement.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      } else {
        _achievements = Achievement.getDefaultAchievements();
        await _saveAchievementsToHive();
      }

      print('📚 Loaded ${_wrongAnswers.length} wrong answers from Hive storage');
    } catch (e) {
      print('❌ Error loading data from Hive: $e');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _progressBox?.close();
      await _wrongAnswersBox?.close();
      await _sessionsBox?.close();
      await _favoritesBox?.close();
      await _achievementsBox?.close();
    } catch (e) {
      print('❌ Error disposing Hive boxes: $e');
    }
  }

  @override
  Future<UserProgress> getUserProgress() async {
    return _userProgress;
  }

  @override
  Future<void> updateUserProgress(UserProgress progress) async {
    _userProgress = progress;
    await _saveUserProgressToHive();
  }

  Future<void> _saveUserProgressToHive() async {
    if (_hiveInitialized && _progressBox != null) {
      try {
        await _progressBox!.put('progress', _userProgress.toJson());
      } catch (e) {
        print('❌ Error saving user progress to Hive: $e');
      }
    }
  }

  @override
  Future<void> incrementStreak() async {
    final progress = await getUserProgress();
    final today = DateTime.now();
    final lastStudy = progress.lastStudyDate;

    int newStreak = progress.currentStreak;

    if (lastStudy != null) {
      final dayDifference = today.difference(lastStudy).inDays;

      if (dayDifference == 1) {
        newStreak += 1;
      } else if (dayDifference > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final longestStreak = newStreak > progress.longestStreak
        ? newStreak
        : progress.longestStreak;

    await updateUserProgress(
      progress.copyWith(
        currentStreak: newStreak,
        longestStreak: longestStreak,
        lastStudyDate: today,
      ),
    );
  }

  @override
  Future<void> addExperience(int xp) async {
    final progress = await getUserProgress();
    final newXp = progress.experiencePoints + xp;
    final currentLevel = progress.userLevel;

    // Calculate new level based on XP
    int newLevel = 1;
    int totalXpNeeded = 0;

    while (totalXpNeeded <= newXp) {
      totalXpNeeded += (newLevel * 100) + 100;
      if (totalXpNeeded <= newXp) {
        newLevel++;
      }
    }

    await updateUserProgress(
      progress.copyWith(
        experiencePoints: newXp,
        userLevel: newLevel,
      ),
    );

    // Check for level achievements if leveled up
    if (newLevel > currentLevel) {
      await checkForNewAchievements();
    }
  }

  @override
  Future<void> incrementTotalQuestions({required bool isCorrect}) async {
    final progress = await getUserProgress();
    await updateUserProgress(
      progress.copyWith(
        totalQuestionsAnswered: progress.totalQuestionsAnswered + 1,
        correctAnswers: isCorrect ? progress.correctAnswers + 1 : progress.correctAnswers,
      ),
    );
  }

  @override
  Future<List<WrongAnswer>> getWrongAnswers() async {
    return _wrongAnswers;
  }

  @override
  Future<void> addWrongAnswer(WrongAnswer wrongAnswer) async {
    _wrongAnswers.add(wrongAnswer);
    await _saveWrongAnswersToHive();
    print('✅ Saved wrong answer to storage. Total: ${_wrongAnswers.length}');
  }

  @override
  Future<void> removeWrongAnswer(String wrongAnswerId) async {
    _wrongAnswers.removeWhere((wa) => wa.id == wrongAnswerId);
    await _saveWrongAnswersToHive();
  }

  @override
  Future<void> markWrongAnswerAsResolved(String wrongAnswerId) async {
    final index = _wrongAnswers.indexWhere((wa) => wa.id == wrongAnswerId);
    if (index != -1) {
      _wrongAnswers[index] = _wrongAnswers[index].markAsReviewed(resolved: true);
      await _saveWrongAnswersToHive();
    }
  }

  Future<void> _saveWrongAnswersToHive() async {
    if (_hiveInitialized && _wrongAnswersBox != null) {
      try {
        final wrongAnswersJson = _wrongAnswers.map((wa) => wa.toJson()).toList();
        await _wrongAnswersBox!.put('wrongAnswers', wrongAnswersJson);
        print('💾 Saved ${wrongAnswersJson.length} wrong answers to Hive');
      } catch (e) {
        print('❌ Error saving wrong answers to Hive: $e');
      }
    }
  }

  @override
  Future<List<WrongAnswer>> getWrongAnswersNeedingReview() async {
    return _wrongAnswers.where((wa) => wa.needsReview).toList();
  }

  @override
  Future<List<LearningSession>> getLearningSessions() async {
    return _sessions;
  }

  @override
  Future<LearningSession?> getCurrentSession() async {
    return _currentSession;
  }

  @override
  Future<void> startNewSession({int? difficultyLevel, String? sessionType}) async {
    _currentSession = LearningSession.start(
      difficultyLevel: difficultyLevel,
      sessionType: sessionType ?? 'practice',
    );
  }

  @override
  Future<void> endCurrentSession() async {
    if (_currentSession != null) {
      _sessions.add(_currentSession!.complete());
      _currentSession = null;
    }
  }

  @override
  Future<void> updateCurrentSession({
    int? questionsAnswered,
    int? correctAnswers,
    String? questionId,
    String? wrongAnswerId,
  }) async {
    if (_currentSession == null) return;

    if (questionId != null) {
      _currentSession = _currentSession!.addQuestion(
        questionId: questionId,
        isCorrect: correctAnswers != null && correctAnswers > _currentSession!.correctAnswers,
        wrongAnswerId: wrongAnswerId,
      );
    }

    if (questionsAnswered != null) {
      _currentSession = _currentSession!.copyWith(
        questionsAnswered: questionsAnswered,
      );
    }

    if (correctAnswers != null) {
      _currentSession = _currentSession!.copyWith(
        correctAnswers: correctAnswers,
      );
    }
  }

  @override
  Future<List<String>> getFavoriteQuestions() async {
    return _favorites;
  }

  @override
  Future<void> toggleFavorite(String questionId) async {
    if (_favorites.contains(questionId)) {
      _favorites.remove(questionId);
    } else {
      _favorites.add(questionId);
    }
    await _saveFavoritesToHive();
  }

  Future<void> _saveFavoritesToHive() async {
    if (_hiveInitialized && _favoritesBox != null) {
      try {
        await _favoritesBox!.put('favorites', _favorites);
      } catch (e) {
        print('❌ Error saving favorites to Hive: $e');
      }
    }
  }

  Future<void> _saveAchievementsToHive() async {
    if (_hiveInitialized && _achievementsBox != null) {
      try {
        final achievementsJson = _achievements.map((a) => a.toJson()).toList();
        await _achievementsBox!.put('achievements', achievementsJson);
      } catch (e) {
        print('❌ Error saving achievements to Hive: $e');
      }
    }
  }

  @override
  Future<bool> isFavorite(String questionId) async {
    return _favorites.contains(questionId);
  }

  @override
  Future<List<Achievement>> getAchievements() async {
    return _achievements;
  }

  @override
  Future<void> updateAchievement(Achievement achievement) async {
    final index = _achievements.indexWhere((a) => a.id == achievement.id);
    if (index != -1) {
      _achievements[index] = achievement;
      await _saveAchievementsToHive();
    }
  }

  @override
  Future<List<Achievement>> checkForNewAchievements() async {
    final achievements = await getAchievements();
    final progress = await getUserProgress();
    final wrongAnswers = await getWrongAnswers();
    final sessions = await getLearningSessions();

    final newAchievements = <Achievement>[];

    for (final achievement in achievements) {
      if (achievement.isUnlocked) continue;

      int currentValue = 0;

      switch (achievement.type) {
        case AchievementType.streak:
          currentValue = progress.currentStreak;
          break;
        case AchievementType.questions:
          currentValue = progress.totalQuestionsAnswered;
          break;
        case AchievementType.level:
          currentValue = progress.userLevel;
          break;
        case AchievementType.review:
          currentValue = wrongAnswers.where((wa) => wa.isResolved).length;
          break;
        case AchievementType.accuracy:
        case AchievementType.special:
        case AchievementType.grammar:
          // These require special handling in the UI/game logic
          continue;
      }

      if (currentValue >= achievement.requiredValue) {
        final updatedAchievement = achievement.updateProgress(currentValue);
        newAchievements.add(updatedAchievement);
        await updateAchievement(updatedAchievement);
      }
    }

    return newAchievements;
  }

  @override
  Future<void> updateQuestionResult({
    required String questionId,
    required bool isCorrect,
    required int answerTime,
    required String mode,
  }) async {
    // Update total question stats
    await incrementTotalQuestions(isCorrect: isCorrect);

    // Add experience points for correct answers
    if (isCorrect) {
      await addExperience(10); // 10 XP for correct answer
    }

    // NOTE: Removed wrong answer creation from here
    // Wrong answers should be created by practice/exam screens with full question data
    // This method should only handle progress/stats updates

    // Update current session if active
    await updateCurrentSession(
      questionId: questionId,
      questionsAnswered: null, // Let the session manage this
      correctAnswers: null,    // Let the session manage this
    );

    // Increment daily streak
    await incrementStreak();

    // Check for new achievements
    await checkForNewAchievements();
  }
}