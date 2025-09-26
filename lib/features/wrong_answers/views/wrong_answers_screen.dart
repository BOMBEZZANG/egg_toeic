import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/constants/app_dimensions.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';

// Filter state provider
final wrongAnswerFiltersProvider =
    StateProvider<WrongAnswerFilters>((ref) => WrongAnswerFilters());

class WrongAnswerFilters {
  final String? modeType; // 'practice', 'exam', null (all)
  final int? level; // 1-5, null (all)
  final String? category; // 'grammar', 'vocabulary', null (all)
  final String? tag; // selected tag, null (all)

  const WrongAnswerFilters({
    this.modeType,
    this.level,
    this.category,
    this.tag,
  });

  WrongAnswerFilters copyWith({
    String? modeType,
    int? level,
    String? category,
    String? tag,
  }) {
    return WrongAnswerFilters(
      modeType: modeType,
      level: level,
      category: category,
      tag: tag,
    );
  }

  bool get hasActiveFilters =>
      modeType != null || level != null || category != null || tag != null;
}

class WrongAnswersScreen extends ConsumerWidget {
  const WrongAnswersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wrongAnswersAsync = ref.watch(wrongAnswersProvider);
    final filters = ref.watch(wrongAnswerFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('오답노트'),
        centerTitle: true,
        actions: [
          if (filters.hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => ref
                  .read(wrongAnswerFiltersProvider.notifier)
                  .state = WrongAnswerFilters(),
              tooltip: '필터 초기화',
            ),
        ],
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
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        data: (wrongAnswers) {
          if (wrongAnswers.isEmpty) {
            return _buildEmptyState(context);
          }

          final filteredAnswers = _filterWrongAnswers(wrongAnswers, filters);

          return Column(
            children: [
              _buildFilterSection(context, ref, wrongAnswers),
              Expanded(
                child: filteredAnswers.isEmpty
                    ? _buildNoResultsState(context)
                    : _buildWrongAnswersList(context, ref, filteredAnswers),
              ),
            ],
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
              color: AppColors.backgroundLight,
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
            '아직 틀린 문제가 없습니다.\n더 많은 문제를 풀어보세요!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '조건에 맞는 문제가 없습니다',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '필터를 변경해서 다시 시도해보세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
      BuildContext context, WidgetRef ref, List<WrongAnswer> wrongAnswers) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Options',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${_filterWrongAnswers(wrongAnswers, ref.watch(wrongAnswerFiltersProvider)).length} questions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  ref,
                  'Type',
                  ref.watch(wrongAnswerFiltersProvider).modeType,
                  ['practice', 'exam'],
                  ['연습모드', '시험모드'],
                  (value) =>
                      ref.read(wrongAnswerFiltersProvider.notifier).state = ref
                          .read(wrongAnswerFiltersProvider)
                          .copyWith(modeType: value),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  'Level',
                  ref.watch(wrongAnswerFiltersProvider).level?.toString(),
                  ['1', '2', '3', '4', '5'],
                  ['1', '2', '3', '4', '5'],
                  (value) =>
                      ref.read(wrongAnswerFiltersProvider.notifier).state = ref
                          .read(wrongAnswerFiltersProvider)
                          .copyWith(
                              level: value != null ? int.parse(value) : null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  'Category',
                  ref.watch(wrongAnswerFiltersProvider).category,
                  ['grammar', 'vocabulary'],
                  ['문법', '어휘'],
                  (value) =>
                      ref.read(wrongAnswerFiltersProvider.notifier).state = ref
                          .read(wrongAnswerFiltersProvider)
                          .copyWith(category: value),
                ),
                const SizedBox(width: 8),
                _buildTagFilter(context, ref, wrongAnswers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    String? currentValue,
    List<String> values,
    List<String> displayNames,
    Function(String?) onChanged,
  ) {
    return PopupMenuButton<String?>(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: currentValue != null
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: currentValue != null
                ? AppColors.primaryColor
                : AppColors.borderColor,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentValue != null
                  ? displayNames[values.indexOf(currentValue)]
                  : label,
              style: TextStyle(
                color: currentValue != null
                    ? AppColors.primaryColor
                    : AppColors.textSecondary,
                fontWeight:
                    currentValue != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: currentValue != null
                  ? AppColors.primaryColor
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String?>(
          value: null,
          child: Text('All ${label}s'),
        ),
        ...values.asMap().entries.map((entry) => PopupMenuItem<String>(
              value: entry.value,
              child: Text(displayNames[entry.key]),
            )),
      ],
      onSelected: onChanged,
    );
  }

  Widget _buildTagFilter(
      BuildContext context, WidgetRef ref, List<WrongAnswer> wrongAnswers) {
    final allTags = wrongAnswers
        .where((answer) => answer.tags != null)
        .expand((answer) => answer.tags!)
        .toSet()
        .toList()
      ..sort();

    if (allTags.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String?>(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: ref.watch(wrongAnswerFiltersProvider).tag != null
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: ref.watch(wrongAnswerFiltersProvider).tag != null
                ? AppColors.primaryColor
                : AppColors.borderColor,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ref.watch(wrongAnswerFiltersProvider).tag ?? 'Tags',
              style: TextStyle(
                color: ref.watch(wrongAnswerFiltersProvider).tag != null
                    ? AppColors.primaryColor
                    : AppColors.textSecondary,
                fontWeight: ref.watch(wrongAnswerFiltersProvider).tag != null
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: ref.watch(wrongAnswerFiltersProvider).tag != null
                  ? AppColors.primaryColor
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<String?>(
          value: null,
          child: Text('All Tags'),
        ),
        ...allTags.map((tag) => PopupMenuItem<String>(
              value: tag,
              child: Text(tag),
            )),
      ],
      onSelected: (value) => ref
          .read(wrongAnswerFiltersProvider.notifier)
          .state = ref.read(wrongAnswerFiltersProvider).copyWith(tag: value),
    );
  }

  Widget _buildWrongAnswersList(
      BuildContext context, WidgetRef ref, List<WrongAnswer> wrongAnswers) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: wrongAnswers.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.paddingMedium),
      itemBuilder: (context, index) =>
          _buildWrongAnswerCard(context, ref, wrongAnswers[index]),
    );
  }

  Widget _buildWrongAnswerCard(
      BuildContext context, WidgetRef ref, WrongAnswer wrongAnswer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with metadata and actions
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusLarge),
                topRight: Radius.circular(AppDimensions.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetadataTags(wrongAnswer),
                ),
                _buildActionButtons(context, ref, wrongAnswer),
              ],
            ),
          ),

          // Question content
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                if (wrongAnswer.questionText != null) ...[
                  Text(
                    wrongAnswer.questionText!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                  ),
                ] else ...[
                  // Debug: Show when questionText is null
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DEBUG: Question text is null for ID: ${wrongAnswer.questionId}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],

                const SizedBox(height: AppDimensions.paddingMedium),

                // Answer options
                if (wrongAnswer.options != null) ...[
                  ...wrongAnswer.options!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = index == wrongAnswer.selectedAnswerIndex;
                    final isCorrect = index == wrongAnswer.correctAnswerIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding:
                          const EdgeInsets.all(AppDimensions.paddingMedium),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.successColor.withOpacity(0.1)
                            : isSelected
                                ? AppColors.errorColor.withOpacity(0.1)
                                : AppColors.backgroundLight,
                        border: Border.all(
                          color: isCorrect
                              ? AppColors.successColor
                              : isSelected
                                  ? AppColors.errorColor
                                  : AppColors.borderColor,
                          width: isCorrect || isSelected ? 2 : 1,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSmall),
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
                                      : Colors.transparent,
                              border: Border.all(
                                color: isCorrect
                                    ? AppColors.successColor
                                    : isSelected
                                        ? AppColors.errorColor
                                        : AppColors.borderColor,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: TextStyle(
                                  color: isCorrect || isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingMedium),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                color: isCorrect
                                    ? AppColors.successColor
                                    : isSelected
                                        ? AppColors.errorColor
                                        : AppColors.textPrimary,
                                fontWeight: isCorrect || isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isCorrect)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.successColor,
                              size: 20,
                            )
                          else if (isSelected)
                            Icon(
                              Icons.cancel,
                              color: AppColors.errorColor,
                              size: 20,
                            ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  // Debug: Show when options are null
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DEBUG: Options are null for ID: ${wrongAnswer.questionId}',
                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],

                // Explanation
                if (wrongAnswer.explanation != null) ...[
                  const SizedBox(height: AppDimensions.paddingMedium),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppColors.infoColor.withOpacity(0.1),
                      border: Border.all(
                          color: AppColors.infoColor.withOpacity(0.3)),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 18,
                              color: AppColors.infoColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Explanation',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppColors.infoColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          wrongAnswer.explanation!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataTags(WrongAnswer wrongAnswer) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Mode type tag
        if (wrongAnswer.modeType != null)
          _buildTag(
            wrongAnswer.modeType == 'practice' ? '연습모드' : '시험모드',
            wrongAnswer.modeType == 'practice'
                ? AppColors.primaryColor
                : AppColors.tertiaryColor,
          ),

        // Level tag
        if (wrongAnswer.difficultyLevel != null)
          _buildTag(
              'Level ${wrongAnswer.difficultyLevel}', AppColors.accentColor),

        // Category tag
        if (wrongAnswer.category != null)
          _buildTag(
            wrongAnswer.category == 'grammar' ? '문법' : '어휘',
            wrongAnswer.category == 'grammar'
                ? AppColors.warningColor
                : AppColors.successColor,
          ),

        // Grammar point tag
        if (wrongAnswer.grammarPoint != null)
          _buildTag(wrongAnswer.grammarPoint!, AppColors.textSecondary),

        // Custom tags
        if (wrongAnswer.tags != null)
          ...wrongAnswer.tags!
              .map((tag) => _buildTag(tag, AppColors.borderColor)),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, WrongAnswer wrongAnswer) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Retake button
        IconButton(
          icon: Icon(
            Icons.refresh,
            size: 20,
            color: AppColors.primaryColor,
          ),
          onPressed: () => _retakeQuestion(context, ref, wrongAnswer),
          tooltip: '문제 다시 풀기',
        ),

        // Bookmark button
        IconButton(
          icon: Icon(
            Icons.bookmark_border,
            size: 20,
            color: AppColors.tertiaryColor,
          ),
          onPressed: () => _toggleBookmark(context, ref, wrongAnswer),
          tooltip: '즐겨찾기 추가',
        ),

        // Delete button
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: 20,
            color: AppColors.errorColor,
          ),
          onPressed: () => _showDeleteConfirmation(context, ref, wrongAnswer),
          tooltip: '오답노트에서 삭제',
        ),
      ],
    );
  }

  List<WrongAnswer> _filterWrongAnswers(
      List<WrongAnswer> wrongAnswers, WrongAnswerFilters filters) {
    print('🔍 FILTERING ${wrongAnswers.length} wrong answers:');
    print('  - Filters: modeType=${filters.modeType}, level=${filters.level}, category=${filters.category}, tag=${filters.tag}');

    final filtered = wrongAnswers.where((answer) {
      final modeTypeMatch = filters.modeType == null || answer.modeType == filters.modeType;
      final levelMatch = filters.level == null || answer.difficultyLevel == filters.level;
      final categoryMatch = filters.category == null || answer.category == filters.category;
      final tagMatch = filters.tag == null || (answer.tags != null && answer.tags!.contains(filters.tag));

      final passes = modeTypeMatch && levelMatch && categoryMatch && tagMatch;

      if (!passes) {
        print('  ❌ FILTERED OUT: ${answer.questionId} (Level ${answer.difficultyLevel})');
        print('    - modeType: ${answer.modeType} (match: $modeTypeMatch)');
        print('    - level: ${answer.difficultyLevel} (match: $levelMatch)');
        print('    - category: ${answer.category} (match: $categoryMatch)');
        print('    - tags: ${answer.tags} (match: $tagMatch)');
      } else {
        print('  ✅ KEPT: ${answer.questionId} (Level ${answer.difficultyLevel})');
      }

      return passes;
    }).toList();

    print('📊 FILTER RESULT: ${filtered.length} out of ${wrongAnswers.length} wrong answers passed filters');
    return filtered;
  }

  void _toggleBookmark(BuildContext context, WidgetRef ref, WrongAnswer wrongAnswer) async {
    if (wrongAnswer.questionId.isNotEmpty) {
      await ref
          .read(userDataRepositoryProvider)
          .toggleFavorite(wrongAnswer.questionId);
      ref.invalidate(favoritesProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('즐겨찾기에 추가되었습니다!'),
          backgroundColor: AppColors.successColor,
        ),
      );
    }
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, WrongAnswer wrongAnswer) {
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
            onPressed: () {
              Navigator.of(context).pop();
              _deleteWrongAnswer(context, ref, wrongAnswer);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _deleteWrongAnswer(BuildContext context, WidgetRef ref, WrongAnswer wrongAnswer) async {
    await ref
        .read(userDataRepositoryProvider)
        .removeWrongAnswer(wrongAnswer.id);
    ref.invalidate(wrongAnswersProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('오답노트에서 삭제되었습니다.'),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  void _retakeQuestion(BuildContext context, WidgetRef ref, WrongAnswer wrongAnswer) {
    if (wrongAnswer.questionText == null || wrongAnswer.options == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('문제 데이터가 없어서 다시 풀 수 없습니다.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    context.pushNamed(
      'retake-question',
      extra: wrongAnswer,
    );
  }
}
