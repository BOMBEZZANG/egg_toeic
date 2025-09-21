import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';

class PracticeLevelSelectionScreen extends ConsumerWidget {
  const PracticeLevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Mode - Select Level'),
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

              // Level Selection
              Expanded(
                child: ListView.builder(
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final level = index + 1;
                    final progress = _getLevelProgress(level);
                    final isUnlocked = _isLevelUnlocked(level);

                    return _buildLevelCard(
                      context,
                      level: level,
                      progress: progress,
                      isUnlocked: isUnlocked,
                      onTap: isUnlocked
                          ? () => context.push('/part5/practice/$level')
                          : null,
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
                  'Practice Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Learn at your own pace with no time pressure\n'
              '• Get immediate explanations for each answer\n'
              '• Review mistakes and learn from them\n'
              '• Track your progress and improve gradually',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context, {
    required int level,
    required double progress,
    required bool isUnlocked,
    VoidCallback? onTap,
  }) {
    final levelNames = ['Beginner', 'Intermediate', 'Advanced'];
    final levelDescriptions = [
      'Basic grammar and vocabulary',
      'Complex sentence structures',
      'Advanced grammar patterns',
    ];
    final levelColors = [AppColors.successColor, Colors.amber, AppColors.errorColor];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnlocked
                ? [
                    levelColors[level - 1].withOpacity(0.8),
                    levelColors[level - 1],
                  ]
                : [Colors.grey[400]!, Colors.grey[600]!],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isUnlocked ? levelColors[level - 1] : Colors.grey)
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
                Icons.school,
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
                        child: Text(
                          'L$level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              levelNames[level - 1],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              levelDescriptions[level - 1],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isUnlocked)
                        const Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Column(
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
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 8,
                        ),
                      ),
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

  double _getLevelProgress(int level) {
    switch (level) {
      case 1:
        return 0.7;
      case 2:
        return 0.3;
      case 3:
        return 0.0;
      default:
        return 0.0;
    }
  }

  bool _isLevelUnlocked(int level) {
    if (level == 1) return true;
    if (level == 2) return _getLevelProgress(1) >= 0.5;
    if (level == 3) return _getLevelProgress(2) >= 0.5;
    return false;
  }
}