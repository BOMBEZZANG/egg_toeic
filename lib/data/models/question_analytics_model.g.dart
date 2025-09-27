// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_analytics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuestionAnalyticsImpl _$$QuestionAnalyticsImplFromJson(
        Map<String, dynamic> json) =>
    _$QuestionAnalyticsImpl(
      questionId: json['questionId'] as String,
      totalAttempts: (json['totalAttempts'] as num).toInt(),
      correctAttempts: (json['correctAttempts'] as num).toInt(),
      wrongAttempts: (json['wrongAttempts'] as num).toInt(),
      correctPercentage: (json['correctPercentage'] as num).toDouble(),
      answerDistribution:
          Map<String, int>.from(json['answerDistribution'] as Map),
      answerPercentages:
          (json['answerPercentages'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      questionMode: json['questionMode'] as String,
      questionType: json['questionType'] as String,
      difficultyLevel: (json['difficultyLevel'] as num).toInt(),
      grammarPoint: json['grammarPoint'] as String,
      averageTimeSeconds: (json['averageTimeSeconds'] as num?)?.toInt(),
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$QuestionAnalyticsImplToJson(
        _$QuestionAnalyticsImpl instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'totalAttempts': instance.totalAttempts,
      'correctAttempts': instance.correctAttempts,
      'wrongAttempts': instance.wrongAttempts,
      'correctPercentage': instance.correctPercentage,
      'answerDistribution': instance.answerDistribution,
      'answerPercentages': instance.answerPercentages,
      'questionMode': instance.questionMode,
      'questionType': instance.questionType,
      'difficultyLevel': instance.difficultyLevel,
      'grammarPoint': instance.grammarPoint,
      'averageTimeSeconds': instance.averageTimeSeconds,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
      'metadata': instance.metadata,
    };
