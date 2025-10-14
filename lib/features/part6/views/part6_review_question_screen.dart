import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/data/models/simple_models.dart';

class Part6ReviewQuestionScreen extends ConsumerWidget {
  final SimpleQuestion question;
  final List<SimpleQuestion> allQuestionsInPassage;

  const Part6ReviewQuestionScreen({
    super.key,
    required this.question,
    required this.allQuestionsInPassage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Question Review',
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
            // Info Badge
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
                    Icons.visibility,
                    color: Color(0xFF42A5F5),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Correct answer is revealed for review',
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

            // Passage Text
            if (question.passageText != null && question.passageText!.isNotEmpty) ...[
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
                        const Icon(Icons.article, size: 18, color: Color(0xFF42A5F5)),
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
                      question.passageText!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Colors.black87,
                      ),
                    ),

                    // Korean Translation
                    if (question.passageTextKorean != null &&
                        question.passageTextKorean!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.translate, size: 16, color: Color(0xFF42A5F5)),
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
                        question.passageTextKorean!,
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
                'Question ${_extractQuestionNumber(question.id)}',
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
              question.questionText,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // Options with correct answer highlighted
            ...question.options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final optionText = entry.value;
              final isCorrectOption = optionIndex == question.correctAnswerIndex;

              Color optionBorderColor;
              Color optionBgColor;
              IconData? optionIcon;

              if (isCorrectOption) {
                optionBorderColor = AppColors.successColor;
                optionBgColor = AppColors.successColor.withOpacity(0.1);
                optionIcon = Icons.check_circle;
              } else {
                optionBorderColor = Colors.grey[300]!;
                optionBgColor = Colors.grey[50]!;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: optionBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: optionBorderColor,
                    width: isCorrectOption ? 2.5 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCorrectOption
                            ? optionBorderColor
                            : Colors.white,
                        border: Border.all(color: optionBorderColor),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + optionIndex),
                          style: TextStyle(
                            color: isCorrectOption
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
                          color: isCorrectOption
                              ? AppColors.successColor
                              : Colors.black87,
                          fontWeight: isCorrectOption
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
              );
            }).toList(),

            const SizedBox(height: 20),

            // Explanation
            if (question.explanation.isNotEmpty) ...[
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
                      question.explanation,
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

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
              ),
            ),
          ],
        ),
      ),
    );
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
