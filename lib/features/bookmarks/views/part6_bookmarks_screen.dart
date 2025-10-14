import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/features/part6/views/part6_retake_question_screen.dart';

class Part6BookmarksScreen extends ConsumerStatefulWidget {
  const Part6BookmarksScreen({super.key});

  @override
  ConsumerState<Part6BookmarksScreen> createState() => _Part6BookmarksScreenState();
}

class _Part6BookmarksScreenState extends ConsumerState<Part6BookmarksScreen> {
  Map<String, List<SimpleQuestion>> _passageQuestionsMap = {};
  bool _isLoadingQuestions = false;
  List<String> _lastLoadedBookmarks = [];

  Future<void> _loadBookmarkedPassageQuestions(List<String> part6Bookmarks) async {
    // Skip if already loading or if bookmarks haven't changed
    if (_isLoadingQuestions || _areBookmarksEqual(part6Bookmarks, _lastLoadedBookmarks)) {
      return;
    }

    print('🔖 Loading bookmarked passages for ${part6Bookmarks.length} bookmarks');

    setState(() {
      _isLoadingQuestions = true;
      _lastLoadedBookmarks = part6Bookmarks;
    });

    try {
      if (part6Bookmarks.isEmpty) {
        setState(() {
          _passageQuestionsMap = {};
          _isLoadingQuestions = false;
        });
        return;
      }

      // Extract unique dates from bookmarked question IDs
      final Set<String> dates = {};
      for (final bookmarkId in part6Bookmarks) {
        print('🔖 Processing bookmark: $bookmarkId');
        final parts = bookmarkId.split('_');
        if (parts.length >= 5 && parts[1] == 'PRAC') {
          final date = '${parts[2]}-${parts[3]}-${parts[4]}';
          dates.add(date);
          print('📅 Extracted date: $date');
        }
      }

      print('📅 Unique dates to load: ${dates.toList()}');

      // Load questions for each date and build passage map
      final questionRepository = ref.read(questionRepositoryProvider);
      final Map<String, List<SimpleQuestion>> passageMap = {};

      for (final date in dates) {
        print('📖 Loading questions for date: $date');
        final questions = await questionRepository.getPart6PracticeQuestionsByDate(date);
        print('📖 Loaded ${questions.length} questions for $date');

        for (final question in questions) {
          final passageText = question.passageText ?? 'Unknown';
          passageMap.putIfAbsent(passageText, () => []);
          if (!passageMap[passageText]!.any((q) => q.id == question.id)) {
            passageMap[passageText]!.add(question);
          }
        }
      }

      print('📚 Total passages loaded: ${passageMap.length}');

      setState(() {
        _passageQuestionsMap = passageMap;
        _isLoadingQuestions = false;
      });
    } catch (e) {
      print('❌ Error loading bookmarked passage questions: $e');
      setState(() {
        _isLoadingQuestions = false;
      });
    }
  }

  bool _areBookmarksEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final aSet = a.toSet();
    final bSet = b.toSet();
    return aSet.difference(bSet).isEmpty && bSet.difference(aSet).isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Part 6 Bookmarks',
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
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading bookmarks', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (favorites) {
          final List<String> favoritesList = favorites.toList();
          final part6Bookmarks = favoritesList.where((String id) => id.startsWith('Part6_')).toList();

          // Trigger loading when favorites are available
          if (part6Bookmarks.isNotEmpty && _passageQuestionsMap.isEmpty && !_isLoadingQuestions) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadBookmarkedPassageQuestions(part6Bookmarks);
            });
          }

          if (part6Bookmarks.isEmpty) {
            return _buildEmptyState(context);
          }

          if (_isLoadingQuestions || _passageQuestionsMap.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading bookmarked passages...'),
                ],
              ),
            );
          }

          final groupedBookmarks = _groupBookmarksByPassage(part6Bookmarks);

          if (groupedBookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('No passages loaded', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Bookmarks: ${part6Bookmarks.length}', textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Passages: ${_passageQuestionsMap.length}', textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedBookmarks.length,
            itemBuilder: (context, index) {
              final passageText = groupedBookmarks.keys.elementAt(index);
              final bookmarkedQuestionIds = groupedBookmarks[passageText]!;
              final allQuestions = _passageQuestionsMap[passageText] ?? [];

              return _buildPassageCard(
                context,
                passageText,
                allQuestions,
                bookmarkedQuestionIds,
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
              color: const Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_border,
              size: 64,
              color: Color(0xFFFF9600),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Part 6 Bookmarks',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start bookmarking Part 6 questions\nto review them later!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<String>> _groupBookmarksByPassage(List<String> bookmarkedIds) {
    final Map<String, List<String>> grouped = {};

    for (final bookmarkId in bookmarkedIds) {
      String passageText = 'Unknown';

      // Find the matching question in loaded passages
      for (final entry in _passageQuestionsMap.entries) {
        final questions = entry.value;
        final matchingQuestion = questions.where((q) => q.id == bookmarkId).firstOrNull;

        if (matchingQuestion != null) {
          passageText = matchingQuestion.passageText ?? 'Unknown';
          break;
        }
      }

      grouped.putIfAbsent(passageText, () => []);
      grouped[passageText]!.add(bookmarkId);
    }

    return grouped;
  }

  Widget _buildPassageCard(
    BuildContext context,
    String passageText,
    List<SimpleQuestion> allQuestions,
    List<String> bookmarkedQuestionIds,
  ) {
    if (allQuestions.isEmpty) return const SizedBox.shrink();

    final bookmarkedQuestionIdsSet = bookmarkedQuestionIds.toSet();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passage Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF9600),
                  Color(0xFFFFB74D),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.article,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reading Passage',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${bookmarkedQuestionIds.length} bookmarked question(s)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Passage Content
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F0),
              border: Border(
                left: BorderSide(color: const Color(0xFFFF9600), width: 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book, size: 18, color: Color(0xFFFF9600)),
                    SizedBox(width: 8),
                    Text(
                      'Passage Text',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  passageText,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: Colors.black87,
                  ),
                ),

                // Korean Translation if available
                if (allQuestions.first.passageTextKorean != null &&
                    allQuestions.first.passageTextKorean!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.translate, size: 18, color: Color(0xFFFF9600)),
                      SizedBox(width: 8),
                      Text(
                        '지문 번역 (Korean Translation)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE0B2)),
                    ),
                    child: Text(
                      allQuestions.first.passageTextKorean!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bookmarked Questions
          ...allQuestions.where((q) => bookmarkedQuestionIdsSet.contains(q.id)).map((question) {
            return _buildQuestionCard(context, question, allQuestions);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, SimpleQuestion question, List<SimpleQuestion> allQuestions) {
    // Extract question number from ID (e.g., Part6_PRAC_2025_10_13_Q131 -> 131)
    String extractQuestionNumber(String id) {
      final parts = id.split('_');
      if (parts.isNotEmpty) {
        final lastPart = parts.last;
        if (lastPart.startsWith('Q')) {
          return lastPart.substring(1);
        }
      }
      return '?';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9600),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Q${extractQuestionNumber(question.id)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              // Re-take icon button
              IconButton(
                icon: const Icon(Icons.refresh),
                color: const Color(0xFF42A5F5),
                iconSize: 24,
                tooltip: 'Re-take Question',
                onPressed: () => _openReviewScreen(context, question, allQuestions),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark, color: Color(0xFFFF9600)),
                onPressed: () => _removeBookmark(question.id),
                tooltip: 'Remove bookmark',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Question Text
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // Options
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isCorrect = index == question.correctAnswerIndex;
            final optionLetter = String.fromCharCode(65 + index);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCorrect
                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                    : Colors.grey[50],
                border: Border.all(
                  color: isCorrect ? const Color(0xFF4CAF50) : Colors.grey[300]!,
                  width: isCorrect ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCorrect ? const Color(0xFF4CAF50) : Colors.white,
                      border: Border.all(
                        color: isCorrect ? const Color(0xFF4CAF50) : Colors.grey[400]!,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        optionLetter,
                        style: TextStyle(
                          color: isCorrect ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 15,
                        color: isCorrect ? const Color(0xFF2E7D32) : Colors.black87,
                        fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isCorrect)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 24,
                    ),
                ],
              ),
            );
          }),

          // Explanation Section
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 20, color: Color(0xFFFF9600)),
                      SizedBox(width: 8),
                      Text(
                        'Explanation',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    question.explanation,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _removeBookmark(String questionId) async {
    try {
      await ref.read(userDataRepositoryProvider).toggleFavorite(questionId);
      // Refresh the favorites list
      ref.invalidate(favoritesProvider);

      // Clear cached bookmarks to force reload
      setState(() {
        _lastLoadedBookmarks = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark removed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing bookmark: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
