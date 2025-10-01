import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/data/models/learning_session_model.dart';
import 'package:egg_toeic/data/models/exam_result_model.dart';
import 'package:egg_toeic/core/services/rewarded_ad_manager.dart';

class ExamLevelSelectionScreen extends ConsumerStatefulWidget {
  const ExamLevelSelectionScreen({super.key});

  @override
  ConsumerState<ExamLevelSelectionScreen> createState() =>
      _ExamLevelSelectionScreenState();
}

class _ExamLevelSelectionScreenState
    extends ConsumerState<ExamLevelSelectionScreen> {

  // Get completed rounds from UserDataRepository
  Future<Set<String>> _getCompletedRounds() async {
    try {
      final userDataRepo = ref.read(userDataRepositoryProvider);
      final sessions = await userDataRepo.getLearningSessions();

      print('🔍 Total sessions found: ${sessions.length}');
      for (final session in sessions) {
        print('📋 Session: ${session.id}, type: ${session.sessionType}, completed: ${session.isCompleted}');
      }

      final completedExamSessions = sessions
          .where((session) =>
              session.sessionType == 'exam' &&
              session.isCompleted)
          .toList();

      print('✅ Completed exam sessions: ${completedExamSessions.length}');

      final completedRounds = <String>{};

      for (final session in completedExamSessions) {
        // Check if any questionId in the session contains round information
        for (final questionId in session.questionIds) {
          if (questionId.contains('EXAM_') && questionId.contains('ROUND_')) {
            final match = RegExp(r'ROUND_\d+').firstMatch(questionId);
            if (match != null) {
              completedRounds.add(match.group(0)!);
              print('🎯 Found completed round: ${match.group(0)} in session ${session.id}');
            }
          }
        }
      }

      print('🎯 Completed rounds extracted: $completedRounds');

      return completedRounds;
    } catch (e) {
      print('❌ Error getting completed rounds: $e');
      return <String>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableRoundsAsync = ref.watch(availableExamRoundsProvider);

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          // Refresh home screen statistics when going back
          ref.invalidate(userProgressProvider);
          ref.invalidate(examResultsProvider);
          ref.invalidate(combinedStatisticsProvider);
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: const Text('시험 모드 - 라운드 선택'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Instructions Card
              _buildInstructionsCard(context),

              const SizedBox(height: 20),

              // Round Selection
              Expanded(
                child: availableRoundsAsync.when(
                  loading: () => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '라운드 정보를 불러오는 중...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 60,
                          color: AppColors.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '라운드 로딩 오류',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load exam rounds: $error',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(availableExamRoundsProvider);
                          },
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                  data: (availableRounds) {
                    // Sort rounds from highest to lowest (Round 8 -> Round 1)
                    final sortedRounds = List<String>.from(availableRounds);
                    sortedRounds.sort((a, b) {
                      final aNum = int.tryParse(a.replaceAll('ROUND_', '')) ?? 0;
                      final bNum = int.tryParse(b.replaceAll('ROUND_', '')) ?? 0;
                      return bNum.compareTo(aNum); // Descending order
                    });

                    return availableRounds.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 60,
                                  color: AppColors.textHint,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '사용 가능한 시험 라운드가 없습니다',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : FutureBuilder<Set<String>>(
                            future: _getCompletedRounds(),
                            builder: (context, completedSnapshot) {
                              final completedRounds = completedSnapshot.data ?? <String>{};

                              return GridView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.4,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: sortedRounds.length,
                                itemBuilder: (context, index) {
                                  final round = sortedRounds[index];
                                  final roundNumber = round.replaceAll('ROUND_', '');
                                  final isCompleted = completedRounds.contains(round);

                                  return _buildRoundCard(
                                    context,
                                    round: round,
                                    roundNumber: roundNumber,
                                    index: index,
                                    isCompleted: isCompleted,
                                    onTap: () => isCompleted
                                        ? _showCompletedRoundModal(context, round, roundNumber)
                                        : _showAdConsentModal(context, round),
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

  Widget _buildInstructionsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Duolingo-style colorful icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF58CC02).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '시험 모드',
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '각 라운드를 선택해서 시험에 도전해보세요!',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundCard(
    BuildContext context, {
    required String round,
    required String roundNumber,
    required int index,
    required bool isCompleted,
    VoidCallback? onTap,
  }) {
    // Duolingo-inspired color scheme
    final colors = [
      const Color(0xFF58CC02), // Green
      const Color(0xFF00C9FF), // Blue
      const Color(0xFFFF9600), // Orange
      const Color(0xFFFF4B4B), // Red
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFFE91E63), // Pink
    ];

    // Use grey for completed rounds, normal colors for incomplete rounds
    final baseColor = colors[index % colors.length];
    final primaryColor = isCompleted
        ? const Color(0xFF6B7280) // Grey for completed
        : baseColor;
    final darkColor = Color.lerp(primaryColor, Colors.black, 0.15)!;

    // Use consistent lightbulb icon for all rounds
    const icon = Icons.lightbulb_rounded;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: darkColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with circular background
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: darkColor.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_rounded : icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),

                  const SizedBox(height: 8),

                  // Round number
                  Text(
                    'Round $roundNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 2),

                      // Progress indicator with completion status
                      Container(
                        width: double.infinity,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: isCompleted ? 1.0 : 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
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
        ),
      ),
    );
  }

  // Show ad consent modal before starting exam
  void _showAdConsentModal(BuildContext context, String round) {
    // Capture the outer context that has access to GoRouter
    final navigatorContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_circle_outline,
                size: 48,
                color: Colors.amber[700],
              ),
            ),
            const SizedBox(height: 20),
            // Title
            const Text(
              '시험 시작',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            // Message
            Text(
              '시험을 보기 위해서\n광고를 시청하시겠습니까?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                // 아니오 button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      // Navigate to exam directly without ad using captured context
                      navigatorContext.push('/part5/exam/$round');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    child: Text(
                      '아니오',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 네, 광고시청하기 button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _loadAndShowRewardedAd(navigatorContext, round);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF58CC02),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      '네, 시청하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Load and show rewarded ad, then navigate to exam
  Future<void> _loadAndShowRewardedAd(BuildContext context, String round) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                '광고 로딩 중...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final adManager = RewardedAdManager();
      final adLoaded = await adManager.loadAd();

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (adLoaded) {
        // Show the ad
        print('🎁 Showing rewarded ad...');
        final adShown = await adManager.showAd();

        // Navigate to exam after ad (regardless of whether user watched completely)
        if (context.mounted) {
          if (adShown) {
            print('✅ Rewarded ad completed, navigating to exam');
          } else {
            print('⚠️ Rewarded ad was dismissed, navigating to exam anyway');
          }
          context.push('/part5/exam/$round');
        }
      } else {
        // Ad failed to load, navigate directly
        print('⚠️ Rewarded ad failed to load, navigating to exam directly');
        if (context.mounted) {
          _showAdFailureSnackBar(context);
          context.push('/part5/exam/$round');
        }
      }

      // Cleanup
      adManager.dispose();
    } catch (e) {
      print('❌ Error loading/showing rewarded ad: $e');
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.pop(context);
        _showAdFailureSnackBar(context);
        context.push('/part5/exam/$round');
      }
    }
  }

  void _showAdFailureSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('광고를 불러올 수 없어 바로 시험으로 이동합니다'),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 2),
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
                      context.push('/part5/exam/$round');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결과 데이터를 찾을 수 없습니다')),
        );
        return;
      }

      // Navigate to the original comprehensive result screen
      context.push('/part5/exam-result', extra: {
        'examRound': examResult.examRound,
        'questions': examResult.questions,
        'userAnswers': examResult.userAnswers,
        'examStartTime': examResult.examStartTime,
        'examEndTime': examResult.examEndTime,
      });
    } catch (e) {
      print('Error loading exam result: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결과를 불러오는 중 오류가 발생했습니다')),
      );
    }
  }

}
