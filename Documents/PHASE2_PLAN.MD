# TOEIC Part 5 Learning App - Phase 2 Development Specification

## 📌 Phase 2 Overview

### Objective
Implement complete Part 5 learning functionality with interactive UI, practice mode, wrong answer review, and seamless user experience building on Phase 1 foundation.

### Timeline
5 working days (Week 2)

### Prerequisites
- Phase 1 completed with all data models and repositories
- Firebase configured with sample questions
- Hive local storage initialized
- Riverpod providers ready

### Deliverables Checklist
- [ ] Home Dashboard with user progress display
- [ ] Part 5 learning flow (level selection → practice → results)
- [ ] Interactive question screens with immediate feedback
- [ ] Detailed explanation screens
- [ ] Wrong answer review system
- [ ] Navigation and routing
- [ ] Animations and micro-interactions
- [ ] Error handling and loading states

---

## 🎨 Day 1: Navigation & Home Dashboard

### 1.1 Navigation Setup

**lib/core/routing/app_router.dart**
```dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/part5',
        name: 'part5-home',
        builder: (context, state) => const Part5HomeScreen(),
        routes: [
          GoRoute(
            path: 'level-select',
            name: 'level-select',
            builder: (context, state) => const LevelSelectionScreen(),
          ),
          GoRoute(
            path: 'practice/:level',
            name: 'practice',
            builder: (context, state) {
              final level = int.parse(state.pathParameters['level'] ?? '1');
              return PracticeModeScreen(difficultyLevel: level);
            },
          ),
          GoRoute(
            path: 'explanation',
            name: 'explanation',
            builder: (context, state) {
              final question = state.extra as Question;
              return ExplanationScreen(question: question);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/wrong-answers',
        name: 'wrong-answers',
        builder: (context, state) => const WrongAnswersScreen(),
        routes: [
          GoRoute(
            path: 'review',
            name: 'wrong-review',
            builder: (context, state) {
              final wrongAnswers = state.extra as List<WrongAnswer>;
              return WrongAnswerReviewScreen(wrongAnswers: wrongAnswers);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
    ],
  );
});
```

### 1.2 Home Screen Implementation

**lib/features/home/views/home_screen.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProgress = ref.watch(userProgressProvider);
    final dailyGoal = ref.watch(dailyGoalProvider);
    final recentAchievement = ref.watch(recentAchievementProvider);
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar with Character
            SliverToBoxAdapter(
              child: _buildHeader(context, userProgress),
            ),
            
            // Daily Progress Card
            SliverToBoxAdapter(
              child: _buildDailyProgress(context, userProgress, dailyGoal),
            ),
            
            // Quick Stats
            SliverToBoxAdapter(
              child: _buildQuickStats(context, userProgress),
            ),
            
            // Main Menu Cards
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                delegate: SliverChildListDelegate([
                  _buildMenuCard(
                    context,
                    title: 'Part 5 Practice',
                    icon: Icons.edit_note,
                    color: AppColors.primary,
                    questionsToday: userProgress.todayQuestions,
                    onTap: () => context.push('/part5'),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'Wrong Answers',
                    icon: Icons.replay,
                    color: AppColors.error,
                    badge: userProgress.pendingReviews.toString(),
                    onTap: () => context.push('/wrong-answers'),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'Achievements',
                    icon: Icons.emoji_events,
                    color: AppColors.warning,
                    badge: recentAchievement != null ? '!' : null,
                    onTap: () => context.push('/achievements'),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'Statistics',
                    icon: Icons.bar_chart,
                    color: AppColors.success,
                    onTap: () => context.push('/statistics'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, UserProgress progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
          ],
        ),
      ),
      child: Row(
        children: [
          // Character Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                progress.characterEmoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level ${progress.userLevel}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  progress.characterName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // XP Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${progress.experiencePoints} XP',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${progress.xpToNextLevel} XP',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress.currentLevelProgress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDailyProgress(
    BuildContext context,
    UserProgress progress,
    DailyGoal goal,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Goal',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.currentStreak} days',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Goal Progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${goal.questionsCompleted}/${goal.targetQuestions} questions',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          goal.isCompleted ? AppColors.success : AppColors.primary,
                        ),
                        minHeight: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (goal.isCompleted)
                Lottie.asset(
                  'assets/animations/check.json',
                  width: 50,
                  height: 50,
                  repeat: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 🎮 Day 2: Part 5 Learning Flow

### 2.1 Part 5 Home Screen

**lib/features/part5/views/part5_home_screen.dart**
```dart
class Part5HomeScreen extends ConsumerWidget {
  const Part5HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelProgress = ref.watch(levelProgressProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Part 5: Incomplete Sentences'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Instructions Card
            _buildInstructionsCard(context),
            
            const SizedBox(height: 20),
            
            // Level Selection
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final progress = levelProgress['level$level'] ?? 0.0;
                  final isUnlocked = level == 1 || 
                    (levelProgress['level${level - 1}'] ?? 0.0) >= 50.0;
                  
                  return _buildLevelCard(
                    context,
                    level: level,
                    progress: progress,
                    isUnlocked: isUnlocked,
                    onTap: isUnlocked
                      ? () => context.push('/part5/practice/$level')
                      : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLevelCard(
    BuildContext context, {
    required int level,
    required double progress,
    required bool isUnlocked,
    VoidCallback? onTap,
  }) {
    final levelNames = ['Beginner', 'Intermediate', 'Advanced'];
    final levelDescriptions = [
      'Basic grammar and vocabulary',
      'Complex sentence structures',
      'Advanced grammar patterns',
    ];
    final levelColors = [AppColors.success, AppColors.warning, AppColors.error];
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnlocked
              ? [
                  levelColors[level - 1].withOpacity(0.8),
                  levelColors[level - 1],
                ]
              : [Colors.grey[400]!, Colors.grey[600]!],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isUnlocked ? levelColors[level - 1] : Colors.grey)
                .withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.school,
                size: 120,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'L$level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              levelNames[level - 1],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              levelDescriptions[level - 1],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isUnlocked)
                        const Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2.2 Practice Mode Screen

**lib/features/part5/views/practice_mode_screen.dart**
```dart
class PracticeModeScreen extends ConsumerStatefulWidget {
  final int difficultyLevel;
  
  const PracticeModeScreen({
    super.key,
    required this.difficultyLevel,
  });
  
  @override
  ConsumerState<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends ConsumerState<PracticeModeScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _feedbackController;
  late Animation<Offset> _slideAnimation;
  
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _showExplanation = false;
  bool _isAnswered = false;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadQuestions();
  }
  
  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }
  
  void _loadQuestions() {
    ref.read(part5ViewModelProvider.notifier).loadQuestions(
      widget.difficultyLevel,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(part5ViewModelProvider);
    
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _showExitDialog(context);
        if (shouldPop) {
          ref.read(part5ViewModelProvider.notifier).endSession();
        }
        return shouldPop;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (message) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $message',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                ElevatedButton(
                  onPressed: _loadQuestions,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (questions, sessionStats) {
            if (questions.isEmpty) {
              return const Center(
                child: Text('No questions available'),
              );
            }
            
            final currentQuestion = questions[_currentQuestionIndex];
            
            return SafeArea(
              child: Column(
                children: [
                  // Progress Header
                  _buildProgressHeader(
                    context,
                    currentIndex: _currentQuestionIndex,
                    total: questions.length,
                    stats: sessionStats,
                  ),
                  
                  // Question Card
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildQuestionCard(
                          context,
                          question: currentQuestion,
                          selectedAnswer: _selectedAnswer,
                          isAnswered: _isAnswered,
                        ),
                      ),
                    ),
                  ),
                  
                  // Action Buttons
                  _buildActionButtons(
                    context,
                    question: currentQuestion,
                    isAnswered: _isAnswered,
                    showExplanation: _showExplanation,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildQuestionCard(
    BuildContext context, {
    required Question question,
    int? selectedAnswer,
    required bool isAnswered,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Number & Grammar Point
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Q${_currentQuestionIndex + 1}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    question.grammarPoint,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Question Text
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Answer Options
            ...List.generate(
              question.options.length,
              (index) => _buildOptionButton(
                context,
                option: question.options[index],
                index: index,
                isSelected: selectedAnswer == index,
                isCorrect: index == question.correctAnswerIndex,
                isAnswered: isAnswered,
                onTap: !isAnswered
                  ? () => _selectAnswer(index)
                  : null,
              ),
            ),
            
            // Explanation Section
            if (isAnswered && _showExplanation) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Explanation',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      question.explanation,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptionButton(
    BuildContext context, {
    required String option,
    required int index,
    required bool isSelected,
    required bool isCorrect,
    required bool isAnswered,
    VoidCallback? onTap,
  }) {
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    Color textColor = Colors.black87;
    IconData? icon;
    
    if (isAnswered) {
      if (isCorrect) {
        backgroundColor = AppColors.success.withOpacity(0.1);
        borderColor = AppColors.success;
        textColor = AppColors.success;
        icon = Icons.check_circle;
      } else if (isSelected) {
        backgroundColor = AppColors.error.withOpacity(0.1);
        borderColor = AppColors.error;
        textColor = AppColors.error;
        icon = Icons.cancel;
      }
    } else if (isSelected) {
      backgroundColor = AppColors.primary.withOpacity(0.1);
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected || (isAnswered && isCorrect) ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: isSelected || (isAnswered && isCorrect)
                      ? FontWeight.w600
                      : FontWeight.normal,
                  ),
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  color: isCorrect ? AppColors.success : AppColors.error,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _selectAnswer(int index) {
    setState(() {
      _selectedAnswer = index;
    });
    
    HapticFeedback.lightImpact();
  }
  
  void _submitAnswer() {
    if (_selectedAnswer == null) return;
    
    final questions = ref.read(part5ViewModelProvider).questions;
    final currentQuestion = questions[_currentQuestionIndex];
    final isCorrect = _selectedAnswer == currentQuestion.correctAnswerIndex;
    
    setState(() {
      _isAnswered = true;
    });
    
    // Update progress
    ref.read(part5ViewModelProvider.notifier).answerQuestion(
      questionId: currentQuestion.id,
      selectedAnswer: _selectedAnswer!,
      isCorrect: isCorrect,
    );
    
    // Show feedback animation
    if (isCorrect) {
      HapticFeedback.heavyImpact();
      _showCorrectAnimation();
    } else {
      HapticFeedback.mediumImpact();
      _showIncorrectAnimation();
    }
  }
  
  void _nextQuestion() {
    final questions = ref.read(part5ViewModelProvider).questions;
    
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
        _showExplanation = false;
      });
      
      _slideController.forward(from: 0);
    } else {
      // Session complete
      _showSessionCompleteDialog();
    }
  }
}
```

---

## 📚 Day 3: ViewModels & State Management

### 3.1 Part 5 ViewModel

**lib/features/part5/viewmodels/part5_viewmodel.dart**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'part5_viewmodel.freezed.dart';

@freezed
class Part5State with _$Part5State {
  const factory Part5State.loading() = _Loading;
  const factory Part5State.data({
    required List<Question> questions,
    required SessionStats sessionStats,
  }) = _Data;
  const factory Part5State.error(String message) = _Error;
}

@freezed
class SessionStats with _$SessionStats {
  const factory SessionStats({
    @Default(0) int questionsAnswered,
    @Default(0) int correctAnswers,
    @Default(0) int wrongAnswers,
    @Default(0) int experienceEarned,
    @Default([]) List<String> answeredQuestionIds,
    DateTime? sessionStartTime,
  }) = _SessionStats;
  
  const SessionStats._();
  
  double get accuracy {
    if (questionsAnswered == 0) return 0;
    return (correctAnswers / questionsAnswered) * 100;
  }
}

final part5ViewModelProvider = 
    StateNotifierProvider<Part5ViewModel, Part5State>((ref) {
  return Part5ViewModel(ref);
});

class Part5ViewModel extends StateNotifier<Part5State> {
  final Ref _ref;
  List<Question> _allQuestions = [];
  LearningSession? _currentSession;
  
  Part5ViewModel(this._ref) : super(const Part5State.loading());
  
  Future<void> loadQuestions(int difficultyLevel) async {
    state = const Part5State.loading();
    
    try {
      // Start new session
      await _startSession(difficultyLevel);
      
      // Load questions
      final questionRepo = _ref.read(questionRepositoryProvider);
      _allQuestions = await questionRepo.getRandomQuestions(
        difficultyLevel: difficultyLevel,
        limit: 10,
      );
      
      if (_allQuestions.isEmpty) {
        state = const Part5State.error('No questions available');
        return;
      }
      
      state = Part5State.data(
        questions: _allQuestions,
        sessionStats: const SessionStats(
          sessionStartTime: DateTime.now(),
        ),
      );
    } catch (e) {
      state = Part5State.error(e.toString());
    }
  }
  
  Future<void> _startSession(int difficultyLevel) async {
    final userDataRepo = _ref.read(userDataRepositoryProvider);
    _currentSession = LearningSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      difficultyLevel: difficultyLevel,
      sessionType: 'practice',
    );
    await userDataRepo.startNewSession();
  }
  
  Future<void> answerQuestion({
    required String questionId,
    required int selectedAnswer,
    required bool isCorrect,
  }) async {
    state.whenData((questions, stats) async {
      // Update session stats
      final newStats = stats.copyWith(
        questionsAnswered: stats.questionsAnswered + 1,
        correctAnswers: isCorrect 
            ? stats.correctAnswers + 1 
            : stats.correctAnswers,
        wrongAnswers: !isCorrect 
            ? stats.wrongAnswers + 1 
            : stats.wrongAnswers,
        experienceEarned: stats.experienceEarned + (isCorrect ? 10 : 3),
        answeredQuestionIds: [...stats.answeredQuestionIds, questionId],
      );
      
      state = Part5State.data(
        questions: questions,
        sessionStats: newStats,
      );
      
      // Update user progress
      final userDataRepo = _ref.read(userDataRepositoryProvider);
      final userProgress = await userDataRepo.getUserProgress();
      
      await userDataRepo.updateUserProgress(
        userProgress.copyWith(
          totalQuestionsAnswered: userProgress.totalQuestionsAnswered + 1,
          correctAnswers: isCorrect 
              ? userProgress.correctAnswers + 1 
              : userProgress.correctAnswers,
          experiencePoints: userProgress.experiencePoints + 
              (isCorrect ? 10 : 3),
        ),
      );
      
      // Add to wrong answers if incorrect
      if (!isCorrect) {
        final question = questions.firstWhere((q) => q.id == questionId);
        await userDataRepo.addWrongAnswer(
          WrongAnswer(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            questionId: questionId,
            selectedAnswerIndex: selectedAnswer,
            correctAnswerIndex: question.correctAnswerIndex,
            answeredAt: DateTime.now(),
            grammarPoint: question.grammarPoint,
            difficultyLevel: question.difficultyLevel,
          ),
        );
      }
      
      // Update session
      await userDataRepo.updateCurrentSession(
        questionsAnswered: newStats.questionsAnswered,
        correctAnswers: newStats.correctAnswers,
        questionId: questionId,
      );
      
      // Check for achievements
      await _checkAchievements(newStats);
    });
  }
  
  Future<void> _checkAchievements(SessionStats stats) async {
    final achievementNotifier = _ref.read(achievementProvider.notifier);
    
    // Perfect streak achievement
    if (stats.correctAnswers >= 10 && stats.wrongAnswers == 0) {
      await achievementNotifier.unlockAchievement('perfect_10');
    }
    
    // First question achievement
    if (stats.questionsAnswered == 1) {
      await achievementNotifier.unlockAchievement('first_steps');
    }
    
    // Speed demon achievement (if implemented with timer)
    // Add more achievement checks here
  }
  
  Future<void> toggleFavorite(String questionId) async {
    final userDataRepo = _ref.read(userDataRepositoryProvider);
    await userDataRepo.toggleFavorite(questionId);
  }
  
  Future<void> endSession() async {
    if (_currentSession != null) {
      final userDataRepo = _ref.read(userDataRepositoryProvider);
      await userDataRepo.endCurrentSession();
      _currentSession = null;
    }
  }
}
```

### 3.2 User Progress Provider

**lib/providers/user_progress_provider.dart**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userProgressProvider = StreamProvider<UserProgress>((ref) {
  final userDataRepo = ref.watch(userDataRepositoryProvider);
  
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) async => await userDataRepo.getUserProgress(),
  ).asyncMap((event) => event);
});

final levelProgressProvider = Provider<Map<String, double>>((ref) {
  final progress = ref.watch(userProgressProvider).value;
  return progress?.levelProgress ?? {};
});

final userCharacterProvider = Provider<CharacterInfo>((ref) {
  final progress = ref.watch(userProgressProvider).value;
  if (progress == null) {
    return CharacterInfo(
      emoji: '🥚',
      name: 'Egg',
      level: 1,
    );
  }
  
  return CharacterInfo.fromLevel(progress.userLevel);
});

@freezed
class CharacterInfo with _$CharacterInfo {
  const factory CharacterInfo({
    required String emoji,
    required String name,
    required int level,
  }) = _CharacterInfo;
  
  factory CharacterInfo.fromLevel(int level) {
    if (level <= 5) {
      return const CharacterInfo(emoji: '🥚', name: 'Egg', level: 1);
    } else if (level <= 10) {
      return const CharacterInfo(emoji: '🐣', name: 'Chick', level: 2);
    } else if (level <= 20) {
      return const CharacterInfo(emoji: '🐦', name: 'Bird', level: 3);
    } else if (level <= 30) {
      return const CharacterInfo(emoji: '🦅', name: 'Eagle', level: 4);
    } else {
      return const CharacterInfo(emoji: '🔥', name: 'Phoenix', level: 5);
    }
  }
}
```

---

## 🔄 Day 4: Wrong Answer Review System

### 4.1 Wrong Answers Screen

**lib/features/wrong_answers/views/wrong_answers_screen.dart**
```dart
class WrongAnswersScreen extends ConsumerWidget {
  const WrongAnswersScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wrongAnswersAsync = ref.watch(wrongAnswersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wrong Answer Review'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<WrongAnswerFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              ref.read(wrongAnswerFilterProvider.notifier).state = filter;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: WrongAnswerFilter.all,
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: WrongAnswerFilter.needsReview,
                child: Text('Needs Review'),
              ),
              const PopupMenuItem(
                value: WrongAnswerFilter.resolved,
                child: Text('Resolved'),
              ),
            ],
          ),
        ],
      ),
      body: wrongAnswersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (wrongAnswers) {
          if (wrongAnswers.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return Column(
            children: [
              // Stats Header
              _buildStatsHeader(context, wrongAnswers),
              
              // Wrong Answers List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: wrongAnswers.length,
                  itemBuilder: (context, index) {
                    final wrongAnswer = wrongAnswers[index];
                    return _buildWrongAnswerCard(
                      context,
                      ref,
                      wrongAnswer,
                    );
                  },
                ),
              ),
              
              // Start Review Button
              if (wrongAnswers.any((wa) => wa.needsReview))
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final reviewList = wrongAnswers
                            .where((wa) => wa.needsReview)
                            .toList();
                        context.push(
                          '/wrong-answers/review',
                          extra: reviewList,
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        'Start Review (${wrongAnswers.where((wa) => wa.needsReview).length} questions)',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildWrongAnswerCard(
    BuildContext context,
    WidgetRef ref,
    WrongAnswer wrongAnswer,
  ) {
    return FutureBuilder<Question?>(
      future: ref.read(questionRepositoryProvider)
          .getQuestionById(wrongAnswer.questionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: LinearProgressIndicator(),
          );
        }
        
        final question = snapshot.data!;
        final daysSince = DateTime.now()
            .difference(wrongAnswer.answeredAt)
            .inDays;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              _showQuestionDetail(context, question, wrongAnswer);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(question.difficultyLevel)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Level ${question.difficultyLevel}',
                          style: TextStyle(
                            color: _getDifficultyColor(question.difficultyLevel),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          question.grammarPoint,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.grey[200],
                        visualDensity: VisualDensity.compact,
                      ),
                      const Spacer(),
                      if (wrongAnswer.isResolved)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        )
                      else if (wrongAnswer.needsReview)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: AppColors.warning,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Review',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Question Preview
                  Text(
                    question.questionText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Your Answer vs Correct Answer
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your answer',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                question.options[wrongAnswer.selectedAnswerIndex],
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.grey,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Correct answer',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                question.options[wrongAnswer.correctAnswerIndex],
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Footer Info
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        daysSince == 0
                            ? 'Today'
                            : daysSince == 1
                                ? 'Yesterday'
                                : '$daysSince days ago',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.replay,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reviewed ${wrongAnswer.reviewCount} times',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
```

---

## 🎯 Day 5: Polish & Animations

### 5.1 Animations & Micro-interactions

**lib/core/widgets/animated_widgets.dart**
```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CorrectAnswerAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  
  const CorrectAnswerAnimation({
    super.key,
    this.onComplete,
  });
  
  @override
  State<CorrectAnswerAnimation> createState() => _CorrectAnswerAnimationState();
}

class _CorrectAnswerAnimationState extends State<CorrectAnswerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/animations/correct.json',
        controller: _controller,
        width: 200,
        height: 200,
      ),
    );
  }
}

class StreakAnimation extends StatelessWidget {
  final int streakCount;
  
  const StreakAnimation({
    super.key,
    required this.streakCount,
  });
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1 + (value * 0.2),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade400,
                    Colors.red.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3 * value),
                    blurRadius: 20 * value,
                    offset: Offset(0, 10 * value),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 48 * value,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$streakCount Day Streak! 🔥',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20 * value,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class XPGainAnimation extends StatelessWidget {
  final int xpAmount;
  
  const XPGainAnimation({
    super.key,
    required this.xpAmount,
  });
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -30 * value),
          child: Opacity(
            opacity: 1 - (value * 0.3),
            child: Text(
              '+$xpAmount XP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                shadows: [
                  Shadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
```

### 5.2 Session Complete Dialog

**lib/features/part5/widgets/session_complete_dialog.dart**
```dart
class SessionCompleteDialog extends StatelessWidget {
  final SessionStats stats;
  final VoidCallback onContinue;
  final VoidCallback onExit;
  
  const SessionCompleteDialog({
    super.key,
    required this.stats,
    required this.onContinue,
    required this.onExit,
  });
  
  @override
  Widget build(BuildContext context) {
    final accuracy = stats.accuracy;
    final grade = _getGrade(accuracy);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grade Display
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getGradeColors(grade),
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getGradeColors(grade)[0].withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  grade,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Session Complete!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              _getEncouragementMessage(accuracy),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Stats Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    icon: Icons.check_circle,
                    value: stats.correctAnswers.toString(),
                    label: 'Correct',
                    color: AppColors.success,
                  ),
                  _buildStatItem(
                    icon: Icons.cancel,
                    value: stats.wrongAnswers.toString(),
                    label: 'Wrong',
                    color: AppColors.error,
                  ),
                  _buildStatItem(
                    icon: Icons.percent,
                    value: '${accuracy.toInt()}%',
                    label: 'Accuracy',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // XP Earned
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primaryLight.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'You earned ${stats.experienceEarned} XP!',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onExit,
                    child: const Text('Exit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onContinue,
                    child: const Text('Continue'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  String _getGrade(double accuracy) {
    if (accuracy >= 95) return 'S';
    if (accuracy >= 90) return 'A+';
    if (accuracy >= 85) return 'A';
    if (accuracy >= 80) return 'B+';
    if (accuracy >= 75) return 'B';
    if (accuracy >= 70) return 'C+';
    if (accuracy >= 65) return 'C';
    return 'D';
  }
  
  List<Color> _getGradeColors(String grade) {
    switch (grade) {
      case 'S':
        return [Colors.purple, Colors.pink];
      case 'A+':
      case 'A':
        return [Colors.blue, Colors.lightBlue];
      case 'B+':
      case 'B':
        return [Colors.green, Colors.lightGreen];
      case 'C+':
      case 'C':
        return [Colors.orange, Colors.amber];
      default:
        return [Colors.grey, Colors.blueGrey];
    }
  }
  
  String _getEncouragementMessage(double accuracy) {
    if (accuracy >= 95) return 'Perfect! You\'re a TOEIC master! 🌟';
    if (accuracy >= 90) return 'Excellent work! Keep it up! 🎯';
    if (accuracy >= 80) return 'Great job! You\'re improving fast! 💪';
    if (accuracy >= 70) return 'Good effort! Practice makes perfect! 📚';
    if (accuracy >= 60) return 'Nice try! Review the explanations! 💡';
    return 'Keep practicing! You\'ll get better! 🚀';
  }
}
```

---

## 📋 Phase 2 Completion Checklist

### Core Functionality
- [ ] Navigation system with go_router
- [ ] Home dashboard with progress display
- [ ] Part 5 level selection screen
- [ ] Practice mode with 10 questions per session
- [ ] Interactive question answering
- [ ] Immediate feedback on answers
- [ ] Detailed explanations
- [ ] Wrong answer tracking
- [ ] Session statistics

### UI/UX Components
- [ ] Custom theme and colors
- [ ] Progress indicators
- [ ] Loading states
- [ ] Error states
- [ ] Empty states
- [ ] Animated feedback
- [ ] Micro-interactions
- [ ] Responsive layouts

### State Management
- [ ] Part 5 ViewModel
- [ ] User progress providers
- [ ] Wrong answer providers
- [ ] Achievement providers
- [ ] Session tracking

### Data Integration
- [ ] Firebase question fetching
- [ ] Local progress saving
- [ ] Wrong answer storage
- [ ] Favorite questions
- [ ] Session recording

### Animations
- [ ] Correct answer animation
- [ ] Wrong answer animation
- [ ] Level up animation
- [ ] Streak animation
- [ ] XP gain animation
- [ ] Page transitions

### Testing Requirements
- [ ] Widget tests for screens
- [ ] ViewModel unit tests
- [ ] Integration tests for learning flow
- [ ] Error handling tests

---

## 🚀 Deployment Notes

### Performance Optimization
- Lazy load questions
- Cache frequently accessed data
- Optimize image and animation assets
- Minimize rebuild areas

### Error Handling
- Network error recovery
- Offline mode support
- Data validation
- Graceful degradation

### Analytics Events
- Session start/end
- Question answered
- Achievement unlocked
- Level completed
- Wrong answer reviewed

---

## 📝 Handoff to Phase 3

Phase 2 establishes the complete Part 5 learning experience. Phase 3 will add:
- Statistics dashboard with charts
- Advanced analytics
- Study patterns analysis
- Performance trends
- Gamification enhancements

All UI components and state management are ready for Phase 3 integration.