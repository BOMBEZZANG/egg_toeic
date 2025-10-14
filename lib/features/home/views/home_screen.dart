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

              // Practice Hub Banner
              SliverToBoxAdapter(
                child: _buildPracticeHubBanner(context, ref),
              ),

              // Exam Hub Banner
              SliverToBoxAdapter(
                child: _buildExamHubBanner(context, ref),
              ),

              // Wrong Answer Hub Banner
              SliverToBoxAdapter(
                child: _buildWrongAnswerHubBanner(context, ref),
              ),

              // Bookmark Hub Banner
              SliverToBoxAdapter(
                child: _buildBookmarkHubBanner(context, ref),
              ),

              // Statistics & Achievements Banner
              SliverToBoxAdapter(
                child: _buildStatisticsBanner(context, ref),
              ),

              // Add some bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
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
            Color(0xFF4CAF50), // Duolingo green
            Color(0xFF66BB6A), // Bright green
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
                  color: const Color(0xFFFF8A65), // Orange like Duolingo
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8A65).withOpacity(0.3),
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
                  color: const Color(0xFF5C6BC0), // Blue like Duolingo
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5C6BC0).withOpacity(0.3),
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
                        color: const Color(0xFFFFC107), // Gold color
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withOpacity(0.3),
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
                                Color(0xFFFFC107),
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
                  const Color(0xFF4CAF50),
                  const Color(0xFF66BB6A)
                ] // Green when completed
              : [
                  const Color(0xFF5C6BC0),
                  const Color(0xFF7986CB)
                ], // Blue when in progress
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (isCompleted
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF5C6BC0))
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
              color: const Color(0xFF5C6BC0), // Duolingo blue
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
              color: const Color(0xFF4CAF50), // Duolingo green
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCuteStatCard(
              context,
              title: '연속 공부일',
              value: '${userProgress.currentStreak}',
              emoji: '🔥',
              color: const Color(0xFFFF8A65), // Duolingo orange
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

  Widget _buildPracticeHubBanner(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await context.push('/practice-hub');
            // Refresh data when returning
            ref.invalidate(userProgressProvider);
            ref.invalidate(examResultsProvider);
            ref.invalidate(combinedStatisticsProvider);
          },
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7E57C2), // Purple
                  Color(0xFF9575CD), // Pink
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7E57C2).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '📅',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '매일 연습문제',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamHubBanner(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await context.push('/exam-hub');
            // Refresh data when returning
            ref.invalidate(userProgressProvider);
            ref.invalidate(examResultsProvider);
            ref.invalidate(combinedStatisticsProvider);
          },
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF42A5F5), // Deep Blue
                  Color(0xFF64B5F6), // Light Blue
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF42A5F5).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '📝',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '모의고사 풀기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWrongAnswerHubBanner(BuildContext context, WidgetRef ref) {
    final wrongAnswersAsync = ref.watch(wrongAnswersProvider);

    return wrongAnswersAsync.when(
      loading: () => _buildWrongAnswerHubBannerContent(context, ref, 0),
      error: (error, stack) =>
          _buildWrongAnswerHubBannerContent(context, ref, 0),
      data: (wrongAnswers) =>
          _buildWrongAnswerHubBannerContent(context, ref, wrongAnswers.length),
    );
  }

  Widget _buildWrongAnswerHubBannerContent(
      BuildContext context, WidgetRef ref, int wrongCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await context.push('/wrong-answer-hub');
            // Refresh data when returning
            ref.invalidate(userProgressProvider);
            ref.invalidate(wrongAnswersProvider);
            ref.invalidate(combinedStatisticsProvider);
          },
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE57373), // Red
                  Color(0xFFEF5350), // Light red
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE57373).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '❌',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '오답노트',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        wrongCount > 0
                            ? '$wrongCount 문제 • Review'
                            : '복습할 문제 없음 🎉',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarkHubBanner(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return favoritesAsync.when(
      loading: () => _buildBookmarkHubBannerContent(context, ref, 0),
      error: (error, stack) => _buildBookmarkHubBannerContent(context, ref, 0),
      data: (favorites) =>
          _buildBookmarkHubBannerContent(context, ref, favorites.length),
    );
  }

  Widget _buildBookmarkHubBannerContent(
      BuildContext context, WidgetRef ref, int bookmarkCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await context.push('/bookmark-hub');
            // Refresh data when returning
            ref.invalidate(userProgressProvider);
            ref.invalidate(favoritesProvider);
            ref.invalidate(combinedStatisticsProvider);
          },
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFB74D), // Orange
                  Color(0xFFFFCA28), // Light orange
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB74D).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🔖',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '즐겨찾기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bookmarkCount > 0
                            ? '$bookmarkCount 문제 • Saved Questions'
                            : '북마크한 문제 없음 📚',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsBanner(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await context.push('/statistics-achievements');
            // Refresh data when returning
            ref.invalidate(userProgressProvider);
            ref.invalidate(examResultsProvider);
            ref.invalidate(combinedStatisticsProvider);
          },
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF26A69A), // Green
                  Color(0xFF4DB6AC), // Bright green
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF26A69A).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '📊',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '통계보기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
