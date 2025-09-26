import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

// TODO: Convert to Freezed after running code generation
// part 'wrong_answer_model.freezed.dart';
// part 'wrong_answer_model.g.dart';

@HiveType(typeId: 1)
class WrongAnswer extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String questionId;
  @HiveField(2)
  final int selectedAnswerIndex;
  @HiveField(3)
  final int correctAnswerIndex;
  @HiveField(4)
  final DateTime answeredAt;
  @HiveField(5)
  final int reviewCount;
  @HiveField(6)
  final bool isResolved;
  @HiveField(7)
  final String? grammarPoint;
  @HiveField(8)
  final int? difficultyLevel;
  @HiveField(9)
  final DateTime? lastReviewedAt;
  @HiveField(10)
  final String? questionText;
  @HiveField(11)
  final List<String>? options;
  @HiveField(12)
  final String? modeType; // 'practice' or 'exam'
  @HiveField(13)
  final String? category; // 'grammar' or 'vocabulary'
  @HiveField(14)
  final List<String>? tags;
  @HiveField(15)
  final String? explanation;

  const WrongAnswer({
    required this.id,
    required this.questionId,
    required this.selectedAnswerIndex,
    required this.correctAnswerIndex,
    required this.answeredAt,
    this.reviewCount = 0,
    this.isResolved = false,
    this.grammarPoint,
    this.difficultyLevel,
    this.lastReviewedAt,
    this.questionText,
    this.options,
    this.modeType,
    this.category,
    this.tags,
    this.explanation,
  });

  factory WrongAnswer.fromJson(Map<String, dynamic> json) {
    return WrongAnswer(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      selectedAnswerIndex: json['selectedAnswerIndex'] as int,
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      answeredAt: DateTime.parse(json['answeredAt'] as String),
      reviewCount: json['reviewCount'] as int? ?? 0,
      isResolved: json['isResolved'] as bool? ?? false,
      grammarPoint: json['grammarPoint'] as String?,
      difficultyLevel: json['difficultyLevel'] as int?,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.parse(json['lastReviewedAt'] as String)
          : null,
      questionText: json['questionText'] as String?,
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
      modeType: json['modeType'] as String?,
      category: json['category'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'selectedAnswerIndex': selectedAnswerIndex,
      'correctAnswerIndex': correctAnswerIndex,
      'answeredAt': answeredAt.toIso8601String(),
      'reviewCount': reviewCount,
      'isResolved': isResolved,
      'grammarPoint': grammarPoint,
      'difficultyLevel': difficultyLevel,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'questionText': questionText,
      'options': options,
      'modeType': modeType,
      'category': category,
      'tags': tags,
      'explanation': explanation,
    };
  }

  factory WrongAnswer.create({
    required String questionId,
    required int selectedAnswerIndex,
    required int correctAnswerIndex,
    String? grammarPoint,
    int? difficultyLevel,
    String? questionText,
    List<String>? options,
    String? modeType,
    String? category,
    List<String>? tags,
    String? explanation,
  }) {
    return WrongAnswer(
      id: const Uuid().v4(),
      questionId: questionId,
      selectedAnswerIndex: selectedAnswerIndex,
      correctAnswerIndex: correctAnswerIndex,
      answeredAt: DateTime.now(),
      grammarPoint: grammarPoint,
      difficultyLevel: difficultyLevel,
      questionText: questionText,
      options: options,
      modeType: modeType,
      category: category,
      tags: tags,
      explanation: explanation,
    );
  }

  bool get needsReview {
    if (isResolved) return false;
    if (lastReviewedAt == null) return true;

    final daysSinceReview = DateTime.now().difference(lastReviewedAt!).inDays;
    return daysSinceReview >= _getReviewInterval();
  }

  int _getReviewInterval() {
    switch (reviewCount) {
      case 0:
        return 1; // Review after 1 day
      case 1:
        return 3; // Review after 3 days
      case 2:
        return 7; // Review after 1 week
      case 3:
        return 14; // Review after 2 weeks
      default:
        return 30; // Review after 1 month
    }
  }

  WrongAnswer markAsReviewed({bool resolved = false}) {
    return copyWith(
      reviewCount: reviewCount + 1,
      lastReviewedAt: DateTime.now(),
      isResolved: resolved,
    );
  }

  WrongAnswer copyWith({
    String? id,
    String? questionId,
    int? selectedAnswerIndex,
    int? correctAnswerIndex,
    DateTime? answeredAt,
    int? reviewCount,
    bool? isResolved,
    String? grammarPoint,
    int? difficultyLevel,
    DateTime? lastReviewedAt,
    String? questionText,
    List<String>? options,
    String? modeType,
    String? category,
    List<String>? tags,
    String? explanation,
  }) {
    return WrongAnswer(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      selectedAnswerIndex: selectedAnswerIndex ?? this.selectedAnswerIndex,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      answeredAt: answeredAt ?? this.answeredAt,
      reviewCount: reviewCount ?? this.reviewCount,
      isResolved: isResolved ?? this.isResolved,
      grammarPoint: grammarPoint ?? this.grammarPoint,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      modeType: modeType ?? this.modeType,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      explanation: explanation ?? this.explanation,
    );
  }

  @override
  List<Object?> get props => [
        id,
        questionId,
        selectedAnswerIndex,
        correctAnswerIndex,
        answeredAt,
        reviewCount,
        isResolved,
        grammarPoint,
        difficultyLevel,
        lastReviewedAt,
        questionText,
        options,
        modeType,
        category,
        tags,
        explanation,
      ];
}