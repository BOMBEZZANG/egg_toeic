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

    // Refresh exam results and statistics when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(examResultsProvider);
      ref.invalidate(separateStatisticsProvider);
      ref.invalidate(combinedStatisticsProvider);
    });
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

class _StatisticsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends ConsumerState<_StatisticsTab> {
  String _selectedFilter = 'all'; // 'all', 'part2', 'part5', 'part6'

  @override
  Widget build(BuildContext context) {
    final userProgressAsync = ref.watch(userProgressProvider);

    // Watch appropriate statistics based on filter
    final separateStatsAsync = _selectedFilter == 'all'
        ? ref.watch(separateStatisticsProvider)
        : _selectedFilter == 'part2'
            ? ref.watch(partStatisticsProvider(2))
            : _selectedFilter == 'part5'
                ? ref.watch(partStatisticsProvider(5))
                : ref.watch(partStatisticsProvider(6));

    // Debug logging for Part2 statistics
    separateStatsAsync.whenData((stats) {
      if (_selectedFilter == 'part2') {
        print('📊 Part2 Statistics: ${stats.examQuestionsAnswered} exam questions, ${stats.examCorrectAnswers} correct');
      }
    });

    final hierarchicalStatsAsync = _selectedFilter == 'all'
        ? ref.watch(hierarchicalStatisticsProvider)
        : _selectedFilter == 'part2'
            ? ref.watch(partHierarchicalStatisticsProvider(2))
            : _selectedFilter == 'part5'
                ? ref.watch(partHierarchicalStatisticsProvider(5))
                : ref.watch(partHierarchicalStatisticsProvider(6));

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

            // Filter Dropdown
            _buildFilterDropdown(context),
            const SizedBox(height: AppDimensions.paddingLarge),

            // Show Part Header if specific part is selected
            if (_selectedFilter != 'all') ...[
              _buildPartHeaderCard(
                context,
                _selectedFilter == 'part2'
                    ? 2
                    : _selectedFilter == 'part5'
                        ? 5
                        : 6,
              ),
              const SizedBox(height: AppDimensions.paddingLarge),
            ],

            // Separate Practice and Exam Statistics
            separateStatsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const SizedBox.shrink(),
              data: (separateStats) => Column(
                children: [
                  _buildModeStatisticsSection(
                    context,
                    separateStats,
                    _selectedFilter == 'part2'
                        ? 2
                        : _selectedFilter == 'part5'
                            ? 5
                            : _selectedFilter == 'part6'
                                ? 6
                                : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingLarge),
                ],
              ),
            ),

            // Hierarchical Category Statistics (문법/어휘)
            hierarchicalStatsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const SizedBox.shrink(),
              data: (hierarchicalStats) {
                if (hierarchicalStats.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    _buildHierarchicalStatisticsSection(
                        context, hierarchicalStats),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: AppColors.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '구분:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.primaryColor,
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Row(
                      children: [
                        Icon(Icons.assessment,
                            size: 18, color: AppColors.primaryColor),
                        SizedBox(width: 8),
                        Text('전체 통계'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'part2',
                    child: Row(
                      children: [
                        Icon(Icons.headphones,
                            size: 18, color: Color(0xFFFF6B9D)),
                        SizedBox(width: 8),
                        Text('Part 2 통계'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'part5',
                    child: Row(
                      children: [
                        Icon(Icons.edit_note,
                            size: 18, color: Color(0xFF4ECDC4)),
                        SizedBox(width: 8),
                        Text('Part 5 통계'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'part6',
                    child: Row(
                      children: [
                        Icon(Icons.article, size: 18, color: Color(0xFF45B7D1)),
                        SizedBox(width: 8),
                        Text('Part 6 통계'),
                      ],
                    ),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFilter = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartHeaderCard(BuildContext context, int partNumber) {
    final partInfo = {
      2: {
        'title': 'Part 2',
        'subtitle': 'Question-Response',
        'description': '듣기 이해',
        'icon': Icons.headphones,
        'color': const Color(0xFFFF6B9D),
      },
      5: {
        'title': 'Part 5',
        'subtitle': 'Incomplete Sentences',
        'description': '문법 & 어휘',
        'icon': Icons.edit_note,
        'color': const Color(0xFF4ECDC4),
      },
      6: {
        'title': 'Part 6',
        'subtitle': 'Text Completion',
        'description': '지문 완성',
        'icon': Icons.article,
        'color': const Color(0xFF45B7D1),
      },
    };

    final info = partInfo[partNumber]!;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            info['color'] as Color,
            (info['color'] as Color).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              info['icon'] as IconData,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info['title'] as String,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  info['subtitle'] as String,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  info['description'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ],
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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

  Widget _buildModeStatisticsSection(
      BuildContext context, dynamic separateStats, int? partNumber) {
    final title = partNumber != null ? 'Part $partNumber 통계' : '모드별 통계';
    final totalTitle = partNumber != null ? 'Part $partNumber 전체' : '전체 통계';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),

        // Total Combined Statistics Card
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.successColor,
                AppColors.successColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assessment, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    totalTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTotalStatItem(
                    context,
                    '총 문제',
                    '${separateStats.totalQuestionsAnswered}',
                    Icons.quiz,
                  ),
                  _buildTotalStatItem(
                    context,
                    '정답 수',
                    '${separateStats.totalCorrectAnswers}',
                    Icons.check_circle,
                  ),
                  _buildTotalStatItem(
                    context,
                    '정답률',
                    '${separateStats.overallAccuracy.toStringAsFixed(1)}%',
                    Icons.my_location,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.paddingMedium),

        // Practice and Exam Statistics Cards
        Row(
          children: [
            // Practice Statistics
            Expanded(
              child: _buildModeStatCard(
                context,
                '연습 모드',
                separateStats.practiceQuestionsAnswered,
                separateStats.practiceCorrectAnswers,
                separateStats.practiceAccuracy,
                AppColors.primaryColor,
                Icons.school,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            // Exam Statistics
            Expanded(
              child: _buildModeStatCard(
                context,
                '시험 모드',
                separateStats.examQuestionsAnswered,
                separateStats.examCorrectAnswers,
                separateStats.examAccuracy,
                Colors.orange,
                Icons.assessment,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalStatItem(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }

  Widget _buildModeStatCard(
    BuildContext context,
    String mode,
    int questionsAnswered,
    int correctAnswers,
    double accuracy,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: color, width: 2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mode,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _buildModeStatRow(context, '문제 수', '$questionsAnswered', color),
          const SizedBox(height: 8),
          _buildModeStatRow(context, '정답 수', '$correctAnswers', color),
          const SizedBox(height: 8),
          _buildModeStatRow(
              context, '정답률', '${accuracy.toStringAsFixed(1)}%', color),
        ],
      ),
    );
  }

  Widget _buildModeStatRow(
      BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildHierarchicalStatisticsSection(
    BuildContext context,
    Map<String, dynamic> hierarchicalStats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '카테고리별 분석 (시험모드)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        ...hierarchicalStats.entries.map((entry) =>
            _buildHierarchicalCategoryCard(context, entry.key, entry.value)),
      ],
    );
  }

  Widget _buildHierarchicalCategoryCard(
    BuildContext context,
    String categoryName,
    dynamic category,
  ) {
    final percentage = category.percentage.round();
    final color = percentage >= 70
        ? AppColors.successColor
        : percentage >= 50
            ? Colors.orange
            : AppColors.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.all(AppDimensions.paddingMedium),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingMedium,
            0,
            AppDimensions.paddingMedium,
            AppDimensions.paddingMedium,
          ),
          title: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(
                  categoryName == '문법'
                      ? Icons.menu_book
                      : categoryName == '어휘'
                          ? Icons.translate
                          : Icons.format_quote, // For 문장삽입 (sentence insert)
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.totalCorrect}/${category.totalQuestions} 정답 (${percentage}%)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            const SizedBox(height: 8),
            // Overall progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              child: LinearProgressIndicator(
                value: category.totalCorrect / category.totalQuestions,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            // Level breakdown
            ...category.levels.entries.map((levelEntry) {
              final level = levelEntry.key;
              final levelStats = levelEntry.value;
              final levelPercentage = levelStats.percentage.round();
              final levelColor = levelPercentage >= 70
                  ? AppColors.successColor
                  : levelPercentage >= 50
                      ? Colors.orange
                      : AppColors.errorColor;

              return Padding(
                padding:
                    const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: levelColor.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          level.toString(),
                          style: TextStyle(
                            color: levelColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Level $level',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              Text(
                                '${levelStats.correct}/${levelStats.total} (${levelPercentage}%)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: levelColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: levelStats.correct / levelStats.total,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(levelColor),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _PartStatisticsTab extends ConsumerWidget {
  final int partNumber;

  const _PartStatisticsTab({required this.partNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProgressAsync = ref.watch(userProgressProvider);
    final partStatsAsync = ref.watch(partStatisticsProvider(partNumber));
    final partHierarchicalStatsAsync =
        ref.watch(partHierarchicalStatisticsProvider(partNumber));

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
            // Part Header Card
            _buildPartHeaderCard(context, partNumber),
            const SizedBox(height: AppDimensions.paddingLarge),

            // Part-Specific Statistics
            partStatsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const SizedBox.shrink(),
              data: (partStats) => Column(
                children: [
                  _buildModeStatisticsSection(context, partStats, partNumber),
                  const SizedBox(height: AppDimensions.paddingLarge),
                ],
              ),
            ),

            // Part-Specific Hierarchical Category Statistics (문법/어휘)
            partHierarchicalStatsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const SizedBox.shrink(),
              data: (hierarchicalStats) {
                if (hierarchicalStats.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    _buildHierarchicalStatisticsSection(
                        context, hierarchicalStats),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartHeaderCard(BuildContext context, int partNumber) {
    final partInfo = {
      2: {
        'title': 'Part 2',
        'subtitle': 'Question-Response',
        'description': '듣기 이해',
        'icon': Icons.headphones,
        'color': const Color(0xFFFF6B9D),
      },
      5: {
        'title': 'Part 5',
        'subtitle': 'Incomplete Sentences',
        'description': '문법 & 어휘',
        'icon': Icons.edit_note,
        'color': const Color(0xFF4ECDC4),
      },
      6: {
        'title': 'Part 6',
        'subtitle': 'Text Completion',
        'description': '지문 완성',
        'icon': Icons.article,
        'color': const Color(0xFF45B7D1),
      },
    };

    final info = partInfo[partNumber]!;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            info['color'] as Color,
            (info['color'] as Color).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              info['icon'] as IconData,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info['title'] as String,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  info['subtitle'] as String,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  info['description'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeStatisticsSection(
      BuildContext context, dynamic separateStats, int partNumber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Part $partNumber 통계',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),

        // Total Statistics Card for this Part
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.successColor,
                AppColors.successColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assessment, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Part $partNumber 전체',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTotalStatItem(
                    context,
                    '총 문제',
                    '${separateStats.totalQuestionsAnswered}',
                    Icons.quiz,
                  ),
                  _buildTotalStatItem(
                    context,
                    '정답 수',
                    '${separateStats.totalCorrectAnswers}',
                    Icons.check_circle,
                  ),
                  _buildTotalStatItem(
                    context,
                    '정답률',
                    '${separateStats.overallAccuracy.toStringAsFixed(1)}%',
                    Icons.my_location,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.paddingMedium),

        // Practice and Exam Statistics Cards for this Part
        Row(
          children: [
            // Practice Statistics
            Expanded(
              child: _buildModeStatCard(
                context,
                '연습 모드',
                separateStats.practiceQuestionsAnswered,
                separateStats.practiceCorrectAnswers,
                separateStats.practiceAccuracy,
                AppColors.primaryColor,
                Icons.school,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            // Exam Statistics
            Expanded(
              child: _buildModeStatCard(
                context,
                '시험 모드',
                separateStats.examQuestionsAnswered,
                separateStats.examCorrectAnswers,
                separateStats.examAccuracy,
                Colors.orange,
                Icons.assessment,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalStatItem(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }

  Widget _buildModeStatCard(
    BuildContext context,
    String mode,
    int questionsAnswered,
    int correctAnswers,
    double accuracy,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: color, width: 2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mode,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _buildModeStatRow(context, '문제 수', '$questionsAnswered', color),
          const SizedBox(height: 8),
          _buildModeStatRow(context, '정답 수', '$correctAnswers', color),
          const SizedBox(height: 8),
          _buildModeStatRow(
              context, '정답률', '${accuracy.toStringAsFixed(1)}%', color),
        ],
      ),
    );
  }

  Widget _buildModeStatRow(
      BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildHierarchicalStatisticsSection(
    BuildContext context,
    Map<String, dynamic> hierarchicalStats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '카테고리별 분석 (시험모드)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        ...hierarchicalStats.entries.map((entry) =>
            _buildHierarchicalCategoryCard(context, entry.key, entry.value)),
      ],
    );
  }

  Widget _buildHierarchicalCategoryCard(
    BuildContext context,
    String categoryName,
    dynamic category,
  ) {
    final percentage = category.percentage.round();
    final color = percentage >= 70
        ? AppColors.successColor
        : percentage >= 50
            ? Colors.orange
            : AppColors.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.all(AppDimensions.paddingMedium),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingMedium,
            0,
            AppDimensions.paddingMedium,
            AppDimensions.paddingMedium,
          ),
          title: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(
                  categoryName == '문법'
                      ? Icons.menu_book
                      : categoryName == '어휘'
                          ? Icons.translate
                          : Icons.format_quote, // For 문장삽입 (sentence insert)
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.totalCorrect}/${category.totalQuestions} 정답 (${percentage}%)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            const SizedBox(height: 8),
            // Overall progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              child: LinearProgressIndicator(
                value: category.totalCorrect / category.totalQuestions,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            // Level breakdown
            ...category.levels.entries.map((levelEntry) {
              final level = levelEntry.key;
              final levelStats = levelEntry.value;
              final levelPercentage = levelStats.percentage.round();
              final levelColor = levelPercentage >= 70
                  ? AppColors.successColor
                  : levelPercentage >= 50
                      ? Colors.orange
                      : AppColors.errorColor;

              return Padding(
                padding:
                    const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: levelColor.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          level.toString(),
                          style: TextStyle(
                            color: levelColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Level $level',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              Text(
                                '${levelStats.correct}/${levelStats.total} (${levelPercentage}%)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: levelColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: levelStats.correct / levelStats.total,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(levelColor),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
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
        error: (error, stack) =>
            const Center(child: Text('Error loading progress')),
        data: (userProgress) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recently Unlocked Section
              _buildRecentlyUnlockedSection(
                  context, achievements, userProgress),
              const SizedBox(height: AppDimensions.paddingLarge),

              // Achievement Categories
              _buildAchievementCategories(context, achievements, userProgress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentlyUnlockedSection(BuildContext context,
      List<Achievement> achievements, UserProgress userProgress) {
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
        ...recent.map(
            (achievement) => _buildRecentAchievementCard(context, achievement)),
      ],
    );
  }

  Widget _buildRecentAchievementCard(
      BuildContext context, Achievement achievement) {
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
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
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

  Widget _buildAchievementCategories(BuildContext context,
      List<Achievement> achievements, UserProgress userProgress) {
    final categories = <String, List<Achievement>>{};

    for (final achievement in achievements) {
      categories.putIfAbsent(achievement.category, () => []).add(achievement);
    }

    final updatedAchievements =
        _updateAchievementProgress(achievements, userProgress);

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
        ...categories.entries.map((entry) => _buildCategorySection(
            context,
            entry.key,
            updatedAchievements
                .where((a) => a.category == entry.key)
                .toList())),
      ],
    );
  }

  Widget _buildCategorySection(
      BuildContext context, String category, List<Achievement> achievements) {
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

  Widget _buildAchievementCard(
      BuildContext context, Achievement achievement, Color categoryColor) {
    final isUnlocked = achievement.isUnlocked;
    final progress = achievement.progress;
    final isNearComplete = achievement.isNearCompletion;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: isUnlocked ? categoryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isUnlocked
              ? categoryColor
              : (isNearComplete
                  ? categoryColor.withOpacity(0.5)
                  : AppColors.borderColor),
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
                  : (isNearComplete
                      ? categoryColor.withOpacity(0.3)
                      : AppColors.backgroundLight),
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
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isUnlocked
                                        ? categoryColor
                                        : AppColors.textPrimary,
                                    fontSize: 11,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          achievement.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? categoryColor.withOpacity(0.2)
                                  : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSmall),
                            ),
                            child: Text(
                              '+${achievement.xpReward} XP',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isUnlocked
                                        ? categoryColor
                                        : AppColors.textSecondary,
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
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSmall),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor:
                                        categoryColor.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        categoryColor),
                                    minHeight: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${achievement.currentValue}/${achievement.requiredValue}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
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

  List<Achievement> _updateAchievementProgress(
      List<Achievement> achievements, UserProgress userProgress) {
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
          if (userProgress.overallAccuracy >= 90 &&
              achievement.id == 'perfect_25') {
            currentValue = achievement.requiredValue;
          } else if (userProgress.overallAccuracy >= 80 &&
              achievement.id == 'perfect_10') {
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
        unlockedAt: isUnlocked && achievement.unlockedAt == null
            ? DateTime.now()
            : achievement.unlockedAt,
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
