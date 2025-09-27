import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/constants/app_dimensions.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:egg_toeic/providers/app_providers.dart';

class ReviewSelectScreen extends ConsumerWidget {
  const ReviewSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wrongAnswersAsync = ref.watch(wrongAnswersProvider);
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('복습하기'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(),

              const SizedBox(height: AppDimensions.paddingXLarge),

              // Review Options
              wrongAnswersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Error loading data: $error'),
                data: (wrongAnswers) => favoritesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error loading favorites: $error'),
                  data: (favorites) => Column(
                    children: [
                      _buildReviewCard(
                        context,
                        title: '오답노트',
                        subtitle: '틀린 문제를 다시 풀어보세요',
                        icon: Icons.replay,
                        color: AppColors.errorColor,
                        count: wrongAnswers.length,
                        enabled: wrongAnswers.isNotEmpty,
                        onTap: () => context.push('/wrong-answers'),
                      ),

                      const SizedBox(height: AppDimensions.paddingMedium),

                      _buildReviewCard(
                        context,
                        title: '즐겨찾기',
                        subtitle: '저장한 중요 문제들을 복습하세요',
                        icon: Icons.favorite,
                        color: AppColors.tertiaryColor,
                        count: favorites.length,
                        enabled: favorites.isNotEmpty,
                        onTap: () => _navigateToFavorites(context),
                      ),

                      const SizedBox(height: AppDimensions.paddingXLarge),

                      // Additional Tips
                      _buildTipsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          const Text(
            '복습으로 실력 향상!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          const Text(
            '틀린 문제와 저장한 문제를 다시 풀어\n완벽하게 마스터해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int count,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(
            color: enabled ? color.withOpacity(0.3) : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: enabled ? AppTheme.cardShadow : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: enabled ? color.withOpacity(0.1) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Icon(
                icon,
                size: 32,
                color: enabled ? color : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: enabled ? AppColors.textPrimary : Colors.grey.shade500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingSmall,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: enabled ? color : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: enabled ? AppColors.textSecondary : Colors.grey.shade400,
                      height: 1.3,
                    ),
                  ),
                  if (!enabled) ...[
                    const SizedBox(height: 8),
                    Text(
                      count == 0 ? '아직 ${title == '오답노트' ? '틀린 문제' : '저장한 문제'}가 없습니다' : '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (enabled)
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.warningColor,
                size: 24,
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              const Text(
                '복습 팁',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _buildTipItem('오답노트는 틀린 문제를 반복 학습할 수 있도록 도와줍니다'),
          _buildTipItem('즐겨찾기는 중요하다고 생각하는 문제를 저장합니다'),
          _buildTipItem('정기적인 복습으로 장기 기억에 저장하세요'),
          _buildTipItem('어려운 문제는 여러 번 반복해서 풀어보세요'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToFavorites(BuildContext context) {
    context.push('/bookmarks');
  }
}