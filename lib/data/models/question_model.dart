import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

// TODO: Convert to Freezed after running code generation
// part 'question_model.freezed.dart';
// part 'question_model.g.dart';

@HiveType(typeId: 3)
class Question extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String questionText;
  @HiveField(2)
  final List<String> options;
  @HiveField(3)
  final int correctAnswerIndex;
  @HiveField(4)
  final int difficultyLevel;
  @HiveField(5)
  final String explanation;
  @HiveField(6)
  final String grammarPoint;
  @HiveField(7)
  final List<String>? tags;
  @HiveField(8)
  final DateTime? createdAt;
  @HiveField(9)
  final bool isBookmarked;

  const Question({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.difficultyLevel,
    required this.explanation,
    required this.grammarPoint,
    this.tags,
    this.createdAt,
    this.isBookmarked = false,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      difficultyLevel: json['difficultyLevel'] as int,
      explanation: json['explanation'] as String,
      grammarPoint: json['grammarPoint'] as String,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'difficultyLevel': difficultyLevel,
      'explanation': explanation,
      'grammarPoint': grammarPoint,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
      'isBookmarked': isBookmarked,
    };
  }

  Question copyWith({
    String? id,
    String? questionText,
    List<String>? options,
    int? correctAnswerIndex,
    int? difficultyLevel,
    String? explanation,
    String? grammarPoint,
    List<String>? tags,
    DateTime? createdAt,
    bool? isBookmarked,
  }) {
    return Question(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      explanation: explanation ?? this.explanation,
      grammarPoint: grammarPoint ?? this.grammarPoint,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  @override
  List<Object?> get props => [
        id,
        questionText,
        options,
        correctAnswerIndex,
        difficultyLevel,
        explanation,
        grammarPoint,
        tags,
        createdAt,
        isBookmarked,
      ];

  factory Question.fromFirestore(Map<String, dynamic> data, String id) {
    return Question(
      id: id,
      questionText: data['questionText'] as String,
      options: List<String>.from(data['options'] as List),
      correctAnswerIndex: data['correctAnswerIndex'] as int,
      difficultyLevel: data['difficultyLevel'] as int,
      explanation: data['explanation'] as String,
      grammarPoint: data['grammarPoint'] as String,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'difficultyLevel': difficultyLevel,
      'explanation': explanation,
      'grammarPoint': grammarPoint,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}