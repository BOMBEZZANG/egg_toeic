import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/providers/repository_providers.dart';

class PracticeDateModeScreen extends ConsumerStatefulWidget {
  final String date;

  const PracticeDateModeScreen({
    super.key,
    required this.date,
  });

  @override
  ConsumerState<PracticeDateModeScreen> createState() => _PracticeDateModeScreenState();
}

class _PracticeDateModeScreenState extends ConsumerState<PracticeDateModeScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _showExplanation = false;
  bool _isAnswered = false;
  List<SimpleQuestion> _questions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadQuestionsForDate();
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
  }

  Future<void> _loadQuestionsForDate() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔍 Loading questions for date: ${widget.date}');

      final questionRepo = ref.read(questionRepositoryProvider);
      final questions = await questionRepo.getPracticeQuestionsByDate(widget.date);

      if (questions.isEmpty) {
        setState(() {
          _error = 'No questions found for date ${widget.date}';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _questions = questions;
        _isLoading = false;
      });

      print('✅ Loaded ${questions.length} questions for date ${widget.date}');
      _slideController.forward();

    } catch (e) {
      print('❌ Error loading questions for date ${widget.date}: $e');
      setState(() {
        _error = 'Error loading questions: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleAnswerSelection(int index) {
    if (_isAnswered) return;

    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = index;
      _isAnswered = true;
    });

    // Update user statistics
    final userRepository = ref.read(userDataRepositoryProvider);
    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = index == currentQuestion.correctAnswerIndex;

    userRepository.updateQuestionResult(
      questionId: currentQuestion.id,
      isCorrect: isCorrect,
      answerTime: 30, // TODO: Track actual answer time
      mode: 'practice',
    );

    // Save wrong answer with full question data if incorrect
    if (!isCorrect) {
      _saveWrongAnswer(currentQuestion, index);
    }

    // Auto-show explanation after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showExplanation = true;
        });
      }
    });
  }

  Future<void> _saveWrongAnswer(SimpleQuestion question, int selectedIndex) async {
    try {
      print('🔍 Saving wrong answer for practice date mode:');
      print('  - Question ID: ${question.id}');
      print('  - Selected: $selectedIndex, Correct: ${question.correctAnswerIndex}');

      final wrongAnswer = WrongAnswer.create(
        questionId: question.id,
        selectedAnswerIndex: selectedIndex,
        correctAnswerIndex: question.correctAnswerIndex,
        grammarPoint: question.grammarPoint,
        difficultyLevel: question.difficultyLevel,
        questionText: question.questionText,
        options: question.options,
        modeType: 'practice',
        category: _getCategoryFromGrammarPoint(question.grammarPoint),
        tags: _extractTagsFromGrammarPoint(question.grammarPoint),
        explanation: question.explanation,
      );

      final repository = ref.read(userDataRepositoryProvider);
      await repository.addWrongAnswer(wrongAnswer);

      // Refresh wrong answers provider
      ref.invalidate(wrongAnswersProvider);

      print('  ✅ Wrong answer saved successfully');
    } catch (e) {
      print('❌ Error saving wrong answer: $e');
    }
  }

  String _getCategoryFromGrammarPoint(String grammarPoint) {
    final vocabularyKeywords = ['vocabulary', 'word', 'meaning', 'synonym', 'antonym'];
    final lowerPoint = grammarPoint.toLowerCase();

    if (vocabularyKeywords.any((keyword) => lowerPoint.contains(keyword))) {
      return 'vocabulary';
    }
    return 'grammar';
  }

  List<String> _extractTagsFromGrammarPoint(String grammarPoint) {
    final tags = <String>[];
    final lowerPoint = grammarPoint.toLowerCase();

    if (lowerPoint.contains('tense')) tags.add('tense');
    if (lowerPoint.contains('passive')) tags.add('passive-voice');
    if (lowerPoint.contains('conditional')) tags.add('conditional');
    if (lowerPoint.contains('preposition')) tags.add('prepositions');
    if (lowerPoint.contains('business')) tags.add('business');

    return tags;
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _showExplanation = false;
        _isAnswered = false;
      });

      // Trigger slide animation
      _slideController.reset();
      _slideController.forward();

      HapticFeedback.mediumImpact();
    } else {
      _completeSession();
    }
  }

  void _completeSession() {
    // Navigate to results or back to selection
    context.pop();

    // Show completion dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 세션 완료!'),
        content: Text('${widget.date} 연습 세션을 완료했습니다!\n총 ${_questions.length}문제를 풀었습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Practice - ${widget.date}'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading questions...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Practice - ${widget.date}'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuestionsForDate,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Practice - ${widget.date}'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No questions available for this date.'),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Practice - ${widget.date}'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            minHeight: 6,
          ),

          // Question content
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question text with bookmark
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with question number and bookmark
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
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Bookmark icon in question card
                              Consumer(
                                builder: (context, ref, child) {
                                  final favoritesAsync = ref.watch(favoritesProvider);

                                  return favoritesAsync.when(
                                    data: (favorites) {
                                      final isBookmarked = favorites.contains(currentQuestion.id);
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: isBookmarked
                                              ? AppColors.accentColor.withOpacity(0.1)
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: IconButton(
                                          onPressed: () => _toggleBookmark(ref, currentQuestion.id),
                                          icon: Icon(
                                            isBookmarked
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                            color: isBookmarked
                                                ? AppColors.accentColor
                                                : AppColors.textSecondary,
                                            size: 22,
                                          ),
                                          tooltip: isBookmarked ? 'Remove from favorites' : 'Add to favorites',
                                          constraints: const BoxConstraints(
                                            minWidth: 40,
                                            minHeight: 40,
                                          ),
                                        ),
                                      );
                                    },
                                    loading: () => Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
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
                                        onPressed: () => _toggleBookmark(ref, currentQuestion.id),
                                        icon: Icon(
                                          Icons.bookmark_border,
                                          color: AppColors.textSecondary,
                                          size: 22,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Question text
                          Text(
                            currentQuestion.questionText,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Answer options
                    ...List.generate(currentQuestion.options.length, (index) {
                      final isSelected = _selectedAnswer == index;
                      final isCorrect = index == currentQuestion.correctAnswerIndex;
                      final showResult = _isAnswered;

                      Color getOptionColor() {
                        if (!showResult) {
                          return isSelected ? AppColors.primaryColor : Colors.white;
                        }

                        // After answer is submitted
                        if (isCorrect) {
                          return AppColors.successColor; // Green for correct answer
                        } else if (isSelected && !isCorrect) {
                          return AppColors.errorColor; // Red for wrong selected answer
                        }
                        return Colors.grey[50]!; // Very light grey for unselected options (keep them visible)
                      }

                      Color getBorderColor() {
                        if (!showResult) {
                          return isSelected ? AppColors.primaryColor : Colors.grey[300]!;
                        }

                        // After answer is submitted
                        if (isCorrect) {
                          return AppColors.successColor;
                        } else if (isSelected && !isCorrect) {
                          return AppColors.errorColor;
                        }
                        return Colors.grey[300]!; // Light border for unselected options
                      }

                      Color getTextColor() {
                        if (!showResult) {
                          return isSelected ? Colors.white : Colors.black87;
                        }

                        // After answer is submitted
                        if (isCorrect || (isSelected && !isCorrect)) {
                          return Colors.white; // White text on colored backgrounds
                        }
                        return Colors.black87; // Dark text on light background for unselected options
                      }

                      return GestureDetector(
                        onTap: () => _handleAnswerSelection(index),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: getOptionColor(),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: getBorderColor(),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: getBorderColor().withOpacity(0.2),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: showResult && (isCorrect || (isSelected && !isCorrect))
                                    ? Colors.white
                                    : (isSelected ? Colors.white : getBorderColor()),
                                child: Text(
                                  String.fromCharCode(65 + index), // A, B, C, D
                                  style: TextStyle(
                                    color: showResult && isCorrect
                                        ? AppColors.successColor
                                        : (showResult && isSelected && !isCorrect)
                                            ? AppColors.errorColor
                                            : showResult
                                                ? Colors.grey[600] // Darker grey for unselected after answer
                                                : (isSelected ? AppColors.primaryColor : Colors.white),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  currentQuestion.options[index],
                                  style: TextStyle(
                                    color: getTextColor(),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (showResult && isCorrect)
                                const Icon(Icons.check_circle, color: Colors.white),
                              if (showResult && isSelected && !isCorrect)
                                const Icon(Icons.cancel, color: Colors.white),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Explanation
                    if (_showExplanation) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
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
                                  Icons.lightbulb,
                                  color: AppColors.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Explanation',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentQuestion.explanation,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            if (currentQuestion.grammarPoint?.isNotEmpty == true) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  currentQuestion.grammarPoint!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Next button
          if (_showExplanation)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentQuestionIndex < _questions.length - 1
                      ? 'Next Question'
                      : 'Complete Session',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
            content: Text(isBookmarked ? '즐겨찾기에 추가되었습니다! 📚' : '즐겨찾기에서 제거되었습니다'),
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
}