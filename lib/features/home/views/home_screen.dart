import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/constants/app_strings.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/providers/repository_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProgressAsync = ref.watch(userProgressProvider);
    final combinedStatsAsync = ref.watch(combinedStatisticsProvider);

    return Scaffold(
      body: SafeArea(
        child: userProgressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
          data: (userProgress) => CustomScrollView(
            slivers: [
              // App Bar with Character
              SliverToBoxAdapter(
                child: _buildHeader(context, userProgress),
              ),

              // Daily Progress Card
              SliverToBoxAdapter(
                child: _buildDailyProgress(context, ref, userProgress),
              ),

              // Quick Stats
              SliverToBoxAdapter(
                child: combinedStatsAsync.when(
                  loading: () => _buildQuickStats(context, userProgress, null),
                  error: (error, stack) =>
                      _buildQuickStats(context, userProgress, null),
                  data: (combinedStats) =>
                      _buildQuickStats(context, userProgress, combinedStats),
                ),
              ),

              // Main Menu Cards (Duolingo bubble style)
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildCuteMenuCard(
                      context,
                      ref: ref,
                      title: 'Part 5',
                      subtitle: 'Grammar & Vocabulary',
                      emoji: '📝',
                      color: const Color(0xFF1CB0F6), // Duolingo blue
                      onTap: () async {
                        await context.push('/part5');
                        // Refresh data when returning from Part 5
                        ref.invalidate(userProgressProvider);
                        ref.invalidate(examResultsProvider);
                        ref.invalidate(combinedStatisticsProvider);
                      },
                    ),
                    _buildCuteMenuCard(
                      context,
                      ref: ref,
                      title: '복습하기',
                      subtitle: 'Review & Practice',
                      emoji: '🔄',
                      color: const Color(0xFFFF9600), // Duolingo orange
                      onTap: () async {
                        await context.push('/review-select');
                        // Refresh data when returning
                        ref.invalidate(userProgressProvider);
                        ref.invalidate(examResultsProvider);
                        ref.invalidate(combinedStatisticsProvider);
                      },
                    ),
                    _buildCuteMenuCard(
                      context,
                      ref: ref,
                      title: '통계 & 업적',
                      subtitle: 'Progress & Achievements',
                      emoji: '📊',
                      color: const Color(0xFFCE82FF), // Duolingo purple
                      onTap: () async {
                        await context.push('/statistics-achievements');
                        // Refresh data when returning
                        ref.invalidate(userProgressProvider);
                        ref.invalidate(examResultsProvider);
                        ref.invalidate(combinedStatisticsProvider);
                      },
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, userProgress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF58CC02), // Duolingo green
            Color(0xFF89E219), // Bright green
          ],
        ),
      ),
      child: Column(
        children: [
          // Top row with streak and level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Streak counter (Duolingo style)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9600), // Orange like Duolingo
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9600).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🔥',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${userProgress.currentStreak}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Level badge (Duolingo style)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1CB0F6), // Blue like Duolingo
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1CB0F6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '👑',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Level ${userProgress.userLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Character and main info
          Row(
            children: [
              // Duolingo-style character bubble
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 4,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Text(
                    userProgress.characterEmoji,
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Name and XP info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProgress.characterName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // XP Display (Duolingo style)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD900), // Gold color
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD900).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '💎',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${userProgress.experiencePoints} XP',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Progress bar (Duolingo style)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress to Level ${userProgress.userLevel + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white.withOpacity(0.3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: userProgress.currentLevelProgress,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFD900),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgress(
      BuildContext context, WidgetRef ref, userProgress) {
    // Get real daily questions count from the repository
    final userDataRepo = ref.read(userDataRepositoryProvider);
    final questionsToday = userDataRepo.getTodaysQuestionCount();
    final dailyGoal = 10; // Default daily goal
    final progress = questionsToday / dailyGoal;
    final isCompleted = questionsToday >= dailyGoal;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCompleted
              ? [
                  const Color(0xFF58CC02),
                  const Color(0xFF89E219)
                ] // Green when completed
              : [
                  const Color(0xFF1CB0F6),
                  const Color(0xFF42A5F5)
                ], // Blue when in progress
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (isCompleted
                    ? const Color(0xFF58CC02)
                    : const Color(0xFF1CB0F6))
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with motivational message
          Row(
            children: [
              Text(
                isCompleted ? '🎉' : '💪',
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? '오늘의 목표 달성!' : '오늘의 목표!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted ? '역시 너무 멋져! 🌟' : '🌟연습문제 10개!🌟',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress Circle (Duolingo style)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$questionsToday',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/ $dailyGoal',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Motivational text
          Text(
            isCompleted ? '' : '${dailyGoal - questionsToday} 문제만 더 풀어보자!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          if (isCompleted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '⭐ +10 XP earned!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, userProgress, combinedStats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildCuteStatCard(
              context,
              title: '총 학습한 문제',
              value: combinedStats != null
                  ? combinedStats.totalQuestionsAnswered.toString()
                  : userProgress.totalQuestionsAnswered.toString(),
              emoji: '📚',
              color: const Color(0xFF1CB0F6), // Duolingo blue
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCuteStatCard(
              context,
              title: '정답률',
              value: combinedStats != null
                  ? '${combinedStats.overallAccuracy.toInt()}%'
                  : '${userProgress.accuracyPercentage.toInt()}%',
              emoji: '🎯',
              color: const Color(0xFF58CC02), // Duolingo green
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCuteStatCard(
              context,
              title: '연속 공부일',
              value: '${userProgress.currentStreak}',
              emoji: '🔥',
              color: const Color(0xFFFF9600), // Duolingo orange
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuteStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String emoji,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji in colored circle
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Value
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Title
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuteMenuCard(
    BuildContext context, {
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
    required Future<void> Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: 140,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Large emoji in white circle (Duolingo style)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Subtitle
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
