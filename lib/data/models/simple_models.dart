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
    this.tags,
    this.createdAt,
    this.isBookmarked = false,
  });

  factory SimpleQuestion.fromFirestore(Map<String, dynamic> data, String id) {
    return SimpleQuestion(
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