import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_answer_model.freezed.dart';
part 'user_answer_model.g.dart';

@freezed
class UserAnswer with _$UserAnswer {
  const factory UserAnswer({
    required String id,
    required String userId,
    required String questionId,
    required int selectedAnswerIndex,
    required int correctAnswerIndex,
    required bool isCorrect,
    required String questionMode, // 'practice' or 'exam'
    required String questionType, // 'grammar' or 'vocabulary'
    required int difficultyLevel,
    required String grammarPoint,
    String? sessionId, // For grouping answers in a session
    int? timeSpentSeconds, // Time spent on this question
    DateTime? answeredAt,
    Map<String, dynamic>? metadata, // Additional context data
  }) = _UserAnswer;

  factory UserAnswer.fromJson(Map<String, dynamic> json) =>
      _$UserAnswerFromJson(json);

  factory UserAnswer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return UserAnswer.fromJson({
      ...data,
      'id': snapshot.id,
      'answeredAt': data['answeredAt'] != null
          ? (data['answeredAt'] as Timestamp).toDate().toIso8601String()
          : null,
    });
  }

  static Map<String, dynamic> toFirestore(UserAnswer userAnswer, SetOptions? options) {
    return {
      ...userAnswer.toJson(),
      'answeredAt': userAnswer.answeredAt != null
          ? Timestamp.fromDate(userAnswer.answeredAt!)
          : FieldValue.serverTimestamp(),
    }..remove('id'); // Remove id as it's handled by Firestore
  }
}

// Extension for easier creation from user input
extension UserAnswerExtension on UserAnswer {
  static UserAnswer fromUserInput({
    required String userId,
    required String questionId,
    required int selectedAnswerIndex,
    required int correctAnswerIndex,
    required String questionMode,
    required String questionType,
    required int difficultyLevel,
    required String grammarPoint,
    String? sessionId,
    int? timeSpentSeconds,
    Map<String, dynamic>? metadata,
  }) {
    return UserAnswer(
      id: '', // Will be set by Firestore
      userId: userId,
      questionId: questionId,
      selectedAnswerIndex: selectedAnswerIndex,
      correctAnswerIndex: correctAnswerIndex,
      isCorrect: selectedAnswerIndex == correctAnswerIndex,
      questionMode: questionMode,
      questionType: questionType,
      difficultyLevel: difficultyLevel,
      grammarPoint: grammarPoint,
      sessionId: sessionId,
      timeSpentSeconds: timeSpentSeconds,
      answeredAt: DateTime.now(),
      metadata: metadata,
    );
  }
}