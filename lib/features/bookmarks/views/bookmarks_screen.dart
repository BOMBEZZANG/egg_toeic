import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/constants/app_dimensions.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/providers/repository_providers.dart';

// Filter state provider for bookmarks
final bookmarkFiltersProvider =
    StateProvider<BookmarkFilters>((ref) => BookmarkFilters());

class BookmarkFilters {
  final String? modeType; // 'practice', 'exam', null (all)
  final int? level; // 1-5, null (all)
  final String? category; // 'grammar', 'vocabulary', null (all)
  final String? grammarPoint; // selected grammar point, null (all)

  const BookmarkFilters({
    this.modeType,
    this.level,
    this.category,
    this.grammarPoint,
  });

  BookmarkFilters copyWith({
    String? modeType,
    int? level,
    String? category,
    String? grammarPoint,
  }) {
    return BookmarkFilters(
      modeType: modeType ?? this.modeType,
      level: level ?? this.level,
      category: category ?? this.category,
      grammarPoint: grammarPoint ?? this.grammarPoint,
    );
  }

  // Helper methods to explicitly set a field to null
  BookmarkFilters clearModeType() => BookmarkFilters(
    modeType: null,
    level: level,
    category: category,
    grammarPoint: grammarPoint,
  );

  BookmarkFilters clearLevel() => BookmarkFilters(
    modeType: modeType,
    level: null,
    category: category,
    grammarPoint: grammarPoint,
  );

  BookmarkFilters clearCategory() => BookmarkFilters(
    modeType: modeType,
    level: level,
    category: null,
    grammarPoint: grammarPoint,
  );

  BookmarkFilters clearGrammarPoint() => BookmarkFilters(
    modeType: modeType,
    level: level,
    category: category,
    grammarPoint: null,
  );

  bool get hasActiveFilters =>
      modeType != null || level != null || category != null || grammarPoint != null;
}

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkedQuestionsProvider);
    final filters = ref.watch(bookmarkFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('즐겨찾기'),
        centerTitle: true,
        actions: [
          if (filters.hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => ref
                  .read(bookmarkFiltersProvider.notifier)
                  .state = BookmarkFilters(),
              tooltip: '필터 초기화',
            ),
        ],
      ),
      body: bookmarksAsync.when(
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
                'Error loading bookmarks',
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
        data: (bookmarkedQuestions) {
          if (bookmarkedQuestions.isEmpty) {
            return _buildEmptyState(context);
          }

          final filteredBookmarks = _filterBookmarks(bookmarkedQuestions, filters);

          return Column(
            children: [
              _buildFilterSection(context, ref, bookmarkedQuestions),
              Expanded(
                child: filteredBookmarks.isEmpty
                    ? _buildNoResultsState(context)
                    : _buildBookmarksList(context, ref, filteredBookmarks),
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
              Icons.bookmark_border,
              size: 64,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '즐겨찾기가 비어있습니다',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '문제를 풀면서 즐겨찾기에\n추가해보세요!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/part5'),
            icon: const Icon(Icons.quiz),
            label: const Text('문제 풀기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
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
      BuildContext context, WidgetRef ref, List<SimpleQuestion> bookmarks) {
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
                '${_filterBookmarks(bookmarks, ref.watch(bookmarkFiltersProvider)).length} questions',
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
                  'Level',
                  ref.watch(bookmarkFiltersProvider).level?.toString(),
                  ['1', '2', '3'],
                  ['1', '2', '3'],
                  (value) {
                    ref.read(bookmarkFiltersProvider.notifier).state = (value == null || value == '__ALL__')
                        ? ref.read(bookmarkFiltersProvider).clearLevel()
                        : ref.read(bookmarkFiltersProvider).copyWith(level: int.parse(value));
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  'Category',
                  ref.watch(bookmarkFiltersProvider).category,
                  ['grammar', 'vocabulary'],
                  ['문법', '어휘'],
                  (value) {
                    ref.read(bookmarkFiltersProvider.notifier).state = (value == null || value == '__ALL__')
                        ? ref.read(bookmarkFiltersProvider).clearCategory()
                        : ref.read(bookmarkFiltersProvider).copyWith(category: value);
                  },
                ),
                const SizedBox(width: 8),
                _buildGrammarPointFilter(context, ref, bookmarks),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(
      BuildContext context, WidgetRef ref, List<SimpleQuestion> bookmarks) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: bookmarks.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.paddingMedium),
      itemBuilder: (context, index) =>
          _buildBookmarkCard(context, ref, bookmarks[index]),
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
    String getAllText() {
      switch (label) {
        case 'Level':
          return '전체 레벨';
        case 'Category':
          return '전체 카테고리';
        default:
          return 'All ${label}s';
      }
    }

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
                  : getAllText(),
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
          value: '__ALL__',
          child: Row(
            children: [
              Icon(
                Icons.clear_all,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                getAllText(),
                style: TextStyle(
                  color: currentValue == null ? AppColors.primaryColor : AppColors.textPrimary,
                  fontWeight: currentValue == null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...values.asMap().entries.map((entry) => PopupMenuItem<String>(
              value: entry.value,
              child: Row(
                children: [
                  Icon(
                    currentValue == entry.value ? Icons.check : Icons.radio_button_unchecked,
                    size: 16,
                    color: currentValue == entry.value ? AppColors.primaryColor : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayNames[entry.key],
                    style: TextStyle(
                      color: currentValue == entry.value ? AppColors.primaryColor : AppColors.textPrimary,
                      fontWeight: currentValue == entry.value ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            )),
      ],
      onSelected: onChanged,
    );
  }

  Widget _buildGrammarPointFilter(
      BuildContext context, WidgetRef ref, List<SimpleQuestion> bookmarks) {
    final allGrammarPoints = bookmarks
        .where((bookmark) => bookmark.grammarPoint != null)
        .map((bookmark) => bookmark.grammarPoint!)
        .toSet()
        .toList()
      ..sort();

    if (allGrammarPoints.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String?>(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: ref.watch(bookmarkFiltersProvider).grammarPoint != null
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: ref.watch(bookmarkFiltersProvider).grammarPoint != null
                ? AppColors.primaryColor
                : AppColors.borderColor,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ref.watch(bookmarkFiltersProvider).grammarPoint ?? '전체 문법',
              style: TextStyle(
                color: ref.watch(bookmarkFiltersProvider).grammarPoint != null
                    ? AppColors.primaryColor
                    : AppColors.textSecondary,
                fontWeight: ref.watch(bookmarkFiltersProvider).grammarPoint != null
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: ref.watch(bookmarkFiltersProvider).grammarPoint != null
                  ? AppColors.primaryColor
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String?>(
          value: '__ALL__',
          child: Row(
            children: [
              Icon(
                Icons.clear_all,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '전체 문법',
                style: TextStyle(
                  color: ref.watch(bookmarkFiltersProvider).grammarPoint == null ? AppColors.primaryColor : AppColors.textPrimary,
                  fontWeight: ref.watch(bookmarkFiltersProvider).grammarPoint == null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        if (allGrammarPoints.isNotEmpty) const PopupMenuDivider(),
        ...allGrammarPoints.map((grammarPoint) => PopupMenuItem<String>(
              value: grammarPoint,
              child: Row(
                children: [
                  Icon(
                    ref.watch(bookmarkFiltersProvider).grammarPoint == grammarPoint ? Icons.check : Icons.radio_button_unchecked,
                    size: 16,
                    color: ref.watch(bookmarkFiltersProvider).grammarPoint == grammarPoint ? AppColors.primaryColor : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    grammarPoint,
                    style: TextStyle(
                      color: ref.watch(bookmarkFiltersProvider).grammarPoint == grammarPoint ? AppColors.primaryColor : AppColors.textPrimary,
                      fontWeight: ref.watch(bookmarkFiltersProvider).grammarPoint == grammarPoint ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            )),
      ],
      onSelected: (value) {
        ref.read(bookmarkFiltersProvider.notifier).state = (value == null || value == '__ALL__')
            ? ref.read(bookmarkFiltersProvider).clearGrammarPoint()
            : ref.read(bookmarkFiltersProvider).copyWith(grammarPoint: value);
      },
    );
  }

  Widget _buildBookmarkCard(
      BuildContext context, WidgetRef ref, SimpleQuestion question) {
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
                  child: _buildMetadataTags(question),
                ),
                _buildActionButtons(context, ref, question),
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
                Text(
                  question.questionText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Answer options
                ...question.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isCorrect = index == question.correctAnswerIndex;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.all(AppDimensions.paddingMedium),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? AppColors.successColor.withOpacity(0.1)
                          : AppColors.backgroundLight,
                      border: Border.all(
                        color: isCorrect
                            ? AppColors.successColor
                            : AppColors.borderColor,
                        width: isCorrect ? 2 : 1,
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
                                : Colors.transparent,
                            border: Border.all(
                              color: isCorrect
                                  ? AppColors.successColor
                                  : AppColors.borderColor,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: TextStyle(
                                color: isCorrect
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
                                  : AppColors.textPrimary,
                              fontWeight: isCorrect
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
                          ),
                      ],
                    ),
                  );
                }),

                // Explanation
                if (question.explanation.isNotEmpty) ...[
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
                          question.explanation,
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

  Widget _buildMetadataTags(SimpleQuestion question) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Level tag
        _buildTag('Level ${question.difficultyLevel}', AppColors.accentColor),

        // Grammar point tag
        if (question.grammarPoint != null)
          _buildTag(question.grammarPoint!, AppColors.primaryColor),

        // Category tag (inferred from grammar point or question content)
        _buildTag(
          _inferCategory(question) == 'grammar' ? '문법' : '어휘',
          _inferCategory(question) == 'grammar'
              ? AppColors.warningColor
              : AppColors.successColor,
        ),
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
      BuildContext context, WidgetRef ref, SimpleQuestion question) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Practice button
        IconButton(
          icon: Icon(
            Icons.quiz,
            size: 20,
            color: AppColors.primaryColor,
          ),
          onPressed: () => _practiceQuestion(context, question),
          tooltip: '문제 풀기',
        ),

        // Remove bookmark button
        IconButton(
          icon: Icon(
            Icons.bookmark,
            size: 20,
            color: AppColors.accentColor,
          ),
          onPressed: () => _removeBookmark(ref, question.id),
          tooltip: '즐겨찾기 삭제',
        ),
      ],
    );
  }

  String _inferCategory(SimpleQuestion question) {
    final grammarPoint = question.grammarPoint?.toLowerCase() ?? '';
    final questionText = question.questionText.toLowerCase();

    if (questionText.contains('meaning') ||
        questionText.contains('synonym') ||
        questionText.contains('definition') ||
        grammarPoint.contains('vocabulary')) {
      return 'vocabulary';
    } else {
      return 'grammar';
    }
  }

  List<SimpleQuestion> _filterBookmarks(
      List<SimpleQuestion> bookmarks, BookmarkFilters filters) {
    return bookmarks.where((bookmark) {
      final levelMatch = filters.level == null || bookmark.difficultyLevel == filters.level;
      final categoryMatch = filters.category == null || _inferCategory(bookmark) == filters.category;
      final grammarPointMatch = filters.grammarPoint == null || bookmark.grammarPoint == filters.grammarPoint;

      return levelMatch && categoryMatch && grammarPointMatch;
    }).toList();
  }

  void _practiceQuestion(BuildContext context, SimpleQuestion question) {
    context.push('/part5/explanation', extra: question);
  }

  void _removeBookmark(WidgetRef ref, String questionId) async {
    try {
      await ref.read(userDataRepositoryProvider).toggleFavorite(questionId);
      // Invalidate both providers to refresh the UI
      ref.invalidate(favoritesProvider);
      ref.invalidate(bookmarkedQuestionsProvider);
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

}