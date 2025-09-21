import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

// TODO: Convert to Freezed after running code generation
// part 'achievement_model.freezed.dart';
// part 'achievement_model.g.dart';

@HiveType(typeId: 4)
class Achievement extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String iconAsset;
  @HiveField(4)
  final int requiredValue;
  @HiveField(5)
  final int currentValue;
  @HiveField(6)
  final bool isUnlocked;
  @HiveField(7)
  final DateTime? unlockedAt;
  @HiveField(8)
  final String category;
  @HiveField(9)
  final int xpReward;
  @HiveField(10)
  final AchievementType type;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.requiredValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.category,
    this.xpReward = 0,
    required this.type,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconAsset: json['iconAsset'] as String,
      requiredValue: json['requiredValue'] as int,
      currentValue: json['currentValue'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      category: json['category'] as String,
      xpReward: json['xpReward'] as int? ?? 0,
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == 'AchievementType.${json['type']}',
        orElse: () => AchievementType.special,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconAsset': iconAsset,
      'requiredValue': requiredValue,
      'currentValue': currentValue,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'category': category,
      'xpReward': xpReward,
      'type': type.toString().split('.').last,
    };
  }

  double get progress {
    if (isUnlocked) return 1.0;
    if (requiredValue == 0) return 0.0;
    return (currentValue / requiredValue).clamp(0.0, 1.0);
  }

  bool get isNearCompletion {
    return progress >= 0.8 && !isUnlocked;
  }

  Achievement updateProgress(int newValue) {
    final shouldUnlock = newValue >= requiredValue;
    return copyWith(
      currentValue: newValue,
      isUnlocked: shouldUnlock,
      unlockedAt: shouldUnlock && !isUnlocked ? DateTime.now() : unlockedAt,
    );
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconAsset,
    int? requiredValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? category,
    int? xpReward,
    AchievementType? type,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      requiredValue: requiredValue ?? this.requiredValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      category: category ?? this.category,
      xpReward: xpReward ?? this.xpReward,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        iconAsset,
        requiredValue,
        currentValue,
        isUnlocked,
        unlockedAt,
        category,
        xpReward,
        type,
      ];

  static List<Achievement> getDefaultAchievements() {
    return [
      // Streak Achievements
      Achievement(
        id: 'streak_3',
        title: 'Getting Started',
        description: 'Study for 3 days in a row',
        iconAsset: 'assets/icons/streak_3.png',
        requiredValue: 3,
        category: 'Streak',
        xpReward: 50,
        type: AchievementType.streak,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Weekly Warrior',
        description: 'Study for 7 days in a row',
        iconAsset: 'assets/icons/streak_7.png',
        requiredValue: 7,
        category: 'Streak',
        xpReward: 100,
        type: AchievementType.streak,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Monthly Master',
        description: 'Study for 30 days in a row',
        iconAsset: 'assets/icons/streak_30.png',
        requiredValue: 30,
        category: 'Streak',
        xpReward: 500,
        type: AchievementType.streak,
      ),

      // Question Achievements
      Achievement(
        id: 'questions_10',
        title: 'First Steps',
        description: 'Answer 10 questions',
        iconAsset: 'assets/icons/questions_10.png',
        requiredValue: 10,
        category: 'Questions',
        xpReward: 30,
        type: AchievementType.questions,
      ),
      Achievement(
        id: 'questions_100',
        title: 'Centurion',
        description: 'Answer 100 questions',
        iconAsset: 'assets/icons/questions_100.png',
        requiredValue: 100,
        category: 'Questions',
        xpReward: 200,
        type: AchievementType.questions,
      ),
      Achievement(
        id: 'questions_1000',
        title: 'Question Master',
        description: 'Answer 1000 questions',
        iconAsset: 'assets/icons/questions_1000.png',
        requiredValue: 1000,
        category: 'Questions',
        xpReward: 1000,
        type: AchievementType.questions,
      ),

      // Accuracy Achievements
      Achievement(
        id: 'perfect_10',
        title: 'Perfectionist',
        description: 'Get 10 questions correct in a row',
        iconAsset: 'assets/icons/perfect_10.png',
        requiredValue: 10,
        category: 'Accuracy',
        xpReward: 100,
        type: AchievementType.accuracy,
      ),
      Achievement(
        id: 'perfect_25',
        title: 'Sharp Shooter',
        description: 'Get 25 questions correct in a row',
        iconAsset: 'assets/icons/perfect_25.png',
        requiredValue: 25,
        category: 'Accuracy',
        xpReward: 250,
        type: AchievementType.accuracy,
      ),

      // Level Achievements
      Achievement(
        id: 'level_5',
        title: 'Hatching',
        description: 'Reach Level 5',
        iconAsset: 'assets/icons/level_5.png',
        requiredValue: 5,
        category: 'Level',
        xpReward: 100,
        type: AchievementType.level,
      ),
      Achievement(
        id: 'level_10',
        title: 'Baby Bird',
        description: 'Reach Level 10',
        iconAsset: 'assets/icons/level_10.png',
        requiredValue: 10,
        category: 'Level',
        xpReward: 200,
        type: AchievementType.level,
      ),
      Achievement(
        id: 'level_20',
        title: 'Taking Flight',
        description: 'Reach Level 20',
        iconAsset: 'assets/icons/level_20.png',
        requiredValue: 20,
        category: 'Level',
        xpReward: 500,
        type: AchievementType.level,
      ),

      // Special Achievements
      Achievement(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Answer a question correctly in under 5 seconds',
        iconAsset: 'assets/icons/speed_demon.png',
        requiredValue: 1,
        category: 'Special',
        xpReward: 50,
        type: AchievementType.special,
      ),
      Achievement(
        id: 'review_master',
        title: 'Review Master',
        description: 'Review 50 wrong answers',
        iconAsset: 'assets/icons/review_master.png',
        requiredValue: 50,
        category: 'Review',
        xpReward: 200,
        type: AchievementType.review,
      ),
      Achievement(
        id: 'grammar_expert',
        title: 'Grammar Expert',
        description: 'Master 10 different grammar points',
        iconAsset: 'assets/icons/grammar_expert.png',
        requiredValue: 10,
        category: 'Grammar',
        xpReward: 300,
        type: AchievementType.grammar,
      ),
    ];
  }
}

@HiveType(typeId: 5)
enum AchievementType {
  @HiveField(0)
  streak,
  @HiveField(1)
  questions,
  @HiveField(2)
  accuracy,
  @HiveField(3)
  level,
  @HiveField(4)
  special,
  @HiveField(5)
  review,
  @HiveField(6)
  grammar,
}