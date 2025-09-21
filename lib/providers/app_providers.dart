import 'package:egg_toeic/data/repositories/user_data_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egg_toeic/data/models/user_progress_model.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/learning_session_model.dart';
import 'package:egg_toeic/data/models/achievement_model.dart';
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
  final repository = ref.read(userDataRepositoryProvider);
  return await repository.getWrongAnswers();
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

final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<String>>>((ref) {
  final repository = ref.read(userDataRepositoryProvider);
  return FavoritesNotifier(repository);
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

// Achievement Providers
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final repository = ref.read(userDataRepositoryProvider);
  return await repository.getAchievements();
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
