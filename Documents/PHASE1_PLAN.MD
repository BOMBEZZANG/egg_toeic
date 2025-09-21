# TOEIC Part 5 Learning App - Phase 1 Development Specification

## 📌 Phase 1 Overview

### Objective
Set up complete project foundation with MVVM architecture, data models, repository patterns, and database configurations.

### Timeline
5 working days (Week 1)

### Deliverables Checklist
- [ ] Flutter project initialization with required dependencies
- [ ] Complete folder structure setup
- [ ] All data models with Freezed implementation
- [ ] Repository interfaces and implementations
- [ ] Firebase configuration and initial data seeding
- [ ] Hive local database setup
- [ ] Basic app initialization and provider setup
- [ ] Unit tests for models and repositories

---

## 🚀 Day 1: Project Setup & Configuration

### 1.1 Create New Flutter Project
```bash
flutter create toeic_master --org com.toeicmaster --platforms ios,android
cd toeic_master
```

### 1.2 Update pubspec.yaml
```yaml
name: toeic_master
description: TOEIC Part 5 Practice App with Gamification
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2
  path_provider: ^2.1.1
  
  # Firebase
  firebase_core: ^2.24.2
  cloud_firestore: ^4.14.0
  firebase_analytics: ^10.7.4
  
  # Data Models
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  
  # UI/UX
  lottie: ^3.0.0
  fl_chart: ^0.66.0
  
  # Utilities
  uuid: ^4.2.1
  intl: ^0.18.1
  collection: ^1.18.0
  equatable: ^2.0.5
  
  # Navigation
  go_router: ^13.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  riverpod_generator: ^2.3.9
  hive_generator: ^2.0.1
  mockito: ^5.4.4
```

### 1.3 Create Folder Structure
```bash
# Run this script in project root
mkdir -p lib/core/constants
mkdir -p lib/core/theme
mkdir -p lib/core/utils
mkdir -p lib/core/widgets
mkdir -p lib/data/models
mkdir -p lib/data/repositories
mkdir -p lib/data/datasources/remote
mkdir -p lib/data/datasources/local
mkdir -p lib/features/home/views
mkdir -p lib/features/home/viewmodels
mkdir -p lib/providers
mkdir -p test/unit/models
mkdir -p test/unit/repositories
```

---

## 📊 Day 2: Data Models Implementation

### 2.1 Create Base Model Configuration

**lib/core/constants/hive_constants.dart**
```dart
class HiveConstants {
  static const String userProgressBox = 'user_progress_box';
  static const String wrongAnswersBox = 'wrong_answers_box';
  static const String favoritesBox = 'favorites_box';
  static const String sessionsBox = 'sessions_box';
  static const String settingsBox = 'settings_box';
  
  // Type IDs for Hive Adapters
  static const int userProgressTypeId = 0;
  static const int wrongAnswerTypeId = 1;
  static const int learningSessionTypeId = 2;
  static const int questionTypeId = 3;
  static const int achievementTypeId = 4;
}
```

### 2.2 Question Model

**lib/data/models/question_model.dart**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

@freezed
@HiveType(typeId: 3)
class Question with _$Question {
  const Question._();
  
  const factory Question({
    @HiveField(0) required String id,
    @HiveField(1) required String questionText,
    @HiveField(2) required List<String> options,
    @HiveField(3) required int correctAnswerIndex,
    @HiveField(4) required int difficultyLevel,
    @HiveField(5) required String explanation,
    @HiveField(6) required String grammarPoint,
    @HiveField(7) List<String>? tags,
    @HiveField(8) DateTime? createdAt,
    @HiveField(9) @Default(false) bool isBookmarked,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
  
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
```

### 2.3 User Progress Model

**lib/data/models/user_progress_model.dart**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'user_progress_model.freezed.dart';
part 'user_progress_model.g.dart';

@freezed
@HiveType(typeId: 0)
class UserProgress with _$UserProgress {
  const UserProgress._();
  
  const factory UserProgress({
    @HiveField(0) @Default(0) int totalQuestionsAnswered,
    @HiveField(1) @Default(0) int correctAnswers,
    @HiveField(2) @Default(0) int currentStreak,
    @HiveField(3) @Default(0) int longestStreak,
    @HiveField(4) @Default(0) int experiencePoints,
    @HiveField(5) @Default(1) int userLevel,
    @HiveField(6) DateTime? lastStudyDate,
    @HiveField(7) @Default({}) Map<String, double> levelProgress,
    @HiveField(8) @Default([]) List<String> unlockedAchievements,
    @HiveField(9) @Default([]) List<String> favoriteQuestionIds,
    @HiveField(10) @Default({}) Map<String, int> grammarPointScores,
    @HiveField(11) @Default(0) int totalStudyTimeMinutes,
  }) = _UserProgress;

  factory UserProgress.fromJson(Map<String, dynamic> json) =>
      _$UserProgressFromJson(json);
  
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
}
```

### 2.4 Wrong Answer Model

**lib/data/models/wrong_answer_model.dart**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'wrong_answer_model.freezed.dart';
part 'wrong_answer_model.g.dart';

@freezed
@HiveType(typeId: 1)
class WrongAnswer with _$WrongAnswer {
  const WrongAnswer._();
  
  const factory WrongAnswer({
    @HiveField(0) required String id,
    @HiveField(1) required String questionId,
    @HiveField(2) required int selectedAnswerIndex,
    @HiveField(3) required int correctAnswerIndex,
    @HiveField(4) required DateTime answeredAt,
    @HiveField(5) @Default(0) int reviewCount,
    @HiveField(6) @Default(false) bool isResolved,
    @HiveField(7) String? grammarPoint,
    @HiveField(8) int? difficultyLevel,
    @HiveField(9) DateTime? lastReviewedAt,
  }) = _WrongAnswer;

  factory WrongAnswer.fromJson(Map<String, dynamic> json) =>
      _$WrongAnswerFromJson(json);
  
  bool get needsReview {
    if (isResolved) return false;
    if (lastReviewedAt == null) return true;
    
    final daysSinceReview = DateTime.now().difference(lastReviewedAt!).inDays;
    return daysSinceReview >= _getReviewInterval();
  }
  
  int _getReviewInterval() {
    switch (reviewCount) {
      case 0: return 1;
      case 1: return 3;
      case 2: return 7;
      case 3: return 14;
      default: return 30;
    }
  }
}
```

### 2.5 Learning Session Model

**lib/data/models/learning_session_model.dart**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'learning_session_model.freezed.dart';
part 'learning_session_model.g.dart';

@freezed
@HiveType(typeId: 2)
class LearningSession with _$LearningSession {
  const LearningSession._();
  
  const factory LearningSession({
    @HiveField(0) required String id,
    @HiveField(1) required DateTime startTime,
    @HiveField(2) DateTime? endTime,
    @HiveField(3) @Default(0) int questionsAnswered,
    @HiveField(4) @Default(0) int correctAnswers,
    @HiveField(5) @Default([]) List<String> questionIds,
    @HiveField(6) int? difficultyLevel,
    @HiveField(7) @Default(0) int experienceEarned,
    @HiveField(8) @Default('practice') String sessionType,
  }) = _LearningSession;

  factory LearningSession.fromJson(Map<String, dynamic> json) =>
      _$LearningSessionFromJson(json);
  
  int get durationMinutes {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inMinutes;
  }
  
  double get accuracy {
    if (questionsAnswered == 0) return 0.0;
    return (correctAnswers / questionsAnswered) * 100;
  }
}
```

### 2.6 Achievement Model

**lib/data/models/achievement_model.dart**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'achievement_model.freezed.dart';
part 'achievement_model.g.dart';

@freezed
@HiveType(typeId: 4)
class Achievement with _$Achievement {
  const Achievement._();
  
  const factory Achievement({
    @HiveField(0) required String id,
    @HiveField(1) required String title,
    @HiveField(2) required String description,
    @HiveField(3) required String iconAsset,
    @HiveField(4) required int requiredValue,
    @HiveField(5) @Default(0) int currentValue,
    @HiveField(6) @Default(false) bool isUnlocked,
    @HiveField(7) DateTime? unlockedAt,
    @HiveField(8) required String category,
    @HiveField(9) @Default(0) int xpReward,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);
  
  double get progress {
    if (isUnlocked) return 1.0;
    return currentValue / requiredValue;
  }
}
```

---

## 🗄️ Day 3: Repository Implementation

### 3.1 Base Repository Interface

**lib/data/repositories/base_repository.dart**
```dart
abstract class BaseRepository {
  Future<void> initialize();
  Future<void> dispose();
}
```

### 3.2 Question Repository

**lib/data/repositories/question_repository.dart**
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toeic_master/data/models/question_model.dart';
import 'package:toeic_master/data/repositories/base_repository.dart';

abstract class QuestionRepository extends BaseRepository {
  Future<List<Question>> getQuestions({
    required int difficultyLevel,
    int limit = 10,
  });
  
  Future<Question?> getQuestionById(String questionId);
  
  Future<List<Question>> getQuestionsByIds(List<String> questionIds);
  
  Future<List<Question>> getRandomQuestions({
    int? difficultyLevel,
    int limit = 10,
  });
  
  Future<void> cacheQuestions(List<Question> questions);
  
  Future<List<Question>> getCachedQuestions();
}

class QuestionRepositoryImpl implements QuestionRepository {
  final FirebaseFirestore _firestore;
  List<Question> _cachedQuestions = [];
  
  QuestionRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Future<void> initialize() async {
    // Load any cached questions from local storage
    _cachedQuestions = await getCachedQuestions();
  }
  
  @override
  Future<void> dispose() async {
    _cachedQuestions.clear();
  }
  
  @override
  Future<List<Question>> getQuestions({
    required int difficultyLevel,
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions_part5')
          .where('difficultyLevel', isEqualTo: difficultyLevel)
          .limit(limit)
          .get();
      
      final questions = querySnapshot.docs
          .map((doc) => Question.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Cache for offline access
      await cacheQuestions(questions);
      
      return questions;
    } catch (e) {
      // If offline, return cached questions
      return _cachedQuestions
          .where((q) => q.difficultyLevel == difficultyLevel)
          .take(limit)
          .toList();
    }
  }
  
  @override
  Future<Question?> getQuestionById(String questionId) async {
    try {
      final doc = await _firestore
          .collection('questions_part5')
          .doc(questionId)
          .get();
      
      if (!doc.exists) return null;
      
      return Question.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      // Check cache
      try {
        return _cachedQuestions.firstWhere((q) => q.id == questionId);
      } catch (_) {
        return null;
      }
    }
  }
  
  @override
  Future<List<Question>> getQuestionsByIds(List<String> questionIds) async {
    if (questionIds.isEmpty) return [];
    
    final questions = <Question>[];
    
    for (final id in questionIds) {
      final question = await getQuestionById(id);
      if (question != null) {
        questions.add(question);
      }
    }
    
    return questions;
  }
  
  @override
  Future<List<Question>> getRandomQuestions({
    int? difficultyLevel,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('questions_part5');
    
    if (difficultyLevel != null) {
      query = query.where('difficultyLevel', isEqualTo: difficultyLevel);
    }
    
    final snapshot = await query.get();
    final allQuestions = snapshot.docs
        .map((doc) => Question.fromFirestore(doc.data(), doc.id))
        .toList();
    
    allQuestions.shuffle();
    
    final selectedQuestions = allQuestions.take(limit).toList();
    await cacheQuestions(selectedQuestions);
    
    return selectedQuestions;
  }
  
  @override
  Future<void> cacheQuestions(List<Question> questions) async {
    _cachedQuestions.addAll(questions);
    
    // Remove duplicates
    final uniqueIds = <String>{};
    _cachedQuestions = _cachedQuestions
        .where((q) => uniqueIds.add(q.id))
        .toList();
    
    // Keep only last 100 questions in cache
    if (_cachedQuestions.length > 100) {
      _cachedQuestions = _cachedQuestions
          .skip(_cachedQuestions.length - 100)
          .toList();
    }
  }
  
  @override
  Future<List<Question>> getCachedQuestions() async {
    // This will be implemented with Hive in local service
    return [];
  }
}
```

### 3.3 User Data Repository

**lib/data/repositories/user_data_repository.dart**
```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:toeic_master/core/constants/hive_constants.dart';
import 'package:toeic_master/data/models/user_progress_model.dart';
import 'package:toeic_master/data/models/wrong_answer_model.dart';
import 'package:toeic_master/data/models/learning_session_model.dart';
import 'package:toeic_master/data/repositories/base_repository.dart';

abstract class UserDataRepository extends BaseRepository {
  // User Progress
  Future<UserProgress> getUserProgress();
  Future<void> updateUserProgress(UserProgress progress);
  Future<void> incrementStreak();
  Future<void> addExperience(int xp);
  
  // Wrong Answers
  Future<List<WrongAnswer>> getWrongAnswers();
  Future<void> addWrongAnswer(WrongAnswer wrongAnswer);
  Future<void> markWrongAnswerAsResolved(String wrongAnswerId);
  Future<List<WrongAnswer>> getWrongAnswersNeedingReview();
  
  // Learning Sessions
  Future<List<LearningSession>> getLearningSession();
  Future<void> startNewSession();
  Future<void> endCurrentSession();
  Future<void> updateCurrentSession({
    int? questionsAnswered,
    int? correctAnswers,
    String? questionId,
  });
  
  // Favorites
  Future<List<String>> getFavoriteQuestions();
  Future<void> toggleFavorite(String questionId);
  Future<bool> isFavorite(String questionId);
}

class UserDataRepositoryImpl implements UserDataRepository {
  Box<UserProgress>? _progressBox;
  Box<List<WrongAnswer>>? _wrongAnswersBox;
  Box<List<LearningSession>>? _sessionsBox;
  Box<List<String>>? _favoritesBox;
  
  LearningSession? _currentSession;
  
  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProgressAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(WrongAnswerAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(LearningSessionAdapter());
    }
    
    // Open boxes
    _progressBox = await Hive.openBox<UserProgress>(
      HiveConstants.userProgressBox,
    );
    _wrongAnswersBox = await Hive.openBox<List<WrongAnswer>>(
      HiveConstants.wrongAnswersBox,
    );
    _sessionsBox = await Hive.openBox<List<LearningSession>>(
      HiveConstants.sessionsBox,
    );
    _favoritesBox = await Hive.openBox<List<String>>(
      HiveConstants.favoritesBox,
    );
    
    // Initialize with default values if empty
    if (_progressBox!.isEmpty) {
      await _progressBox!.put('progress', UserProgress.initial());
    }
    if (_wrongAnswersBox!.isEmpty) {
      await _wrongAnswersBox!.put('wrongAnswers', []);
    }
    if (_sessionsBox!.isEmpty) {
      await _sessionsBox!.put('sessions', []);
    }
    if (_favoritesBox!.isEmpty) {
      await _favoritesBox!.put('favorites', []);
    }
  }
  
  @override
  Future<void> dispose() async {
    await _progressBox?.close();
    await _wrongAnswersBox?.close();
    await _sessionsBox?.close();
    await _favoritesBox?.close();
  }
  
  @override
  Future<UserProgress> getUserProgress() async {
    return _progressBox!.get('progress') ?? UserProgress.initial();
  }
  
  @override
  Future<void> updateUserProgress(UserProgress progress) async {
    await _progressBox!.put('progress', progress);
  }
  
  @override
  Future<void> incrementStreak() async {
    final progress = await getUserProgress();
    final today = DateTime.now();
    final lastStudy = progress.lastStudyDate;
    
    int newStreak = progress.currentStreak;
    
    if (lastStudy != null) {
      final dayDifference = today.difference(lastStudy).inDays;
      
      if (dayDifference == 1) {
        newStreak += 1;
      } else if (dayDifference > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }
    
    final longestStreak = newStreak > progress.longestStreak 
        ? newStreak 
        : progress.longestStreak;
    
    await updateUserProgress(
      progress.copyWith(
        currentStreak: newStreak,
        longestStreak: longestStreak,
        lastStudyDate: today,
      ),
    );
  }
  
  @override
  Future<void> addExperience(int xp) async {
    final progress = await getUserProgress();
    final newXp = progress.experiencePoints + xp;
    final xpForNextLevel = progress.xpToNextLevel;
    
    int newLevel = progress.userLevel;
    int remainingXp = newXp;
    
    while (remainingXp >= xpForNextLevel) {
      remainingXp -= xpForNextLevel;
      newLevel++;
    }
    
    await updateUserProgress(
      progress.copyWith(
        experiencePoints: remainingXp,
        userLevel: newLevel,
      ),
    );
  }
  
  @override
  Future<List<WrongAnswer>> getWrongAnswers() async {
    return _wrongAnswersBox!.get('wrongAnswers') ?? [];
  }
  
  @override
  Future<void> addWrongAnswer(WrongAnswer wrongAnswer) async {
    final wrongAnswers = await getWrongAnswers();
    wrongAnswers.add(wrongAnswer);
    await _wrongAnswersBox!.put('wrongAnswers', wrongAnswers);
  }
  
  @override
  Future<void> markWrongAnswerAsResolved(String wrongAnswerId) async {
    final wrongAnswers = await getWrongAnswers();
    final index = wrongAnswers.indexWhere((wa) => wa.id == wrongAnswerId);
    
    if (index != -1) {
      wrongAnswers[index] = wrongAnswers[index].copyWith(
        isResolved: true,
        lastReviewedAt: DateTime.now(),
        reviewCount: wrongAnswers[index].reviewCount + 1,
      );
      await _wrongAnswersBox!.put('wrongAnswers', wrongAnswers);
    }
  }
  
  @override
  Future<List<WrongAnswer>> getWrongAnswersNeedingReview() async {
    final wrongAnswers = await getWrongAnswers();
    return wrongAnswers.where((wa) => wa.needsReview).toList();
  }
  
  @override
  Future<List<LearningSession>> getLearningSession() async {
    return _sessionsBox!.get('sessions') ?? [];
  }
  
  @override
  Future<void> startNewSession() async {
    _currentSession = LearningSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
    );
  }
  
  @override
  Future<void> endCurrentSession() async {
    if (_currentSession != null) {
      final sessions = await getLearningSession();
      sessions.add(_currentSession!.copyWith(endTime: DateTime.now()));
      await _sessionsBox!.put('sessions', sessions);
      _currentSession = null;
    }
  }
  
  @override
  Future<void> updateCurrentSession({
    int? questionsAnswered,
    int? correctAnswers,
    String? questionId,
  }) async {
    if (_currentSession == null) return;
    
    _currentSession = _currentSession!.copyWith(
      questionsAnswered: questionsAnswered ?? _currentSession!.questionsAnswered,
      correctAnswers: correctAnswers ?? _currentSession!.correctAnswers,
      questionIds: questionId != null 
          ? [..._currentSession!.questionIds, questionId]
          : _currentSession!.questionIds,
    );
  }
  
  @override
  Future<List<String>> getFavoriteQuestions() async {
    return _favoritesBox!.get('favorites') ?? [];
  }
  
  @override
  Future<void> toggleFavorite(String questionId) async {
    final favorites = await getFavoriteQuestions();
    
    if (favorites.contains(questionId)) {
      favorites.remove(questionId);
    } else {
      favorites.add(questionId);
    }
    
    await _favoritesBox!.put('favorites', favorites);
  }
  
  @override
  Future<bool> isFavorite(String questionId) async {
    final favorites = await getFavoriteQuestions();
    return favorites.contains(questionId);
  }
}
```

---

## 🔥 Day 4: Firebase & Local Service Setup

### 4.1 Firebase Service

**lib/data/datasources/remote/firebase_service.dart**
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();
  
  late final FirebaseFirestore _firestore;
  
  Future<void> initialize() async {
    await Firebase.initializeApp();
    _firestore = FirebaseFirestore.instance;
    
    // Enable offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  
  FirebaseFirestore get firestore => _firestore;
  
  // Seed initial questions (for development only)
  Future<void> seedInitialQuestions() async {
    final batch = _firestore.batch();
    
    final sampleQuestions = _getSampleQuestions();
    
    for (final question in sampleQuestions) {
      final docRef = _firestore.collection('questions_part5').doc();
      batch.set(docRef, question);
    }
    
    await batch.commit();
    print('Seeded ${sampleQuestions.length} questions');
  }
  
  List<Map<String, dynamic>> _getSampleQuestions() {
    return [
      // Level 1 Questions
      {
        'questionText': 'The meeting _____ scheduled for 3 PM tomorrow.',
        'options': ['is', 'are', 'were', 'be'],
        'correctAnswerIndex': 0,
        'difficultyLevel': 1,
        'explanation': '"Is" is the correct form of the verb "to be" for singular subjects in present tense. "The meeting" is singular, so we use "is".',
        'grammarPoint': 'Subject-Verb Agreement',
        'tags': ['grammar', 'verb', 'present-tense'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'questionText': 'Please submit your report _____ Friday.',
        'options': ['by', 'in', 'at', 'on'],
        'correctAnswerIndex': 0,
        'difficultyLevel': 1,
        'explanation': '"By" indicates a deadline - the report must be submitted before or on Friday. "On" would mean specifically on Friday, but "by" is more appropriate for deadlines.',
        'grammarPoint': 'Prepositions of Time',
        'tags': ['grammar', 'preposition', 'time'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      
      // Level 2 Questions
      {
        'questionText': 'The proposal _____ reviewed by the board next week.',
        'options': ['will be', 'would be', 'has been', 'is being'],
        'correctAnswerIndex': 0,
        'difficultyLevel': 2,
        'explanation': '"Will be" forms the future passive voice. The proposal will receive the action (being reviewed) in the future (next week).',
        'grammarPoint': 'Passive Voice - Future',
        'tags': ['grammar', 'passive-voice', 'future-tense'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      
      // Level 3 Questions
      {
        'questionText': 'Not only _____ the project on time, but they also came under budget.',
        'options': [
          'did they complete',
          'they completed',
          'they did complete',
          'completed they'
        ],
        'correctAnswerIndex': 0,
        'difficultyLevel': 3,
        'explanation': 'After "Not only" at the beginning of a sentence, we use inverted word order (auxiliary verb + subject + main verb).',
        'grammarPoint': 'Inversion after Negative Adverbs',
        'tags': ['grammar', 'advanced', 'inversion'],
        'createdAt': DateTime.now().toIso8601String(),
      },
      
      // Add more questions here...
      // Total should be at least 30 questions (10 per level)
    ];
  }
}
```

### 4.2 Hive Local Service

**lib/data/datasources/local/hive_service.dart**
```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:toeic_master/core/constants/hive_constants.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();
  
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    await Hive.initFlutter();
    _initialized = true;
  }
  
  Future<Box<T>> openBox<T>(String boxName) async {
    if (!_initialized) {
      await initialize();
    }
    
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    
    return await Hive.openBox<T>(boxName);
  }
  
  Future<void> closeBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }
  }
  
  Future<void> deleteBox(String boxName) async {
    await Hive.deleteBoxFromDisk(boxName);
  }
  
  Future<void> clearAllData() async {
    final boxNames = [
      HiveConstants.userProgressBox,
      HiveConstants.wrongAnswersBox,
      HiveConstants.favoritesBox,
      HiveConstants.sessionsBox,
      HiveConstants.settingsBox,
    ];
    
    for (final boxName in boxNames) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).clear();
      }
    }
  }
  
  void registerAdapters() {
    // Register all Hive adapters here
    // This will be called after code generation
  }
}
```

---

## 🎯 Day 5: Providers & App Initialization

### 5.1 Repository Providers

**lib/providers/repository_providers.dart**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toeic_master/data/repositories/question_repository.dart';
import 'package:toeic_master/data/repositories/user_data_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return QuestionRepositoryImpl(firestore: firestore);
});

final userDataRepositoryProvider = Provider<UserDataRepository>((ref) {
  return UserDataRepositoryImpl();
});

// Initialize all repositories
final repositoryInitializerProvider = FutureProvider<void>((ref) async {
  final questionRepo = ref.read(questionRepositoryProvider);
  final userDataRepo = ref.read(userDataRepositoryProvider);
  
  await Future.wait([
    questionRepo.initialize(),
    userDataRepo.initialize(),
  ]);
});
```

### 5.2 Main App Configuration

**lib/main.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toeic_master/core/theme/app_theme.dart';
import 'package:toeic_master/data/datasources/remote/firebase_service.dart';
import 'package:toeic_master/data/datasources/local/hive_service.dart';
import 'package:toeic_master/providers/repository_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await FirebaseService().initialize();
  await HiveService().initialize();
  
  // Seed sample data in development
  // await FirebaseService().seedInitialQuestions();
  
  runApp(
    const ProviderScope(
      child: ToeicMasterApp(),
    ),
  );
}

class ToeicMasterApp extends ConsumerWidget {
  const ToeicMasterApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsync = ref.watch(repositoryInitializerProvider);
    
    return MaterialApp(
      title: 'TOEIC Master',
      theme: AppTheme.lightTheme,
      home: initAsync.when(
        data: (_) => const HomeScreen(),
        loading: () => const SplashScreen(),
        error: (error, stack) => ErrorScreen(error: error),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add logo here
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TOEIC Master'),
      ),
      body: const Center(
        child: Text('Phase 1 Complete! Ready for Phase 2'),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final Object? error;
  
  const ErrorScreen({super.key, this.error});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5.3 App Theme Configuration

**lib/core/theme/app_theme.dart**
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      fontFamily: 'Poppins',
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
```

---

## 🧪 Testing Requirements

### Unit Test Example

**test/unit/models/user_progress_test.dart**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toeic_master/data/models/user_progress_model.dart';

void main() {
  group('UserProgress', () {
    test('should calculate overall accuracy correctly', () {
      final progress = UserProgress(
        totalQuestionsAnswered: 100,
        correctAnswers: 75,
      );
      
      expect(progress.overallAccuracy, 75.0);
    });
    
    test('should handle zero questions answered', () {
      final progress = UserProgress(
        totalQuestionsAnswered: 0,
        correctAnswers: 0,
      );
      
      expect(progress.overallAccuracy, 0.0);
    });
    
    test('should calculate XP to next level correctly', () {
      final progress = UserProgress(
        userLevel: 5,
        experiencePoints: 250,
      );
      
      expect(progress.xpToNextLevel, 600);
    });
  });
}
```

---

## 📋 Completion Checklist

### Code Generation
```bash
# Run after implementing all models
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Firebase Setup
1. [ ] Create Firebase project
2. [ ] Add Android app configuration
3. [ ] Add iOS app configuration
4. [ ] Download and add configuration files
5. [ ] Enable Firestore database
6. [ ] Set security rules for read-only questions

### Testing
1. [ ] All models compile without errors
2. [ ] Hive adapters generated successfully
3. [ ] Firebase connection established
4. [ ] Sample questions seeded
5. [ ] Basic app launches without crashes

### Documentation
1. [ ] Update README with setup instructions
2. [ ] Document model relationships
3. [ ] Create API documentation for repositories

---

## 🚩 Phase 1 Deliverable Verification

Upon completion of Phase 1, the following should be ready:

1. **Working Flutter app** that compiles and runs
2. **All data models** implemented with Freezed
3. **Repository pattern** fully implemented
4. **Firebase integration** configured and tested
5. **Local storage** with Hive configured
6. **Basic app structure** with splash and home screens
7. **Unit tests** for critical components
8. **Documentation** for Phase 2 handoff

---

## 📝 Notes for Phase 2 Developer

- All models are immutable using Freezed
- Repository pattern abstracts data sources
- Firebase is for questions only; user data is local
- Hive boxes are initialized in UserDataRepository
- Provider setup is complete for dependency injection
- Theme and constants are defined in core/

**Next Steps**: Implement Part 5 UI screens and learning flow using the established architecture.