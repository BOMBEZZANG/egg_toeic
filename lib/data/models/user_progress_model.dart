import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

// TODO: Convert to Freezed after running code generation
// part 'user_progress_model.freezed.dart';
// part 'user_progress_model.g.dart';

@HiveType(typeId: 0)
class UserProgress extends Equatable {
  @HiveField(0)
  final int totalQuestionsAnswered;
  @HiveField(1)
  final int correctAnswers;
  @HiveField(2)
  final int currentStreak;
  @HiveField(3)
  final int longestStreak;
  @HiveField(4)
  final int experiencePoints;
  @HiveField(5)
  final int userLevel;
  @HiveField(6)
  final DateTime? lastStudyDate;
  @HiveField(7)
  final Map<String, double> levelProgress;
  @HiveField(8)
  final List<String> unlockedAchievements;
  @HiveField(9)
  final List<String> favoriteQuestionIds;
  @HiveField(10)
  final Map<String, int> grammarPointScores;
  @HiveField(11)
  final int totalStudyTimeMinutes;

  const UserProgress({
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

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalQuestionsAnswered: json['totalQuestionsAnswered'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      experiencePoints: json['experiencePoints'] as int? ?? 0,
      userLevel: json['userLevel'] as int? ?? 1,
      lastStudyDate: json['lastStudyDate'] != null
          ? DateTime.parse(json['lastStudyDate'] as String)
          : null,
      levelProgress: Map<String, double>.from(json['levelProgress'] as Map? ?? {}),
      unlockedAchievements: List<String>.from(json['unlockedAchievements'] as List? ?? []),
      favoriteQuestionIds: List<String>.from(json['favoriteQuestionIds'] as List? ?? []),
      grammarPointScores: Map<String, int>.from(json['grammarPointScores'] as Map? ?? {}),
      totalStudyTimeMinutes: json['totalStudyTimeMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'correctAnswers': correctAnswers,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'experiencePoints': experiencePoints,
      'userLevel': userLevel,
      'lastStudyDate': lastStudyDate?.toIso8601String(),
      'levelProgress': levelProgress,
      'unlockedAchievements': unlockedAchievements,
      'favoriteQuestionIds': favoriteQuestionIds,
      'grammarPointScores': grammarPointScores,
      'totalStudyTimeMinutes': totalStudyTimeMinutes,
    };
  }

  UserProgress copyWith({
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
    return UserProgress(
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

  factory UserProgress.initial() => UserProgress(
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

  String get characterName {
    return characterType;
  }

  double get accuracyPercentage {
    return overallAccuracy;
  }

  // Questions answered today
  int? get questionsToday {
    if (lastStudyDate == null) return 0;
    final today = DateTime.now();
    final lastStudy = lastStudyDate!;

    if (today.year == lastStudy.year &&
        today.month == lastStudy.month &&
        today.day == lastStudy.day) {
      // Return approximate questions for today (can be improved with session tracking)
      return (totalQuestionsAnswered * 0.1).round().clamp(0, 20);
    }
    return 0;
  }
}