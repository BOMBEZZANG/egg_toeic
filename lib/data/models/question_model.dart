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

  static List<String>? _extractTags(dynamic tagsData) {
    if (tagsData == null) return null;
    if (tagsData is List) {
      return List<String>.from(tagsData);
    } else if (tagsData is Map) {
      final tagsMap = tagsData as Map<String, dynamic>;
      final sortedKeys = tagsMap.keys.toList()..sort();
      return sortedKeys.map((key) => tagsMap[key].toString()).toList();
    } else if (tagsData is String) {
      return [tagsData];
    }
    return null;
  }

  factory Question.fromFirestore(Map<String, dynamic> data, String id) {
    // Handle options field that can be either List or Map format
    List<String> optionsList = [];
    final optionsData = data['options'];

    if (optionsData is List) {
      // Handle List format: ["option1", "option2", "option3", "option4"]
      optionsList = List<String>.from(optionsData);
    } else if (optionsData is Map) {
      // Handle Map format: {"0": "option1", "1": "option2", "2": "option3", "3": "option4"}
      final optionsMap = optionsData as Map<String, dynamic>;
      // Sort by key to maintain order (0, 1, 2, 3)
      final sortedKeys = optionsMap.keys.toList()..sort();
      optionsList = sortedKeys.map((key) => optionsMap[key].toString()).toList();
    } else if (optionsData is String) {
      // Handle single string - split by common delimiters
      optionsList = optionsData.split('\n').where((s) => s.trim().isNotEmpty).toList();
    } else {
      print('⚠️ Unknown options format for question $id: ${optionsData.runtimeType}');
      optionsList = ['Option A', 'Option B', 'Option C', 'Option D']; // Fallback
    }

    return Question(
      id: id,
      questionText: data['questionText'] as String,
      options: optionsList,
      correctAnswerIndex: data['correctAnswerIndex'] as int,
      difficultyLevel: data['difficultyLevel'] as int,
      explanation: data['explanation'] as String,
      grammarPoint: data['grammarPoint'] as String,
      tags: _extractTags(data['tags']),
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