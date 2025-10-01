// Temporary simple repository for immediate compilation
// TODO: Replace with full Hive implementation after fixing adapter issues

import 'package:egg_toeic/data/models/user_progress_model.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/learning_session_model.dart';
import 'package:egg_toeic/data/models/achievement_model.dart';
import 'package:egg_toeic/data/models/exam_result_model.dart';
import 'package:egg_toeic/data/repositories/base_repository.dart';
import 'package:egg_toeic/data/repositories/user_data_repository.dart';

abstract class TempUserDataRepository extends BaseRepository {
  Future<UserProgress> getUserProgress();
  Future<void> updateUserProgress(UserProgress progress);
  Future<void> incrementStreak();
  Future<void> addExperience(int xp);
  Future<void> incrementTotalQuestions({required bool isCorrect});
  Future<List<WrongAnswer>> getWrongAnswers();
  Future<void> addWrongAnswer(WrongAnswer wrongAnswer);
  Future<void> removeWrongAnswer(String wrongAnswerId);
  Future<void> markWrongAnswerAsResolved(String wrongAnswerId);
  Future<List<WrongAnswer>> getWrongAnswersNeedingReview();
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
  Future<List<String>> getFavoriteQuestions();
  Future<void> toggleFavorite(String questionId);
  Future<bool> isFavorite(String questionId);
  Future<List<Achievement>> getAchievements();
  Future<void> updateAchievement(Achievement achievement);
  Future<List<Achievement>> checkForNewAchievements();
}

class TempUserDataRepositoryImpl implements UserDataRepository {
  // In-memory storage for now
  UserProgress _userProgress = UserProgress.initial();
  List<WrongAnswer> _wrongAnswers = [];
  List<LearningSession> _sessions = [];
  List<String> _favorites = [];
  List<Achievement> _achievements = Achievement.getDefaultAchievements();
  List<ExamResult> _examResults = [];
  LearningSession? _currentSession;

  @override
  Future<void> initialize() async {
    // No initialization needed for in-memory storage
  }

  @override
  Future<void> dispose() async {
    // No cleanup needed for in-memory storage
  }

  @override
  Future<UserProgress> getUserProgress() async {
    return _userProgress;
  }

  @override
  Future<void> updateUserProgress(UserProgress progress) async {
    _userProgress = progress;
  }

  @override
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
      print('Error getting today\'s question count in temp repository: $e');
      return 0;
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
    print('📖 Repository GET wrong answers:');
    print('  - Repository instance: ${hashCode}');
    print('  - _wrongAnswers list: ${_wrongAnswers.hashCode}');
    print('  - Count: ${_wrongAnswers.length}');
    for (var i = 0; i < _wrongAnswers.length; i++) {
      print('    $i: ${_wrongAnswers[i].questionId}');
    }
    return _wrongAnswers;
  }

  @override
  Future<void> addWrongAnswer(WrongAnswer wrongAnswer) async {
    print('💾 Repository ADDING wrong answer:');
    print('  - ID: ${wrongAnswer.id}');
    print('  - QuestionID: ${wrongAnswer.questionId}');
    print('  - QuestionText: "${wrongAnswer.questionText}" (null: ${wrongAnswer.questionText == null})');
    print('  - Options: ${wrongAnswer.options} (null: ${wrongAnswer.options == null})');
    print('  - Repository instance: ${hashCode}');
    print('  - Current _wrongAnswers list: ${_wrongAnswers.hashCode}');

    // Check for duplicate by questionId - prevent adding the same question twice
    final exists = _wrongAnswers.any((wa) => wa.questionId == wrongAnswer.questionId);
    if (exists) {
      print('⚠️  Question ${wrongAnswer.questionId} already saved as wrong answer, skipping duplicate');
      return;
    }

    _wrongAnswers.add(wrongAnswer);

    print('💾 Repository ADDED. Total count: ${_wrongAnswers.length}');
    print('💾 Current items in list:');
    for (var i = 0; i < _wrongAnswers.length; i++) {
      print('    $i: ${_wrongAnswers[i].questionId}');
    }
  }

  @override
  Future<void> removeWrongAnswer(String wrongAnswerId) async {
    _wrongAnswers.removeWhere((wa) => wa.id == wrongAnswerId);
  }

  @override
  Future<void> markWrongAnswerAsResolved(String wrongAnswerId) async {
    final index = _wrongAnswers.indexWhere((wa) => wa.id == wrongAnswerId);
    if (index != -1) {
      _wrongAnswers[index] = _wrongAnswers[index].markAsReviewed(resolved: true);
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
  Future<void> saveCompletedSession(LearningSession session) async {
    // Check if session already exists and update it, otherwise add it
    final existingIndex = _sessions.indexWhere((s) => s.id == session.id);
    if (existingIndex != -1) {
      _sessions[existingIndex] = session;
    } else {
      _sessions.add(session);
    }
    print('💾 Session saved/updated: ${session.id}. Total sessions: ${_sessions.length}');
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
    }
  }

  @override
  Future<List<Achievement>> checkForNewAchievements() async {
    final progress = await getUserProgress();
    final wrongAnswers = await getWrongAnswers();
    final newAchievements = <Achievement>[];

    for (final achievement in _achievements) {
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
    print('📊 updateQuestionResult called:');
    print('  - questionId: $questionId');
    print('  - isCorrect: $isCorrect');
    print('  - mode: $mode');
    print('  - NOTE: Wrong answers should be handled by practice screens, not here');

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

  // Exam Results methods (in-memory implementation)
  @override
  Future<void> saveExamResult(ExamResult examResult) async {
    // Remove any existing result for the same round (keep only latest)
    _examResults.removeWhere((result) => result.examRound == examResult.examRound);

    // Add the new result
    _examResults.add(examResult);

    print('💾 Saved exam result for ${examResult.examRound} (in-memory). Total results: ${_examResults.length}');
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
}

