// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_answer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserAnswerImpl _$$UserAnswerImplFromJson(Map<String, dynamic> json) =>
    _$UserAnswerImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      questionId: json['questionId'] as String,
      selectedAnswerIndex: (json['selectedAnswerIndex'] as num).toInt(),
      correctAnswerIndex: (json['correctAnswerIndex'] as num).toInt(),
      isCorrect: json['isCorrect'] as bool,
      questionMode: json['questionMode'] as String,
      questionType: json['questionType'] as String,
      difficultyLevel: (json['difficultyLevel'] as num).toInt(),
      grammarPoint: json['grammarPoint'] as String,
      sessionId: json['sessionId'] as String?,
      timeSpentSeconds: (json['timeSpentSeconds'] as num?)?.toInt(),
      answeredAt: json['answeredAt'] == null
          ? null
          : DateTime.parse(json['answeredAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$UserAnswerImplToJson(_$UserAnswerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'questionId': instance.questionId,
      'selectedAnswerIndex': instance.selectedAnswerIndex,
      'correctAnswerIndex': instance.correctAnswerIndex,
      'isCorrect': instance.isCorrect,
      'questionMode': instance.questionMode,
      'questionType': instance.questionType,
      'difficultyLevel': instance.difficultyLevel,
      'grammarPoint': instance.grammarPoint,
      'sessionId': instance.sessionId,
      'timeSpentSeconds': instance.timeSpentSeconds,
      'answeredAt': instance.answeredAt?.toIso8601String(),
      'metadata': instance.metadata,
    };
