import 'package:egg_toeic/data/repositories/user_data_repository.dart';
import 'package:egg_toeic/data/repositories/question_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egg_toeic/data/models/user_progress_model.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/learning_session_model.dart';
import 'package:egg_toeic/data/models/achievement_model.dart';
import 'package:egg_toeic/data/models/exam_result_model.dart';
import 'package:egg_toeic/providers/repository_providers.dart';

// Use the simple question model as Question
typedef Question = SimpleQuestion;

// User Progress Providers
final userProgressProvider = FutureProvider<UserProgress>((ref) async {
  final repository = ref.read(userDataRepositoryProvider);
  return await repository.getUserProgress();
});

final userProgressNotifierProvider =
    StateNotifierProvider<UserProgressNotifier, AsyncValue<UserProgress>>(
        (ref) {
  final repository = ref.read(userDataRepositoryProvider);
  return UserProgressNotifier(repository);
});

class UserProgressNotifier extends StateNotifier<AsyncValue<UserProgress>> {
  final UserDataRepository _repository;

  UserProgressNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await _repository.getUserProgress();
      state = AsyncValue.data(progress);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> incrementStreak() async {
    await _repository.incrementStreak();
    await _loadProgress();
  }

  Future<void> addExperience(int xp) async {
    await _repository.addExperience(xp);
    await _loadProgress();
  }

  Future<void> incrementQuestions({required bool isCorrect}) async {
    await _repository.incrementTotalQuestions(isCorrect: isCorrect);
    await _loadProgress();
  }

  Future<void> updateProgress(UserProgress progress) async {
    await _repository.updateUserProgress(progress);
    state = AsyncValue.data(progress);
  }
}

// Question Providers
final questionsProvider =
    FutureProvider.family<List<Question>, int>((ref, difficultyLevel) async {
  final repository = ref.read(questionRepositoryProvider);
  return await repository.getQuestions(
      difficultyLevel: difficultyLevel, limit: 10);
});

final randomQuestionsProvider =
    FutureProvider.family<List<Question>, int?>((ref, difficultyLevel) async {
  final repository = ref.read(questionRepositoryProvider);
  return await repository.getRandomQuestions(
      difficultyLevel: difficultyLevel, limit: 10);
});

final questionByIdProvider =
    FutureProvider.family<Question?, String>((ref, questionId) async {
  final repository = ref.read(questionRepositoryProvider);
  return await repository.getQuestionById(questionId);
});

// Wrong Answers Providers
final wrongAnswersProvider = FutureProvider<List<WrongAnswer>>((ref) async {
  print('🔄 wrongAnswersProvider: Starting to load wrong answers...');

  final repository = ref.read(userDataRepositoryProvider);
  final questionRepository = ref.read(questionRepositoryProvider);

  print('🔄 wrongAnswersProvider: Got repository instances');

  final wrongAnswers = await repository.getWrongAnswers();

  print('📚 wrongAnswersProvider: Loaded ${wrongAnswers.length} wrong answers from repository');

  // Enrich wrong answers with question data if missing
  final enrichedWrongAnswers = <WrongAnswer>[];
  for (final wa in wrongAnswers) {
    print('  - Processing: ${wa.questionId}, Level: ${wa.difficultyLevel}, '
          'QuestionText: ${wa.questionText != null ? "✓" : "✗"}, '
          'Options: ${wa.options != null ? "✓ (${wa.options!.length})" : "✗"}');

    if (wa.questionText == null || wa.options == null) {
      print('    🔄 Enriching question data for: ${wa.questionId}');
      try {
        final question = await questionRepository.getQuestionById(wa.questionId);
        if (question != null) {
          final enrichedWa = wa.copyWith(
            questionText: question.questionText,
            options: question.options,
            explanation: question.explanation,
            grammarPoint: question.grammarPoint,
            difficultyLevel: wa.difficultyLevel ?? 1, // Keep existing level or default to 1
          );
          enrichedWrongAnswers.add(enrichedWa);
          print('    ✅ Enriched successfully');
        } else {
          print('    ❌ Question not found in database');
          enrichedWrongAnswers.add(wa); // Keep original if question not found
        }
      } catch (e) {
        print('    ❌ Error enriching question: $e');
        enrichedWrongAnswers.add(wa); // Keep original if error occurs
      }
    } else {
      enrichedWrongAnswers.add(wa); // Already has data
    }
  }

  print('📚 wrongAnswersProvider: Returning ${enrichedWrongAnswers.length} enriched wrong answers');
  return enrichedWrongAnswers;
});

final wrongAnswersNeedingReviewProvider =
    FutureProvider<List<WrongAnswer>>((ref) async {
  final repository = ref.read(userDataRepositoryProvider);
  return await repository.getWrongAnswersNeedingReview();
});

final wrongAnswersNotifierProvider =
    StateNotifierProvider<WrongAnswersNotifier, AsyncValue<List<WrongAnswer>>>(
        (ref) {
  final repository = ref.read(userDataRepositoryProvider);
  return WrongAnswersNotifier(repository);
});

class WrongAnswersNotifier
    extends StateNotifier<AsyncValue<List<WrongAnswer>>> {
  final UserDataRepository _repository;

  WrongAnswersNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadWrongAnswers();
  }

  Future<void> _loadWrongAnswers() async {
    try {
      final wrongAnswers = await _repository.getWrongAnswers();
      state = AsyncValue.data(wrongAnswers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addWrongAnswer(WrongAnswer wrongAnswer) async {
    await _repository.addWrongAnswer(wrongAnswer);
    await _loadWrongAnswers();
  }

  Future<void> markAsResolved(String wrongAnswerId) async {
    await _repository.markWrongAnswerAsResolved(wrongAnswerId);
    await _loadWrongAnswers();
  }
}

// Learning Session Providers
final learningSessionsProvider =
    FutureProvider<List<LearningSession>>((ref) async {
  final repository = ref.read(userDataRepositoryProvider);
  return await repository.getLearningSessions();
});

final currentSessionProvider =
    StateNotifierProvider<CurrentSessionNotifier, LearningSession?>((ref) {
  final repository = ref.read(userDataRepositoryProvider);
  return CurrentSessionNotifier(repository);
});

class CurrentSessionNotifier extends StateNotifier<LearningSession?> {
  final UserDataRepository _repository;

  CurrentSessionNotifier(this._repository) : super(null) {
    _loadCurrentSession();
  }

  Future<void> _loadCurrentSession() async {
    final session = await _repository.getCurrentSession();
    state = session;
  }

  Future<void> startNewSession(
      {int? difficultyLevel, String? sessionType}) async {
    await _repository.startNewSession(
        difficultyLevel: difficultyLevel, sessionType: sessionType);
    await _loadCurrentSession();
  }

  Future<void> endSession() async {
    await _repository.endCurrentSession();
    state = null;
  }

  Future<void> updateSession({
    int? questionsAnswered,
    int? correctAnswers,
    String? questionId,
    String? wrongAnswerId,
  }) async {
    await _repository.updateCurrentSession(
      questionsAnswered: questionsAnswered,
      correctAnswers: correctAnswers,
      questionId: questionId,
      wrongAnswerId: wrongAnswerId,
    );
    await _loadCurrentSession();
  }
}

// Favorites Providers
final favoritesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.read(userDataRepositoryProvider);
  return await repository.getFavoriteQuestions();
});

// Bookmarked Questions Provider (with cached question data)
final bookmarkedQuestionsProvider = FutureProvider<List<SimpleQuestion>>((ref) async {
  print('🔄 bookmarkedQuestionsProvider: Starting to load bookmarked questions...');

  // Watch favoritesProvider to automatically refresh when favorites change
  final favoritesAsync = ref.watch(favoritesProvider);

  final questionRepository = ref.read(questionRepositoryProvider);

  print('🔄 bookmarkedQuestionsProvider: Got repository instances');

  final favoriteIds = favoritesAsync.when(
    data: (ids) => ids,
    loading: () => <String>[],
    error: (_, __) => <String>[],
  );

  print('📚 bookmarkedQuestionsProvider: Loaded ${favoriteIds.length} favorite IDs');

  if (favoriteIds.isEmpty) {
    print('📚 bookmarkedQuestionsProvider: No favorites found, returning empty list');
    return <SimpleQuestion>[];
  }

  // Fetch all question data in one batch
  print('🔄 bookmarkedQuestionsProvider: Fetching question data for ${favoriteIds.length} favorites...');
  final questions = await questionRepository.getQuestionsByIds(favoriteIds);

  print('📚 bookmarkedQuestionsProvider: Successfully loaded ${questions.length} bookmarked questions');
  return questions;
});

final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<String>>>((ref) {
  final repository = ref.read(userDataRepositoryProvider);
  return FavoritesNotifier(repository);
});

final bookmarkedQuestionsNotifierProvider =
    StateNotifierProvider<BookmarkedQuestionsNotifier, AsyncValue<List<SimpleQuestion>>>((ref) {
  final userDataRepository = ref.read(userDataRepositoryProvider);
  final questionRepository = ref.read(questionRepositoryProvider);
  return BookmarkedQuestionsNotifier(userDataRepository, questionRepository);
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final UserDataRepository _repository;

  FavoritesNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _repository.getFavoriteQuestions();
      state = AsyncValue.data(favorites);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleFavorite(String questionId) async {
    await _repository.toggleFavorite(questionId);
    await _loadFavorites();
  }

  Future<bool> isFavorite(String questionId) async {
    return await _repository.isFavorite(questionId);
  }
}

class BookmarkedQuestionsNotifier extends StateNotifier<AsyncValue<List<SimpleQuestion>>> {
  final UserDataRepository _userDataRepository;
  final QuestionRepository _questionRepository;

  BookmarkedQuestionsNotifier(this._userDataRepository, this._questionRepository)
      : super(const AsyncValue.loading()) {
    _loadBookmarkedQuestions();
  }

  Future<void> _loadBookmarkedQuestions() async {
    try {
      final favoriteIds = await _userDataRepository.getFavoriteQuestions();

      if (favoriteIds.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      final questions = await _questionRepository.getQuestionsByIds(favoriteIds);
      state = AsyncValue.data(questions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadBookmarkedQuestions();
  }

  Future<void> toggleBookmark(String questionId) async {
    await _userDataRepository.toggleFavorite(questionId);
    await _loadBookmarkedQuestions();
  }
}

// Achievement Providers
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final repository = ref.read(userDataRepositoryProvider);
  final achievements = await repository.getAchievements();

  // If no achievements exist, return default achievements
  if (achievements.isEmpty) {
    return Achievement.getDefaultAchievements();
  }

  return achievements;
});

final achievementsNotifierProvider =
    StateNotifierProvider<AchievementsNotifier, AsyncValue<List<Achievement>>>(
        (ref) {
  final repository = ref.read(userDataRepositoryProvider);
  return AchievementsNotifier(repository);
});

class AchievementsNotifier
    extends StateNotifier<AsyncValue<List<Achievement>>> {
  final UserDataRepository _repository;

  AchievementsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final achievements = await _repository.getAchievements();
      state = AsyncValue.data(achievements);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<List<Achievement>> checkForNewAchievements() async {
    final newAchievements = await _repository.checkForNewAchievements();
    await _loadAchievements();
    return newAchievements;
  }

  Future<void> updateAchievement(Achievement achievement) async {
    await _repository.updateAchievement(achievement);
    await _loadAchievements();
  }
}

// Exam Results Providers
final examResultsProvider = FutureProvider<List<ExamResult>>((ref) async {
  final repository = ref.read(userDataRepositoryProvider);
  return await repository.getAllExamResults();
});

// Combined Statistics Model
class CombinedStatistics {
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final double overallAccuracy;
  final int practiceQuestionsAnswered;
  final int examQuestionsAnswered;

  const CombinedStatistics({
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.overallAccuracy,
    required this.practiceQuestionsAnswered,
    required this.examQuestionsAnswered,
  });
}

// Combined Statistics Provider
final combinedStatisticsProvider = FutureProvider<CombinedStatistics>((ref) async {
  // Get practice sessions (to include ALL parts' practice data)
  final sessions = await ref.read(learningSessionsProvider.future);

  // Get exam results
  final examResults = await ref.read(examResultsProvider.future);

  // Calculate practice statistics from ALL sessions (Part 5 + Part 6)
  int practiceQuestionsAnswered = 0;

  for (final session in sessions) {
    if (session.sessionType == 'practice' || session.sessionType.contains('practice')) {
      practiceQuestionsAnswered += session.questionsAnswered;
    }
  }

  // Calculate exam statistics
  int examQuestionsAnswered = 0;
  int examCorrectAnswers = 0;

  for (final examResult in examResults) {
    examQuestionsAnswered += examResult.userAnswers.length;
    for (int i = 0; i < examResult.userAnswers.length && i < examResult.questions.length; i++) {
      if (examResult.userAnswers[i] == examResult.questions[i].correctAnswerIndex) {
        examCorrectAnswers++;
      }
    }
  }

  // Note: For practice correct answers, we need to calculate from sessions
  int practiceCorrectAnswers = 0;
  for (final session in sessions) {
    if (session.sessionType == 'practice' || session.sessionType.contains('practice')) {
      practiceCorrectAnswers += session.correctAnswers;
    }
  }

  // Combine practice and exam statistics
  final totalQuestions = practiceQuestionsAnswered + examQuestionsAnswered;
  final totalCorrect = practiceCorrectAnswers + examCorrectAnswers;
  final overallAccuracy = totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0.0;

  return CombinedStatistics(
    totalQuestionsAnswered: totalQuestions,
    totalCorrectAnswers: totalCorrect,
    overallAccuracy: overallAccuracy,
    practiceQuestionsAnswered: practiceQuestionsAnswered,
    examQuestionsAnswered: examQuestionsAnswered,
  );
});

// Separate Statistics Model
class SeparateStatistics {
  final int practiceQuestionsAnswered;
  final int practiceCorrectAnswers;
  final double practiceAccuracy;
  final int examQuestionsAnswered;
  final int examCorrectAnswers;
  final double examAccuracy;
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final double overallAccuracy;

  const SeparateStatistics({
    required this.practiceQuestionsAnswered,
    required this.practiceCorrectAnswers,
    required this.practiceAccuracy,
    required this.examQuestionsAnswered,
    required this.examCorrectAnswers,
    required this.examAccuracy,
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.overallAccuracy,
  });
}

// Separate Statistics Provider
final separateStatisticsProvider = FutureProvider<SeparateStatistics>((ref) async {
  // Get practice sessions (to include ALL parts' practice data)
  final sessions = await ref.read(learningSessionsProvider.future);

  // Get exam results
  final examResults = await ref.read(examResultsProvider.future);

  // Calculate practice statistics from ALL sessions (Part 5 + Part 6)
  int practiceQuestionsAnswered = 0;
  int practiceCorrectAnswers = 0;

  for (final session in sessions) {
    if (session.sessionType == 'practice' || session.sessionType.contains('practice')) {
      practiceQuestionsAnswered += session.questionsAnswered;
      practiceCorrectAnswers += session.correctAnswers;
    }
  }

  // Calculate exam statistics
  int examQuestionsAnswered = 0;
  int examCorrectAnswers = 0;

  for (final examResult in examResults) {
    examQuestionsAnswered += examResult.userAnswers.length;
    for (int i = 0; i < examResult.userAnswers.length && i < examResult.questions.length; i++) {
      if (examResult.userAnswers[i] == examResult.questions[i].correctAnswerIndex) {
        examCorrectAnswers++;
      }
    }
  }

  // Calculate accuracies
  final practiceAccuracy = practiceQuestionsAnswered > 0
      ? (practiceCorrectAnswers / practiceQuestionsAnswered) * 100
      : 0.0;
  final examAccuracy = examQuestionsAnswered > 0
      ? (examCorrectAnswers / examQuestionsAnswered) * 100
      : 0.0;

  // Combine practice and exam statistics
  final totalQuestions = practiceQuestionsAnswered + examQuestionsAnswered;
  final totalCorrect = practiceCorrectAnswers + examCorrectAnswers;
  final overallAccuracy = totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0.0;

  return SeparateStatistics(
    practiceQuestionsAnswered: practiceQuestionsAnswered,
    practiceCorrectAnswers: practiceCorrectAnswers,
    practiceAccuracy: practiceAccuracy,
    examQuestionsAnswered: examQuestionsAnswered,
    examCorrectAnswers: examCorrectAnswers,
    examAccuracy: examAccuracy,
    totalQuestionsAnswered: totalQuestions,
    totalCorrectAnswers: totalCorrect,
    overallAccuracy: overallAccuracy,
  );
});

// Hierarchical Category Statistics Model
class HierarchicalCategoryStatistics {
  final String name;
  final int totalCorrect;
  final int totalQuestions;
  final Map<int, CategoryLevelStats> levels;

  HierarchicalCategoryStatistics({
    required this.name,
    required this.totalCorrect,
    required this.totalQuestions,
    required this.levels,
  });

  double get percentage => totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0;
}

class CategoryLevelStats {
  final int level;
  final int correct;
  final int total;

  CategoryLevelStats({
    required this.level,
    required this.correct,
    required this.total,
  });

  double get percentage => total > 0 ? (correct / total) * 100 : 0;
}

// Hierarchical Statistics Provider (from all exam results)
final hierarchicalStatisticsProvider = FutureProvider<Map<String, HierarchicalCategoryStatistics>>((ref) async {
  final examResults = await ref.read(examResultsProvider.future);

  // Initialize hierarchical categories (includes 문장삽입 for Part 6 questions)
  Map<String, Map<int, CategoryLevelStats>> hierarchicalCategories = {
    '문법': {},
    '어휘': {},
    '문장삽입': {}, // Added to support Part 6 sentence insert questions
  };

  // Process all exam results
  for (final examResult in examResults) {
    for (int i = 0; i < examResult.questions.length; i++) {
      final question = examResult.questions[i];
      final userAnswer = i < examResult.userAnswers.length ? examResult.userAnswers[i] : -1;
      final isCorrect = userAnswer == question.correctAnswerIndex;

      // Determine main category (문법 or 어휘)
      final mainCategory = _determineMainCategory(question);
      final difficultyLevel = question.difficultyLevel;

      // Initialize level stats if not exists
      if (!hierarchicalCategories[mainCategory]!.containsKey(difficultyLevel)) {
        hierarchicalCategories[mainCategory]![difficultyLevel] = CategoryLevelStats(
          level: difficultyLevel,
          correct: 0,
          total: 0,
        );
      }

      // Update stats
      final currentStats = hierarchicalCategories[mainCategory]![difficultyLevel]!;
      hierarchicalCategories[mainCategory]![difficultyLevel] = CategoryLevelStats(
        level: difficultyLevel,
        correct: currentStats.correct + (isCorrect ? 1 : 0),
        total: currentStats.total + 1,
      );
    }
  }

  // Create final hierarchical category statistics
  final result = <String, HierarchicalCategoryStatistics>{};
  for (final mainCategory in hierarchicalCategories.keys) {
    final levels = hierarchicalCategories[mainCategory]!;
    final totalCorrect = levels.values.fold(0, (sum, stats) => sum + stats.correct);
    final totalQuestions = levels.values.fold(0, (sum, stats) => sum + stats.total);

    if (totalQuestions > 0) {
      result[mainCategory] = HierarchicalCategoryStatistics(
        name: mainCategory,
        totalCorrect: totalCorrect,
        totalQuestions: totalQuestions,
        levels: levels,
      );
    }
  }

  return result;
});

// Helper function to determine main category
String _determineMainCategory(SimpleQuestion question) {
  // First, check if it's a Part 6 question
  final isPart6 = _getPartNumber(question.id) == 6;

  // For Part 6, check if it's a sentence insert question
  if (isPart6) {
    // Sentence insert questions typically have full sentences as options
    // Check if ALL options are full sentences (contain periods or are long)
    final options = question.options;
    if (options.length >= 3) {
      int sentenceCount = 0;
      for (final option in options) {
        // Consider it a sentence if it:
        // 1. Contains a period, or
        // 2. Is longer than 50 characters, or
        // 3. Contains subject-verb structure (has "I", "we", "they", "he", "she", "it" followed by a verb)
        if (option.contains('.') ||
            option.length > 50 ||
            RegExp(r'\b(I|We|They|He|She|It)\s+(am|is|are|was|were|have|has|had|will|would|can|could|should|shall)\b', caseSensitive: false).hasMatch(option) ||
            RegExp(r'\b(I|We|They|He|She|It)\s+\w+(s|ed|ing)\b', caseSensitive: false).hasMatch(option)) {
          sentenceCount++;
        }
      }

      // If at least 3 out of 4 options are sentences, it's a sentence insert question
      if (sentenceCount >= 3) {
        return '문장삽입';
      }
    }
  }

  final questionType = question.questionType?.toLowerCase() ?? '';

  if (questionType.contains('vocabulary')) {
    return '어휘';
  } else if (questionType.contains('grammar')) {
    return '문법';
  }

  // Fallback logic
  final text = question.questionText.toLowerCase();
  final grammarPoint = question.grammarPoint.toLowerCase();

  if (text.contains('meaning') ||
      text.contains('synonym') ||
      text.contains('definition') ||
      text.contains('word that best') ||
      grammarPoint.contains('vocabulary')) {
    return '어휘';
  }

  return '문법';
}

// Helper function to determine which part a question belongs to
int? _getPartNumber(String questionId) {
  // Part 6 questions contain "Part6" in their ID
  if (questionId.contains('PART6') || questionId.contains('Part6')) {
    return 6;
  }
  // Part 5 questions start with "PRAC_" and do NOT contain "Part6"
  else if (questionId.startsWith('PRAC_') && !questionId.contains('Part6')) {
    return 5;
  }
  return null;
}

// Part-Specific Statistics Provider
final partStatisticsProvider = FutureProvider.family<SeparateStatistics, int>((ref, partNumber) async {
  // Get practice sessions
  final sessions = await ref.read(learningSessionsProvider.future);

  // Get exam results
  final examResults = await ref.read(examResultsProvider.future);

  // Filter sessions for this part (practice)
  final practiceSessionsForPart = sessions.where((session) {
    if (session.sessionType == 'practice' || session.sessionType.contains('practice')) {
      // Check if any question IDs belong to this part
      return session.questionIds.any((qId) => _getPartNumber(qId) == partNumber);
    }
    return false;
  }).toList();

  // Calculate practice statistics for this part
  int practiceQuestionsAnswered = 0;
  int practiceCorrectAnswers = 0;

  for (final session in practiceSessionsForPart) {
    practiceQuestionsAnswered += session.questionsAnswered;
    practiceCorrectAnswers += session.correctAnswers;
  }

  // Filter exam results for this part
  final examRepository = ref.read(questionRepositoryProvider);
  int examQuestionsAnswered = 0;
  int examCorrectAnswers = 0;

  for (final examResult in examResults) {
    // Check if this exam result belongs to the specified part
    for (int i = 0; i < examResult.questions.length; i++) {
      final question = examResult.questions[i];
      if (_getPartNumber(question.id) == partNumber) {
        examQuestionsAnswered++;
        if (i < examResult.userAnswers.length &&
            examResult.userAnswers[i] == question.correctAnswerIndex) {
          examCorrectAnswers++;
        }
      }
    }
  }

  // Calculate accuracies
  final practiceAccuracy = practiceQuestionsAnswered > 0
      ? (practiceCorrectAnswers / practiceQuestionsAnswered) * 100
      : 0.0;
  final examAccuracy = examQuestionsAnswered > 0
      ? (examCorrectAnswers / examQuestionsAnswered) * 100
      : 0.0;

  // Combine practice and exam statistics
  final totalQuestions = practiceQuestionsAnswered + examQuestionsAnswered;
  final totalCorrect = practiceCorrectAnswers + examCorrectAnswers;
  final overallAccuracy = totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0.0;

  return SeparateStatistics(
    practiceQuestionsAnswered: practiceQuestionsAnswered,
    practiceCorrectAnswers: practiceCorrectAnswers,
    practiceAccuracy: practiceAccuracy,
    examQuestionsAnswered: examQuestionsAnswered,
    examCorrectAnswers: examCorrectAnswers,
    examAccuracy: examAccuracy,
    totalQuestionsAnswered: totalQuestions,
    totalCorrectAnswers: totalCorrect,
    overallAccuracy: overallAccuracy,
  );
});

// Part-Specific Hierarchical Statistics Provider
final partHierarchicalStatisticsProvider = FutureProvider.family<Map<String, HierarchicalCategoryStatistics>, int>((ref, partNumber) async {
  final examResults = await ref.read(examResultsProvider.future);

  // Initialize hierarchical categories (Part 6 has 3 categories, others have 2)
  Map<String, Map<int, CategoryLevelStats>> hierarchicalCategories = partNumber == 6
      ? {
          '문법': {},
          '어휘': {},
          '문장삽입': {},
        }
      : {
          '문법': {},
          '어휘': {},
        };

  // Process exam results for this specific part
  for (final examResult in examResults) {
    for (int i = 0; i < examResult.questions.length; i++) {
      final question = examResult.questions[i];

      // Only process questions from the specified part
      if (_getPartNumber(question.id) != partNumber) continue;

      final userAnswer = i < examResult.userAnswers.length ? examResult.userAnswers[i] : -1;
      final isCorrect = userAnswer == question.correctAnswerIndex;

      // Determine main category (문법 or 어휘)
      final mainCategory = _determineMainCategory(question);
      final difficultyLevel = question.difficultyLevel;

      // Initialize level stats if not exists
      if (!hierarchicalCategories[mainCategory]!.containsKey(difficultyLevel)) {
        hierarchicalCategories[mainCategory]![difficultyLevel] = CategoryLevelStats(
          level: difficultyLevel,
          correct: 0,
          total: 0,
        );
      }

      // Update stats
      final currentStats = hierarchicalCategories[mainCategory]![difficultyLevel]!;
      hierarchicalCategories[mainCategory]![difficultyLevel] = CategoryLevelStats(
        level: difficultyLevel,
        correct: currentStats.correct + (isCorrect ? 1 : 0),
        total: currentStats.total + 1,
      );
    }
  }

  // Create final hierarchical category statistics
  final result = <String, HierarchicalCategoryStatistics>{};
  for (final mainCategory in hierarchicalCategories.keys) {
    final levels = hierarchicalCategories[mainCategory]!;
    final totalCorrect = levels.values.fold(0, (sum, stats) => sum + stats.correct);
    final totalQuestions = levels.values.fold(0, (sum, stats) => sum + stats.total);

    if (totalQuestions > 0) {
      result[mainCategory] = HierarchicalCategoryStatistics(
        name: mainCategory,
        totalCorrect: totalCorrect,
        totalQuestions: totalQuestions,
        levels: levels,
      );
    }
  }

  return result;
});
