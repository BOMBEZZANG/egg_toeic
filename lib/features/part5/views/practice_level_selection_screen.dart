import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/repositories/question_repository.dart';

class PracticeLevelSelectionScreen extends ConsumerWidget {
  const PracticeLevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Mode - Daily Sessions'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Instructions Card
              _buildInstructionsCard(context),

              const SizedBox(height: 20),

              // Practice Sessions List
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final practiceSessionsAsync = ref.watch(practiceSessionsProvider);

                    return practiceSessionsAsync.when(
                      data: (sessionsByDate) {
                        final sessions = _buildPracticeSessionsFromFirebaseData(sessionsByDate);

                        if (sessions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No practice sessions available yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Generate some questions from the admin panel',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: sessions.length,
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            return _buildPracticeSessionCard(
                              context,
                              session: session,
                              onTap: () => _navigateToSession(context, session),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading practice sessions...'),
                          ],
                        ),
                      ),
                      error: (error, stack) {
                        print('Error loading practice sessions: $error');
                        print('Stack trace: $stack');

                        // Fallback to mock data on error
                        final sessions = _getPracticeSessions();
                        return ListView.builder(
                          itemCount: sessions.length,
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            return _buildPracticeSessionCard(
                              context,
                              session: session,
                              onTap: () => _navigateToSession(context, session),
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
    );
  }

  Widget _buildInstructionsCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📚', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  'Daily Practice Sessions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• 매일 새로운 10문제 세트로 꾸준한 학습\n'
              '• 레벨별 균형잡힌 문제 구성 (Level 1~3)\n'
              '• 문법과 어휘 문제가 적절히 섞여 있음\n'
              '• 즉시 해설 확인으로 효과적인 학습',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeSessionCard(
    BuildContext context, {
    required PracticeSession session,
    required VoidCallback onTap,
  }) {
    final isToday = _isToday(session.date);
    final isCompleted = session.completedQuestions == 10;
    final progressPercent = (session.completedQuestions / 10.0 * 100).toInt();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isToday
                ? [
                    AppColors.primaryColor.withOpacity(0.8),
                    AppColors.primaryColor
                  ]
                : isCompleted
                    ? [
                        AppColors.successColor.withOpacity(0.8),
                        AppColors.successColor
                      ]
                    : [Colors.blue.withOpacity(0.8), Colors.blue],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isToday ? AppColors.primaryColor : Colors.blue)
                  .withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.quiz,
                size: 120,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isToday
                              ? Icons.today
                              : isCompleted
                                  ? Icons.check_circle
                                  : Icons.quiz,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              session.subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress and Stats
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progress',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '$progressPercent% (${session.completedQuestions}/10)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: session.completedQuestions / 10.0,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (session.accuracy > 0) ...[
                        const SizedBox(width: 16),
                        Column(
                          children: [
                            Text(
                              '${(session.accuracy * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Accuracy',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PracticeSession> _buildPracticeSessionsFromFirebaseData(Map<String, List<Question>> sessionsByDate) {
    final sessions = <PracticeSession>[];
    final dates = sessionsByDate.keys.toList();
    dates.sort((a, b) => b.compareTo(a)); // Sort dates in descending order (latest first)

    int sessionNumber = dates.length;

    for (final dateString in dates) {
      final questions = sessionsByDate[dateString]!;
      final date = DateTime.parse(dateString);

      // For demo purposes, we'll simulate some completion data
      // In a real app, this would come from user progress data
      final isToday = _isToday(date);
      final daysSinceToday = DateTime.now().difference(date).inDays;

      int completedQuestions;
      double accuracy;

      if (isToday) {
        // Today's session - partially completed
        completedQuestions = 3;
        accuracy = 0.0;
      } else if (daysSinceToday < 7) {
        // Recent sessions - varying completion
        completedQuestions = 10 - daysSinceToday;
        accuracy = 0.6 + (daysSinceToday * 0.05);
      } else {
        // Older sessions - completed
        completedQuestions = 10;
        accuracy = 0.85;
      }

      sessions.add(PracticeSession(
        id: 'firebase_${dateString.replaceAll('-', '_')}',
        title: 'PRACTICE $sessionNumber',
        subtitle: _formatDate(date),
        date: date,
        completedQuestions: completedQuestions > questions.length ? questions.length : completedQuestions,
        totalQuestions: questions.length,
        accuracy: accuracy,
        questionIds: questions.map((q) => q.id).toList(),
      ));

      sessionNumber--;
    }

    return sessions;
  }

  List<PracticeSession> _getPracticeSessions() {
    final now = DateTime.now();
    final sessions = <PracticeSession>[];

    // Generate last 30 days of practice sessions (latest first) - fallback mock data
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final sessionNumber = 30 - i; // Most recent session has highest number

      sessions.add(PracticeSession(
        id: 'practice_$sessionNumber',
        title: 'PRACTICE $sessionNumber',
        subtitle: _formatDate(date),
        date: date,
        completedQuestions:
            i == 0 ? 3 : (i < 7 ? (10 - i) : 10), // Simulate progress
        totalQuestions: 10,
        accuracy: i == 0
            ? 0.0
            : (i < 7 ? 0.6 + (i * 0.05) : 0.85), // Simulate accuracy
        questionIds: [], // Empty for mock data
      ));
    }

    return sessions;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _navigateToSession(BuildContext context, PracticeSession session) {
    // Navigate to the practice session
    context.push('/part5/practice/session/${session.id}');
  }
}

class PracticeSession {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final int completedQuestions;
  final int totalQuestions;
  final double accuracy;
  final List<String> questionIds;

  PracticeSession({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.completedQuestions,
    required this.totalQuestions,
    required this.accuracy,
    required this.questionIds,
  });
}
