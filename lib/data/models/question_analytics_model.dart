import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'question_analytics_model.freezed.dart';
part 'question_analytics_model.g.dart';

@freezed
class QuestionAnalytics with _$QuestionAnalytics {
  const factory QuestionAnalytics({
    required String questionId,
    required int totalAttempts,
    required int correctAttempts,
    required int wrongAttempts,
    required double correctPercentage,
    required Map<String, int> answerDistribution, // {"0": 45, "1": 20, "2": 15, "3": 12}
    required Map<String, double> answerPercentages, // {"0": 48.9, "1": 21.7, "2": 16.3, "3": 13.1}
    required String questionMode, // 'practice' or 'exam'
    required String questionType, // 'grammar' or 'vocabulary'
    required int difficultyLevel,
    required String grammarPoint,
    int? averageTimeSeconds,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata, // Additional analytics data
  }) = _QuestionAnalytics;

  factory QuestionAnalytics.fromJson(Map<String, dynamic> json) =>
      _$QuestionAnalyticsFromJson(json);

  factory QuestionAnalytics.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return QuestionAnalytics.fromJson({
      ...data,
      'questionId': snapshot.id,
      'lastUpdated': data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate().toIso8601String()
          : null,
    });
  }

  static Map<String, dynamic> toFirestore(QuestionAnalytics analytics, SetOptions? options) {
    return {
      ...analytics.toJson(),
      'lastUpdated': analytics.lastUpdated != null
          ? Timestamp.fromDate(analytics.lastUpdated!)
          : FieldValue.serverTimestamp(),
    }..remove('questionId'); // Remove questionId as it's the document ID
  }
}

// Extension for calculating analytics
extension QuestionAnalyticsCalculations on QuestionAnalytics {
  /// Gets the most popular wrong answer index
  int? get mostPopularWrongAnswer {
    final wrongAnswers = Map<String, int>.from(answerDistribution);
    wrongAnswers.remove(correctAnswerIndex.toString());

    if (wrongAnswers.isEmpty) return null;

    var maxCount = 0;
    String? maxIndex;
    wrongAnswers.forEach((index, count) {
      if (count > maxCount) {
        maxCount = count;
        maxIndex = index;
      }
    });

    return maxIndex != null ? int.parse(maxIndex!) : null;
  }

  /// Gets the difficulty assessment based on correct percentage
  String get difficultyAssessment {
    if (correctPercentage >= 80) return 'Easy';
    if (correctPercentage >= 60) return 'Medium';
    if (correctPercentage >= 40) return 'Hard';
    return 'Very Hard';
  }

  /// Checks if this question needs review (low success rate)
  bool get needsReview => correctPercentage < 50 && totalAttempts > 10;

  /// Gets the correct answer index from answer distribution
  int get correctAnswerIndex {
    // Find the answer that should be correct based on the stored data
    // This assumes the correct answer is stored in metadata or can be derived
    // For now, we'll need to get this from the original question
    return metadata?['correctAnswerIndex'] as int? ?? 0;
  }
}

// Helper class for building analytics from user answers
class QuestionAnalyticsBuilder {
  static QuestionAnalytics fromUserAnswers({
    required String questionId,
    required List<Map<String, dynamic>> userAnswers,
    required String questionMode,
    required String questionType,
    required int difficultyLevel,
    required String grammarPoint,
    required int correctAnswerIndex,
  }) {
    final totalAttempts = userAnswers.length;
    final correctAttempts = userAnswers.where((answer) => answer['isCorrect'] == true).length;
    final wrongAttempts = totalAttempts - correctAttempts;
    final correctPercentage = totalAttempts > 0 ? (correctAttempts / totalAttempts) * 100 : 0.0;

    // Calculate answer distribution
    final answerDistribution = <String, int>{
      '0': 0,
      '1': 0,
      '2': 0,
      '3': 0,
    };

    for (final answer in userAnswers) {
      final selectedIndex = answer['selectedAnswerIndex'].toString();
      answerDistribution[selectedIndex] = (answerDistribution[selectedIndex] ?? 0) + 1;
    }

    // Calculate answer percentages
    final answerPercentages = <String, double>{};
    answerDistribution.forEach((index, count) {
      answerPercentages[index] = totalAttempts > 0 ? (count / totalAttempts) * 100 : 0.0;
    });

    // Calculate average time if available
    final timesWithData = userAnswers
        .where((answer) => answer['timeSpentSeconds'] != null)
        .map((answer) => answer['timeSpentSeconds'] as int)
        .toList();

    final averageTimeSeconds = timesWithData.isNotEmpty
        ? (timesWithData.reduce((a, b) => a + b) / timesWithData.length).round()
        : null;

    return QuestionAnalytics(
      questionId: questionId,
      totalAttempts: totalAttempts,
      correctAttempts: correctAttempts,
      wrongAttempts: wrongAttempts,
      correctPercentage: double.parse(correctPercentage.toStringAsFixed(1)),
      answerDistribution: answerDistribution,
      answerPercentages: answerPercentages.map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(1)))),
      questionMode: questionMode,
      questionType: questionType,
      difficultyLevel: difficultyLevel,
      grammarPoint: grammarPoint,
      averageTimeSeconds: averageTimeSeconds,
      lastUpdated: DateTime.now(),
      metadata: {
        'correctAnswerIndex': correctAnswerIndex,
        'lastRecalculated': DateTime.now().toIso8601String(),
      },
    );
  }
}