import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:egg_toeic/data/models/learning_session_model.dart';

class ExamResultSummaryScreen extends ConsumerStatefulWidget {
  final String round;
  final LearningSession session;

  const ExamResultSummaryScreen({
    super.key,
    required this.round,
    required this.session,
  });

  @override
  ConsumerState<ExamResultSummaryScreen> createState() =>
      _ExamResultSummaryScreenState();
}

class _ExamResultSummaryScreenState
    extends ConsumerState<ExamResultSummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _roundDisplayName =>
      widget.round.replaceAll('ROUND_', 'Round ');

  double get _accuracy =>
      widget.session.questionsAnswered > 0
          ? widget.session.correctAnswers / widget.session.questionsAnswered
          : 0.0;

  String get _grade {
    if (_accuracy >= 0.9) return 'A+';
    if (_accuracy >= 0.8) return 'A';
    if (_accuracy >= 0.7) return 'B+';
    if (_accuracy >= 0.6) return 'B';
    if (_accuracy >= 0.5) return 'C+';
    if (_accuracy >= 0.4) return 'C';
    return 'D';
  }

  Color get _gradeColor {
    if (_accuracy >= 0.8) return const Color(0xFF4CAF50); // Green
    if (_accuracy >= 0.6) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  Duration get _examDuration {
    if (widget.session.endTime != null) {
      return widget.session.endTime!.difference(widget.session.startTime);
    }
    return Duration.zero;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}분 ${seconds}초';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('$_roundDisplayName 결과'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildContent(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Grade Circle
          _buildGradeCircle(),

          const SizedBox(height: 32),

          // Score Cards
          _buildScoreCards(),

          const SizedBox(height: 32),

          // Additional Info
          _buildAdditionalInfo(),

          const SizedBox(height: 32),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildGradeCircle() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _gradeColor.withOpacity(0.1),
            _gradeColor.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: _gradeColor,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: _gradeColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _grade,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: _gradeColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_accuracy * 100).toInt()}%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: _gradeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCards() {
    return Row(
      children: [
        Expanded(
          child: _buildScoreCard(
            title: '정답',
            value: '${widget.session.correctAnswers}',
            subtitle: '/${widget.session.questionsAnswered}',
            icon: Icons.check_circle,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildScoreCard(
            title: '오답',
            value: '${widget.session.questionsAnswered - widget.session.correctAnswers}',
            subtitle: '/${widget.session.questionsAnswered}',
            icon: Icons.cancel,
            color: const Color(0xFFF44336),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '시험 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('시험 라운드', _roundDisplayName),
          _buildInfoRow('소요 시간', _formatDuration(_examDuration)),
          _buildInfoRow('시험 날짜', _formatDate(widget.session.startTime)),
          _buildInfoRow('점수', '${widget.session.correctAnswers}/${widget.session.questionsAnswered}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // 다시풀기 Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate back to level selection and immediately start exam
              context.go('/part5/exam/${widget.round}');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시풀기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 홈으로 Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.go('/part5');
            },
            icon: const Icon(Icons.home),
            label: const Text('홈으로'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}