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
  Future<void> saveCompletedSession(LearningSession session);

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

  // Exam Progress (for save/resume functionality)
  Future<void> saveExamProgress(String progressId, Map<String, dynamic> progressData);
  Future<Map<String, dynamic>?> loadExamProgress(String progressId);
  Future<void> deleteExamProgress(String progressId);

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

        // Debug: show all loaded exam results BEFORE migration
        print('📊 Before migration:');
        for (final result in _examResults) {
          print('  📋 ${result.examRound} (Part ${result.partNumber}), questions: ${result.questions.length}, userAnswers: ${result.userAnswers.length}, accuracy: ${result.accuracy}');
        }

        // EMERGENCY FIX: Clear all corrupted exam results (questions.length = 0 but correctAnswers > 0)
        final hasEmptyQuestions = _examResults.any((r) => r.questions.isEmpty && r.correctAnswers > 0);
        if (hasEmptyQuestions) {
          print('🚨 CLEARING ALL CORRUPTED EXAM RESULTS - found results with empty questions but positive correctAnswers');
          print('   Please retake your exams to see statistics correctly');
          _examResults.clear();
          await _saveExamResultsToHive();

          // Also delete from Firebase
          try {
            final userId = _authService.currentUserId;
            final batch = _firestore.batch();
            final snapshot = await _firestore
                .collection('users')
                .doc(userId)
                .collection('examResults')
                .get();
            for (final doc in snapshot.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit();
            print('🗑️ Deleted ${snapshot.docs.length} corrupted exam results from Firebase');
          } catch (e) {
            print('⚠️ Could not delete from Firebase: $e');
          }

          print('✅ Cleared all exam data. Ready for fresh exams.');
          return; // Exit early, skip migration
        }

        // Recalculate accuracy for all results to fix any data corruption
        bool needsRecalculation = false;
        final updatedResults = <ExamResult>[];

        for (final result in _examResults) {
          if (result.questions.isNotEmpty) {
            // Recalculate correct answers
            int recalculatedCorrect = 0;
            for (int i = 0; i < result.userAnswers.length && i < result.questions.length; i++) {
              if (result.userAnswers[i] == result.questions[i].correctAnswerIndex) {
                recalculatedCorrect++;
              }
            }

            final recalculatedAccuracy = recalculatedCorrect / result.questions.length;

            // Check if data needs fixing
            if (recalculatedCorrect != result.correctAnswers ||
                (recalculatedAccuracy - result.accuracy).abs() > 0.01) {
              print('🔄 Fixing ${result.examRound}: correctAnswers ${result.correctAnswers} → $recalculatedCorrect, accuracy ${result.accuracy.toStringAsFixed(3)} → ${recalculatedAccuracy.toStringAsFixed(3)}');
              needsRecalculation = true;

              updatedResults.add(ExamResult(
                id: result.id,
                examRound: result.examRound,
                questions: result.questions,
                userAnswers: result.userAnswers,
                examStartTime: result.examStartTime,
                examEndTime: result.examEndTime,
                correctAnswers: recalculatedCorrect,
                accuracy: recalculatedAccuracy,
                partNumber: result.partNumber,
              ));
            } else {
              updatedResults.add(result);
            }
          } else if (result.correctAnswers > 0) {
            // Has correct answers but no questions - invalid data, skip it
            print('⚠️ Skipping ${result.examRound}: has correctAnswers but no questions');
            needsRecalculation = true;
          } else {
            updatedResults.add(result);
          }
        }

        if (needsRecalculation) {
          _examResults = updatedResults;
          await _saveExamResultsToHive();
          print('✅ Recalculated accuracy for exam results');
        }
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
    // Sync from Firebase first (only if local data seems fresh)
    if (_userProgress.totalQuestionsAnswered == 0) {
      await _syncProgressFromFirestore();
    }
    return _userProgress;
  }

  Future<void> _syncProgressFromFirestore() async {
    try {
      final userId = _authService.currentUserId;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        _userProgress = UserProgress(
          userLevel: data['userLevel'] as int? ?? 1,
          experiencePoints: data['experiencePoints'] as int? ?? 0,
          currentStreak: data['currentStreak'] as int? ?? 0,
          longestStreak: data['longestStreak'] as int? ?? 0,
          totalQuestionsAnswered: data['totalQuestionsAnswered'] as int? ?? 0,
          correctAnswers: data['correctAnswers'] as int? ?? 0,
          lastStudyDate: data['lastStudyDate'] != null
              ? (data['lastStudyDate'] as Timestamp).toDate()
              : null,
        );

        // Save to Hive for offline access
        await _saveUserProgressToHive();

        print('📥 User progress synced from Firebase');
      }
    } catch (e) {
      print('❌ Error syncing progress from Firebase: $e');
      // Don't throw - use local data if sync fails
    }
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

    // Sync to Firebase for persistence across devices/reinstalls
    await _saveProgressToFirestore(progress);
  }

  Future<void> _saveProgressToFirestore(UserProgress progress) async {
    try {
      final userId = _authService.currentUserId;

      await _firestore
          .collection('users')
          .doc(userId)
          .set({
        'userLevel': progress.userLevel,
        'experiencePoints': progress.experiencePoints,
        'currentStreak': progress.currentStreak,
        'longestStreak': progress.longestStreak,
        'totalQuestionsAnswered': progress.totalQuestionsAnswered,
        'correctAnswers': progress.correctAnswers,
        'lastStudyDate': progress.lastStudyDate != null
            ? Timestamp.fromDate(progress.lastStudyDate!)
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('☁️ User progress synced to Firebase');
    } catch (e) {
      print('❌ Error saving progress to Firebase: $e');
      // Don't throw - local save already succeeded
    }
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
    // Check for duplicate by questionId - prevent adding the same question twice
    final exists = _wrongAnswers.any((wa) => wa.questionId == wrongAnswer.questionId);
    if (exists) {
      print('⚠️  Question ${wrongAnswer.questionId} already saved as wrong answer, skipping duplicate');
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

          // Merge cloud and local wrong answers (by questionId to prevent duplicates)
          final localQuestionIds = _wrongAnswers.map((wa) => wa.questionId).toSet();
          final newFromCloud = cloudWrongAnswers
              .where((wa) => !localQuestionIds.contains(wa.questionId))
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
  Future<void> saveCompletedSession(LearningSession session) async {
    // Check if session already exists and update it, otherwise add it
    final existingIndex = _sessions.indexWhere((s) => s.id == session.id);
    if (existingIndex != -1) {
      _sessions[existingIndex] = session;
    } else {
      _sessions.add(session);
    }
    await _saveSessionsToHive();

    // Sync to Firebase for cross-device support
    await _saveSessionToFirestore(session);

    print('💾 Session saved/updated: ${session.id}. Total sessions: ${_sessions.length}');
  }

  Future<void> _saveSessionToFirestore(LearningSession session) async {
    try {
      final userId = _authService.currentUserId;

      // Save only summary data (metadata)
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('learningSessions')
          .doc(session.id)
          .set({
        'sessionId': session.id,
        'sessionType': session.sessionType,
        'startTime': Timestamp.fromDate(session.startTime),
        'endTime': session.endTime != null
            ? Timestamp.fromDate(session.endTime!)
            : null,
        'questionsAnswered': session.questionsAnswered,
        'correctAnswers': session.correctAnswers,
        'isCompleted': session.isCompleted,
        // Don't save full questionIds array unless needed
      }, SetOptions(merge: true));

      print('☁️ Session synced to Firebase: ${session.id}');
    } catch (e) {
      print('❌ Error saving session to Firebase: $e');
      // Don't throw - local save already succeeded
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
    // Sync from Firebase if achievements are still default
    if (_achievements.isEmpty || _achievements.every((a) => !a.isUnlocked)) {
      await _syncAchievementsFromFirestore();
    }
    return _achievements;
  }

  Future<void> _syncAchievementsFromFirestore() async {
    try {
      final userId = _authService.currentUserId;

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      if (snapshot.docs.isEmpty) {
        print('📥 No achievements found in Firebase, using defaults');
        return;
      }

      print('🔄 Syncing ${snapshot.docs.length} achievements from Firebase...');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final achievementId = data['id'] as String;

        // Find the achievement in our local list
        final index = _achievements.indexWhere((a) => a.id == achievementId);

        if (index != -1) {
          // Parse achievement type from string
          AchievementType type;
          try {
            type = AchievementType.values.firstWhere(
              (e) => e.toString() == data['type'],
              orElse: () => AchievementType.special,
            );
          } catch (e) {
            type = AchievementType.special;
          }

          // Update the achievement with Firebase data
          _achievements[index] = Achievement(
            id: achievementId,
            title: data['title'] as String,
            description: data['description'] as String,
            iconAsset: data['iconAsset'] as String,
            category: data['category'] as String,
            type: type,
            isUnlocked: data['isUnlocked'] as bool? ?? false,
            unlockedAt: data['unlockedAt'] != null
                ? (data['unlockedAt'] as Timestamp).toDate()
                : null,
            currentValue: data['currentValue'] as int? ?? 0,
            requiredValue: data['requiredValue'] as int,
            xpReward: data['xpReward'] as int? ?? 0,
          );

          print('📥 Synced achievement: $achievementId');
        }
      }

      // Save synced achievements to Hive
      await _saveAchievementsToHive();
      print('✅ Synced ${snapshot.docs.length} achievements from Firebase');
    } catch (e) {
      print('❌ Error syncing achievements from Firebase: $e');
      // Don't throw - use local/default achievements if sync fails
    }
  }

  @override
  Future<void> updateAchievement(Achievement achievement) async {
    final index = _achievements.indexWhere((a) => a.id == achievement.id);
    if (index != -1) {
      _achievements[index] = achievement;
      await _saveAchievementsToHive();

      // Sync to Firebase
      await _saveAchievementToFirestore(achievement);
    }
  }

  Future<void> _saveAchievementToFirestore(Achievement achievement) async {
    try {
      final userId = _authService.currentUserId;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievement.id)
          .set({
        'id': achievement.id,
        'title': achievement.title,
        'description': achievement.description,
        'iconAsset': achievement.iconAsset,
        'category': achievement.category,
        'type': achievement.type.toString(),
        'isUnlocked': achievement.isUnlocked,
        'unlockedAt': achievement.unlockedAt != null
            ? Timestamp.fromDate(achievement.unlockedAt!)
            : null,
        'currentValue': achievement.currentValue,
        'requiredValue': achievement.requiredValue,
        'xpReward': achievement.xpReward,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('☁️ Achievement synced to Firebase: ${achievement.id}');
    } catch (e) {
      print('❌ Error saving achievement to Firebase: $e');
      // Don't throw - local save already succeeded
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

    // Save to Hive (local)
    await _saveExamResultsToHive();

    // Save to Firebase (cloud sync)
    await _saveExamResultToFirestore(examResult);

    print('💾 Saved exam result for ${examResult.examRound}. Total results: ${_examResults.length}');
  }

  /// Helper to determine which TOEIC part a question belongs to
  int? _getPartNumberFromQuestionId(String questionId) {
    if (questionId.contains('PART2') || questionId.contains('Part2')) {
      return 2;
    } else if (questionId.contains('PART6') || questionId.contains('Part6')) {
      return 6;
    } else if ((questionId.startsWith('PRAC_') || questionId.startsWith('EXAM_')) &&
        !questionId.contains('Part6') && !questionId.contains('Part2')) {
      return 5;
    }
    return null;
  }

  Future<void> _saveExamResultToFirestore(ExamResult examResult) async {
    try {
      final userId = _authService.currentUserId;

      print('☁️ Saving exam result to Firebase for user: $userId, round: ${examResult.examRound}');

      final duration = examResult.examEndTime.difference(examResult.examStartTime);
      final totalQuestions = examResult.questions.length;
      final percentage = totalQuestions > 0
          ? ((examResult.correctAnswers / totalQuestions) * 100).round()
          : 0;

      // Determine which part this exam belongs to
      int? partNumber;
      if (examResult.questions.isNotEmpty) {
        partNumber = _getPartNumberFromQuestionId(examResult.questions.first.id);
        print('🔍 Detected part number from question ID "${examResult.questions.first.id}": $partNumber');
      }

      // Also use the partNumber from the examResult if available
      if (examResult.partNumber != null) {
        partNumber = examResult.partNumber;
        print('✅ Using partNumber from ExamResult: $partNumber');
      }

      // Save only summary data (metadata), not full question details
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('examResults')
          .doc(examResult.examRound)
          .set({
        'id': examResult.id,
        'examRound': examResult.examRound,
        'partNumber': partNumber, // NEW: Store which part this exam is for
        'completedAt': FieldValue.serverTimestamp(),
        'examStartTime': Timestamp.fromDate(examResult.examStartTime),
        'examEndTime': Timestamp.fromDate(examResult.examEndTime),
        'totalQuestions': totalQuestions,
        'correctAnswers': examResult.correctAnswers,
        'accuracy': examResult.accuracy,
        'percentage': percentage,
        'duration': duration.inSeconds,
        // Don't save full questions array - too much data!
      }, SetOptions(merge: true));

      print('☁️ Exam result synced to Firebase: ${examResult.examRound} (Part $partNumber)');
    } catch (e) {
      print('❌ Error saving exam result to Firebase: $e');
      // Don't throw - local save already succeeded
    }
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
    // Sync from Firebase first
    await _syncExamResultsFromFirestore();
    return List.from(_examResults);
  }

  Future<void> _syncExamResultsFromFirestore() async {
    try {
      final userId = _authService.currentUserId;

      print('🔍 Syncing exam results from Firebase for user: $userId');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('examResults')
          .get();

      print('🔄 Syncing ${snapshot.docs.length} exam results from Firebase...');

      if (snapshot.docs.isEmpty) {
        print('⚠️ No exam results found in Firebase. Path: users/$userId/examResults');
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final examRound = data['examRound'] as String;
        final partNumber = data['partNumber'] as int?;

        // Check if we already have this result locally
        final existingIndex = _examResults.indexWhere((r) => r.examRound == examRound);

        if (existingIndex == -1) {
          // We don't have this result locally - it came from another device
          // Create a minimal ExamResult from Firebase metadata
          final examStartTime = data['examStartTime'] != null
              ? (data['examStartTime'] as Timestamp).toDate()
              : DateTime.now();
          final examEndTime = data['examEndTime'] != null
              ? (data['examEndTime'] as Timestamp).toDate()
              : DateTime.now();

          final examResult = ExamResult(
            id: data['id'] as String,
            examRound: examRound,
            correctAnswers: data['correctAnswers'] as int,
            accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0.0,
            questions: [], // Empty - we don't store full questions in Firebase
            userAnswers: [], // Empty
            examStartTime: examStartTime,
            examEndTime: examEndTime,
            partNumber: partNumber,
          );

          _examResults.add(examResult);
          print('📥 Loaded exam result from Firebase: $examRound (Part $partNumber)');
        } else {
          // Update partNumber if it's missing in local data
          final existingResult = _examResults[existingIndex];
          if (existingResult.partNumber == null && partNumber != null) {
            print('🔄 Updating partNumber for $examRound: null → $partNumber');
            _examResults[existingIndex] = ExamResult(
              id: existingResult.id,
              examRound: existingResult.examRound,
              correctAnswers: existingResult.correctAnswers,
              accuracy: existingResult.accuracy,
              questions: existingResult.questions,
              userAnswers: existingResult.userAnswers,
              examStartTime: existingResult.examStartTime,
              examEndTime: existingResult.examEndTime,
              partNumber: partNumber, // Update with Firebase value
            );
          } else {
            print('⏭️ Skipping $examRound: already exists locally with Part ${existingResult.partNumber}');
          }
        }
      }

      // Save synced results to Hive
      if (snapshot.docs.isNotEmpty) {
        await _saveExamResultsToHive();
        print('✅ Synced ${snapshot.docs.length} exam results from Firebase');

        // Debug: show all exam results after sync
        print('📊 After Firebase sync:');
        for (final result in _examResults) {
          print('  📋 ${result.examRound} (Part ${result.partNumber}), questions: ${result.questions.length}, userAnswers: ${result.userAnswers.length}');
        }
      }
    } catch (e) {
      print('❌ Error syncing exam results from Firebase: $e');
      // Don't throw - use local data if sync fails
    }
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

  // Exam Progress Methods (for save/resume functionality)
  @override
  Future<void> saveExamProgress(String progressId, Map<String, dynamic> progressData) async {
    try {
      final userId = _authService.currentUserId;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('examProgress')
          .doc(progressId)
          .set(progressData);
    } catch (e) {
      print('❌ Error saving exam progress: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> loadExamProgress(String progressId) async {
    try {
      final userId = _authService.currentUserId;
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('examProgress')
          .doc(progressId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Error loading exam progress: $e');
      return null;
    }
  }

  @override
  Future<void> deleteExamProgress(String progressId) async {
    try {
      final userId = _authService.currentUserId;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('examProgress')
          .doc(progressId)
          .delete();
    } catch (e) {
      print('❌ Error deleting exam progress: $e');
      rethrow;
    }
  }
}