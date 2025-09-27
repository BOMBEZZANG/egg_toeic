import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/constants/app_dimensions.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:egg_toeic/data/models/user_progress_model.dart';
import 'package:egg_toeic/data/models/achievement_model.dart';
import 'package:egg_toeic/data/models/learning_session_model.dart';
import 'package:egg_toeic/providers/app_providers.dart';

class StatisticsAchievementsScreen extends ConsumerStatefulWidget {
  const StatisticsAchievementsScreen({super.key});

  @override
  ConsumerState<StatisticsAchievementsScreen> createState() =>
      _StatisticsAchievementsScreenState();
}

class _StatisticsAchievementsScreenState
    extends ConsumerState<StatisticsAchievementsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계 & 업적'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.bar_chart),
              text: '통계',
            ),
            Tab(
              icon: Icon(Icons.emoji_events),
              text: '업적',
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _StatisticsTab(),
            _AchievementsTab(),
          ],
        ),
      ),
    );
  }
}

class _StatisticsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProgressAsync = ref.watch(userProgressProvider);
    final learningSessionsAsync = ref.watch(learningSessionsProvider);
    final wrongAnswersAsync = ref.watch(wrongAnswersProvider);

    return userProgressAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
      data: (userProgress) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Character Card Section
            _buildCharacterCard(context, userProgress),
            const SizedBox(height: AppDimensions.paddingLarge),

            // Key Stats Grid
            _buildKeyStatsGrid(context, userProgress),
            const SizedBox(height: AppDimensions.paddingLarge),

            // Performance Charts Section
            _buildPerformanceSection(context, userProgress, ref),
            const SizedBox(height: AppDimensions.paddingLarge),

            // Grammar Points Analysis
            _buildGrammarPointsSection(context, userProgress),
            const SizedBox(height: AppDimensions.paddingLarge),

            // Quick Insights
            _buildInsightsSection(context, userProgress),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard(BuildContext context, UserProgress progress) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Character Emoji
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    progress.characterEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.characterName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level ${progress.userLevel}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${progress.experiencePoints} / ${progress.xpToNextLevel} XP',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          // XP Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            child: LinearProgressIndicator(
              value: progress.currentLevelProgress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStatsGrid(BuildContext context, UserProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '주요 통계',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppDimensions.paddingMedium,
          mainAxisSpacing: AppDimensions.paddingMedium,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              context,
              '총 문제 수',
              '${progress.totalQuestionsAnswered}',
              Icons.quiz,
              AppColors.primaryColor,
            ),
            _buildStatCard(
              context,
              '전체 정답률',
              '${progress.overallAccuracy.toStringAsFixed(1)}%',
              Icons.my_location,
              AppColors.successColor,
            ),
            _buildStatCard(
              context,
              '현재 연속',
              '${progress.currentStreak}일',
              Icons.local_fire_department,
              AppColors.warningColor,
            ),
            _buildStatCard(
              context,
              '총 학습 시간',
              '${(progress.totalStudyTimeMinutes / 60).toStringAsFixed(1)}시간',
              Icons.schedule,
              AppColors.infoColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(BuildContext context, UserProgress progress, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '레벨별 성과',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.borderColor),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              _buildLevelProgressBar(context, 'Level 1', progress.levelProgress['level1'] ?? 0.0, AppColors.primaryColor),
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildLevelProgressBar(context, 'Level 2', progress.levelProgress['level2'] ?? 0.0, AppColors.successColor),
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildLevelProgressBar(context, 'Level 3', progress.levelProgress['level3'] ?? 0.0, AppColors.warningColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelProgressBar(BuildContext context, String level, double progress, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            level,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(progress * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildGrammarPointsSection(BuildContext context, UserProgress progress) {
    final grammarEntries = progress.grammarPointScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topGrammar = grammarEntries.take(5).toList();
    final weakGrammar = grammarEntries.reversed.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '문법 포인트 분석',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),

        // Strong Areas
        if (topGrammar.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(color: AppColors.successColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: AppColors.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '강점 영역',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.successColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...topGrammar.map((entry) => _buildGrammarPointRow(
                  context, entry.key, entry.value, AppColors.successColor)),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
        ],

        // Weak Areas
        if (weakGrammar.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(color: AppColors.warningColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_down,
                      color: AppColors.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '개선 필요 영역',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.warningColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...weakGrammar.map((entry) => _buildGrammarPointRow(
                  context, entry.key, entry.value, AppColors.warningColor)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGrammarPointRow(BuildContext context, String grammarPoint, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              grammarPoint,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Text(
              '$score점',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(BuildContext context, UserProgress progress) {
    final insights = _generateInsights(progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 인사이트',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        ...insights.map((insight) => _buildInsightCard(context, insight)),
      ],
    );
  }

  Widget _buildInsightCard(BuildContext context, Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: insight['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: insight['color'].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            insight['icon'],
            color: insight['color'],
            size: 24,
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Text(
              insight['text'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateInsights(UserProgress progress) {
    final insights = <Map<String, dynamic>>[];

    // Top grammar point
    if (progress.grammarPointScores.isNotEmpty) {
      final topGrammar = progress.grammarPointScores.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      insights.add({
        'icon': Icons.star,
        'color': AppColors.successColor,
        'text': '가장 강한 영역: ${topGrammar.key} (${topGrammar.value}점)',
      });
    }

    // Longest streak
    if (progress.longestStreak > 0) {
      insights.add({
        'icon': Icons.local_fire_department,
        'color': AppColors.warningColor,
        'text': '최장 연속 기록: ${progress.longestStreak}일',
      });
    }

    // Accuracy insight
    if (progress.overallAccuracy >= 80) {
      insights.add({
        'icon': Icons.my_location,
        'color': AppColors.successColor,
        'text': '훌륭한 정답률! ${progress.overallAccuracy.toStringAsFixed(1)}%를 유지하고 있어요',
      });
    } else if (progress.overallAccuracy >= 60) {
      insights.add({
        'icon': Icons.trending_up,
        'color': AppColors.primaryColor,
        'text': '좋은 성과! 80% 목표까지 ${(80 - progress.overallAccuracy).toStringAsFixed(1)}% 남았어요',
      });
    }

    // Study progress
    if (progress.questionsToday != null && progress.questionsToday! > 0) {
      insights.add({
        'icon': Icons.today,
        'color': AppColors.infoColor,
        'text': '오늘 ${progress.questionsToday}문제 완료! 꾸준히 하고 있어요',
      });
    }

    return insights;
  }
}

class _AchievementsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final userProgressAsync = ref.watch(userProgressProvider);

    return achievementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading achievements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
      data: (achievements) => userProgressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('Error loading progress')),
        data: (userProgress) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recently Unlocked Section
              _buildRecentlyUnlockedSection(context, achievements, userProgress),
              const SizedBox(height: AppDimensions.paddingLarge),

              // Achievement Categories
              _buildAchievementCategories(context, achievements, userProgress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentlyUnlockedSection(BuildContext context, List<Achievement> achievements, UserProgress userProgress) {
    final recentUnlocked = achievements
        .where((a) => a.isUnlocked && a.unlockedAt != null)
        .toList()
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));

    final recent = recentUnlocked.take(3).toList();

    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.1),
              Colors.orange.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events,
              size: 48,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              '첫 번째 업적을 달성해보세요!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '문제를 풀고 연속 학습하여 업적을 해제하세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '최근 달성 업적',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        ...recent.map((achievement) => _buildRecentAchievementCard(context, achievement)),
      ],
    );
  }

  Widget _buildRecentAchievementCard(BuildContext context, Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.orange.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Text(
                  '+${achievement.xpReward} XP',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(achievement.unlockedAt!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCategories(BuildContext context, List<Achievement> achievements, UserProgress userProgress) {
    final categories = <String, List<Achievement>>{};

    for (final achievement in achievements) {
      categories.putIfAbsent(achievement.category, () => []).add(achievement);
    }

    final updatedAchievements = _updateAchievementProgress(achievements, userProgress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '업적 카테고리',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        ...categories.entries.map((entry) =>
          _buildCategorySection(context, entry.key,
            updatedAchievements.where((a) => a.category == entry.key).toList())),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, String category, List<Achievement> achievements) {
    final categoryColors = {
      'Streak': AppColors.warningColor,
      'Questions': AppColors.primaryColor,
      'Accuracy': AppColors.successColor,
      'Level': AppColors.infoColor,
      'Special': AppColors.tertiaryColor,
      'Review': AppColors.accentColor,
      'Grammar': AppColors.secondaryColor,
    };

    final color = categoryColors[category] ?? AppColors.primaryColor;
    final unlocked = achievements.where((a) => a.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '$unlocked/${achievements.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 6,
            mainAxisSpacing: AppDimensions.paddingMedium,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) =>
            _buildAchievementCard(context, achievements[index], color),
        ),
        const SizedBox(height: AppDimensions.paddingLarge),
      ],
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement, Color categoryColor) {
    final isUnlocked = achievement.isUnlocked;
    final progress = achievement.progress;
    final isNearComplete = achievement.isNearCompletion;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: isUnlocked
          ? categoryColor.withOpacity(0.1)
          : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isUnlocked
            ? categoryColor
            : (isNearComplete ? categoryColor.withOpacity(0.5) : AppColors.borderColor),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked ? AppTheme.cardShadow : null,
      ),
      child: Row(
        children: [
          // Achievement Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isUnlocked
                ? categoryColor
                : (isNearComplete ? categoryColor.withOpacity(0.3) : AppColors.backgroundLight),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events : Icons.lock,
              color: isUnlocked
                ? Colors.white
                : (isNearComplete ? categoryColor : AppColors.textHint),
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),

          // Achievement Info - Compact Horizontal Layout
          Expanded(
            child: Row(
              children: [
                // Left side - Title and Description
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          achievement.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? categoryColor : AppColors.textPrimary,
                                fontSize: 11,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          achievement.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 8,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right side - Progress/Status and XP
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // XP Reward
                      if (achievement.xpReward > 0)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                ? categoryColor.withOpacity(0.2)
                                : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            ),
                            child: Text(
                              '+${achievement.xpReward} XP',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isUnlocked ? categoryColor : AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 7,
                                  ),
                            ),
                          ),
                        ),

                      // Progress or Completion Status
                      if (!isUnlocked) ...[
                        Flexible(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: categoryColor.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                                    minHeight: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${achievement.currentValue}/${achievement.requiredValue}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 7,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Flexible(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.check,
                                size: 10,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '완료',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: categoryColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 8,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Achievement> _updateAchievementProgress(List<Achievement> achievements, UserProgress userProgress) {
    return achievements.map((achievement) {
      int currentValue = achievement.currentValue;
      bool isUnlocked = achievement.isUnlocked;

      switch (achievement.type) {
        case AchievementType.streak:
          currentValue = userProgress.longestStreak;
          break;
        case AchievementType.questions:
          currentValue = userProgress.totalQuestionsAnswered;
          break;
        case AchievementType.level:
          currentValue = userProgress.userLevel;
          break;
        case AchievementType.accuracy:
          // For accuracy achievements, we'd need more detailed tracking
          // For now, use a simplified approach
          if (userProgress.overallAccuracy >= 90 && achievement.id == 'perfect_25') {
            currentValue = achievement.requiredValue;
          } else if (userProgress.overallAccuracy >= 80 && achievement.id == 'perfect_10') {
            currentValue = achievement.requiredValue;
          }
          break;
        default:
          // Keep current value for special achievements
          break;
      }

      // Check if should be unlocked
      if (currentValue >= achievement.requiredValue && !isUnlocked) {
        isUnlocked = true;
      }

      return achievement.copyWith(
        currentValue: currentValue,
        isUnlocked: isUnlocked,
        unlockedAt: isUnlocked && achievement.unlockedAt == null ? DateTime.now() : achievement.unlockedAt,
      );
    }).toList();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '어제';
    } else if (difference < 7) {
      return '${difference}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}