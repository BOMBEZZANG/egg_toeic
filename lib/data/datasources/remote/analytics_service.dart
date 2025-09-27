import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:egg_toeic/data/models/user_answer_model.dart';
import 'package:egg_toeic/data/models/question_analytics_model.dart';
import 'package:egg_toeic/data/models/question_model.dart';
import 'package:egg_toeic/core/utils/logger.dart';

class AnalyticsService {
  static const String _userAnswersCollection = 'userAnswers';
  static const String _questionAnalyticsCollection = 'questionAnalytics';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submits a user's answer to a question and updates analytics
  Future<void> submitUserAnswer({
    required String userId,
    required Question question,
    required int selectedAnswerIndex,
    String? sessionId,
    int? timeSpentSeconds,
    Map<String, dynamic>? metadata,
    bool isFirstAttempt = true,
  }) async {
    try {
      final userAnswer = UserAnswerExtension.fromUserInput(
        userId: userId,
        questionId: question.id,
        selectedAnswerIndex: selectedAnswerIndex,
        correctAnswerIndex: question.correctAnswerIndex,
        questionMode: _extractQuestionMode(question.id),
        questionType: _extractQuestionType(question),
        difficultyLevel: question.difficultyLevel,
        grammarPoint: question.grammarPoint,
        sessionId: sessionId,
        timeSpentSeconds: timeSpentSeconds,
        metadata: {
          ...?metadata,
          'isFirstAttempt': isFirstAttempt,
        },
      );

      // Submit user answer
      final userAnswerData = UserAnswer.toFirestore(userAnswer, null);

      // Debug: Log the data being sent to Firestore
      Logger.info('🔍 Submitting user answer data: $userAnswerData');
      Logger.info('🔍 Anonymous user ID: $userId');

      await _firestore
          .collection(_userAnswersCollection)
          .add(userAnswerData);

      // Update question analytics - only for first attempts
      if (isFirstAttempt) {
        await _updateQuestionAnalyticsDirectly(question, selectedAnswerIndex, timeSpentSeconds);
      }

      Logger.info('User answer submitted successfully for question ${question.id}');
    } catch (e) {
      Logger.error('Failed to submit user answer: $e');
      rethrow;
    }
  }

  /// Gets user answers for a specific user
  Future<List<UserAnswer>> getUserAnswers({
    required String userId,
    String? questionId,
    String? sessionId,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(_userAnswersCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('answeredAt', descending: true);

      if (questionId != null) {
        query = query.where('questionId', isEqualTo: questionId);
      }

      if (sessionId != null) {
        query = query.where('sessionId', isEqualTo: sessionId);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => UserAnswer.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null))
          .toList();
    } catch (e) {
      Logger.error('Failed to get user answers: $e');
      rethrow;
    }
  }

  /// Gets analytics for a specific question
  Future<QuestionAnalytics?> getQuestionAnalytics(String questionId) async {
    try {
      final doc = await _firestore
          .collection(_questionAnalyticsCollection)
          .doc(questionId)
          .get();

      if (doc.exists) {
        return QuestionAnalytics.fromFirestore(doc, null);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get question analytics: $e');
      rethrow;
    }
  }

  /// Gets analytics for multiple questions
  Future<List<QuestionAnalytics>> getMultipleQuestionAnalytics(
    List<String> questionIds,
  ) async {
    try {
      if (questionIds.isEmpty) return [];

      // Firestore 'in' query limit is 10, so we need to batch
      final List<QuestionAnalytics> allAnalytics = [];
      const batchSize = 10;

      for (int i = 0; i < questionIds.length; i += batchSize) {
        final batch = questionIds.skip(i).take(batchSize).toList();
        final querySnapshot = await _firestore
            .collection(_questionAnalyticsCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        final batchAnalytics = querySnapshot.docs
            .map((doc) => QuestionAnalytics.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null))
            .toList();

        allAnalytics.addAll(batchAnalytics);
      }

      return allAnalytics;
    } catch (e) {
      Logger.error('Failed to get multiple question analytics: $e');
      rethrow;
    }
  }

  /// Gets top performing questions (highest correct percentage)
  Future<List<QuestionAnalytics>> getTopPerformingQuestions({
    String? questionMode,
    String? questionType,
    int? difficultyLevel,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection(_questionAnalyticsCollection)
          .orderBy('correctPercentage', descending: true)
          .limit(limit);

      if (questionMode != null) {
        query = query.where('questionMode', isEqualTo: questionMode);
      }

      if (questionType != null) {
        query = query.where('questionType', isEqualTo: questionType);
      }

      if (difficultyLevel != null) {
        query = query.where('difficultyLevel', isEqualTo: difficultyLevel);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => QuestionAnalytics.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null))
          .toList();
    } catch (e) {
      Logger.error('Failed to get top performing questions: $e');
      rethrow;
    }
  }

  /// Gets worst performing questions (lowest correct percentage)
  Future<List<QuestionAnalytics>> getWorstPerformingQuestions({
    String? questionMode,
    String? questionType,
    int? difficultyLevel,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection(_questionAnalyticsCollection)
          .where('totalAttempts', isGreaterThan: 5) // Only questions with enough data
          .orderBy('totalAttempts')
          .orderBy('correctPercentage')
          .limit(limit);

      if (questionMode != null) {
        query = query.where('questionMode', isEqualTo: questionMode);
      }

      if (questionType != null) {
        query = query.where('questionType', isEqualTo: questionType);
      }

      if (difficultyLevel != null) {
        query = query.where('difficultyLevel', isEqualTo: difficultyLevel);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => QuestionAnalytics.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null))
          .toList();
    } catch (e) {
      Logger.error('Failed to get worst performing questions: $e');
      rethrow;
    }
  }

  /// Manually recalculates analytics for a question (for data maintenance)
  Future<void> recalculateQuestionAnalytics(Question question) async {
    await _updateQuestionAnalytics(question, forceRecalculation: true);
  }

  /// Updates question analytics directly using increments (for first attempts only)
  Future<void> _updateQuestionAnalyticsDirectly(
    Question question,
    int selectedAnswerIndex,
    int? timeSpentSeconds,
  ) async {
    try {
      final questionRef = _firestore
          .collection(_questionAnalyticsCollection)
          .doc(question.id);

      final isCorrect = selectedAnswerIndex == question.correctAnswerIndex;

      // Get current analytics or create default
      final currentDoc = await questionRef.get();

      if (!currentDoc.exists) {
        // Create initial analytics document
        final initialAnalytics = QuestionAnalytics(
          questionId: question.id,
          totalAttempts: 1,
          correctAttempts: isCorrect ? 1 : 0,
          wrongAttempts: isCorrect ? 0 : 1,
          correctPercentage: isCorrect ? 100.0 : 0.0,
          answerDistribution: {
            '0': selectedAnswerIndex == 0 ? 1 : 0,
            '1': selectedAnswerIndex == 1 ? 1 : 0,
            '2': selectedAnswerIndex == 2 ? 1 : 0,
            '3': selectedAnswerIndex == 3 ? 1 : 0,
          },
          answerPercentages: {
            '0': selectedAnswerIndex == 0 ? 100.0 : 0.0,
            '1': selectedAnswerIndex == 1 ? 100.0 : 0.0,
            '2': selectedAnswerIndex == 2 ? 100.0 : 0.0,
            '3': selectedAnswerIndex == 3 ? 100.0 : 0.0,
          },
          questionMode: _extractQuestionMode(question.id),
          questionType: _extractQuestionType(question),
          difficultyLevel: question.difficultyLevel,
          grammarPoint: question.grammarPoint,
          averageTimeSeconds: timeSpentSeconds,
          lastUpdated: DateTime.now(),
          metadata: {
            'correctAnswerIndex': question.correctAnswerIndex,
          },
        );

        await questionRef.set(QuestionAnalytics.toFirestore(initialAnalytics, null));
      } else {
        // Update existing analytics using increments
        final batch = _firestore.batch();

        batch.update(questionRef, {
          'totalAttempts': FieldValue.increment(1),
          'correctAttempts': FieldValue.increment(isCorrect ? 1 : 0),
          'wrongAttempts': FieldValue.increment(isCorrect ? 0 : 1),
          'answerDistribution.$selectedAnswerIndex': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        // Calculate and update percentages (requires a read after the increment)
        await _updatePercentages(questionRef);
      }

      Logger.info('Updated analytics directly for question ${question.id}');
    } catch (e) {
      Logger.error('Failed to update question analytics directly for ${question.id}: $e');
      rethrow;
    }
  }

  /// Updates percentages after incrementing counters
  Future<void> _updatePercentages(DocumentReference questionRef) async {
    try {
      final doc = await questionRef.get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final totalAttempts = data['totalAttempts'] as int;
      final correctAttempts = data['correctAttempts'] as int;
      final answerDistribution = Map<String, int>.from(data['answerDistribution'] ?? {});

      if (totalAttempts == 0) return;

      final correctPercentage = (correctAttempts / totalAttempts) * 100;
      final answerPercentages = <String, double>{};

      answerDistribution.forEach((index, count) {
        answerPercentages[index] = (count / totalAttempts) * 100;
      });

      await questionRef.update({
        'correctPercentage': double.parse(correctPercentage.toStringAsFixed(1)),
        'answerPercentages': answerPercentages.map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(1)))),
      });
    } catch (e) {
      Logger.error('Failed to update percentages: $e');
    }
  }

  /// Updates question analytics based on user answers (for recalculation)
  Future<void> _updateQuestionAnalytics(
    Question question, {
    bool forceRecalculation = false,
  }) async {
    try {
      // Get all user answers for this question
      final userAnswersQuery = await _firestore
          .collection(_userAnswersCollection)
          .where('questionId', isEqualTo: question.id)
          .get();

      final userAnswersData = userAnswersQuery.docs
          .map((doc) => doc.data())
          .toList();

      if (userAnswersData.isEmpty && !forceRecalculation) {
        return; // No answers yet, nothing to calculate
      }

      // Build analytics from user answers
      final analytics = QuestionAnalyticsBuilder.fromUserAnswers(
        questionId: question.id,
        userAnswers: userAnswersData,
        questionMode: _extractQuestionMode(question.id),
        questionType: _extractQuestionType(question),
        difficultyLevel: question.difficultyLevel,
        grammarPoint: question.grammarPoint,
        correctAnswerIndex: question.correctAnswerIndex,
      );

      // Save to Firestore
      await _firestore
          .collection(_questionAnalyticsCollection)
          .doc(question.id)
          .set(QuestionAnalytics.toFirestore(analytics, null));

      Logger.info('Updated analytics for question ${question.id}');
    } catch (e) {
      Logger.error('Failed to update question analytics for ${question.id}: $e');
      // Don't rethrow here as this is often called asynchronously
    }
  }

  /// Helper to extract question mode from question ID
  String _extractQuestionMode(String questionId) {
    if (questionId.contains('EXAM_')) return 'exam';
    if (questionId.contains('PRACTICE_')) return 'practice';
    return 'practice'; // Default
  }

  /// Helper to extract question type from question data
  String _extractQuestionType(Question question) {
    // You can enhance this logic based on your question data
    if (question.grammarPoint.isNotEmpty) return 'grammar';
    return 'vocabulary'; // Default
  }

  /// Gets user performance statistics
  Future<Map<String, dynamic>> getUserPerformanceStats(String userId) async {
    try {
      final userAnswers = await getUserAnswers(userId: userId);

      if (userAnswers.isEmpty) {
        return {
          'totalAnswered': 0,
          'correctAnswers': 0,
          'accuracy': 0.0,
          'averageTime': 0,
          'strongGrammarPoints': <String>[],
          'weakGrammarPoints': <String>[],
        };
      }

      final totalAnswered = userAnswers.length;
      final correctAnswers = userAnswers.where((answer) => answer.isCorrect).length;
      final accuracy = (correctAnswers / totalAnswered) * 100;

      // Calculate average time
      final answersWithTime = userAnswers
          .where((answer) => answer.timeSpentSeconds != null)
          .toList();
      final averageTime = answersWithTime.isNotEmpty
          ? answersWithTime
              .map((answer) => answer.timeSpentSeconds!)
              .reduce((a, b) => a + b) / answersWithTime.length
          : 0;

      // Analyze grammar points
      final grammarPointStats = <String, Map<String, int>>{};
      for (final answer in userAnswers) {
        final grammarPoint = answer.grammarPoint;
        grammarPointStats[grammarPoint] ??= {'correct': 0, 'total': 0};
        grammarPointStats[grammarPoint]!['total'] =
            grammarPointStats[grammarPoint]!['total']! + 1;
        if (answer.isCorrect) {
          grammarPointStats[grammarPoint]!['correct'] =
              grammarPointStats[grammarPoint]!['correct']! + 1;
        }
      }

      // Find strong and weak grammar points
      final strongPoints = <String>[];
      final weakPoints = <String>[];

      grammarPointStats.forEach((grammarPoint, stats) {
        final total = stats['total']!;
        final correct = stats['correct']!;
        if (total >= 3) { // Only consider points with enough data
          final accuracy = correct / total;
          if (accuracy >= 0.8) {
            strongPoints.add(grammarPoint);
          } else if (accuracy < 0.5) {
            weakPoints.add(grammarPoint);
          }
        }
      });

      return {
        'totalAnswered': totalAnswered,
        'correctAnswers': correctAnswers,
        'accuracy': double.parse(accuracy.toStringAsFixed(1)),
        'averageTime': averageTime.round(),
        'strongGrammarPoints': strongPoints,
        'weakGrammarPoints': weakPoints,
        'grammarPointStats': grammarPointStats,
      };
    } catch (e) {
      Logger.error('Failed to get user performance stats: $e');
      rethrow;
    }
  }
}