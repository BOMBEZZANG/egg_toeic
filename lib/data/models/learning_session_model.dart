import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

// TODO: Convert to Freezed after running code generation
// part 'learning_session_model.freezed.dart';
// part 'learning_session_model.g.dart';

@HiveType(typeId: 2)
class LearningSession extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime startTime;
  @HiveField(2)
  final DateTime? endTime;
  @HiveField(3)
  final int questionsAnswered;
  @HiveField(4)
  final int correctAnswers;
  @HiveField(5)
  final List<String> questionIds;
  @HiveField(6)
  final int? difficultyLevel;
  @HiveField(7)
  final int experienceEarned;
  @HiveField(8)
  final String sessionType;
  @HiveField(9)
  final List<String> wrongAnswerIds;
  @HiveField(10)
  final bool isCompleted;

  const LearningSession({
    required this.id,
    required this.startTime,
    this.endTime,
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.questionIds = const [],
    this.difficultyLevel,
    this.experienceEarned = 0,
    this.sessionType = 'practice',
    this.wrongAnswerIds = const [],
    this.isCompleted = false,
  });

  factory LearningSession.fromJson(Map<String, dynamic> json) {
    return LearningSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      questionsAnswered: json['questionsAnswered'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      questionIds: List<String>.from(json['questionIds'] as List? ?? []),
      difficultyLevel: json['difficultyLevel'] as int?,
      experienceEarned: json['experienceEarned'] as int? ?? 0,
      sessionType: json['sessionType'] as String? ?? 'practice',
      wrongAnswerIds: List<String>.from(json['wrongAnswerIds'] as List? ?? []),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'questionsAnswered': questionsAnswered,
      'correctAnswers': correctAnswers,
      'questionIds': questionIds,
      'difficultyLevel': difficultyLevel,
      'experienceEarned': experienceEarned,
      'sessionType': sessionType,
      'wrongAnswerIds': wrongAnswerIds,
      'isCompleted': isCompleted,
    };
  }

  factory LearningSession.start({
    int? difficultyLevel,
    String sessionType = 'practice',
  }) {
    return LearningSession(
      id: const Uuid().v4(),
      startTime: DateTime.now(),
      difficultyLevel: difficultyLevel,
      sessionType: sessionType,
    );
  }

  int get durationMinutes {
    if (endTime == null) {
      return DateTime.now().difference(startTime).inMinutes;
    }
    return endTime!.difference(startTime).inMinutes;
  }

  double get accuracy {
    if (questionsAnswered == 0) return 0.0;
    return (correctAnswers / questionsAnswered) * 100;
  }

  double get averageTimePerQuestion {
    if (questionsAnswered == 0) return 0.0;
    return durationMinutes / questionsAnswered;
  }

  LearningSession complete() {
    return copyWith(
      endTime: DateTime.now(),
      isCompleted: true,
    );
  }

  LearningSession addQuestion({
    required String questionId,
    required bool isCorrect,
    String? wrongAnswerId,
  }) {
    return copyWith(
      questionsAnswered: questionsAnswered + 1,
      correctAnswers: isCorrect ? correctAnswers + 1 : correctAnswers,
      questionIds: [...questionIds, questionId],
      wrongAnswerIds: wrongAnswerId != null
          ? [...wrongAnswerIds, wrongAnswerId]
          : wrongAnswerIds,
    );
  }

  LearningSession addExperience(int xp) {
    return copyWith(
      experienceEarned: experienceEarned + xp,
    );
  }

  LearningSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? questionsAnswered,
    int? correctAnswers,
    List<String>? questionIds,
    int? difficultyLevel,
    int? experienceEarned,
    String? sessionType,
    List<String>? wrongAnswerIds,
    bool? isCompleted,
  }) {
    return LearningSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      questionIds: questionIds ?? this.questionIds,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      experienceEarned: experienceEarned ?? this.experienceEarned,
      sessionType: sessionType ?? this.sessionType,
      wrongAnswerIds: wrongAnswerIds ?? this.wrongAnswerIds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        startTime,
        endTime,
        questionsAnswered,
        correctAnswers,
        questionIds,
        difficultyLevel,
        experienceEarned,
        sessionType,
        wrongAnswerIds,
        isCompleted,
      ];
}