import 'package:egg_toeic/data/datasources/remote/analytics_service.dart';
import 'package:egg_toeic/data/models/user_answer_model.dart';
import 'package:egg_toeic/data/models/question_analytics_model.dart';
import 'package:egg_toeic/data/models/question_model.dart';
import 'package:egg_toeic/data/repositories/base_repository.dart';

class AnalyticsRepository implements BaseRepository {
  final AnalyticsService _analyticsService;

  AnalyticsRepository(this._analyticsService);

  @override
  Future<void> initialize() async {
    // Analytics service doesn't need initialization
  }

  @override
  Future<void> dispose() async {
    // Analytics service doesn't need disposal
  }

  /// Submits a user's answer and updates question analytics
  Future<void> submitAnswer({
    required String userId,
    required Question question,
    required int selectedAnswerIndex,
    String? sessionId,
    int? timeSpentSeconds,
    Map<String, dynamic>? metadata,
    bool isFirstAttempt = true,
  }) async {
    try {
      await _analyticsService.submitUserAnswer(
        userId: userId,
        question: question,
        selectedAnswerIndex: selectedAnswerIndex,
        sessionId: sessionId,
        timeSpentSeconds: timeSpentSeconds,
        metadata: metadata,
        isFirstAttempt: isFirstAttempt,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Gets user's answer history
  Future<List<UserAnswer>> getUserAnswers({
    required String userId,
    String? questionId,
    String? sessionId,
    int? limit,
  }) async {
    try {
      return await _analyticsService.getUserAnswers(
        userId: userId,
        questionId: questionId,
        sessionId: sessionId,
        limit: limit,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Gets analytics for a specific question
  Future<QuestionAnalytics?> getQuestionAnalytics(String questionId) async {
    try {
      return await _analyticsService.getQuestionAnalytics(questionId);
    } catch (e) {
      rethrow;
    }
  }

  /// Gets analytics for multiple questions
  Future<List<QuestionAnalytics>> getMultipleQuestionAnalytics(
    List<String> questionIds,
  ) async {
    try {
      return await _analyticsService.getMultipleQuestionAnalytics(questionIds);
    } catch (e) {
      rethrow;
    }
  }

  /// Gets top performing questions
  Future<List<QuestionAnalytics>> getTopPerformingQuestions({
    String? questionMode,
    String? questionType,
    int? difficultyLevel,
    int limit = 10,
  }) async {
    try {
      return await _analyticsService.getTopPerformingQuestions(
        questionMode: questionMode,
        questionType: questionType,
        difficultyLevel: difficultyLevel,
        limit: limit,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Gets worst performing questions
  Future<List<QuestionAnalytics>> getWorstPerformingQuestions({
    String? questionMode,
    String? questionType,
    int? difficultyLevel,
    int limit = 10,
  }) async {
    try {
      return await _analyticsService.getWorstPerformingQuestions(
        questionMode: questionMode,
        questionType: questionType,
        difficultyLevel: difficultyLevel,
        limit: limit,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Gets comprehensive user performance statistics
  Future<Map<String, dynamic>> getUserPerformanceStats(String userId) async {
    try {
      return await _analyticsService.getUserPerformanceStats(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Manually triggers recalculation of question analytics (for maintenance)
  Future<void> recalculateQuestionAnalytics(Question question) async {
    try {
      await _analyticsService.recalculateQuestionAnalytics(question);
    } catch (e) {
      rethrow;
    }
  }

  /// Gets analytics summary for a list of questions with basic stats
  Future<Map<String, dynamic>> getAnalyticsSummary(List<String> questionIds) async {
    try {
      final analytics = await getMultipleQuestionAnalytics(questionIds);

      if (analytics.isEmpty) {
        return {
          'totalQuestions': questionIds.length,
          'questionsWithData': 0,
          'averageSuccessRate': 0.0,
          'totalAttempts': 0,
          'difficultyBreakdown': <String, int>{},
          'modeBreakdown': <String, int>{},
        };
      }

      final totalAttempts = analytics.fold<int>(0, (sum, a) => sum + a.totalAttempts);
      final averageSuccessRate = analytics.fold<double>(0, (sum, a) => sum + a.correctPercentage) / analytics.length;

      final difficultyBreakdown = <String, int>{};
      final modeBreakdown = <String, int>{};

      for (final analytic in analytics) {
        final diffKey = 'Level ${analytic.difficultyLevel}';
        difficultyBreakdown[diffKey] = (difficultyBreakdown[diffKey] ?? 0) + 1;

        final modeKey = analytic.questionMode;
        modeBreakdown[modeKey] = (modeBreakdown[modeKey] ?? 0) + 1;
      }

      return {
        'totalQuestions': questionIds.length,
        'questionsWithData': analytics.length,
        'averageSuccessRate': double.parse(averageSuccessRate.toStringAsFixed(1)),
        'totalAttempts': totalAttempts,
        'difficultyBreakdown': difficultyBreakdown,
        'modeBreakdown': modeBreakdown,
        'topPerformers': analytics
            .where((a) => a.correctPercentage >= 80)
            .length,
        'needingReview': analytics
            .where((a) => a.correctPercentage < 50 && a.totalAttempts > 5)
            .length,
      };
    } catch (e) {
      rethrow;
    }
  }
}