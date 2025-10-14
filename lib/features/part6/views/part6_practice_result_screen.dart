import 'package:egg_toeic/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/core/widgets/custom_app_bar.dart';

class Part6PracticeResultScreen extends ConsumerStatefulWidget {
  final String date;
  final List<SimpleQuestion> questions;
  final Map<String, int> userAnswers;
  final DateTime sessionStartTime;
  final DateTime sessionEndTime;

  const Part6PracticeResultScreen({
    super.key,
    required this.date,
    required this.questions,
    required this.userAnswers,
    required this.sessionStartTime,
    required this.sessionEndTime,
  });

  @override
  ConsumerState<Part6PracticeResultScreen> createState() => _Part6PracticeResultScreenState();
}

class _Part6PracticeResultScreenState extends ConsumerState<Part6PracticeResultScreen>
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

  // Calculate overall score
  Part6PracticeResults _calculateResults() {
    int totalQuestions = widget.questions.length;
    int correctAnswers = 0;
    int answeredQuestions = 0;
    List<Part6QuestionResult> questionResults = [];
    Map<String, int> passagePerformance = {};

    for (int i = 0; i < totalQuestions; i++) {
      final question = widget.questions[i];
      final userAnswer = widget.userAnswers[question.id] ?? -1;
      final isAnswered = userAnswer != -1;
      final isCorrect = userAnswer == question.correctAnswerIndex;

      if (isAnswered) answeredQuestions++;
      if (isCorrect) correctAnswers++;

      // Track passage performance
      final passageId = question.passageText ?? 'Unknown';
      if (!passagePerformance.containsKey(passageId)) {
        passagePerformance[passageId] = 0;
      }
      if (isCorrect) {
        passagePerformance[passageId] = passagePerformance[passageId]! + 1;
      }

      questionResults.add(Part6QuestionResult(
        questionNumber: i + 1,
        question: question,
        userAnswerIndex: userAnswer,
        isCorrect: isCorrect,
        isAnswered: isAnswered,
      ));
    }

    return Part6PracticeResults(
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      answeredQuestions: answeredQuestions,
      percentage: (correctAnswers / totalQuestions * 100).round(),
      duration: widget.sessionEndTime.difference(widget.sessionStartTime),
      questionResults: questionResults,
      passagePerformance: passagePerformance,
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _calculateResults();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: 'Part 6 연습 결과 - ${widget.date}',
        backgroundColor: const Color(0xFF42A5F5), // Part6 light blue
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.assessment), text: '개요'),
            Tab(icon: Icon(Icons.list_alt), text: '문제'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF42A5F5), // Light sky blue
              Color(0xFF29B6F6), // Brighter blue
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(results),
              _buildQuestionsTab(results),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildOverviewTab(Part6PracticeResults results) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Score Header
          _buildScoreHeader(results),
          const SizedBox(height: 20),

          // Passage Performance
          _buildPassagePerformance(results),
          const SizedBox(height: 20),

          // Time Stats
          _buildTimeStats(results),
        ],
      ),
    );
  }

  Widget _buildScoreHeader(Part6PracticeResults results) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF42A5F5).withOpacity(0.3),
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
      child: Column(
        children: [
          // Emoji icon in colored circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF42A5F5),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF42A5F5).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _getScoreIcon(results.percentage),
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${results.correctAnswers}/${results.totalQuestions}',
            style: const TextStyle(
              color: Color(0xFF42A5F5),
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${results.percentage}% 정답',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF42A5F5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF42A5F5).withOpacity(0.2),
              ),
            ),
            child: Text(
              _getPerformanceLabel(results.percentage),
              style: TextStyle(
                color: const Color(0xFF42A5F5).withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassagePerformance(Part6PracticeResults results) {
    // Group questions by passage
    final passageGroups = <String, List<Part6QuestionResult>>{};
    for (final result in results.questionResults) {
      final passageId = result.question.passageText ?? 'Unknown';
      if (!passageGroups.containsKey(passageId)) {
        passageGroups[passageId] = [];
      }
      passageGroups[passageId]!.add(result);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withOpacity(0.3),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.article, color: const Color(0xFF1E88E5)),
                const SizedBox(width: 8),
                const Text(
                  '지문별 분석',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(passageGroups.length, (index) {
              final passageEntry = passageGroups.entries.toList()[index];
              final passageQuestions = passageEntry.value;
              final correctInPassage = passageQuestions.where((q) => q.isCorrect).length;
              final totalInPassage = passageQuestions.length;
              final passagePercentage = (correctInPassage / totalInPassage * 100).round();

              final color = passagePercentage >= 75
                  ? AppColors.successColor
                  : passagePercentage >= 50
                      ? Colors.orange
                      : AppColors.errorColor;

              // Get Korean translation if available
              final passageTextKorean = passageQuestions.first.question.passageTextKorean;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '지문 ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '$correctInPassage/$totalInPassage 정답 ($passagePercentage%)',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          passagePercentage >= 75 ? Icons.check_circle : Icons.warning_amber,
                          color: color,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: correctInPassage / totalInPassage,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                    // Show Korean translation if available
                    if (passageTextKorean != null && passageTextKorean.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF42A5F5).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF42A5F5).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.translate, size: 16, color: const Color(0xFF42A5F5)),
                                const SizedBox(width: 4),
                                const Text(
                                  '지문 번역',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF42A5F5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              passageTextKorean,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStats(Part6PracticeResults results) {
    final minutes = results.duration.inMinutes;
    final seconds = results.duration.inSeconds % 60;
    final avgTimePerQuestion =
        results.duration.inSeconds / results.totalQuestions;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF29B6F6).withOpacity(0.3),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: const Color(0xFF29B6F6)),
                const SizedBox(width: 8),
                const Text(
                  '시간 통계',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '총 시간',
                    '${minutes}분 ${seconds}초',
                    Icons.access_time,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '문제당 평균',
                    '${avgTimePerQuestion.round()}초',
                    Icons.speed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF29B6F6), size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF29B6F6),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsTab(Part6PracticeResults results) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.questionResults.length,
      itemBuilder: (context, index) {
        final questionResult = results.questionResults[index];
        return _buildQuestionResultCard(questionResult);
      },
    );
  }

  Widget _buildQuestionResultCard(Part6QuestionResult result) {
    final isCorrect = result.isCorrect;
    final isAnswered = result.isAnswered;

    Color borderColor;
    Color bgColor;

    if (!isAnswered) {
      borderColor = Colors.grey;
      bgColor = Colors.grey.withOpacity(0.1);
    } else if (isCorrect) {
      borderColor = AppColors.successColor;
      bgColor = AppColors.successColor.withOpacity(0.1);
    } else {
      borderColor = AppColors.errorColor;
      bgColor = AppColors.errorColor.withOpacity(0.1);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Q${result.questionNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  !isAnswered
                      ? Icons.remove_circle
                      : (isCorrect ? Icons.check_circle : Icons.cancel),
                  color: borderColor,
                  size: 20,
                ),
                const Spacer(),
                // Bookmark icon
                Consumer(
                  builder: (context, ref, child) {
                    final favoritesAsync = ref.watch(favoritesProvider);

                    return favoritesAsync.when(
                      data: (favorites) {
                        final isBookmarked = favorites.contains(result.question.id);
                        return GestureDetector(
                          onTap: () => _toggleBookmark(ref, result.question.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isBookmarked
                                  ? const Color(0xFFFF9600).withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked
                                  ? const Color(0xFFFF9600)
                                  : Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        );
                      },
                      loading: () => Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      error: (_, __) => Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.bookmark_border,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question text
            Text(
              result.question.questionText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Explanation (always shown for practice)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF42A5F5).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: const Color(0xFF42A5F5)),
                      const SizedBox(width: 4),
                      const Text(
                        '해설',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF42A5F5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.question.explanation,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Answer information
            if (!isAnswered) ...[
              Text(
                '답을 선택하지 않음',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Text(
                    '당신의 답: ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Expanded(
                    child: Text(
                      '${String.fromCharCode(65 + result.userAnswerIndex)}. ${result.question.options[result.userAnswerIndex]}',
                      style: TextStyle(
                        color: borderColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '정답: ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Expanded(
                  child: Text(
                    '${String.fromCharCode(65 + result.question.correctAnswerIndex)}. ${result.question.options[result.question.correctAnswerIndex]}',
                    style: TextStyle(
                      color: AppColors.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Answer Analytics Section
            Consumer(
              builder: (context, ref, child) {
                final analyticsAsync = ref.watch(questionAnalyticsProvider(result.question.id));

                return analyticsAsync.when(
                  loading: () => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('답변 통계 로딩 중...', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  error: (error, stack) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '답변 통계를 불러올 수 없습니다',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  data: (analytics) {
                    if (analytics == null || analytics.answerPercentages.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '아직 답변 통계가 없습니다',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '다른 사용자들의 선택',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: analytics.correctPercentage >= 70
                                      ? AppColors.successColor.withOpacity(0.1)
                                      : analytics.correctPercentage >= 50
                                          ? Colors.orange.withOpacity(0.1)
                                          : AppColors.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '정답률 ${analytics.correctPercentage.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: analytics.correctPercentage >= 70
                                        ? AppColors.successColor
                                        : analytics.correctPercentage >= 50
                                            ? Colors.orange
                                            : AppColors.errorColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(result.question.options.length, (optionIndex) {
                            final percentage = analytics.answerPercentages[optionIndex.toString()] ?? 0.0;
                            final isUserSelected = result.userAnswerIndex == optionIndex;
                            final isCorrectOption = optionIndex == result.question.correctAnswerIndex;

                            Color barColor = Colors.grey[400]!;
                            if (isCorrectOption) {
                              barColor = AppColors.successColor;
                            } else if (isUserSelected && !isCorrectOption) {
                              barColor = AppColors.errorColor;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: isUserSelected ? barColor : Colors.transparent,
                                          border: Border.all(color: barColor),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Center(
                                          child: Text(
                                            String.fromCharCode(65 + optionIndex),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isUserSelected ? Colors.white : barColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          result.question.options[optionIndex],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isCorrectOption ? FontWeight.bold : FontWeight.normal,
                                            color: isCorrectOption
                                                ? AppColors.successColor
                                                : Colors.grey[700],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isUserSelected) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.person,
                                          size: 12,
                                          color: barColor,
                                        ),
                                      ],
                                      if (isCorrectOption) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.check_circle,
                                          size: 12,
                                          color: AppColors.successColor,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const SizedBox(width: 28), // Align with option text
                                      Expanded(
                                        flex: 3,
                                        child: Container(
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: FractionallySizedBox(
                                            widthFactor: percentage / 100,
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: barColor.withOpacity(0.8),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${percentage.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: barColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                // Invalidate providers to refresh home screen statistics
                ref.invalidate(userProgressProvider);
                ref.invalidate(practiceSessionMetadataProvider);
                ref.invalidate(combinedStatisticsProvider);
                // Give providers time to invalidate before navigating
                await Future.delayed(const Duration(milliseconds: 50));
                // Navigate directly to home
                if (context.mounted) {
                  context.go('/');
                }
              },
              icon: const Icon(Icons.home),
              label: const Text('홈으로'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF42A5F5),
                side: const BorderSide(color: Color(0xFF42A5F5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to wrong answers review
                context.push('/wrong-answers');
              },
              icon: const Icon(Icons.quiz),
              label: const Text('오답 복습'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF42A5F5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/bookmarks'),
              icon: const Icon(Icons.bookmark),
              label: const Text('북마크'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF9600),
                side: const BorderSide(color: Color(0xFFFF9600)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getScoreIcon(int percentage) {
    if (percentage >= 90) return Icons.emoji_events;
    if (percentage >= 80) return Icons.grade;
    if (percentage >= 70) return Icons.thumb_up;
    if (percentage >= 60) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  String _getPerformanceLabel(int percentage) {
    if (percentage >= 90) return '훌륭한 성과! 🎉';
    if (percentage >= 80) return '잘했어요! 👍';
    if (percentage >= 70) return '좋아요! 😊';
    if (percentage >= 60) return '개선의 여지가 있어요 📈';
    return '계속 연습하세요! 💪';
  }

  void _toggleBookmark(WidgetRef ref, String questionId) async {
    try {
      final userDataRepo = ref.read(userDataRepositoryProvider);
      await userDataRepo.toggleFavorite(questionId);

      // Refresh favorites provider
      ref.invalidate(favoritesProvider);

      if (mounted) {
        final isBookmarked = await userDataRepo.isFavorite(questionId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBookmarked ? '북마크에 추가되었습니다! 📚' : '북마크에서 제거되었습니다',
            ),
            backgroundColor: isBookmarked
                ? const Color(0xFFFF9600)
                : Colors.grey[600],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('북마크 처리 중 오류가 발생했습니다'),
            backgroundColor: AppColors.errorColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// Data classes for Part6 practice results
class Part6PracticeResults {
  final int totalQuestions;
  final int correctAnswers;
  final int answeredQuestions;
  final int percentage;
  final Duration duration;
  final List<Part6QuestionResult> questionResults;
  final Map<String, int> passagePerformance;

  Part6PracticeResults({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.answeredQuestions,
    required this.percentage,
    required this.duration,
    required this.questionResults,
    required this.passagePerformance,
  });
}

class Part6QuestionResult {
  final int questionNumber;
  final SimpleQuestion question;
  final int userAnswerIndex;
  final bool isCorrect;
  final bool isAnswered;

  Part6QuestionResult({
    required this.questionNumber,
    required this.question,
    required this.userAnswerIndex,
    required this.isCorrect,
    required this.isAnswered,
  });
}
