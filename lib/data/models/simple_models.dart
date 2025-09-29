// Temporary simple models without Freezed for immediate compilation
// TODO: Replace with Freezed models after code generation

import 'package:equatable/equatable.dart';

enum AchievementType {
  streak,
  questions,
  accuracy,
  level,
  special,
  review,
  grammar,
}

class SimpleQuestion extends Equatable {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final int difficultyLevel;
  final String explanation;
  final String grammarPoint;
  final String questionType;  // 'grammar' or 'vocabulary'
  final List<String>? tags;
  final DateTime? createdAt;
  final bool isBookmarked;

  const SimpleQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.difficultyLevel,
    required this.explanation,
    required this.grammarPoint,
    required this.questionType,
    this.tags,
    this.createdAt,
    this.isBookmarked = false,
  });

  static List<String> _extractTags(dynamic tagsData) {
    if (tagsData == null) return [];
    if (tagsData is List) {
      return List<String>.from(tagsData);
    } else if (tagsData is Map) {
      final tagsMap = tagsData as Map<String, dynamic>;
      final sortedKeys = tagsMap.keys.toList()..sort();
      return sortedKeys.map((key) => tagsMap[key].toString()).toList();
    } else if (tagsData is String) {
      return [tagsData];
    }
    return [];
  }

  factory SimpleQuestion.fromFirestore(Map<String, dynamic> data, String id) {
    try {
      // Handle options field that can be either List or Map format
      List<String> optionsList = [];
      final optionsData = data['options'];

      if (optionsData is List) {
        // Handle List format: ["option1", "option2", "option3", "option4"]
        optionsList = List<String>.from(optionsData);
        print('📋 Loaded options as List: $optionsList');
      } else if (optionsData is Map) {
        // Handle Map format: {"0": "option1", "1": "option2", "2": "option3", "3": "option4"}
        final optionsMap = optionsData as Map<String, dynamic>;
        // Sort by key to maintain order (0, 1, 2, 3)
        final sortedKeys = optionsMap.keys.toList()..sort();
        optionsList = sortedKeys.map((key) => optionsMap[key].toString()).toList();
        print('📋 Loaded options as Map: $optionsList');
      } else if (optionsData is String) {
        // Handle single string - split by common delimiters
        optionsList = optionsData.split('\n').where((s) => s.trim().isNotEmpty).toList();
        print('📋 Loaded options as String: $optionsList');
      } else {
        print('⚠️ Unknown options format for question $id: ${optionsData.runtimeType}');
        optionsList = ['Option A', 'Option B', 'Option C', 'Option D']; // Fallback
      }

      return SimpleQuestion(
        id: id,
        questionText: data['questionText'] as String? ?? 'Question text missing',
        options: optionsList,
        correctAnswerIndex: data['correctAnswerIndex'] as int? ?? 0,
        difficultyLevel: data['difficultyLevel'] as int? ?? 1,
        explanation: data['explanation'] as String? ?? 'No explanation provided',
        grammarPoint: data['grammarPoint'] as String? ?? 'Grammar',
        questionType: data['questionType'] as String? ?? 'grammar',
        tags: _extractTags(data['tags']),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] is String
                ? DateTime.parse(data['createdAt'] as String)
                : (data['createdAt'] as dynamic).toDate())
            : DateTime.now(),
      );
    } catch (e) {
      print('❌ Error parsing question $id: $e');
      print('📊 Question data keys: ${data.keys.toList()}');
      print('📊 Options data type: ${data['options'].runtimeType}');
      print('📊 Raw options data: ${data['options']}');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'difficultyLevel': difficultyLevel,
      'explanation': explanation,
      'grammarPoint': grammarPoint,
      'questionType': questionType,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Add JSON serialization methods for Hive storage
  factory SimpleQuestion.fromJson(Map<String, dynamic> json) {
    return SimpleQuestion(
      id: json['id'] as String,
      questionText: json['questionText'] as String? ?? 'Question text missing',
      options: List<String>.from(json['options'] as List? ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
      difficultyLevel: json['difficultyLevel'] as int? ?? 1,
      explanation: json['explanation'] as String? ?? 'No explanation provided',
      grammarPoint: json['grammarPoint'] as String? ?? 'Grammar',
      questionType: json['questionType'] as String? ?? 'grammar',
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
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
      'questionType': questionType,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
      'isBookmarked': isBookmarked,
    };
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
        questionType,
        tags,
        createdAt,
        isBookmarked,
      ];
}

class SimpleUserProgress extends Equatable {
  final int totalQuestionsAnswered;
  final int correctAnswers;
  final int currentStreak;
  final int longestStreak;
  final int experiencePoints;
  final int userLevel;
  final DateTime? lastStudyDate;
  final Map<String, double> levelProgress;
  final List<String> unlockedAchievements;
  final List<String> favoriteQuestionIds;
  final Map<String, int> grammarPointScores;
  final int totalStudyTimeMinutes;

  const SimpleUserProgress({
    this.totalQuestionsAnswered = 0,
    this.correctAnswers = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.experiencePoints = 0,
    this.userLevel = 1,
    this.lastStudyDate,
    this.levelProgress = const {},
    this.unlockedAchievements = const [],
    this.favoriteQuestionIds = const [],
    this.grammarPointScores = const {},
    this.totalStudyTimeMinutes = 0,
  });

  factory SimpleUserProgress.initial() => SimpleUserProgress(
        lastStudyDate: DateTime.now(),
        levelProgress: {
          'level1': 0.0,
          'level2': 0.0,
          'level3': 0.0,
        },
      );

  double get overallAccuracy {
    if (totalQuestionsAnswered == 0) return 0.0;
    return (correctAnswers / totalQuestionsAnswered) * 100;
  }

  int get xpToNextLevel {
    return (userLevel * 100) + 100;
  }

  double get currentLevelProgress {
    final levelXp = experiencePoints % xpToNextLevel;
    return levelXp / xpToNextLevel;
  }

  String get characterType {
    if (userLevel <= 5) return 'Egg';
    if (userLevel <= 10) return 'Chick';
    if (userLevel <= 20) return 'Bird';
    if (userLevel <= 30) return 'Eagle';
    return 'Phoenix';
  }

  String get characterEmoji {
    if (userLevel <= 5) return '🥚';
    if (userLevel <= 10) return '🐣';
    if (userLevel <= 20) return '🐦';
    if (userLevel <= 30) return '🦅';
    return '🔥';
  }

  SimpleUserProgress copyWith({
    int? totalQuestionsAnswered,
    int? correctAnswers,
    int? currentStreak,
    int? longestStreak,
    int? experiencePoints,
    int? userLevel,
    DateTime? lastStudyDate,
    Map<String, double>? levelProgress,
    List<String>? unlockedAchievements,
    List<String>? favoriteQuestionIds,
    Map<String, int>? grammarPointScores,
    int? totalStudyTimeMinutes,
  }) {
    return SimpleUserProgress(
      totalQuestionsAnswered: totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      userLevel: userLevel ?? this.userLevel,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      levelProgress: levelProgress ?? this.levelProgress,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      favoriteQuestionIds: favoriteQuestionIds ?? this.favoriteQuestionIds,
      grammarPointScores: grammarPointScores ?? this.grammarPointScores,
      totalStudyTimeMinutes: totalStudyTimeMinutes ?? this.totalStudyTimeMinutes,
    );
  }

  @override
  List<Object?> get props => [
        totalQuestionsAnswered,
        correctAnswers,
        currentStreak,
        longestStreak,
        experiencePoints,
        userLevel,
        lastStudyDate,
        levelProgress,
        unlockedAchievements,
        favoriteQuestionIds,
        grammarPointScores,
        totalStudyTimeMinutes,
      ];
}