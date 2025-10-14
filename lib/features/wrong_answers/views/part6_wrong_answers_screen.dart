import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/features/part6/views/part6_retake_question_screen.dart';

class Part6WrongAnswersScreen extends ConsumerStatefulWidget {
  const Part6WrongAnswersScreen({super.key});

  @override
  ConsumerState<Part6WrongAnswersScreen> createState() => _Part6WrongAnswersScreenState();
}

class _Part6WrongAnswersScreenState extends ConsumerState<Part6WrongAnswersScreen> {
  Map<String, List<SimpleQuestion>> _passageQuestionsMap = {};
  bool _isLoadingQuestions = false;

  @override
  Widget build(BuildContext context) {
    final wrongAnswersAsync = ref.watch(wrongAnswersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Part 6 오답노트'),
        centerTitle: true,
        backgroundColor: const Color(0xFF42A5F5),
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
          // Filter Part 6 wrong answers
          final part6WrongAnswers = wrongAnswers.where((wa) {
            return wa.questionId.startsWith('Part6_');
          }).toList();

          if (part6WrongAnswers.isEmpty) {
            return _buildEmptyState(context);
          }

          // Load all questions for passages with wrong answers
          _loadPassageQuestions(part6WrongAnswers);

          if (_isLoadingQuestions) {
            return const Center(child: CircularProgressIndicator());
          }

          // Group by passage text after questions are loaded
          final passageGroups = _groupWrongAnswersByPassage(part6WrongAnswers);

          if (passageGroups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      '틀린 문제의 지문을 불러올 수 없습니다',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: passageGroups.length,
            itemBuilder: (context, index) {
              final passageEntry = passageGroups.entries.toList()[index];
              final passageText = passageEntry.key;
              final wrongAnswersInPassage = passageEntry.value;
              final allQuestions = _passageQuestionsMap[passageText] ?? [];

              return _buildPassageCard(
                context,
                passageText,
                allQuestions,
                wrongAnswersInPassage,
                index + 1,
              );
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
            'Part 6에 틀린 문제가 없습니다.\n계속 열심히 하세요!',
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

  Map<String, List<WrongAnswer>> _groupWrongAnswersByPassage(List<WrongAnswer> wrongAnswers) {
    final Map<String, List<WrongAnswer>> grouped = {};

    // For each wrong answer, find its question and group by passage text
    for (final wrongAnswer in wrongAnswers) {
      String? passageText;

      // Find the question in our loaded passage questions
      for (final entry in _passageQuestionsMap.entries) {
        final questions = entry.value;
        final matchingQuestion = questions.where((q) => q.id == wrongAnswer.questionId).firstOrNull;

        if (matchingQuestion != null) {
          passageText = matchingQuestion.passageText ?? 'Unknown';
          break;
        }
      }

      if (passageText != null) {
        grouped.putIfAbsent(passageText, () => []);
        grouped[passageText]!.add(wrongAnswer);
      } else {
        print('⚠️ Could not find passage for wrong answer: ${wrongAnswer.questionId}');
      }
    }

    print('📊 Grouped ${wrongAnswers.length} wrong answers into ${grouped.length} passages');
    for (final entry in grouped.entries) {
      print('  - Passage: ${entry.key.substring(0, 50)}... (${entry.value.length} wrong answers)');
    }

    return grouped;
  }

  Future<void> _loadPassageQuestions(List<WrongAnswer> part6WrongAnswers) async {
    if (_passageQuestionsMap.isNotEmpty || _isLoadingQuestions) return;

    setState(() {
      _isLoadingQuestions = true;
    });

    try {
      // Extract unique dates from wrong answer IDs
      final Set<String> dates = {};
      for (final wa in part6WrongAnswers) {
        // Extract date from ID format: Part6_PRAC_2025_10_13_Q131 or Part6_EXAM_ROUND_1_Q1
        final parts = wa.questionId.split('_');
        if (parts[1] == 'PRAC' && parts.length >= 5) {
          final date = '${parts[2]}-${parts[3]}-${parts[4]}';
          dates.add(date);
        }
      }

      final questionRepository = ref.read(questionRepositoryProvider);
      final Map<String, List<SimpleQuestion>> passageMap = {};

      // Load questions for each date
      for (final date in dates) {
        final questions = await questionRepository.getPart6PracticeQuestionsByDate(date);

        // Group by passage text
        for (final question in questions) {
          final passageText = question.passageText ?? 'Unknown';
          passageMap.putIfAbsent(passageText, () => []);
          passageMap[passageText]!.add(question);
        }
      }

      // Sort questions in each passage by question number
      for (final passage in passageMap.values) {
        passage.sort((a, b) {
          final aNum = _extractQuestionNumber(a.id);
          final bNum = _extractQuestionNumber(b.id);
          return aNum.compareTo(bNum);
        });
      }

      if (mounted) {
        setState(() {
          _passageQuestionsMap = passageMap;
          _isLoadingQuestions = false;
        });
      }
    } catch (e) {
      print('❌ Error loading passage questions: $e');
      if (mounted) {
        setState(() {
          _isLoadingQuestions = false;
        });
      }
    }
  }

  int _extractQuestionNumber(String questionId) {
    try {
      final parts = questionId.split('_');
      for (final part in parts) {
        if (part.startsWith('Q') && part.length > 1) {
          return int.tryParse(part.substring(1)) ?? 0;
        }
      }
    } catch (e) {
      print('Error extracting question number from $questionId: $e');
    }
    return 0;
  }

  Widget _buildPassageCard(
    BuildContext context,
    String passageText,
    List<SimpleQuestion> allQuestions,
    List<WrongAnswer> wrongAnswersInPassage,
    int passageNumber,
  ) {
    if (allQuestions.isEmpty) return const SizedBox.shrink();

    final wrongQuestionIds = wrongAnswersInPassage.map((wa) => wa.questionId).toSet();
    final passage = allQuestions.first.passageText ?? 'No passage available';
    final passageTextKorean = allQuestions.first.passageTextKorean;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF42A5F5).withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF42A5F5).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Passage $passageNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${wrongAnswersInPassage.length}개 틀린 문제 • 총 ${allQuestions.length}문제',
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Passage Text
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
                        passage,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),

                      // Korean Translation
                      if (passageTextKorean != null && passageTextKorean.isNotEmpty) ...[
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
                          passageTextKorean,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Only Wrong Questions
                ...allQuestions.where((q) => wrongQuestionIds.contains(q.id)).map((question) {
                  final wrongAnswer = wrongAnswersInPassage.firstWhere((wa) => wa.questionId == question.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildQuestionCard(
                      context,
                      question,
                      wrongAnswer,
                      allQuestions,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    SimpleQuestion question,
    WrongAnswer wrongAnswer,
    List<SimpleQuestion> allQuestions,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.errorColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.errorColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q${_extractQuestionNumber(question.id)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '틀린 문제',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.errorColor,
                  ),
                ),
              ),
              // Re-take icon button
              IconButton(
                icon: const Icon(Icons.refresh),
                color: const Color(0xFF42A5F5),
                iconSize: 24,
                tooltip: 'Re-take Question',
                onPressed: () => _openReviewScreen(context, question, allQuestions),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.cancel,
                color: AppColors.errorColor,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Question Text
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // Options
          ...question.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final optionText = entry.value;
            final isSelected = wrongAnswer.selectedAnswerIndex == optionIndex;
            final isCorrectOption = optionIndex == question.correctAnswerIndex;

            Color optionBorderColor;
            Color optionBgColor;
            IconData? optionIcon;

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

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: optionBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: optionBorderColor,
                  width: (isSelected || isCorrectOption) ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: (isSelected || isCorrectOption)
                          ? optionBorderColor
                          : Colors.white,
                      border: Border.all(color: optionBorderColor),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + optionIndex),
                        style: TextStyle(
                          color: (isSelected || isCorrectOption)
                              ? Colors.white
                              : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      optionText,
                      style: TextStyle(
                        fontSize: 13,
                        color: isCorrectOption
                            ? AppColors.successColor
                            : (isSelected ? AppColors.errorColor : Colors.black87),
                        fontWeight: (isSelected || isCorrectOption)
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (optionIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      optionIcon,
                      color: optionBorderColor,
                      size: 18,
                    ),
                  ],
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 12),

          // Explanation
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
                    const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF42A5F5)),
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
                  question.explanation,
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
      ),
    );
  }

  void _openReviewScreen(
    BuildContext context,
    SimpleQuestion question,
    List<SimpleQuestion> allQuestions,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Part6RetakeQuestionScreen(
          question: question,
          allQuestionsInPassage: allQuestions,
        ),
      ),
    );
  }
}
