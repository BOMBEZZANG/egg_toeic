import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/features/wrong_answers/views/part2_retake_question_screen.dart';

// Provider to fetch Part2 question details
final part2QuestionProvider = FutureProvider.family<SimpleQuestion?, String>((ref, questionId) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore
        .collection('part2examQuestions')
        .doc(questionId)
        .get();

    if (!doc.exists || doc.data() == null) return null;

    return SimpleQuestion.fromFirestore(doc.data()!, questionId);
  } catch (e) {
    print('Error fetching Part2 question: $e');
    return null;
  }
});

class Part2WrongAnswersScreen extends ConsumerWidget {
  const Part2WrongAnswersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wrongAnswersAsync = ref.watch(wrongAnswersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Part 2 오답노트'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6F00), // Orange for Part 2
        foregroundColor: Colors.white,
      ),
      body: wrongAnswersAsync.when(
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
                'Error loading wrong answers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        data: (wrongAnswers) {
          // Filter Part 2 wrong answers
          final part2WrongAnswers = wrongAnswers.where((wa) {
            return wa.questionId.startsWith('Part2_');
          }).toList();

          if (part2WrongAnswers.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: part2WrongAnswers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final wrongAnswer = part2WrongAnswers[index];
              return _buildWrongAnswerCard(context, ref, wrongAnswer, index + 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.successColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.successColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '완벽해요! 🎉',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.successColor,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Part 2에 틀린 문제가 없습니다.\n계속 열심히 하세요!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWrongAnswerCard(
    BuildContext context,
    WidgetRef ref,
    WrongAnswer wrongAnswer,
    int number,
  ) {
    final questionAsync = ref.watch(part2QuestionProvider(wrongAnswer.questionId));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFFF6F00).withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to retake screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Part2RetakeQuestionScreen(
                wrongAnswer: wrongAnswer,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6F00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.headphones,
                      color: Color(0xFFFF6F00),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question $number',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Question-Response',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        color: const Color(0xFFFF6F00),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Part2RetakeQuestionScreen(
                                wrongAnswer: wrongAnswer,
                              ),
                            ),
                          );
                        },
                        tooltip: '다시 풀기',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: AppColors.errorColor,
                        onPressed: () {
                          _showDeleteConfirmation(context, ref, wrongAnswer);
                        },
                        tooltip: '삭제',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Question details
              questionAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
                    ),
                  ),
                ),
                error: (error, stack) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '문제 정보를 불러올 수 없습니다',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                data: (question) {
                  if (question == null) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '문제 정보를 찾을 수 없습니다',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Text
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6F00).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFF6F00).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.record_voice_over,
                                  size: 16,
                                  color: const Color(0xFFFF6F00),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Question',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF6F00),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.questionText,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Responses
                      ...List.generate(3, (index) {
                        final letter = String.fromCharCode(65 + index);
                        final isCorrect = index == wrongAnswer.correctAnswerIndex;
                        final isSelected = index == wrongAnswer.selectedAnswerIndex;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? AppColors.successColor.withOpacity(0.05)
                                  : isSelected
                                      ? AppColors.errorColor.withOpacity(0.05)
                                      : Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCorrect
                                    ? AppColors.successColor
                                    : isSelected
                                        ? AppColors.errorColor
                                        : Colors.grey[300]!,
                                width: isCorrect || isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isCorrect
                                        ? AppColors.successColor
                                        : isSelected
                                            ? AppColors.errorColor
                                            : Colors.grey[400],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      letter,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    question.options[index],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[800],
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                if (isCorrect)
                                  Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: AppColors.successColor,
                                  ),
                                if (isSelected && !isCorrect)
                                  Icon(
                                    Icons.cancel,
                                    size: 18,
                                    color: AppColors.errorColor,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 12),

                      // Explanation
                      if (question.explanation.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.infoColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.infoColor.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 16,
                                    color: AppColors.infoColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '해설',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.infoColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                question.explanation,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // Tap to retake hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '카드를 탭하면 다시 풀기',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    WrongAnswer wrongAnswer,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문제 삭제'),
        content: const Text('이 문제를 오답노트에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(userDataRepositoryProvider)
                  .removeWrongAnswer(wrongAnswer.id);
              ref.invalidate(wrongAnswersProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('오답노트에서 삭제되었습니다.'),
                    backgroundColor: AppColors.errorColor,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
