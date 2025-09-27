import 'package:flutter/material.dart';
import 'package:egg_toeic/data/models/question_analytics_model.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/constants/app_dimensions.dart';

class QuestionAnalyticsWidget extends StatelessWidget {
  final QuestionAnalytics? analytics;
  final bool isCompact;
  final VoidCallback? onTap;

  const QuestionAnalyticsWidget({
    super.key,
    this.analytics,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (analytics == null) {
      return _buildNoDataWidget(context);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isCompact ? _buildCompactView(context) : _buildDetailedView(context),
      ),
    );
  }

  Widget _buildNoDataWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'No data yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(BuildContext context) {
    return Row(
      children: [
        // Success rate circle
        _buildSuccessRateCircle(context, size: 30),
        const SizedBox(width: 12),

        // Basic stats
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${analytics!.correctPercentage}% correct',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${analytics!.totalAttempts} attempts',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Difficulty indicator
        _buildDifficultyChip(),
      ],
    );
  }

  Widget _buildDetailedView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.analytics,
              color: AppColors.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Question Analytics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            _buildDifficultyChip(),
          ],
        ),

        const SizedBox(height: 16),

        // Main statistics
        Row(
          children: [
            // Success rate
            Expanded(
              child: Column(
                children: [
                  _buildSuccessRateCircle(context, size: 60),
                  const SizedBox(height: 8),
                  Text(
                    '${analytics!.correctPercentage}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Success Rate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Attempts
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.infoColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.people,
                        color: AppColors.infoColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${analytics!.totalAttempts}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Attempts',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Average time
            if (analytics!.averageTimeSeconds != null)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.warningColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.timer,
                          color: AppColors.warningColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${analytics!.averageTimeSeconds}s',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Avg. Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Answer distribution
        _buildAnswerDistribution(context),

        const SizedBox(height: 12),

        // Grammar point and mode info
        Row(
          children: [
            Expanded(
              child: _buildInfoChip(
                'Grammar: ${analytics!.grammarPoint}',
                AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              analytics!.questionMode.toUpperCase(),
              analytics!.questionMode == 'exam'
                ? AppColors.errorColor
                : AppColors.successColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessRateCircle(BuildContext context, {required double size}) {
    final successRate = analytics!.correctPercentage / 100;
    Color color;

    if (successRate >= 0.8) {
      color = AppColors.successColor;
    } else if (successRate >= 0.6) {
      color = AppColors.warningColor;
    } else {
      color = AppColors.errorColor;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: successRate,
            strokeWidth: size / 10,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        if (size > 40)
          Text(
            '${analytics!.correctPercentage.toInt()}%',
            style: TextStyle(
              fontSize: size / 5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
      ],
    );
  }

  Widget _buildDifficultyChip() {
    Color color;
    switch (analytics!.difficultyLevel) {
      case 1:
        color = AppColors.successColor;
        break;
      case 2:
        color = AppColors.warningColor;
        break;
      case 3:
        color = AppColors.errorColor;
        break;
      default:
        color = AppColors.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        'Level ${analytics!.difficultyLevel}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAnswerDistribution(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Answer Distribution',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),

        // Answer bars
        for (int i = 0; i < 4; i++)
          _buildAnswerBar(i),
      ],
    );
  }

  Widget _buildAnswerBar(int answerIndex) {
    final percentage = analytics!.answerPercentages[answerIndex.toString()] ?? 0.0;
    final count = analytics!.answerDistribution[answerIndex.toString()] ?? 0;
    final isCorrect = answerIndex == (analytics!.metadata?['correctAnswerIndex'] as int? ?? 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              String.fromCharCode(65 + answerIndex), // A, B, C, D
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCorrect ? AppColors.successColor : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isCorrect ? AppColors.successColor : AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '${percentage.toStringAsFixed(1)}% ($count)',
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}