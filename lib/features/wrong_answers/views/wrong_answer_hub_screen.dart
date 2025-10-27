import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';

class WrongAnswerHubScreen extends ConsumerWidget {
  const WrongAnswerHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wrongAnswersAsync = ref.watch(wrongAnswersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Wrong Answer Hub',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // Solid matte light indigo background
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF5C6BC0).withOpacity(0.2),
                    width: 1,
                  ),
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
                        Icons.quiz,
                        color: Color(0xFF5C6BC0),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        '틀린 문제를 복습하고\n실력을 향상시키세요!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3949AB),
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Statistics Card
              wrongAnswersAsync.when(
                loading: () => _buildStatsCard(0, 0, 0),
                error: (error, stack) => _buildStatsCard(0, 0, 0),
                data: (wrongAnswers) {
                  final List<WrongAnswer> wrongAnswersList = wrongAnswers.toList();

                  final part2Count = wrongAnswersList.where((WrongAnswer wa) {
                    return wa.questionId.startsWith('Part2_');
                  }).length;

                  final part5Count = wrongAnswersList.where((WrongAnswer wa) {
                    return wa.questionId.startsWith('Part5_') ||
                           (!wa.questionId.startsWith('Part2_') && !wa.questionId.startsWith('Part6_'));
                  }).length;

                  final part6Count = wrongAnswersList.where((WrongAnswer wa) {
                    return wa.questionId.startsWith('Part6_');
                  }).length;

                  return _buildStatsCard(part2Count, part5Count, part6Count);
                },
              ),

              const SizedBox(height: 32),

              // Reading Section Header
              _buildSectionHeader(
                'Review by Part',
                Icons.menu_book,
                const Color(0xFF5C6BC0),
              ),
              const SizedBox(height: 16),

              // Parts Grid
              _buildPartsGrid(context, wrongAnswersAsync),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(int part2Count, int part5Count, int part6Count) {
    final totalCount = part2Count + part5Count + part6Count;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Solid matte color - vibrant indigo
        color: const Color(0xFF5C6BC0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C6BC0).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '총 복습할 문제',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$totalCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Part 2', part2Count),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem('Part 5', part5Count),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem('Part 6', part6Count),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPartsGrid(BuildContext context, AsyncValue wrongAnswersAsync) {
    return wrongAnswersAsync.when(
      loading: () => _buildPartsGridContent(context, 0, 0, 0),
      error: (error, stack) => _buildPartsGridContent(context, 0, 0, 0),
      data: (wrongAnswers) {
        final List<WrongAnswer> wrongAnswersList = wrongAnswers.toList();

        final part2Count = wrongAnswersList.where((WrongAnswer wa) {
          return wa.questionId.startsWith('Part2_');
        }).length;

        final part5Count = wrongAnswersList.where((WrongAnswer wa) {
          return wa.questionId.startsWith('Part5_') ||
                 (!wa.questionId.startsWith('Part2_') && !wa.questionId.startsWith('Part6_'));
        }).length;

        final part6Count = wrongAnswersList.where((WrongAnswer wa) {
          return wa.questionId.startsWith('Part6_');
        }).length;

        return _buildPartsGridContent(context, part2Count, part5Count, part6Count);
      },
    );
  }

  Widget _buildPartsGridContent(BuildContext context, int part2Count, int part5Count, int part6Count) {
    final parts = [
      _WrongAnswerPartInfo(
        partNumber: 2,
        title: 'Part 2',
        subtitle: 'Question-Response',
        icon: Icons.headphones_rounded,
        color: const Color(0xFFFF6F00), // Orange for Part 2
        wrongCount: part2Count,
      ),
      _WrongAnswerPartInfo(
        partNumber: 5,
        title: 'Part 5',
        subtitle: 'Grammar & Vocabulary',
        icon: Icons.edit_note,
        color: const Color(0xFF00BCD4), // Cyan for Part 5
        wrongCount: part5Count,
      ),
      _WrongAnswerPartInfo(
        partNumber: 6,
        title: 'Part 6',
        subtitle: 'Reading Comprehension',
        icon: Icons.article,
        color: const Color(0xFF9C27B0), // Purple for Part 6
        wrongCount: part6Count,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0, // Changed from 1.15 to 1.0 to give more vertical space
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: parts.length,
      itemBuilder: (context, index) {
        return _buildPartCard(context, parts[index]);
      },
    );
  }

  Widget _buildPartCard(BuildContext context, _WrongAnswerPartInfo partInfo) {
    final hasWrongAnswers = partInfo.wrongCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasWrongAnswers
            ? () => _navigateToPart(context, partInfo.partNumber)
            : () => _showNoWrongAnswersDialog(context, partInfo.title),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            // Solid matte color instead of gradient
            color: hasWrongAnswers
                ? partInfo.color
                : Colors.grey[400],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: hasWrongAnswers
                    ? partInfo.color.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        partInfo.icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    // Title
                    Text(
                      partInfo.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Subtitle
                    Text(
                      partInfo.subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        hasWrongAnswers ? '${partInfo.wrongCount} 문제' : '없음',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Check icon for no wrong answers
              if (!hasWrongAnswers)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white.withOpacity(0.8),
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPart(BuildContext context, int partNumber) {
    if (partNumber == 2) {
      context.push('/wrong-answers/part2');
    } else if (partNumber == 5) {
      context.push('/wrong-answers/part5');
    } else if (partNumber == 6) {
      context.push('/wrong-answers/part6');
    }
  }

  void _showNoWrongAnswersDialog(BuildContext context, String partName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF58CC02), size: 28),
            SizedBox(width: 12),
            Text(
              '완벽해요!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '$partName에 틀린 문제가 없습니다!\n계속 열심히 하세요! 🎉',
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '확인',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WrongAnswerPartInfo {
  final int partNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int wrongCount;

  _WrongAnswerPartInfo({
    required this.partNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.wrongCount,
  });
}
