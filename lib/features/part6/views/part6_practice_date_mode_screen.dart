import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/learning_session_model.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/data/models/question_model.dart' as question_model;
import 'package:egg_toeic/core/services/auth_service.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';

class Part6PracticeDateModeScreen extends ConsumerStatefulWidget {
  final String date;

  const Part6PracticeDateModeScreen({
    super.key,
    required this.date,
  });

  @override
  ConsumerState<Part6PracticeDateModeScreen> createState() =>
      _Part6PracticeDateModeScreenState();
}

class _Part6PracticeDateModeScreenState
    extends ConsumerState<Part6PracticeDateModeScreen> {
  List<SimpleQuestion> _allQuestions = [];
  List<List<SimpleQuestion>> _passageGroups = [];
  int _currentPassageIndex = 0;
  Map<String, int> _userAnswers = {}; // questionId -> answer index

  bool _isLoading = true;
  String? _errorMessage;
  bool _isCompleted = false; // Track if session is completed

  // Track session progress
  int _correctAnswers = 0;
  late DateTime _sessionStartTime;
  String? _sessionId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initSession();
    _loadQuestions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initSession() {
    _sessionStartTime = DateTime.now();
    _sessionId = 'part6_practice_${widget.date}_${_sessionStartTime.millisecondsSinceEpoch}';
    print('🚀 Part6 Practice Session started: $_sessionId');
  }

  Future<void> _loadQuestions() async {
    try {
      print('🔄 Loading Part6 practice questions for date: ${widget.date}');

      final questionRepository = ref.read(questionRepositoryProvider);
      final questions = await questionRepository.getPart6PracticeQuestionsByDate(widget.date);

      print('✅ Loaded ${questions.length} Part6 practice questions');

      if (questions.isEmpty) {
        print('⚠️ No Part6 practice questions found for date: ${widget.date}');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _allQuestions = [];
            _passageGroups = [];
          });
        }
        return;
      }

      // Group questions by passage
      final passageGroups = _groupQuestionsByPassage(questions);
      print('📚 Grouped into ${passageGroups.length} passages');

      if (mounted) {
        setState(() {
          _allQuestions = questions;
          _passageGroups = passageGroups;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('❌ Error loading Part6 practice questions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load questions: $e';
        });
      }
    }
  }

  // Group questions by passage (every 4 questions share the same passageText)
  List<List<SimpleQuestion>> _groupQuestionsByPassage(List<SimpleQuestion> questions) {
    final groups = <List<SimpleQuestion>>[];
    final Map<String, List<SimpleQuestion>> passageMap = {};

    for (final question in questions) {
      final passageKey = question.passageText ?? 'default';
      passageMap.putIfAbsent(passageKey, () => []);
      passageMap[passageKey]!.add(question);
    }

    for (final group in passageMap.values) {
      group.sort((a, b) {
        final aNum = _extractQuestionNumber(a.id);
        final bNum = _extractQuestionNumber(b.id);
        return aNum.compareTo(bNum);
      });
      groups.add(group);
    }

    return groups;
  }

  int _extractQuestionNumber(String questionId) {
    try {
      final parts = questionId.split('_');
      for (final part in parts) {
        if (part.startsWith('Q') && part.length > 1) {
          return int.tryParse(part.substring(1)) ?? 0;
        }
      }
    } catch (e) {
      print('Error extracting question number from $questionId: $e');
    }
    return 0;
  }

  void _selectAnswer(String questionId, int answerIndex) {
    // Don't allow answer changes after completion
    if (_isCompleted) return;

    HapticFeedback.lightImpact();
    setState(() {
      _userAnswers[questionId] = answerIndex;
    });

    // Submit analytics for this answer
    _submitAnswerAnalytics(questionId, answerIndex);

    // Check if correct and track
    final question = _allQuestions.firstWhere((q) => q.id == questionId);
    final isCorrect = answerIndex == question.correctAnswerIndex;

    if (isCorrect) {
      _correctAnswers++;
    } else {
      // Save wrong answer
      _saveWrongAnswer(question, answerIndex);
    }

    // Save progress after each question
    _saveProgressSession();

    print('📝 Part6 Question answered. Correct: $isCorrect (Total correct: $_correctAnswers)');
  }

  Future<void> _submitAnswerAnalytics(String questionId, int selectedAnswerIndex) async {
    try {
      final question = _allQuestions.firstWhere((q) => q.id == questionId);
      final authService = AuthService();
      final userId = authService.currentUserId;

      final analyticsRepo = ref.read(analyticsRepositoryProvider);
      await analyticsRepo.submitAnswer(
        userId: userId,
        question: question_model.Question(
          id: question.id,
          questionText: question.questionText,
          options: question.options,
          correctAnswerIndex: question.correctAnswerIndex,
          explanation: question.explanation,
          grammarPoint: question.grammarPoint,
          difficultyLevel: question.difficultyLevel,
        ),
        selectedAnswerIndex: selectedAnswerIndex,
        sessionId: 'part6_practice_${widget.date}_${DateTime.now().millisecondsSinceEpoch}',
        timeSpentSeconds: null,
        metadata: {
          'date': widget.date,
          'part': 'part6',
          'questionNumber': _extractQuestionNumber(questionId),
        },
        isFirstAttempt: true,
      );

      print('✅ Part6 analytics submitted for question ${question.id}');
    } catch (e) {
      print('❌ Error submitting Part6 analytics: $e');
    }
  }

  Future<void> _saveWrongAnswer(SimpleQuestion question, int selectedIndex) async {
    try {
      final wrongAnswer = WrongAnswer.create(
        questionId: question.id,
        selectedAnswerIndex: selectedIndex,
        correctAnswerIndex: question.correctAnswerIndex,
        grammarPoint: 'Reading Comprehension',
        difficultyLevel: question.difficultyLevel,
        questionText: question.questionText,
        options: question.options,
        modeType: 'practice',
        category: 'reading',
        tags: ['part6', 'reading-comprehension'],
        explanation: question.explanation,
      );

      final repository = ref.read(userDataRepositoryProvider);
      await repository.addWrongAnswer(wrongAnswer);
      ref.invalidate(wrongAnswersProvider);

      print('✅ Part6 wrong answer saved');
    } catch (e) {
      print('❌ Error saving Part6 wrong answer: $e');
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
                Text(isBookmarked ? '북마크에 추가되었습니다! 📚' : '북마크에서 제거되었습니다'),
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
            content: Text('북마크 처리 중 오류가 발생했습니다'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _nextPassage() {
    if (_currentPassageIndex < _passageGroups.length - 1) {
      setState(() {
        _currentPassageIndex++;
      });
      _scrollToTop();
      HapticFeedback.mediumImpact();
    } else {
      _completeSession();
    }
  }

  void _previousPassage() {
    if (_currentPassageIndex > 0) {
      setState(() {
        _currentPassageIndex--;
      });
      _scrollToTop();
      HapticFeedback.mediumImpact();
    }
  }

  void _scrollToTop() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  bool _isPassageComplete() {
    if (_passageGroups.isEmpty) return false;
    final currentQuestions = _passageGroups[_currentPassageIndex];
    for (final question in currentQuestions) {
      if (!_userAnswers.containsKey(question.id)) {
        return false;
      }
    }
    return true;
  }

  int _getTotalAnswered() {
    return _userAnswers.length;
  }

  Future<void> _completeSession() async {
    final endTime = DateTime.now();
    await _saveLearningSession(endTime);

    if (mounted) {
      setState(() {
        _isCompleted = true;
      });

      // Scroll to top to show results
      _scrollToTop();
    }
  }

  Future<void> _saveLearningSession(DateTime endTime) async {
    try {
      final userRepository = ref.read(userDataRepositoryProvider);

      final learningSession = LearningSession(
        id: _sessionId!,
        sessionType: 'part6_practice',
        startTime: _sessionStartTime,
        endTime: endTime,
        questionsAnswered: _allQuestions.length,
        correctAnswers: _correctAnswers,
        questionIds: _allQuestions.map((q) => q.id).toList(),
        isCompleted: true,
      );

      await userRepository.saveCompletedSession(learningSession);
      print('✅ Part6 learning session saved: ${learningSession.id}');

      // Force refresh metadata (both legacy and part-specific)
      ref.invalidate(practiceSessionMetadataProvider);
      ref.invalidate(practiceSessionMetadataByPartProvider(6));
    } catch (e) {
      print('❌ Error saving Part6 learning session: $e');
    }
  }

  Future<void> _saveProgressSession() async {
    try {
      final userRepository = ref.read(userDataRepositoryProvider);
      final currentTime = DateTime.now();
      final questionsAnswered = _userAnswers.length;

      final learningSession = LearningSession(
        id: _sessionId!,
        sessionType: 'part6_practice',
        startTime: _sessionStartTime,
        endTime: currentTime,
        questionsAnswered: questionsAnswered,
        correctAnswers: _correctAnswers,
        questionIds: _userAnswers.keys.toList(),
        isCompleted: false,
      );

      await userRepository.saveCompletedSession(learningSession);
      print('💾 Part6 progress saved: $questionsAnswered/${_allQuestions.length} questions');

      ref.invalidate(practiceSessionMetadataProvider);
    } catch (e) {
      print('❌ Error saving Part6 progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Part 6 Practice - ${widget.date}'),
          backgroundColor: const Color(0xFF42A5F5),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF42A5F5)),
              ),
              SizedBox(height: 16),
              Text('Loading questions...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Part 6 Practice - ${widget.date}'),
          backgroundColor: const Color(0xFF42A5F5),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.construction,
                  size: 80,
                  color: Color(0xFF42A5F5),
                ),
                const SizedBox(height: 24),
                const Text(
                  '준비 중',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF42A5F5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF42A5F5),
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
      );
    }

    if (_passageGroups.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Part 6 Practice - ${widget.date}'),
          backgroundColor: const Color(0xFF42A5F5),
          foregroundColor: Colors.white,
        ),
        body: Center(
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
                    backgroundColor: const Color(0xFF42A5F5),
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
      );
    }

    final currentQuestions = _passageGroups[_currentPassageIndex];
    final passage = currentQuestions.first.passageText ?? 'No passage available';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Part 6 Practice - ${widget.date}'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${_getTotalAnswered()}/${_allQuestions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Passage ${_currentPassageIndex + 1}/${_passageGroups.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF42A5F5),
                      ),
                    ),
                    Text(
                      '${_getTotalAnswered()}/${_allQuestions.length} Answered',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _getTotalAnswered() / _allQuestions.length,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF42A5F5)),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),

          // Scrollable content: Passage + Questions
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Passage card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF42A5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Reading Passage',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          passage,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                        // Show Korean translation after completion
                        if (_isCompleted && currentQuestions.first.passageTextKorean != null &&
                            currentQuestions.first.passageTextKorean!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Divider(thickness: 1.5),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.translate, size: 18, color: const Color(0xFF42A5F5)),
                              const SizedBox(width: 8),
                              const Text(
                                '지문 번역 (Korean Translation)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF42A5F5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF42A5F5).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF42A5F5).withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              currentQuestions.first.passageTextKorean!,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.grey[800],
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Questions
                  ...currentQuestions.asMap().entries.map((entry) {
                    final question = entry.value;
                    final questionNumber = _extractQuestionNumber(question.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildQuestionCard(question, questionNumber),
                    );
                  }).toList(),

                  const SizedBox(height: 80), // Space for bottom buttons
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _isCompleted
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Invalidate providers to refresh home screen
                            ref.invalidate(userProgressProvider);
                            ref.invalidate(practiceSessionMetadataProvider);
                            ref.invalidate(combinedStatisticsProvider);
                            context.go('/');
                          },
                          icon: const Icon(Icons.home),
                          label: const Text('홈으로'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF42A5F5),
                            side: const BorderSide(color: Color(0xFF42A5F5)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/wrong-answers'),
                          icon: const Icon(Icons.quiz),
                          label: const Text('오답 복습'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF42A5F5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/bookmarks'),
                          icon: const Icon(Icons.bookmark),
                          label: const Text('북마크'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF9600),
                            side: const BorderSide(color: Color(0xFFFF9600)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (_currentPassageIndex > 0)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _previousPassage,
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text('Previous'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (_currentPassageIndex > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _currentPassageIndex == _passageGroups.length - 1
                              ? _completeSession
                              : _nextPassage,
                          icon: Icon(
                            _currentPassageIndex == _passageGroups.length - 1
                                ? Icons.check_circle
                                : Icons.arrow_forward,
                            size: 18,
                          ),
                          label: Text(_currentPassageIndex == _passageGroups.length - 1
                              ? 'Finish'
                              : 'Next Passage'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF42A5F5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(SimpleQuestion question, int questionNumber) {
    final selectedAnswer = _userAnswers[question.id];
    final isCorrect = selectedAnswer == question.correctAnswerIndex;

    // Determine border color based on completion state
    Color borderColor;
    if (!_isCompleted) {
      borderColor = selectedAnswer != null
          ? const Color(0xFF42A5F5)
          : const Color(0xFFE0E0E0);
    } else {
      if (selectedAnswer == null) {
        borderColor = Colors.grey;
      } else if (isCorrect) {
        borderColor = AppColors.successColor;
      } else {
        borderColor = AppColors.errorColor;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number and text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isCompleted ? borderColor : const Color(0xFF42A5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              // Bookmark icon
              Consumer(
                builder: (context, ref, child) {
                  final favoritesAsync = ref.watch(favoritesProvider);

                  return favoritesAsync.when(
                    data: (favorites) {
                      final isBookmarked = favorites.contains(question.id);
                      return Container(
                        decoration: BoxDecoration(
                          color: isBookmarked
                              ? const Color(0xFFFF9600).withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () => _toggleBookmark(ref, question.id),
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: isBookmarked
                                ? const Color(0xFFFF9600)
                                : Colors.grey[600],
                            size: 20,
                          ),
                          tooltip: isBookmarked ? '북마크 해제' : '북마크 추가',
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      );
                    },
                    loading: () => Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () => _toggleBookmark(ref, question.id),
                        icon: Icon(
                          Icons.bookmark_border,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  );
                },
              ),
              // Show result icon when completed
              if (_isCompleted) ...[
                const SizedBox(width: 8),
                Icon(
                  selectedAnswer == null
                      ? Icons.remove_circle
                      : (isCorrect ? Icons.check_circle : Icons.cancel),
                  color: borderColor,
                  size: 24,
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Options
          ...question.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final optionText = entry.value;
            final isSelected = selectedAnswer == optionIndex;
            final isCorrectOption = optionIndex == question.correctAnswerIndex;
            final optionLetter = String.fromCharCode(65 + optionIndex);

            // Determine option styling based on completion state
            Color optionBorderColor;
            Color optionBgColor;
            IconData? optionIcon;

            if (!_isCompleted) {
              // During practice: show selection state
              optionBorderColor = isSelected ? const Color(0xFF42A5F5) : Colors.grey[300]!;
              optionBgColor = isSelected ? const Color(0xFF42A5F5).withOpacity(0.1) : Colors.grey[50]!;
            } else {
              // After completion: show correct/incorrect
              if (isCorrectOption) {
                optionBorderColor = AppColors.successColor;
                optionBgColor = AppColors.successColor.withOpacity(0.1);
                optionIcon = Icons.check_circle;
              } else if (isSelected && !isCorrectOption) {
                optionBorderColor = AppColors.errorColor;
                optionBgColor = AppColors.errorColor.withOpacity(0.1);
                optionIcon = Icons.cancel;
              } else {
                optionBorderColor = Colors.grey[300]!;
                optionBgColor = Colors.grey[50]!;
              }
            }

            return GestureDetector(
              onTap: () => _selectAnswer(question.id, optionIndex),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: optionBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: optionBorderColor,
                    width: (isSelected || (_isCompleted && isCorrectOption)) ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? optionBorderColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: optionBorderColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          optionLetter,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        optionText,
                        style: TextStyle(
                          fontSize: 14,
                          color: _isCompleted && isCorrectOption
                              ? AppColors.successColor
                              : (isSelected ? Colors.black87 : Colors.black54),
                          fontWeight: (isSelected || (_isCompleted && isCorrectOption))
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_isCompleted && optionIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        optionIcon,
                        color: optionBorderColor,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),

          // Show explanation and analytics after completion
          if (_isCompleted) ...[
            const SizedBox(height: 16),

            // Explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF42A5F5).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: const Color(0xFF42A5F5)),
                      const SizedBox(width: 4),
                      const Text(
                        '해설',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF42A5F5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.explanation,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Analytics - Other users' selections
            Consumer(
              builder: (context, ref, child) {
                final analyticsAsync = ref.watch(questionAnalyticsProvider(question.id));

                return analyticsAsync.when(
                  loading: () => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('답변 통계 로딩 중...', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  error: (error, stack) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '답변 통계를 불러올 수 없습니다',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  data: (analytics) {
                    if (analytics == null || analytics.answerPercentages.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '아직 답변 통계가 없습니다',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '다른 사용자들의 선택',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: analytics.correctPercentage >= 70
                                      ? AppColors.successColor.withOpacity(0.1)
                                      : analytics.correctPercentage >= 50
                                          ? Colors.orange.withOpacity(0.1)
                                          : AppColors.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '정답률 ${analytics.correctPercentage.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: analytics.correctPercentage >= 70
                                        ? AppColors.successColor
                                        : analytics.correctPercentage >= 50
                                            ? Colors.orange
                                            : AppColors.errorColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(question.options.length, (optionIndex) {
                            final percentage = analytics.answerPercentages[optionIndex.toString()] ?? 0.0;
                            final isUserSelected = selectedAnswer == optionIndex;
                            final isCorrectOption = optionIndex == question.correctAnswerIndex;

                            Color barColor = Colors.grey[400]!;
                            if (isCorrectOption) {
                              barColor = AppColors.successColor;
                            } else if (isUserSelected && !isCorrectOption) {
                              barColor = AppColors.errorColor;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isUserSelected ? barColor : Colors.transparent,
                                      border: Border.all(color: barColor),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + optionIndex),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isUserSelected ? Colors.white : barColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: FractionallySizedBox(
                                        widthFactor: percentage / 100,
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: barColor.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 45,
                                    child: Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: barColor,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  if (isUserSelected) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.person,
                                      size: 14,
                                      color: barColor,
                                    ),
                                  ],
                                  if (isCorrectOption) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: AppColors.successColor,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
