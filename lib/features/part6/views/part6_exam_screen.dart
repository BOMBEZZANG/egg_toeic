import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/exam_result_model.dart';
import 'package:egg_toeic/data/models/question_model.dart' as question_model;
import 'package:egg_toeic/core/services/auth_service.dart';

class Part6ExamScreen extends ConsumerStatefulWidget {
  final String round;

  const Part6ExamScreen({super.key, required this.round});

  @override
  ConsumerState<Part6ExamScreen> createState() => _Part6ExamScreenState();
}

class _Part6ExamScreenState extends ConsumerState<Part6ExamScreen> {
  List<SimpleQuestion> _allQuestions = [];
  List<List<SimpleQuestion>> _passageGroups = []; // Groups of 4 questions per passage
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPassageIndex = 0;
  Map<String, int> _userAnswers = {}; // questionId -> answer index
  DateTime? _examStartTime;
  bool _isFinishing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final questionRepo = ref.read(questionRepositoryProvider);
      final questions =
          await questionRepo.getPart6ExamQuestionsByRound(widget.round);

      if (mounted) {
        setState(() {
          _allQuestions = questions;
          _passageGroups = _groupQuestionsByPassage(questions);
          _isLoading = false;
          _examStartTime = DateTime.now();
        });

        print('✅ Loaded ${_allQuestions.length} Part6 questions in ${_passageGroups.length} passages');

        // Start exam session
        _startExamSession();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load questions: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Group questions by passage (every 4 questions share the same passageText)
  List<List<SimpleQuestion>> _groupQuestionsByPassage(List<SimpleQuestion> questions) {
    final groups = <List<SimpleQuestion>>[];
    final Map<String, List<SimpleQuestion>> passageMap = {};

    // Group questions by passage text
    for (final question in questions) {
      final passageKey = question.passageText ?? 'default';
      passageMap.putIfAbsent(passageKey, () => []);
      passageMap[passageKey]!.add(question);
    }

    // Convert map to list and sort each group by question number
    for (final group in passageMap.values) {
      group.sort((a, b) {
        // Extract question numbers from IDs (e.g., Part6_EXAM_T1_P6_Q131)
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

  void _selectAnswer(String questionId, int answerIndex) async {
    setState(() {
      _userAnswers[questionId] = answerIndex;
    });

    // Submit analytics for this answer
    await _submitAnswerAnalytics(questionId, answerIndex);
  }

  // Submit user answer analytics to Firebase
  Future<void> _submitAnswerAnalytics(String questionId, int selectedAnswerIndex) async {
    try {
      final question = _allQuestions.firstWhere((q) => q.id == questionId);

      // Get user ID from AuthService
      final authService = AuthService();
      final userId = authService.currentUserId;

      // For exam mode, always consider as first attempt per session
      final isFirstAttempt = true;

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
        sessionId: 'part6_exam_${widget.round}_${DateTime.now().millisecondsSinceEpoch}',
        timeSpentSeconds: null,
        metadata: {
          'examRound': widget.round,
          'part': 'part6',
          'questionNumber': _extractQuestionNumber(questionId),
        },
        isFirstAttempt: isFirstAttempt,
      );

      print('✅ Submitted analytics for Part6 exam question ${question.id}');
    } catch (e) {
      print('❌ Error submitting answer analytics: $e');
      // Don't block the user experience if analytics fail
    }
  }

  // Start exam learning session
  Future<void> _startExamSession() async {
    try {
      final userDataRepo = ref.read(userDataRepositoryProvider);

      // Create a custom session with round information
      await userDataRepo.startNewSession(sessionType: 'exam');

      // Add the round information to the session
      await userDataRepo.updateCurrentSession(
        questionId: 'PART6_EXAM_${widget.round}_START',
      );

      print('✅ Started Part6 exam session for ${widget.round}');
    } catch (e) {
      print('❌ Error starting Part6 exam session: $e');
    }
  }

  // End exam learning session with completion status
  Future<void> _endExamSession() async {
    try {
      final userDataRepo = ref.read(userDataRepositoryProvider);

      // Calculate correct answers
      int correctAnswers = 0;
      for (final question in _allQuestions) {
        final userAnswer = _userAnswers[question.id];
        if (userAnswer == question.correctAnswerIndex) {
          correctAnswers++;
        }
      }

      // Update session with completion data
      await userDataRepo.updateCurrentSession(
        questionsAnswered: _allQuestions.length,
        correctAnswers: correctAnswers,
      );

      // End the session as completed
      await userDataRepo.endCurrentSession();

      print('✅ Ended Part6 exam session for ${widget.round} - $correctAnswers/${_allQuestions.length} correct');
    } catch (e) {
      print('❌ Error ending Part6 exam session: $e');
    }
  }

  void _nextPassage() {
    if (_currentPassageIndex < _passageGroups.length - 1) {
      setState(() {
        _currentPassageIndex++;
      });
      // Scroll to top to show the new passage
      _scrollToTop();
    }
  }

  void _previousPassage() {
    if (_currentPassageIndex > 0) {
      setState(() {
        _currentPassageIndex--;
      });
      // Scroll to top to show the new passage
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    // Use a small delay to ensure the UI has updated before scrolling
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

  // Save wrong answers for review (with duplicate prevention)
  Future<void> _saveWrongAnswers() async {
    final userDataRepo = ref.read(userDataRepositoryProvider);

    // Get existing wrong answers to check for duplicates
    final existingWrongAnswers = await userDataRepo.getWrongAnswers();
    final existingQuestionIds = existingWrongAnswers.map((wa) => wa.questionId).toSet();

    int newWrongAnswers = 0;
    int skippedDuplicates = 0;

    for (final question in _allQuestions) {
      final userAnswer = _userAnswers[question.id];
      final correctAnswer = question.correctAnswerIndex;

      if (userAnswer != null && userAnswer != correctAnswer) {
        // Check if this question is already in wrong answers
        if (existingQuestionIds.contains(question.id)) {
          print('⏭️ Skipping duplicate wrong answer for question: ${question.id}');
          skippedDuplicates++;
          continue; // Skip this question - already in wrong answers
        }

        // Determine category
        String category = 'reading';
        final questionText = question.questionText.toLowerCase();

        if (questionText.contains('vocabulary') ||
            questionText.contains('meaning') ||
            questionText.contains('synonym')) {
          category = 'vocabulary';
        } else if (questionText.contains('grammar')) {
          category = 'grammar';
        }

        // Generate tags
        List<String> tags = ['part6'];
        if (questionText.contains('tense')) tags.add('tense');
        if (questionText.contains('passive')) tags.add('passive-voice');
        if (questionText.contains('conditional')) tags.add('conditional');
        if (questionText.contains('preposition')) tags.add('prepositions');
        if (questionText.contains('business')) tags.add('business');

        final wrongAnswer = WrongAnswer.create(
          questionId: question.id,
          selectedAnswerIndex: userAnswer,
          correctAnswerIndex: correctAnswer,
          grammarPoint: _determineGrammarPoint(question.questionText),
          difficultyLevel: question.difficultyLevel,
          questionText: question.questionText,
          options: question.options,
          modeType: 'exam',
          category: category,
          tags: tags,
          explanation: 'Review this Part 6 question to improve your reading comprehension.',
        );

        await userDataRepo.addWrongAnswer(wrongAnswer);
        newWrongAnswers++;
        print('✅ Added new wrong answer for question: ${question.id}');
      }
    }

    print('📊 Wrong answers saved: $newWrongAnswers new, $skippedDuplicates duplicates skipped');
  }

  String _determineGrammarPoint(String questionText) {
    final text = questionText.toLowerCase();

    if (text.contains('have') && text.contains('been')) return 'Present Perfect Tense';
    if (text.contains('would') && text.contains('if')) return 'Conditional Sentences';
    if (text.contains('was') && text.contains('by')) return 'Passive Voice';
    if (text.contains(' at ') || text.contains(' on ') || text.contains(' in ')) return 'Prepositions';
    if (text.contains('will') || text.contains('going to')) return 'Future Tense';
    if (text.contains('should') || text.contains('must') || text.contains('have to')) return 'Modal Verbs';
    if (text.contains('however') || text.contains('therefore') || text.contains('moreover')) return 'Transition Words';

    return 'Reading Comprehension';
  }

  // Save detailed exam result for future access
  Future<void> _saveDetailedExamResult(DateTime examEndTime) async {
    try {
      final userDataRepo = ref.read(userDataRepositoryProvider);

      // Convert Map<String, int> to List<int> in the correct order
      final userAnswersList = _allQuestions.map((q) {
        return _userAnswers[q.id] ?? -1; // -1 if not answered
      }).toList();

      final examResult = ExamResult.create(
        examRound: widget.round,
        questions: _allQuestions,
        userAnswers: userAnswersList,
        examStartTime: _examStartTime!,
        examEndTime: examEndTime,
      );

      await userDataRepo.saveExamResult(examResult);

      print('✅ Saved detailed Part6 exam result for ${widget.round}');
    } catch (e) {
      print('❌ Error saving detailed Part6 exam result: $e');
    }
  }

  void _finishExam() async {
    if (_isFinishing) return;

    // Check if all questions are answered
    if (_userAnswers.length < _allQuestions.length) {
      final unanswered = _allQuestions.length - _userAnswers.length;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '미완료 문제',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            '$unanswered개의 문제가 미완료 상태입니다.\n그래도 제출하시겠습니까?',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF42A5F5),
              ),
              child: const Text('제출'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() {
      _isFinishing = true;
    });

    try {
      final examEndTime = DateTime.now();

      // Save wrong answers for review
      await _saveWrongAnswers();

      // Save detailed exam result for future access
      await _saveDetailedExamResult(examEndTime);

      // End exam session
      await _endExamSession();

      // Invalidate providers to refresh statistics on home screen
      ref.invalidate(userProgressProvider);
      ref.invalidate(examResultsProvider);
      ref.invalidate(combinedStatisticsProvider);

      // Small delay to ensure all data is flushed to disk
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate to result screen
      if (mounted) {
        context.push(
          '/part6/exam-result',
          extra: {
            'examRound': widget.round,
            'questions': _allQuestions,
            'userAnswers': _userAnswers,
            'examStartTime': _examStartTime!,
            'examEndTime': examEndTime,
          },
        );
      }
    } catch (e) {
      print('❌ Error finishing exam: $e');
      if (mounted) {
        setState(() {
          _isFinishing = false;
        });

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('오류'),
            content: Text('시험 제출 중 오류가 발생했습니다.\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Part 6 - ${widget.round.replaceAll('ROUND_', 'Round ')}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF42A5F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_allQuestions.isNotEmpty)
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF42A5F5)),
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _passageGroups.isEmpty
                  ? const Center(
                      child: Text(
                        'No questions available for this round',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : _buildExamScreen(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Questions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadQuestions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF42A5F5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildExamScreen() {
    final currentQuestions = _passageGroups[_currentPassageIndex];
    final passage = currentQuestions.first.passageText ?? 'No passage available';

    return Column(
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
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Questions
                ...currentQuestions.asMap().entries.map((entry) {
                  final index = entry.key;
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
          child: Row(
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
                  onPressed: _isFinishing
                      ? null
                      : _currentPassageIndex == _passageGroups.length - 1
                          ? _finishExam
                          : _nextPassage,
                  icon: _isFinishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          _currentPassageIndex == _passageGroups.length - 1
                              ? Icons.check_circle
                              : Icons.arrow_forward,
                          size: 18,
                        ),
                  label: Text(_isFinishing
                      ? 'Submitting...'
                      : _currentPassageIndex == _passageGroups.length - 1
                          ? 'Finish Exam'
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
    );
  }

  Widget _buildQuestionCard(SimpleQuestion question, int questionNumber) {
    final selectedAnswer = _userAnswers[question.id];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedAnswer != null
              ? const Color(0xFF42A5F5)
              : const Color(0xFFE0E0E0),
          width: selectedAnswer != null ? 2 : 1,
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
                  color: const Color(0xFF42A5F5),
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
            ],
          ),

          const SizedBox(height: 16),

          // Options
          ...question.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final optionText = entry.value;
            final isSelected = selectedAnswer == optionIndex;
            final optionLetter = String.fromCharCode(65 + optionIndex); // A, B, C, D

            return GestureDetector(
              onTap: () => _selectAnswer(question.id, optionIndex),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF42A5F5).withOpacity(0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF42A5F5)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF42A5F5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF42A5F5)
                              : Colors.grey[400]!,
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
                          color: isSelected
                              ? Colors.black87
                              : Colors.black54,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
