import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/providers/repository_providers.dart';

class Part6RetakeQuestionScreen extends ConsumerStatefulWidget {
  final SimpleQuestion question;
  final List<SimpleQuestion> allQuestionsInPassage;

  const Part6RetakeQuestionScreen({
    super.key,
    required this.question,
    required this.allQuestionsInPassage,
  });

  @override
  ConsumerState<Part6RetakeQuestionScreen> createState() =>
      _Part6RetakeQuestionScreenState();
}

class _Part6RetakeQuestionScreenState
    extends ConsumerState<Part6RetakeQuestionScreen> {
  int? _selectedAnswer;
  bool _showResult = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Re-take Question',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Badge (only before answering)
            if (!_showResult)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF42A5F5).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.refresh,
                      color: Color(0xFF42A5F5),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Try to answer correctly this time!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Passage Text (without Korean translation initially)
            if (widget.question.passageText != null &&
                widget.question.passageText!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.article,
                            size: 18, color: Color(0xFF42A5F5)),
                        const SizedBox(width: 8),
                        const Text(
                          'Reading Passage',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF42A5F5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.question.passageText!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Colors.black87,
                      ),
                    ),

                    // Show Korean Translation only after answering
                    if (_showResult &&
                        widget.question.passageTextKorean != null &&
                        widget.question.passageTextKorean!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.translate,
                              size: 16, color: Color(0xFF42A5F5)),
                          const SizedBox(width: 8),
                          const Text(
                            '지문 번역',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF42A5F5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.question.passageTextKorean!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Question Number
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Question ${_extractQuestionNumber(widget.question.id)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Question Text
            Text(
              widget.question.questionText,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // Options
            ...widget.question.options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final optionText = entry.value;
              final isSelected = _selectedAnswer == optionIndex;
              final isCorrectOption =
                  optionIndex == widget.question.correctAnswerIndex;

              Color optionBorderColor;
              Color optionBgColor;
              IconData? optionIcon;

              if (_showResult) {
                // After answering, show correct/incorrect
                if (isCorrectOption) {
                  optionBorderColor = AppColors.successColor;
                  optionBgColor = AppColors.successColor.withOpacity(0.1);
                  optionIcon = Icons.check_circle;
                } else if (isSelected) {
                  optionBorderColor = AppColors.errorColor;
                  optionBgColor = AppColors.errorColor.withOpacity(0.1);
                  optionIcon = Icons.cancel;
                } else {
                  optionBorderColor = Colors.grey[300]!;
                  optionBgColor = Colors.grey[50]!;
                }
              } else {
                // Before answering, show selected state
                if (isSelected) {
                  optionBorderColor = const Color(0xFF42A5F5);
                  optionBgColor = const Color(0xFF42A5F5).withOpacity(0.1);
                } else {
                  optionBorderColor = Colors.grey[300]!;
                  optionBgColor = Colors.grey[50]!;
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: _showResult
                      ? null
                      : () => setState(() => _selectedAnswer = optionIndex),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: optionBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: optionBorderColor,
                        width: (isSelected || (_showResult && isCorrectOption))
                            ? 2.5
                            : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: (_showResult && isCorrectOption)
                                ? optionBorderColor
                                : (_showResult && isSelected)
                                    ? optionBorderColor
                                    : isSelected && !_showResult
                                        ? optionBorderColor
                                        : Colors.white,
                            border: Border.all(color: optionBorderColor),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + optionIndex),
                              style: TextStyle(
                                color: (_showResult &&
                                        (isCorrectOption || isSelected))
                                    ? Colors.white
                                    : isSelected && !_showResult
                                        ? Colors.white
                                        : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontSize: 15,
                              color: _showResult && isCorrectOption
                                  ? AppColors.successColor
                                  : _showResult && isSelected
                                      ? AppColors.errorColor
                                      : Colors.black87,
                              fontWeight: (isSelected || (_showResult && isCorrectOption))
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (optionIcon != null) ...[
                          const SizedBox(width: 10),
                          Icon(
                            optionIcon,
                            color: optionBorderColor,
                            size: 22,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),

            // Result Summary (only after answering)
            if (_showResult) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _selectedAnswer == widget.question.correctAnswerIndex
                      ? AppColors.successColor.withOpacity(0.1)
                      : AppColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedAnswer == widget.question.correctAnswerIndex
                        ? AppColors.successColor
                        : AppColors.errorColor,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedAnswer == widget.question.correctAnswerIndex
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: _selectedAnswer == widget.question.correctAnswerIndex
                          ? AppColors.successColor
                          : AppColors.errorColor,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedAnswer == widget.question.correctAnswerIndex
                          ? 'Correct! 🎉'
                          : 'Incorrect',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _selectedAnswer == widget.question.correctAnswerIndex
                            ? AppColors.successColor
                            : AppColors.errorColor,
                      ),
                    ),
                    if (_selectedAnswer != widget.question.correctAnswerIndex) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Review the explanation below',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Explanation (only after answering)
            if (_showResult && widget.question.explanation.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF42A5F5).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: Color(0xFF42A5F5),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Explanation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF42A5F5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.question.explanation,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: _showResult
            ? ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: _selectedAnswer != null ? _checkAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedAnswer != null
                      ? const Color(0xFF42A5F5)
                      : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Check Answer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        _selectedAnswer != null ? Colors.white : Colors.grey[600],
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
    final isCorrect = _selectedAnswer == widget.question.correctAnswerIndex;
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

  String _extractQuestionNumber(String questionId) {
    try {
      final parts = questionId.split('_');
      for (final part in parts) {
        if (part.startsWith('Q') && part.length > 1) {
          return part.substring(1);
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return '?';
  }
}
