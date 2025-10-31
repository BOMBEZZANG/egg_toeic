import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/data/models/simple_models.dart';

class Part2ExamRoundSelectionScreen extends ConsumerStatefulWidget {
  const Part2ExamRoundSelectionScreen({super.key});

  @override
  ConsumerState<Part2ExamRoundSelectionScreen> createState() =>
      _Part2ExamRoundSelectionScreenState();
}

class _Part2ExamRoundSelectionScreenState
    extends ConsumerState<Part2ExamRoundSelectionScreen> {

  // Get completed rounds from UserDataRepository by checking ExamResults
  Future<Set<String>> _getCompletedRounds() async {
    try {
      final userDataRepo = ref.read(userDataRepositoryProvider);

      // Get all exam results
      final allExamResults = await userDataRepo.getAllExamResults();

      // Filter for Part 2 exam results (partNumber == 2)
      final part2Results = allExamResults.where((result) => result.partNumber == 2).toList();

      final completedRounds = <String>{};

      for (final result in part2Results) {
        completedRounds.add(result.examRound);
      }

      return completedRounds;
    } catch (e) {
      print('❌ [Part2] Error getting completed rounds: $e');
      return <String>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableRoundsAsync = ref.watch(availablePart2ExamRoundsProvider);

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          ref.invalidate(userProgressProvider);
          ref.invalidate(examResultsProvider);
          ref.invalidate(combinedStatisticsProvider);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Round Selection',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          centerTitle: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFE0B2), // Light orange
                        Color(0xFFFFCC80), // Medium orange
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.headphones_rounded,
                          color: Color(0xFFFF6F00), // Vibrant orange
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          '각 라운드를 선택해서\nPart 2 듣기 시험에 도전해보세요!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFE65100), // Dark orange for text
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Rounds grid
                Expanded(
                  child: availableRoundsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)), // Orange
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '라운드 로딩 오류',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$error',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    data: (availableRounds) {
                      if (availableRounds.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.headphones_outlined,
                                size: 60,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '사용 가능한 라운드가 없습니다',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return FutureBuilder<Set<String>>(
                        future: _getCompletedRounds(),
                        builder: (context, completedSnapshot) {
                          final completedRounds = completedSnapshot.data ?? <String>{};

                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.9,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: availableRounds.length,
                            itemBuilder: (context, index) {
                              final round = availableRounds[index];
                              final roundNumber = round.replaceAll('ROUND_', '');
                              final isCompleted = completedRounds.contains(round);

                              return _buildModernRoundCard(
                                context,
                                roundNumber: roundNumber,
                                round: round,
                                index: index,
                                isCompleted: isCompleted,
                                onTap: () => isCompleted
                                    ? _showCompletedRoundModal(context, round, roundNumber)
                                    : context.push('/part2/exam/$round'),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernRoundCard(
    BuildContext context, {
    required String roundNumber,
    required String round,
    required int index,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    final colors = [
      const [Color(0xFFFF6F00), Color(0xFFFF8F00)], // Orange gradient 1
      const [Color(0xFFFF8F00), Color(0xFFFFA726)], // Orange gradient 2
      const [Color(0xFFFFA726), Color(0xFFFFB74D)], // Orange gradient 3
      const [Color(0xFFFF6F00), Color(0xFFFF8F00)], // Orange gradient 1
      const [Color(0xFFFF8F00), Color(0xFFFFA726)], // Orange gradient 2
      const [Color(0xFFFFA726), Color(0xFFFFB74D)], // Orange gradient 3
    ];

    // Use grey for completed rounds
    final gradientColors = isCompleted
        ? const [Color(0xFF9E9E9E), Color(0xFFBDBDBD)] // Grey gradient
        : colors[index % colors.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_rounded : Icons.headphones_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Title and Subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Round $roundNumber',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Part 2 Test',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '25 Questions',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Completion badge
              if (isCompleted)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981), // Green
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Show modal for completed rounds with retry and result options
  void _showCompletedRoundModal(BuildContext context, String round, String roundNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '라운드 $roundNumber 완료!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '이미 완료한 시험입니다',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // 결과보기 button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showExamResult(context, round);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '결과보기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 다시풀기 button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/part2/exam/$round');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '다시풀기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExamResult(BuildContext context, String round) async {
    try {
      final userDataRepo = ref.read(userDataRepositoryProvider);

      // Get detailed exam result for this round
      final examResult = await userDataRepo.getExamResult(round);

      if (examResult == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('결과 데이터를 찾을 수 없습니다')),
          );
        }
        return;
      }

      // Convert List<int> userAnswers to Map<int, int> for Part2ExamResultScreen
      final userAnswersMap = <int, int>{};
      for (int i = 0; i < examResult.userAnswers.length; i++) {
        if (examResult.userAnswers[i] != -1) {
          userAnswersMap[i] = examResult.userAnswers[i];
        }
      }

      if (context.mounted) {
        // Navigate to Part2 exam result screen
        context.push('/part2/exam-result', extra: {
          'examRound': examResult.examRound,
          'questions': examResult.questions,
          'userAnswers': userAnswersMap,
          'examStartTime': examResult.examStartTime,
          'examEndTime': examResult.examEndTime,
        });
      }
    } catch (e) {
      print('❌ [Part2] Error loading exam result: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결과를 불러오는 중 오류가 발생했습니다')),
        );
      }
    }
  }
}
