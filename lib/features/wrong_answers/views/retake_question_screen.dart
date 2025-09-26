import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/constants/app_dimensions.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/providers/repository_providers.dart';

class RetakeQuestionScreen extends ConsumerStatefulWidget {
  final WrongAnswer wrongAnswer;

  const RetakeQuestionScreen({super.key, required this.wrongAnswer});

  @override
  ConsumerState<RetakeQuestionScreen> createState() => _RetakeQuestionScreenState();
}

class _RetakeQuestionScreenState extends ConsumerState<RetakeQuestionScreen> {
  int? _selectedAnswer;
  bool _showResult = false;

  @override
  Widget build(BuildContext context) {
    final wrongAnswer = widget.wrongAnswer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('문제 다시 풀기'),
        centerTitle: true,
      ),
      body: wrongAnswer.questionText != null && wrongAnswer.options != null
          ? _buildQuestionContent(wrongAnswer)
          : _buildLoadingContent(wrongAnswer),
      bottomNavigationBar: _buildBottomBar(wrongAnswer),
    );
  }

  Widget _buildQuestionContent(WrongAnswer wrongAnswer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.refresh, color: AppColors.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '복습 문제',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (wrongAnswer.difficultyLevel != null)
                  Text(
                    'Level ${wrongAnswer.difficultyLevel}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.paddingLarge),

          // Question text
          Text(
            wrongAnswer.questionText!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppDimensions.paddingLarge),

          // Answer options
          ...wrongAnswer.options!.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedAnswer == index;
            final isCorrect = index == wrongAnswer.correctAnswerIndex;
            final wasOriginallySelected = index == wrongAnswer.selectedAnswerIndex;

            Color backgroundColor = AppColors.backgroundLight;
            Color borderColor = AppColors.borderColor;

            if (_showResult) {
              if (isCorrect) {
                backgroundColor = AppColors.successColor.withOpacity(0.1);
                borderColor = AppColors.successColor;
              } else if (isSelected) {
                backgroundColor = AppColors.errorColor.withOpacity(0.1);
                borderColor = AppColors.errorColor;
              } else if (wasOriginallySelected) {
                backgroundColor = Colors.grey.withOpacity(0.1);
                borderColor = Colors.grey;
              }
            } else if (isSelected) {
              backgroundColor = AppColors.primaryColor.withOpacity(0.1);
              borderColor = AppColors.primaryColor;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
              child: InkWell(
                onTap: _showResult ? null : () => setState(() => _selectedAnswer = index),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(color: borderColor, width: 2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _showResult && isCorrect
                              ? AppColors.successColor
                              : _showResult && (isSelected && !isCorrect)
                                  ? AppColors.errorColor
                                  : isSelected && !_showResult
                                      ? AppColors.primaryColor
                                      : Colors.transparent,
                          border: Border.all(color: borderColor),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: TextStyle(
                              color: _showResult && (isCorrect || (isSelected && !isCorrect))
                                  ? Colors.white
                                  : isSelected && !_showResult
                                      ? Colors.white
                                      : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingMedium),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_showResult) ...[
                        if (isCorrect)
                          Icon(Icons.check_circle, color: AppColors.successColor, size: 20)
                        else if (isSelected)
                          Icon(Icons.cancel, color: AppColors.errorColor, size: 20)
                        else if (wasOriginallySelected)
                          Icon(Icons.history, color: Colors.grey, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),

          // Result explanation
          if (_showResult && wrongAnswer.explanation != null) ...[
            const SizedBox(height: AppDimensions.paddingLarge),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.infoColor.withOpacity(0.1),
                border: Border.all(color: AppColors.infoColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppColors.infoColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Explanation',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.infoColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wrongAnswer.explanation!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],

          // Result summary
          if (_showResult) ...[
            const SizedBox(height: AppDimensions.paddingLarge),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: _selectedAnswer == wrongAnswer.correctAnswerIndex
                    ? AppColors.successColor.withOpacity(0.1)
                    : AppColors.warningColor.withOpacity(0.1),
                border: Border.all(
                  color: _selectedAnswer == wrongAnswer.correctAnswerIndex
                      ? AppColors.successColor
                      : AppColors.warningColor,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedAnswer == wrongAnswer.correctAnswerIndex
                        ? Icons.check_circle
                        : Icons.info,
                    color: _selectedAnswer == wrongAnswer.correctAnswerIndex
                        ? AppColors.successColor
                        : AppColors.warningColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedAnswer == wrongAnswer.correctAnswerIndex
                        ? '정답입니다! 🎉'
                        : '이번에도 틀렸습니다',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _selectedAnswer == wrongAnswer.correctAnswerIndex
                          ? AppColors.successColor
                          : AppColors.warningColor,
                    ),
                  ),
                  if (_selectedAnswer != wrongAnswer.correctAnswerIndex) ...[
                    const SizedBox(height: 4),
                    Text(
                      '다시 한번 복습해보세요',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingContent(WrongAnswer wrongAnswer) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '문제를 불러오는 중...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(WrongAnswer wrongAnswer) {
    if (_showResult) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
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
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
            ),
            child: const Text(
              '완료',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
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
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _selectedAnswer != null ? _checkAnswer : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedAnswer != null
                ? AppColors.primaryColor
                : AppColors.borderColor,
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
          ),
          child: Text(
            '정답 확인',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _selectedAnswer != null ? Colors.white : AppColors.textHint,
            ),
          ),
        ),
      ),
    );
  }

  void _checkAnswer() async {
    if (_selectedAnswer == null) return;

    setState(() {
      _showResult = true;
    });

    // Update user progress
    final isCorrect = _selectedAnswer == widget.wrongAnswer.correctAnswerIndex;

    if (isCorrect) {
      // Mark as resolved if answered correctly
      await ref
          .read(userDataRepositoryProvider)
          .markWrongAnswerAsResolved(widget.wrongAnswer.id);
    }

    // Add experience and update stats
    final repository = ref.read(userDataRepositoryProvider);

    // Add experience points
    if (isCorrect) {
      await repository.addExperience(10); // 10 XP for correct answer
    }

    // Update question stats
    await repository.incrementTotalQuestions(isCorrect: isCorrect);

    // Update daily streak
    await repository.incrementStreak();
  }
}