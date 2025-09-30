import 'package:hive_flutter/hive_flutter.dart';
import 'package:egg_toeic/core/constants/hive_constants.dart';
import 'package:egg_toeic/data/models/user_progress_model.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/learning_session_model.dart';
import 'package:egg_toeic/data/models/achievement_model.dart';
import 'package:egg_toeic/data/models/exam_result_model.dart';
import 'package:egg_toeic/data/repositories/base_repository.dart';
import 'package:egg_toeic/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class UserDataRepository extends BaseRepository {
  // User Progress
  Future<UserProgress> getUserProgress();
  Future<void> updateUserProgress(UserProgress progress);
  Future<void> incrementStreak();
  Future<void> addExperience(int xp);
  Future<void> incrementTotalQuestions({required bool isCorrect});

  // Daily Progress
  int getTodaysQuestionCount();

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

  // Exam Results
  Future<void> saveExamResult(ExamResult examResult);
  Future<ExamResult?> getExamResult(String examRound);
  Future<List<ExamResult>> getAllExamResults();

  // Question Results
  Future<void> updateQuestionResult({
    required String questionId,
    required bool isCorrect,
    required int answerTime,
    required String mode,
  });
}

class UserDataRepositoryImpl implements UserDataRepository {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Box<dynamic>? _progressBox;
  Box<dynamic>? _wrongAnswersBox;
  Box<dynamic>? _sessionsBox;
  Box<dynamic>? _favoritesBox;
  Box<dynamic>? _achievementsBox;
  Box<dynamic>? _examResultsBox;

  LearningSession? _currentSession;

  // Get current user ID from AuthService
  String get _userId => _authService.currentUserId;

  // Fallback in-memory storage for when Hive fails
  UserProgress _userProgress = UserProgress.initial();
  List<WrongAnswer> _wrongAnswers = [];
  List<LearningSession> _sessions = [];
  List<String> _favorites = [];
  List<Achievement> _achievements = Achievement.getDefaultAchievements();
  List<ExamResult> _examResults = [];

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
      _examResultsBox = await Hive.openBox<dynamic>('exam_results_box');

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

      // Load wrong answers from Hive first
      final wrongAnswersJson = _wrongAnswersBox?.get('wrongAnswers');
      if (wrongAnswersJson != null && wrongAnswersJson is List) {
        _wrongAnswers = wrongAnswersJson
            .map((json) => WrongAnswer.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      } else {
        _wrongAnswers = [];
      }

      // Try to sync from Firestore (if online and authenticated)
      await _loadWrongAnswersFromFirestore();

      // Load favorites from Hive first
      final favoritesJson = _favoritesBox?.get('favorites');
      if (favoritesJson != null && favoritesJson is List) {
        _favorites = List<String>.from(favoritesJson);
      } else {
        _favorites = [];
      }

      // Try to sync from Firestore (if online and authenticated)
      await _syncFavoritesFromFirestore();

      // Load sessions
      final sessionsJson = _sessionsBox?.get('sessions');
      if (sessionsJson != null && sessionsJson is List) {
        _sessions = sessionsJson
            .map((json) => LearningSession.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        print('📚 Loaded ${_sessions.length} sessions from Hive storage');
      } else {
        _sessions = [];
        print('📚 No sessions found in Hive storage, starting with empty list');
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

      // Load exam results
      final examResultsJson = _examResultsBox?.get('examResults');
      if (examResultsJson != null && examResultsJson is List) {
        _examResults = examResultsJson
            .map((json) => ExamResult.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        print('📚 Loaded ${_examResults.length} exam results from Hive storage');
      } else {
        _examResults = [];
        print('📚 No exam results found in Hive storage, starting with empty list');
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
      await _examResultsBox?.close();
    } catch (e) {
      print('❌ Error disposing Hive boxes: $e');
    }
  }

  @override
  Future<UserProgress> getUserProgress() async {
    return _userProgress;
  }

  /// Gets the actual number of questions answered today
  int getTodaysQuestionCount() {
    try {
      // Use the progress data to calculate today's questions
      final progress = _userProgress;
      final lastStudy = progress.lastStudyDate;
      final today = DateTime.now();

      // If last study was today, return total answered count
      // Otherwise return 0
      if (lastStudy != null &&
          lastStudy.year == today.year &&
          lastStudy.month == today.month &&
          lastStudy.day == today.day) {
        return progress.totalQuestionsAnswered.clamp(0, 10);
      }

      return 0;
    } catch (e) {
      print('Error getting today\'s question count: $e');
      return 0;
    }
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

    // Also save to Firestore - with auth check
    try {
      // Check if user is authenticated before saving
      if (_authService.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('progress')
            .doc('current')
            .set(_userProgress.toJson(), SetOptions(merge: true));
        print('✅ User progress synced to Firestore');
      } else {
        print('⏳ Skipping Firestore sync - authentication not ready yet');
      }
    } catch (e) {
      print('❌ Error saving user progress to Firestore: $e');
      // Continue execution - local storage is still working
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
    // Check for duplicate - prevent adding the same wrong answer twice
    final exists = _wrongAnswers.any((wa) => wa.id == wrongAnswer.id);
    if (exists) {
      print('⚠️  Wrong answer ${wrongAnswer.id} already exists, skipping duplicate');
      return;
    }

    _wrongAnswers.add(wrongAnswer);

    // Save to Hive first (fast, local)
    if (_hiveInitialized && _wrongAnswersBox != null) {
      try {
        final wrongAnswersJson = _wrongAnswers.map((wa) => wa.toJson()).toList();
        await _wrongAnswersBox!.put('wrongAnswers', wrongAnswersJson);
        print('💾 Saved ${_wrongAnswers.length} wrong answers to Hive');
      } catch (e) {
        print('❌ Error saving wrong answers to Hive: $e');
      }
    }

    // Sync only this new wrong answer to Firestore (not all of them)
    await _syncSingleWrongAnswerToFirestore(wrongAnswer);

    print('✅ Saved wrong answer to storage. Total: ${_wrongAnswers.length}');
  }

  @override
  Future<void> removeWrongAnswer(String wrongAnswerId) async {
    _wrongAnswers.removeWhere((wa) => wa.id == wrongAnswerId);
    await _saveWrongAnswersToHive();

    // Also delete from Firestore
    try {
      if (_authService.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('wrongAnswers')
            .doc(wrongAnswerId)
            .delete();
        print('✅ Deleted wrong answer from Firestore');
      }
    } catch (e) {
      print('❌ Error deleting wrong answer from Firestore: $e');
    }
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

    // Also save to Firestore - with auth check
    await _syncWrongAnswersToFirestore();
  }

  Future<void> _loadWrongAnswersFromFirestore() async {
    try {
      if (_authService.currentUser != null) {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('wrongAnswers')
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final cloudWrongAnswers = querySnapshot.docs
              .map((doc) {
                try {
                  return WrongAnswer.fromJson(doc.data());
                } catch (e) {
                  print('⚠️ Error parsing wrong answer ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<WrongAnswer>()
              .toList();

          // Merge cloud and local wrong answers (by ID)
          final localIds = _wrongAnswers.map((wa) => wa.id).toSet();
          final newFromCloud = cloudWrongAnswers
              .where((wa) => !localIds.contains(wa.id))
              .toList();

          if (newFromCloud.isNotEmpty) {
            _wrongAnswers.addAll(newFromCloud);
            // Save merged list back to local storage
            if (_hiveInitialized && _wrongAnswersBox != null) {
              final wrongAnswersJson = _wrongAnswers.map((wa) => wa.toJson()).toList();
              await _wrongAnswersBox!.put('wrongAnswers', wrongAnswersJson);
            }
            print('✅ Loaded ${newFromCloud.length} wrong answers from Firestore (${_wrongAnswers.length} total)');
          }
        }
      }
    } catch (e) {
      print('⚠️ Could not load wrong answers from Firestore: $e');
      // Continue with local wrong answers
    }
  }

  Future<void> _syncWrongAnswersToFirestore() async {
    try {
      if (_authService.currentUser != null) {
        // Save each wrong answer as a separate document for easier querying
        final batch = _firestore.batch();

        for (final wrongAnswer in _wrongAnswers) {
          final docRef = _firestore
              .collection('users')
              .doc(_userId)
              .collection('wrongAnswers')
              .doc(wrongAnswer.id);

          batch.set(docRef, {
            ...wrongAnswer.toJson(),
            'userId': _userId,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        await batch.commit();
        print('✅ Wrong answers synced to Firestore (${_wrongAnswers.length} items)');
      } else {
        print('⏳ Skipping wrong answers sync - authentication not ready yet');
      }
    } catch (e) {
      print('❌ Error syncing wrong answers to Firestore: $e');
      // Continue execution - local storage is still working
    }
  }

  // Sync only a single wrong answer to Firestore (more efficient)
  Future<void> _syncSingleWrongAnswerToFirestore(WrongAnswer wrongAnswer) async {
    try {
      if (_authService.currentUser != null) {
        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('wrongAnswers')
            .doc(wrongAnswer.id);

        await docRef.set({
          ...wrongAnswer.toJson(),
          'userId': _userId,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('✅ Synced wrong answer ${wrongAnswer.id} to Firestore');
      }
    } catch (e) {
      print('❌ Error syncing wrong answer to Firestore: $e');
      // Continue execution - local storage is still working
    }
  }

  Future<void> _saveSessionsToHive() async {
    if (_hiveInitialized && _sessionsBox != null) {
      try {
        final sessionsJson = _sessions.map((session) => session.toJson()).toList();
        await _sessionsBox!.put('sessions', sessionsJson);
        print('💾 Saved ${sessionsJson.length} sessions to Hive');
      } catch (e) {
        print('❌ Error saving sessions to Hive: $e');
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
      await _saveSessionsToHive(); // Save sessions to Hive after adding new one
      print('💾 Session ended and saved to Hive. Total sessions: ${_sessions.length}');
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

  Future<void> _syncFavoritesFromFirestore() async {
    try {
      if (_authService.currentUser != null) {
        final doc = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('favorites')
            .doc('bookmarks')
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['questionIds'] is List) {
            final cloudFavorites = List<String>.from(data['questionIds']);

            // Merge cloud and local favorites (union)
            final mergedFavorites = {..._favorites, ...cloudFavorites}.toList();

            if (mergedFavorites.length > _favorites.length) {
              _favorites = mergedFavorites;
              // Save merged list back to local storage
              if (_hiveInitialized && _favoritesBox != null) {
                await _favoritesBox!.put('favorites', _favorites);
              }
              print('✅ Synced bookmarks from Firestore (${_favorites.length} total)');
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Could not sync bookmarks from Firestore: $e');
      // Continue with local bookmarks
    }
  }

  Future<void> _saveFavoritesToHive() async {
    if (_hiveInitialized && _favoritesBox != null) {
      try {
        await _favoritesBox!.put('favorites', _favorites);
      } catch (e) {
        print('❌ Error saving favorites to Hive: $e');
      }
    }

    // Also save to Firestore - with auth check
    try {
      if (_authService.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('favorites')
            .doc('bookmarks')
            .set({
          'questionIds': _favorites,
          'lastUpdated': FieldValue.serverTimestamp(),
          'count': _favorites.length,
        }, SetOptions(merge: true));
        print('✅ Bookmarks synced to Firestore (${_favorites.length} items)');
      } else {
        print('⏳ Skipping bookmark sync - authentication not ready yet');
      }
    } catch (e) {
      print('❌ Error saving bookmarks to Firestore: $e');
      // Continue execution - local storage is still working
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

  // Exam Results methods
  @override
  Future<void> saveExamResult(ExamResult examResult) async {
    // Remove any existing result for the same round (keep only latest)
    _examResults.removeWhere((result) => result.examRound == examResult.examRound);

    // Add the new result
    _examResults.add(examResult);

    // Save to Hive
    await _saveExamResultsToHive();

    print('💾 Saved exam result for ${examResult.examRound}. Total results: ${_examResults.length}');
  }

  @override
  Future<ExamResult?> getExamResult(String examRound) async {
    try {
      return _examResults
          .where((result) => result.examRound == examRound)
          .cast<ExamResult?>()
          .firstWhere((result) => result != null, orElse: () => null);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<ExamResult>> getAllExamResults() async {
    return List.from(_examResults);
  }

  Future<void> _saveExamResultsToHive() async {
    if (_hiveInitialized && _examResultsBox != null) {
      try {
        final examResultsJson = _examResults.map((result) => result.toJson()).toList();
        await _examResultsBox!.put('examResults', examResultsJson);
        // Force flush to disk to ensure data persists
        await _examResultsBox!.flush();
        print('💾 Saved ${examResultsJson.length} exam results to Hive and flushed to disk');
      } catch (e) {
        print('❌ Error saving exam results to Hive: $e');
      }
    } else {
      print('⚠️ Cannot save exam results: Hive not initialized or box is null');
    }
  }
}