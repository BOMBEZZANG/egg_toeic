import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/learning_session_model.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/core/widgets/question_analytics_widget.dart';
import 'package:egg_toeic/data/models/question_model.dart' as question_model;
import 'package:egg_toeic/core/services/auth_service.dart';

class PracticeDateModeScreen extends ConsumerStatefulWidget {
  final String date;

  const PracticeDateModeScreen({
    super.key,
    required this.date,
  });

  @override
  ConsumerState<PracticeDateModeScreen> createState() =>
      _PracticeDateModeScreenState();
}

class _PracticeDateModeScreenState extends ConsumerState<PracticeDateModeScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _showExplanation = false;
  bool _isAnswered = false;
  
  // Track session progress
  int _correctAnswers = 0;
  late DateTime _sessionStartTime;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initSession();
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

  void _initSession() {
    _sessionStartTime = DateTime.now();
    _sessionId = 'practice_${widget.date}_${_sessionStartTime.millisecondsSinceEpoch}';
    print('🚀 Session started: $_sessionId');
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleAnswerSelection(int index, List<SimpleQuestion> questions) {
    if (_isAnswered) return;

    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = index;
      _isAnswered = true;
    });

    // Update user statistics
    final userRepository = ref.read(userDataRepositoryProvider);
    final currentQuestion = questions[_currentQuestionIndex];
    final isCorrect = index == currentQuestion.correctAnswerIndex;

    // Track correct answers for session
    if (isCorrect) {
      _correctAnswers++;
    }

    userRepository.updateQuestionResult(
      questionId: currentQuestion.id,
      isCorrect: isCorrect,
      answerTime: 30, // TODO: Track actual answer time
      mode: 'practice',
    );

    // Submit analytics data
    _submitAnalyticsData(currentQuestion, index);

    // Save wrong answer with full question data if incorrect
    if (!isCorrect) {
      _saveWrongAnswer(currentQuestion, index);
    }

    print('📝 Question ${_currentQuestionIndex + 1}/${questions.length} answered. Correct: $isCorrect (Total correct: $_correctAnswers)');

    // Save progress after each question
    _saveProgressSession(questions);

    // Auto-show explanation after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showExplanation = true;
        });
      }
    });
  }

  Future<void> _submitAnalyticsData(
      SimpleQuestion currentQuestion, int selectedIndex) async {
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
          difficultyLevel: currentQuestion.difficultyLevel,
        ),
        selectedAnswerIndex: selectedIndex,
        sessionId: 'practice_date_session_${widget.date}_${DateTime.now().millisecondsSinceEpoch}',
        timeSpentSeconds: null, // You can track time if needed
        isFirstAttempt: isFirstAttempt,
      );

      // Analytics are now tracked with Firebase Auth UID
      print('✅ Analytics data submitted for question ${currentQuestion.id}');
    } catch (e) {
      print('❌ Error submitting analytics: $e');
    }
  }

  Future<void> _saveWrongAnswer(
      SimpleQuestion question, int selectedIndex) async {
    try {
      print('🔍 Saving wrong answer for practice date mode:');
      print('  - Question ID: ${question.id}');
      print(
          '  - Selected: $selectedIndex, Correct: ${question.correctAnswerIndex}');

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
    final vocabularyKeywords = [
      'vocabulary',
      'word',
      'meaning',
      'synonym',
      'antonym'
    ];
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

  void _nextQuestion(List<SimpleQuestion> questions) {
    if (_currentQuestionIndex < questions.length - 1) {
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
      _completeSession(questions);
    }
  }

  Future<void> _completeSession(List<SimpleQuestion> questions) async {
    final endTime = DateTime.now();
    
    // Save learning session to track progress
    await _saveLearningSession(questions, endTime);
    
    // Navigate to results or back to selection
    context.pop();

    // Show completion dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 세션 완료!'),
        content: Text(
            '${widget.date} 연습 세션을 완료했습니다!\n총 ${questions.length}문제를 풀었습니다.\n정답: $_correctAnswers/${questions.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveLearningSession(List<SimpleQuestion> questions, DateTime endTime) async {
    try {
      final userRepository = ref.read(userDataRepositoryProvider);

      final learningSession = LearningSession(
        id: _sessionId!,
        sessionType: 'practice',
        startTime: _sessionStartTime,
        endTime: endTime,
        questionsAnswered: questions.length,
        correctAnswers: _correctAnswers,
        questionIds: questions.map((q) => q.id).toList(),
        isCompleted: true,
      );

      await userRepository.saveCompletedSession(learningSession);
      print('✅ Learning session saved: ${learningSession.id}');
      print('   - Date: ${widget.date}');
      print('   - Questions: ${questions.length}');
      print('   - Correct: $_correctAnswers');

      // Force refresh the practice metadata provider
      ref.invalidate(practiceSessionMetadataProvider);

    } catch (e) {
      print('❌ Error saving learning session: $e');
    }
  }
  
  Future<void> _saveProgressSession(List<SimpleQuestion> questions) async {
    try {
      final userRepository = ref.read(userDataRepositoryProvider);
      final currentTime = DateTime.now();
      final questionsAnswered = _currentQuestionIndex + 1;

      final learningSession = LearningSession(
        id: _sessionId!,
        sessionType: 'practice',
        startTime: _sessionStartTime,
        endTime: currentTime,
        questionsAnswered: questionsAnswered,
        correctAnswers: _correctAnswers,
        questionIds: questions.take(questionsAnswered).map((q) => q.id).toList(),
        isCompleted: false,
      );

      await userRepository.saveCompletedSession(learningSession);
      print('💾 Progress saved: $questionsAnswered/${questions.length} questions, $_correctAnswers correct');

      // Force refresh the practice metadata provider
      ref.invalidate(practiceSessionMetadataProvider);

    } catch (e) {
      print('❌ Error saving progress session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync =
        ref.watch(practiceQuestionsByDateProvider(widget.date));

    return questionsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text('Practice - ${widget.date}'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading questions...'),
              ],
            ),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: Text('Practice - ${widget.date}'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 200,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading questions: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(
                        practiceQuestionsByDateProvider(widget.date)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (questions) {
        if (questions.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Practice - ${widget.date}'),
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.free_breakfast,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '해당 날짜는 휴식일!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '이 날짜에는 연습 문제가 없습니다.\n다른 날짜를 선택해 주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '달력으로 돌아가기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Ensure we don't go out of bounds
        if (_currentQuestionIndex >= questions.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _currentQuestionIndex = 0;
              _selectedAnswer = null;
              _showExplanation = false;
              _isAnswered = false;
            });
          });
        }

        final currentQuestion = questions[_currentQuestionIndex];
        final progress = (_currentQuestionIndex + 1) / questions.length;

        // Start animation on first load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_slideController.status == AnimationStatus.dismissed) {
            _slideController.forward();
          }
        });

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
                      '${_currentQuestionIndex + 1}/${questions.length}',
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
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor),
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
                                        color: AppColors.primaryColor
                                            .withOpacity(0.2),
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
                                        final favoritesAsync =
                                            ref.watch(favoritesProvider);

                                        return favoritesAsync.when(
                                          data: (favorites) {
                                            final isBookmarked = favorites
                                                .contains(currentQuestion.id);
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: isBookmarked
                                                    ? AppColors.accentColor
                                                        .withOpacity(0.1)
                                                    : Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: IconButton(
                                                onPressed: () =>
                                                    _toggleBookmark(ref,
                                                        currentQuestion.id),
                                                icon: Icon(
                                                  isBookmarked
                                                      ? Icons.bookmark
                                                      : Icons.bookmark_border,
                                                  color: isBookmarked
                                                      ? AppColors.accentColor
                                                      : AppColors.textSecondary,
                                                  size: 22,
                                                ),
                                                tooltip: isBookmarked
                                                    ? 'Remove from favorites'
                                                    : 'Add to favorites',
                                                constraints:
                                                    const BoxConstraints(
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              ),
                                            ),
                                          ),
                                          error: (_, __) => Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: IconButton(
                                              onPressed: () => _toggleBookmark(
                                                  ref, currentQuestion.id),
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
                          Consumer(
                            builder: (context, ref, child) {
                              final analyticsAsync = ref.watch(questionAnalyticsProvider(currentQuestion.id));

                              return Column(
                                children: List.generate(currentQuestion.options.length, (index) {
                                  final isSelected = _selectedAnswer == index;
                                  final isCorrect = index == currentQuestion.correctAnswerIndex;
                                  final showResult = _isAnswered;

                                  // Get percentage for this option from analytics
                                  double? optionPercentage;
                                  if (showResult && analyticsAsync.hasValue && analyticsAsync.value != null) {
                                    optionPercentage = analyticsAsync.value!.answerPercentages[index.toString()];
                                  }

                            Color getOptionColor() {
                              if (!showResult) {
                                return isSelected
                                    ? AppColors.primaryColor
                                    : Colors.white;
                              }

                              // After answer is submitted
                              if (isCorrect) {
                                return AppColors
                                    .successColor; // Green for correct answer
                              } else if (isSelected && !isCorrect) {
                                return AppColors
                                    .errorColor; // Red for wrong selected answer
                              }
                              return Colors.grey[
                                  50]!; // Very light grey for unselected options (keep them visible)
                            }

                            Color getBorderColor() {
                              if (!showResult) {
                                return isSelected
                                    ? AppColors.primaryColor
                                    : Colors.grey[300]!;
                              }

                              // After answer is submitted
                              if (isCorrect) {
                                return AppColors.successColor;
                              } else if (isSelected && !isCorrect) {
                                return AppColors.errorColor;
                              }
                              return Colors.grey[
                                  300]!; // Light border for unselected options
                            }

                            Color getTextColor() {
                              if (!showResult) {
                                return isSelected
                                    ? Colors.white
                                    : Colors.black87;
                              }

                              // After answer is submitted
                              if (isCorrect || (isSelected && !isCorrect)) {
                                return Colors
                                    .white; // White text on colored backgrounds
                              }
                              return Colors
                                  .black87; // Dark text on light background for unselected options
                            }

                            return GestureDetector(
                              onTap: () =>
                                  _handleAnswerSelection(index, questions),
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
                                      backgroundColor: showResult &&
                                              (isCorrect ||
                                                  (isSelected && !isCorrect))
                                          ? Colors.white
                                          : (isSelected
                                              ? Colors.white
                                              : getBorderColor()),
                                      child: Text(
                                        String.fromCharCode(
                                            65 + index), // A, B, C, D
                                        style: TextStyle(
                                          color: showResult && isCorrect
                                              ? AppColors.successColor
                                              : (showResult &&
                                                      isSelected &&
                                                      !isCorrect)
                                                  ? AppColors.errorColor
                                                  : showResult
                                                      ? Colors.grey[
                                                          600] // Darker grey for unselected after answer
                                                      : (isSelected
                                                          ? AppColors
                                                              .primaryColor
                                                          : Colors.white),
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
                                      const Icon(Icons.check_circle,
                                          color: Colors.white),
                                    if (showResult && isSelected && !isCorrect)
                                      const Icon(Icons.cancel,
                                          color: Colors.white),
                                    // Show percentage when answered and analytics available
                                    if (showResult && optionPercentage != null) ...[
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
                                  );
                                }),
                              );
                            },
                          ),

                          // Explanation
                          if (_showExplanation) ...[
                            const SizedBox(height: 20),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height *
                                    0.4, // Max 40% of screen height
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color:
                                        AppColors.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Analytics Section with offline fallback
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final analyticsAsync = ref.watch(
                                            questionAnalyticsProvider(
                                                currentQuestion.id));

                                        return analyticsAsync.when(
                                          loading: () => Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 12),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.blue.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.blue
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Loading analytics...',
                                                  style:
                                                      TextStyle(fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                          error: (error, stack) => Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 12),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.orange
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.orange
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.cloud_off,
                                                  color: Colors.orange,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Analytics offline',
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          data: (analytics) => analytics != null
                                              ? Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 12),
                                                  child:
                                                      QuestionAnalyticsWidget(
                                                    analytics: analytics,
                                                    isCompact: true,
                                                  ),
                                                )
                                              : Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 12),
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                      color: Colors.grey
                                                          .withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .analytics_outlined,
                                                        color: Colors.grey,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'No data available',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        );
                                      },
                                    ),

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

                                    // Tags row for difficulty level and question type
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        // Difficulty Level Tag
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getDifficultyColor(currentQuestion.difficultyLevel),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Level ${currentQuestion.difficultyLevel}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        // Question Type Tag (inferred from grammar point)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getQuestionTypeColor(_inferQuestionType(currentQuestion.grammarPoint)),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _inferQuestionType(currentQuestion.grammarPoint),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        // Grammar Point/Question Category Tag
                                        if (currentQuestion.grammarPoint?.isNotEmpty == true)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(20),
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

                                        // Additional tags if available
                                        if (currentQuestion.tags?.isNotEmpty == true)
                                          ...currentQuestion.tags!.map((tag) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[600],
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              tag,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )),
                                      ],
                                    ),

                                  ],
                                ),
                                ),
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
                      onPressed: () => _nextQuestion(questions),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentQuestionIndex < questions.length - 1
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
            ));
      },
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

  // Helper method to get color based on difficulty level
  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFF4CAF50); // Green for easy
      case 2:
        return const Color(0xFFFF9800); // Orange for medium
      case 3:
        return const Color(0xFFF44336); // Red for hard
      default:
        return Colors.grey;
    }
  }

  // Helper method to infer question type from grammar point
  String _inferQuestionType(String? grammarPoint) {
    if (grammarPoint == null || grammarPoint.isEmpty) {
      return 'Grammar';
    }

    // Common vocabulary keywords
    const vocabularyKeywords = [
      'vocabulary', 'word', 'meaning', 'synonym', 'antonym',
      'definition', 'phrase', 'idiom', 'expression'
    ];

    final lowerGrammarPoint = grammarPoint.toLowerCase();
    for (final keyword in vocabularyKeywords) {
      if (lowerGrammarPoint.contains(keyword)) {
        return 'Vocabulary';
      }
    }

    return 'Grammar';
  }

  // Helper method to get color based on question type
  Color _getQuestionTypeColor(String questionType) {
    switch (questionType.toLowerCase()) {
      case 'vocabulary':
        return const Color(0xFF9C27B0); // Purple for vocabulary
      case 'grammar':
        return const Color(0xFF2196F3); // Blue for grammar
      default:
        return const Color(0xFF607D8B); // Blue-grey for unknown
    }
  }
}
