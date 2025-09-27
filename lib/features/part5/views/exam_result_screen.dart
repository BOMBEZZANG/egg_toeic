import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:egg_toeic/data/models/simple_models.dart';

class ExamResultScreen extends ConsumerStatefulWidget {
  final String examRound;
  final List<SimpleQuestion> questions;
  final List<int> userAnswers;
  final DateTime examStartTime;
  final DateTime examEndTime;

  const ExamResultScreen({
    super.key,
    required this.examRound,
    required this.questions,
    required this.userAnswers,
    required this.examStartTime,
    required this.examEndTime,
  });

  @override
  ConsumerState<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends ConsumerState<ExamResultScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
  ExamResults _calculateResults() {
    int totalQuestions = widget.questions.length;
    int correctAnswers = 0;
    List<QuestionResult> questionResults = [];
    Map<String, CategoryScore> categoryScores = {};
    Map<String, int> tagAnalysis = {};

    for (int i = 0; i < totalQuestions; i++) {
      final question = widget.questions[i];
      final userAnswer = widget.userAnswers[i];
      final isCorrect = userAnswer == question.correctAnswerIndex;

      if (isCorrect) correctAnswers++;

      // Determine category and tags
      final category = _determineCategory(question);
      final tags = _extractTags(question);

      // Update category scores
      if (!categoryScores.containsKey(category)) {
        categoryScores[category] =
            CategoryScore(category: category, correct: 0, total: 0);
      }
      categoryScores[category] = categoryScores[category]!.copyWith(
        correct: categoryScores[category]!.correct + (isCorrect ? 1 : 0),
        total: categoryScores[category]!.total + 1,
      );

      // Update tag analysis
      for (final tag in tags) {
        if (!isCorrect) {
          tagAnalysis[tag] = (tagAnalysis[tag] ?? 0) + 1;
        }
      }

      questionResults.add(QuestionResult(
        questionNumber: i + 1,
        question: question,
        userAnswerIndex: userAnswer,
        isCorrect: isCorrect,
        category: category,
        tags: tags,
      ));
    }

    return ExamResults(
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      percentage: (correctAnswers / totalQuestions * 100).round(),
      duration: widget.examEndTime.difference(widget.examStartTime),
      questionResults: questionResults,
      categoryScores: categoryScores.values.toList(),
      weakAreas: _identifyWeakAreas(tagAnalysis),
    );
  }

  String _determineCategory(SimpleQuestion question) {
    final text = question.questionText.toLowerCase();
    final grammarPoint = question.grammarPoint?.toLowerCase() ?? '';

    // Vocabulary indicators
    if (text.contains('meaning') ||
        text.contains('synonym') ||
        text.contains('definition') ||
        text.contains('word that best') ||
        grammarPoint.contains('vocabulary')) {
      return '어휘';
    }

    // Grammar indicators
    return '문법';
  }

  List<String> _extractTags(SimpleQuestion question) {
    final text = question.questionText.toLowerCase();
    final grammarPoint = question.grammarPoint?.toLowerCase() ?? '';
    final tags = <String>[];

    // Grammar tags
    if (text.contains('tense') || grammarPoint.contains('tense'))
      tags.add('시제');
    if (text.contains('passive') || grammarPoint.contains('passive'))
      tags.add('수동태');
    if (text.contains('conditional') || grammarPoint.contains('conditional'))
      tags.add('조건문');
    if (text.contains('modal') || grammarPoint.contains('modal'))
      tags.add('조동사');
    if (text.contains('preposition') || grammarPoint.contains('preposition'))
      tags.add('전치사');
    if (text.contains('article') || grammarPoint.contains('article'))
      tags.add('관사');
    if (text.contains('subject') && text.contains('verb')) tags.add('주어-동사 일치');
    if (text.contains('relative') || grammarPoint.contains('relative'))
      tags.add('관계절');
    if (text.contains('infinitive') || grammarPoint.contains('infinitive'))
      tags.add('부정사');
    if (text.contains('gerund') || grammarPoint.contains('gerund'))
      tags.add('동명사');
    if (text.contains('comparative') || grammarPoint.contains('comparative'))
      tags.add('비교급');

    // Vocabulary tags
    if (text.contains('business') || grammarPoint.contains('business'))
      tags.add('비즈니스 용어');
    if (text.contains('formal') || grammarPoint.contains('formal'))
      tags.add('격식체');
    if (text.contains('phrasal') || grammarPoint.contains('phrasal'))
      tags.add('구동사');
    if (text.contains('idiom') || grammarPoint.contains('idiom'))
      tags.add('숙어');

    // Default tag if none found
    if (tags.isEmpty) {
      tags.add('일반');
    }

    return tags;
  }

  List<WeakArea> _identifyWeakAreas(Map<String, int> tagAnalysis) {
    final weakAreas = <WeakArea>[];

    // Sort tags by error count
    final sortedTags = tagAnalysis.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedTags.take(5)) {
      // Top 5 weak areas
      weakAreas.add(WeakArea(
        topic: entry.key,
        errorCount: entry.value,
        recommendation: _getRecommendation(entry.key),
      ));
    }

    return weakAreas;
  }

  String _getRecommendation(String tag) {
    switch (tag) {
      case '시제':
        return '과거, 현재, 미래 시제 형태에 집중하세요. 시간 순서 연습을 해보세요.';
      case '전치사':
        return '일반적인 전치사 조합을 학습하세요. 장소와 시간 표현을 연습하세요.';
      case '수동태':
        return '수동태 형성 방법을 복습하세요. 능동태에서 수동태로 변환하는 연습을 하세요.';
      case '조동사':
        return '조동사의 의미와 용법을 학습하세요. 의무, 가능성, 조언 표현을 연습하세요.';
      case '조건문':
        return '0, 1, 2, 3조건문 구조를 복습하세요.';
      case '주어-동사 일치':
        return '단수/복수 주어와 함께 연습하세요. 집합명사와 부정대명사에 집중하세요.';
      case '비즈니스 용어':
        return '비즈니스 어휘를 확장하세요. 직장 커뮤니케이션과 격식체 표현을 학습하세요.';
      case '관사':
        return '정관사/부정관사 규칙을 복습하세요. 가산/불가산 명사와 함께 연습하세요.';
      default:
        return '이 문법 포인트를 정기적으로 계속 연습하고 복습하세요.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _calculateResults();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('${widget.examRound.replaceAll('ROUND_', '라운드 ')} 결과'),
        backgroundColor:
            const Color.fromARGB(255, 19, 215, 137), // Duolingo green
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
            Tab(icon: Icon(Icons.trending_up), text: '분석'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF58CC02), // Duolingo green
              Color(0xFF89E219), // Bright green
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
              _buildAnalysisTab(results),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildOverviewTab(ExamResults results) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Score Header
          _buildScoreHeader(results),
          const SizedBox(height: 20),

          // Category Breakdown
          _buildCategoryBreakdown(results),
          const SizedBox(height: 20),

          // Time Stats
          _buildTimeStats(results),
        ],
      ),
    );
  }

  Widget _buildScoreHeader(ExamResults results) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), // More rounded like Duolingo
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF58CC02).withOpacity(0.3),
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
          // Emoji icon in colored circle (Duolingo style)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF58CC02),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF58CC02).withOpacity(0.3),
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
              color: Color(0xFF58CC02),
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
              color: const Color(0xFF58CC02).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF58CC02).withOpacity(0.2),
              ),
            ),
            child: Text(
              _getPerformanceLabel(results.percentage),
              style: TextStyle(
                color: const Color(0xFF58CC02).withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(ExamResults results) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), // More rounded like Duolingo
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1CB0F6).withOpacity(0.3),
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
                Icon(Icons.category, color: const Color(0xFF1CB0F6)),
                const SizedBox(width: 8),
                const Text(
                  '카테고리별 분석',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...results.categoryScores.map((category) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCategoryItem(category),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(CategoryScore category) {
    final percentage = (category.correct / category.total * 100).round();
    final color = percentage >= 70
        ? AppColors.successColor
        : percentage >= 50
            ? Colors.orange
            : AppColors.errorColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category.category,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            Text(
              '${category.correct}/${category.total} ($percentage%)',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: category.correct / category.total,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildTimeStats(ExamResults results) {
    final minutes = results.duration.inMinutes;
    final seconds = results.duration.inSeconds % 60;
    final avgTimePerQuestion =
        results.duration.inSeconds / results.totalQuestions;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), // More rounded like Duolingo
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9600).withOpacity(0.3),
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
                Icon(Icons.timer, color: const Color(0xFFFF9600)),
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
        Icon(icon, color: const Color(0xFFFF9600), size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF9600),
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

  Widget _buildQuestionsTab(ExamResults results) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.questionResults.length,
      itemBuilder: (context, index) {
        final questionResult = results.questionResults[index];
        return _buildQuestionResultCard(questionResult);
      },
    );
  }

  Widget _buildQuestionResultCard(QuestionResult result) {
    final isCorrect = result.isCorrect;
    final borderColor =
        isCorrect ? AppColors.successColor : AppColors.errorColor;
    final bgColor = isCorrect
        ? AppColors.successColor.withOpacity(0.1)
        : AppColors.errorColor.withOpacity(0.1);

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
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: borderColor,
                  size: 20,
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    result.category,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.grey[200],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question text (truncated)
            Text(
              result.question.questionText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Answer information
            if (result.userAnswerIndex >= 0) ...[
              Row(
                children: [
                  Text(
                    '당신의 답: ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    '${String.fromCharCode(65 + result.userAnswerIndex)}. ${result.question.options[result.userAnswerIndex]}',
                    style: TextStyle(
                      color: borderColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ] else ...[
              Text(
                '답을 선택하지 않음',
                style: TextStyle(
                  color: AppColors.errorColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            if (!isCorrect) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '정답: ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    '${String.fromCharCode(65 + result.question.correctAnswerIndex)}. ${result.question.options[result.question.correctAnswerIndex]}',
                    style: TextStyle(
                      color: AppColors.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],

            // Tags
            if (result.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: result.tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisTab(ExamResults results) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Performance analysis
          _buildPerformanceAnalysis(results),
          const SizedBox(height: 20),

          // Weak areas
          _buildWeakAreas(results),
          const SizedBox(height: 20),

          // Study recommendations
          _buildStudyRecommendations(results),
        ],
      ),
    );
  }

  Widget _buildPerformanceAnalysis(ExamResults results) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  '성과 분석',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getDetailedAnalysis(results),
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakAreas(ExamResults results) {
    if (results.weakAreas.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.emoji_events, color: AppColors.successColor, size: 48),
              const SizedBox(height: 16),
              const Text(
                '훌륭한 성과! 🎉',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '특별히 약한 영역이 없습니다. 계속 잘하고 있어요!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_down, color: AppColors.errorColor),
                const SizedBox(width: 8),
                const Text(
                  '개선이 필요한 영역',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...results.weakAreas.map((area) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWeakAreaItem(area),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakAreaItem(WeakArea area) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                area.topic,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.errorColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${area.errorCount}개 오답',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            area.recommendation,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyRecommendations(ExamResults results) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  '학습 계획',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._getStudyRecommendations(results)
                .map((recommendation) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              recommendation,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )),
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
              onPressed: () => context.pop(),
              icon: const Icon(Icons.home),
              label: const Text('홈으로'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1CB0F6), // Duolingo blue
                side: const BorderSide(color: Color(0xFF1CB0F6)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // More rounded
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
                backgroundColor: const Color(0xFF58CC02), // Duolingo green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // More rounded
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
                foregroundColor: const Color(0xFFFF9600), // Duolingo orange
                side: const BorderSide(color: Color(0xFFFF9600)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // More rounded
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

  String _getDetailedAnalysis(ExamResults results) {
    final percentage = results.percentage;
    final strongCategories = results.categoryScores
        .where((cat) => (cat.correct / cat.total) >= 0.8)
        .map((cat) => cat.category)
        .toList();

    final weakCategories = results.categoryScores
        .where((cat) => (cat.correct / cat.total) < 0.6)
        .map((cat) => cat.category)
        .toList();

    String analysis = '';

    if (percentage >= 80) {
      analysis +=
          'Excellent performance! You demonstrate strong understanding of TOEIC Part 5 concepts. ';
    } else if (percentage >= 70) {
      analysis +=
          'Good performance overall. With focused practice, you can achieve even better results. ';
    } else if (percentage >= 60) {
      analysis +=
          'You\'re on the right track, but there\'s room for improvement. Focus on fundamental concepts. ';
    } else {
      analysis +=
          'Consider reviewing basic grammar and vocabulary concepts before attempting more practice tests. ';
    }

    if (strongCategories.isNotEmpty) {
      analysis += 'Your strengths include: ${strongCategories.join(', ')}. ';
    }

    if (weakCategories.isNotEmpty) {
      analysis += 'Focus on improving: ${weakCategories.join(', ')}. ';
    }

    return analysis;
  }

  List<String> _getStudyRecommendations(ExamResults results) {
    final recommendations = <String>[];
    final percentage = results.percentage;

    if (percentage < 60) {
      recommendations
          .add('Review basic grammar fundamentals daily for 30 minutes');
      recommendations.add(
          'Start with easier practice questions before attempting full exams');
      recommendations.add(
          'Focus on understanding question patterns and common mistake types');
    } else if (percentage < 80) {
      recommendations
          .add('Practice specific weak areas identified in the analysis');
      recommendations
          .add('Review explanations for incorrect answers carefully');
      recommendations.add('Take regular practice tests to build confidence');
    } else {
      recommendations
          .add('Continue regular practice to maintain your high performance');
      recommendations.add('Focus on time management during practice sessions');
      recommendations
          .add('Challenge yourself with more difficult question sets');
    }

    if (results.weakAreas.isNotEmpty) {
      recommendations.add(
          'Dedicate extra study time to: ${results.weakAreas.take(2).map((e) => e.topic).join(', ')}');
    }

    recommendations
        .add('Review your mistakes regularly using the Wrong Answers section');

    return recommendations;
  }
}

// Data classes for exam results
class ExamResults {
  final int totalQuestions;
  final int correctAnswers;
  final int percentage;
  final Duration duration;
  final List<QuestionResult> questionResults;
  final List<CategoryScore> categoryScores;
  final List<WeakArea> weakAreas;

  ExamResults({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.percentage,
    required this.duration,
    required this.questionResults,
    required this.categoryScores,
    required this.weakAreas,
  });
}

class QuestionResult {
  final int questionNumber;
  final SimpleQuestion question;
  final int userAnswerIndex;
  final bool isCorrect;
  final String category;
  final List<String> tags;

  QuestionResult({
    required this.questionNumber,
    required this.question,
    required this.userAnswerIndex,
    required this.isCorrect,
    required this.category,
    required this.tags,
  });
}

class CategoryScore {
  final String category;
  final int correct;
  final int total;

  CategoryScore({
    required this.category,
    required this.correct,
    required this.total,
  });

  CategoryScore copyWith({
    String? category,
    int? correct,
    int? total,
  }) {
    return CategoryScore(
      category: category ?? this.category,
      correct: correct ?? this.correct,
      total: total ?? this.total,
    );
  }
}

class WeakArea {
  final String topic;
  final int errorCount;
  final String recommendation;

  WeakArea({
    required this.topic,
    required this.errorCount,
    required this.recommendation,
  });
}
