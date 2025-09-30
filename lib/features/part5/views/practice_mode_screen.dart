import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/core/widgets/question_analytics_widget.dart';
import 'package:egg_toeic/data/models/question_model.dart' as question_model;
import 'package:egg_toeic/core/services/auth_service.dart';
import 'package:egg_toeic/core/widgets/custom_app_bar.dart';

class PracticeModeScreen extends ConsumerStatefulWidget {
  final int difficultyLevel;

  const PracticeModeScreen({
    super.key,
    required this.difficultyLevel,
  });

  @override
  ConsumerState<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends ConsumerState<PracticeModeScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _showExplanation = false;
  bool _isAnswered = false;
  List<SimpleQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadQuestions();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  void _loadQuestions() async {
    try {
      print(
          'Loading questions for difficulty level: ${widget.difficultyLevel}');
      final questionRepo = ref.read(questionRepositoryProvider);
      final questions = await questionRepo.getQuestions(
        difficultyLevel: widget.difficultyLevel,
        limit: 10,
        mode: 'practice', // Add mode parameter for practice mode
      );
      print('Loaded ${questions.length} questions');
      if (questions.isEmpty) {
        print(
            'No questions found for difficulty level ${widget.difficultyLevel}');
      }
      setState(() {
        _questions = questions;
      });
    } catch (e) {
      // Handle error
      print('Error loading questions: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Level ${widget.difficultyLevel} Practice',
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _showExitDialog(context);
          if (shouldPop && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              // Progress Header
              _buildProgressHeader(context),

              // Question Card
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildQuestionCard(context, currentQuestion),
                  ),
                ),
              ),

              // Action Buttons
              _buildActionButtons(context, currentQuestion),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(BuildContext context) {
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bookmark icon
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final question = _questions[_currentQuestionIndex];
                        final favoritesAsync = ref.watch(favoritesProvider);

                        return favoritesAsync.when(
                          data: (favorites) {
                            final isBookmarked =
                                favorites.contains(question.id);
                            return IconButton(
                              onPressed: () =>
                                  _toggleBookmark(ref, question.id),
                              icon: Icon(
                                isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isBookmarked
                                    ? AppColors.accentColor
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              tooltip: isBookmarked ? '즐겨찾기 해제' : '즐겨찾기 추가',
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            );
                          },
                          loading: () => const SizedBox(
                            width: 32,
                            height: 32,
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          error: (_, __) => IconButton(
                            onPressed: () => _toggleBookmark(ref, question.id),
                            icon: Icon(
                              Icons.bookmark_border,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Level ${widget.difficultyLevel}',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, SimpleQuestion question) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Number, Grammar Point & Bookmark
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Q${_currentQuestionIndex + 1}',
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    question.grammarPoint,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.grey[200],
                ),
                const Spacer(),
                // Bookmark icon in question card
                Consumer(
                  builder: (context, ref, child) {
                    final favoritesAsync = ref.watch(favoritesProvider);

                    return favoritesAsync.when(
                      data: (favorites) {
                        final isBookmarked = favorites.contains(question.id);
                        return Container(
                          decoration: BoxDecoration(
                            color: isBookmarked
                                ? AppColors.accentColor.withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => _toggleBookmark(ref, question.id),
                            icon: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isBookmarked
                                  ? AppColors.accentColor
                                  : AppColors.textSecondary,
                              size: 24,
                            ),
                            tooltip: isBookmarked ? 'Remove from favorites' : 'Add to favorites',
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                          ),
                        );
                      },
                      loading: () => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, __) => Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => _toggleBookmark(ref, question.id),
                          icon: Icon(
                            Icons.bookmark_border,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Question Text
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Answer Options
            Consumer(
              builder: (context, ref, child) {
                final analyticsAsync = ref.watch(questionAnalyticsProvider(question.id));

                return Column(
                  children: List.generate(
                    question.options.length,
                    (index) {
                      // Get percentage for this option from analytics
                      double? optionPercentage;
                      if (_isAnswered && analyticsAsync.hasValue && analyticsAsync.value != null) {
                        optionPercentage = analyticsAsync.value!.answerPercentages[index.toString()];
                      }

                      return _buildOptionButton(
                        context,
                        option: question.options[index],
                        index: index,
                        isSelected: _selectedAnswer == index,
                        isCorrect: index == question.correctAnswerIndex,
                        isAnswered: _isAnswered,
                        optionPercentage: optionPercentage,
                        onTap: !_isAnswered ? () => _selectAnswer(index) : null,
                      );
                    },
                  ),
                );
              },
            ),

            // Explanation Section
            if (_isAnswered && _showExplanation) ...[
              const SizedBox(height: 24),

              // Analytics Section
              Consumer(
                builder: (context, ref, child) {
                  final analyticsAsync = ref.watch(questionAnalyticsProvider(question.id));

                  return analyticsAsync.when(
                    loading: () => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text('Loading analytics...'),
                        ],
                      ),
                    ),
                    error: (error, stack) => const SizedBox.shrink(),
                    data: (analytics) => analytics != null
                        ? Column(
                            children: [
                              QuestionAnalyticsWidget(
                                analytics: analytics,
                                isCompact: false,
                              ),
                              const SizedBox(height: 16),
                            ],
                          )
                        : const SizedBox.shrink(),
                  );
                },
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Explanation',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      question.explanation,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Useful Tags Section
                    _buildUsefulTags(question),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required String option,
    required int index,
    required bool isSelected,
    required bool isCorrect,
    required bool isAnswered,
    double? optionPercentage,
    VoidCallback? onTap,
  }) {
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    Color textColor = Colors.black87;
    IconData? icon;

    if (isAnswered) {
      if (isCorrect) {
        backgroundColor = AppColors.successColor.withOpacity(0.1);
        borderColor = AppColors.successColor;
        textColor = AppColors.successColor;
        icon = Icons.check_circle;
      } else if (isSelected) {
        backgroundColor = AppColors.errorColor.withOpacity(0.1);
        borderColor = AppColors.errorColor;
        textColor = AppColors.errorColor;
        icon = Icons.cancel;
      }
    } else if (isSelected) {
      backgroundColor = AppColors.primaryColor.withOpacity(0.1);
      borderColor = AppColors.primaryColor;
      textColor = AppColors.primaryColor;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected || (isAnswered && isCorrect) ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: TextStyle(
                      color: textColor,
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
                    color: textColor,
                    fontSize: 16,
                    fontWeight: isSelected || (isAnswered && isCorrect)
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  color:
                      isCorrect ? AppColors.successColor : AppColors.errorColor,
                  size: 24,
                ),
              // Show percentage when answered and analytics available
              if (isAnswered && optionPercentage != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    '${optionPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCorrect
                        ? AppColors.successColor
                        : AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SimpleQuestion question) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_isAnswered) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showExplanation = !_showExplanation;
                  });
                },
                icon: Icon(_showExplanation
                    ? Icons.visibility_off
                    : Icons.lightbulb_outline),
                label: Text(
                    _showExplanation ? 'Hide Explanation' : 'Show Explanation'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _nextQuestion,
                icon: const Icon(Icons.arrow_forward),
                label: Text(_currentQuestionIndex < _questions.length - 1
                    ? 'Next'
                    : 'Finish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedAnswer != null ? _submitAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit Answer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _selectAnswer(int index) {
    setState(() {
      _selectedAnswer = index;
    });
    HapticFeedback.lightImpact();
  }

  void _submitAnswer() async {
    if (_selectedAnswer == null) return;

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = _selectedAnswer == currentQuestion.correctAnswerIndex;

    setState(() {
      _isAnswered = true;
    });

    // Submit analytics data
    try {
      // Get user ID from AuthService
      final authService = AuthService();
      final userId = authService.currentUserId;

      // For practice mode, consider all attempts (analytics will handle first attempt tracking)
      final isFirstAttempt = true;

      final analyticsRepo = ref.read(analyticsRepositoryProvider);
      await analyticsRepo.submitAnswer(
        userId: userId,
        question: question_model.Question(
          id: currentQuestion.id,
          questionText: currentQuestion.questionText,
          options: currentQuestion.options,
          correctAnswerIndex: currentQuestion.correctAnswerIndex,
          explanation: currentQuestion.explanation,
          grammarPoint: currentQuestion.grammarPoint,
          difficultyLevel: widget.difficultyLevel,
        ),
        selectedAnswerIndex: _selectedAnswer!,
        sessionId: 'practice_session_${DateTime.now().millisecondsSinceEpoch}',
        timeSpentSeconds: null, // You can track time if needed
        isFirstAttempt: isFirstAttempt,
      );

      // Analytics are now tracked with Firebase Auth UID
      print('✅ Analytics data submitted for question ${currentQuestion.id}');
    } catch (e) {
      print('❌ Error submitting analytics: $e');
    }

    // Show feedback haptic
    if (isCorrect) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();

      // Save wrong answer with full question data
      await _saveWrongAnswer(currentQuestion);
    }
  }

  void _toggleBookmark(WidgetRef ref, String questionId) async {
    try {
      await ref.read(userDataRepositoryProvider).toggleFavorite(questionId);

      // Refresh favorites provider
      ref.invalidate(favoritesProvider);

      if (mounted) {
        final isBookmarked =
            await ref.read(userDataRepositoryProvider).isFavorite(questionId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isBookmarked ? '즐겨찾기에 추가되었습니다! 📚' : '즐겨찾기에서 제거되었습니다'),
            backgroundColor:
                isBookmarked ? AppColors.successColor : AppColors.textSecondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('즐겨찾기 처리 중 오류가 발생했습니다'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveWrongAnswer(SimpleQuestion question) async {
    try {
      print(
          '🔍 Saving wrong answer for level ${widget.difficultyLevel} question:');
      print('  - Question ID: ${question.id}');
      print(
          '  - Question Text: "${question.questionText}" (length: ${question.questionText.length})');
      print(
          '  - Options: ${question.options} (count: ${question.options.length})');
      print('  - Grammar Point: "${question.grammarPoint}"');

      final wrongAnswer = WrongAnswer.create(
        questionId: question.id,
        selectedAnswerIndex: _selectedAnswer!,
        correctAnswerIndex: question.correctAnswerIndex,
        grammarPoint: question.grammarPoint,
        difficultyLevel: widget.difficultyLevel,
        questionText: question.questionText,
        options: question.options,
        modeType: 'practice',
        category: _getCategoryFromGrammarPoint(question.grammarPoint),
        tags: _extractTagsFromGrammarPoint(question.grammarPoint),
        explanation: question.explanation,
      );

      print('  ✅ BEFORE SAVE: WrongAnswer data:');
      print(
          '    - questionText: "${wrongAnswer.questionText}" (null: ${wrongAnswer.questionText == null})');
      print(
          '    - options: ${wrongAnswer.options} (null: ${wrongAnswer.options == null})');

      final repository = ref.read(userDataRepositoryProvider);
      await repository.addWrongAnswer(wrongAnswer);

      // Refresh wrong answers provider
      ref.invalidate(wrongAnswersProvider);
    } catch (e) {
      print('Error saving wrong answer: $e');
    }
  }

  String _getCategoryFromGrammarPoint(String grammarPoint) {
    // Simple categorization logic - you can enhance this
    final vocabularyKeywords = [
      'vocabulary',
      'word',
      'meaning',
      'synonym',
      'antonym'
    ];
    final grammarKeywords = [
      'tense',
      'verb',
      'noun',
      'adjective',
      'adverb',
      'preposition',
      'conjunction',
      'article'
    ];

    final lowerPoint = grammarPoint.toLowerCase();

    if (vocabularyKeywords.any((keyword) => lowerPoint.contains(keyword))) {
      return 'vocabulary';
    } else if (grammarKeywords.any((keyword) => lowerPoint.contains(keyword))) {
      return 'grammar';
    } else {
      return 'grammar'; // default to grammar
    }
  }

  List<String> _extractTagsFromGrammarPoint(String grammarPoint) {
    // Extract meaningful tags from grammar point
    final tags = <String>[];
    final words = grammarPoint.toLowerCase().split(' ');

    for (String word in words) {
      if (word.length > 3 && !['and', 'the', 'with', 'for'].contains(word)) {
        tags.add(word);
      }
    }

    return tags.take(3).toList(); // Limit to 3 tags
  }

  Widget _buildUsefulTags(SimpleQuestion question) {
    final tags = _extractTagsFromGrammarPoint(question.grammarPoint);

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Topics:',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
        _showExplanation = false;
      });

      _slideController.forward(from: 0);
    } else {
      // Session complete
      _showSessionCompleteDialog();
    }
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Practice?'),
            content: const Text('Your progress will be lost if you exit now.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSessionCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Complete!'),
        content: const Text(
            'Congratulations! You have completed this practice session.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/part5');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}
