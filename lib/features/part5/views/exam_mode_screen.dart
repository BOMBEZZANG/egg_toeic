import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/exam_result_model.dart';
import 'package:egg_toeic/data/models/question_model.dart' as question_model;
import 'package:egg_toeic/core/services/auth_service.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/core/widgets/custom_app_bar.dart';

class ExamModeScreen extends ConsumerStatefulWidget {
  final String round;

  const ExamModeScreen({super.key, required this.round});

  @override
  ConsumerState<ExamModeScreen> createState() => _ExamModeScreenState();
}

class _ExamModeScreenState extends ConsumerState<ExamModeScreen> {
  List<SimpleQuestion> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentQuestionIndex = 0;
  List<int> _userAnswers = [];
  DateTime? _examStartTime;
  bool _isFinishing = false; // Prevent multiple finish calls

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questionRepo = ref.read(questionRepositoryProvider);
      final questions =
          await questionRepo.getExamQuestionsByRound(widget.round);

      if (mounted) {
        setState(() {
          _questions = questions;
          _userAnswers = List.filled(
              questions.length, -1); // Initialize with -1 (no answer)
          _isLoading = false;
          _examStartTime = DateTime.now();
        });

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

  void _selectAnswer(int answerIndex) async {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answerIndex;
    });

    // Submit analytics for this answer
    await _submitAnswerAnalytics(answerIndex);
  }

  // Submit user answer analytics to Firebase
  Future<void> _submitAnswerAnalytics(int selectedAnswerIndex) async {
    try {
      final currentQuestion = _questions[_currentQuestionIndex];

      // Get user ID from AuthService
      final authService = AuthService();
      final userId = authService.currentUserId;

      // For exam mode, always consider as first attempt per session
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
        selectedAnswerIndex: selectedAnswerIndex,
        sessionId: 'exam_${widget.round}_${DateTime.now().millisecondsSinceEpoch}',
        timeSpentSeconds: null, // Could track time if needed
        metadata: {
          'examRound': widget.round,
          'questionNumber': _currentQuestionIndex + 1,
        },
        isFirstAttempt: isFirstAttempt,
      );

      print('✅ Submitted analytics for exam question ${currentQuestion.id}');
    } catch (e) {
      print('❌ Error submitting answer analytics: $e');
      // Don't block the user experience if analytics fail
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _finishExam() async {
    // Prevent multiple calls
    if (_isFinishing) {
      print('⚠️ Finish already in progress, ignoring duplicate call');
      return;
    }

    setState(() {
      _isFinishing = true;
    });

    try {
      final examEndTime = DateTime.now();

      await _saveWrongAnswers();

      // Save detailed exam result for future access
      await _saveDetailedExamResult(examEndTime);

      // End exam session
      await _endExamSession();

      // Small delay to ensure all data is flushed to disk
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate to comprehensive result screen
      if (mounted) {
        context.push('/part5/exam-result', extra: {
          'examRound': widget.round,
          'questions': _questions,
          'userAnswers': _userAnswers,
          'examStartTime': _examStartTime!,
          'examEndTime': examEndTime,
        });
      }
    } catch (e) {
      print('❌ Error finishing exam: $e');
      if (mounted) {
        setState(() {
          _isFinishing = false;
        });
      }
    }
  }

  // Start exam learning session
  Future<void> _startExamSession() async {
    try {
      final userDataRepo = ref.read(userDataRepositoryProvider);

      // Create a custom session with round information
      // We'll use the updateCurrentSession to add round info to the session
      await userDataRepo.startNewSession(sessionType: 'exam');

      // Add the round information to the session by updating questionId with round info
      await userDataRepo.updateCurrentSession(
        questionId: 'EXAM_${widget.round}_START',
      );

      print('✅ Started exam session for ${widget.round}');
    } catch (e) {
      print('❌ Error starting exam session: $e');
    }
  }

  // End exam learning session with completion status
  Future<void> _endExamSession() async {
    try {
      final userDataRepo = ref.read(userDataRepositoryProvider);

      // Calculate correct answers
      int correctAnswers = 0;
      for (int i = 0; i < _userAnswers.length; i++) {
        if (_userAnswers[i] == _questions[i].correctAnswerIndex) {
          correctAnswers++;
        }
      }

      // Update session with completion data
      await userDataRepo.updateCurrentSession(
        questionsAnswered: _questions.length,
        correctAnswers: correctAnswers,
      );

      // End the session as completed
      await userDataRepo.endCurrentSession();

      print('✅ Ended exam session for ${widget.round} - $correctAnswers/${_questions.length} correct');
    } catch (e) {
      print('❌ Error ending exam session: $e');
    }
  }

  int _calculateScore() {
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i].correctAnswerIndex) {
        correct++;
      }
    }
    return correct;
  }

  Duration _getExamDuration() {
    if (_examStartTime == null) return Duration.zero;
    return DateTime.now().difference(_examStartTime!);
  }

  Future<void> _saveWrongAnswers() async {
    final userDataRepo = ref.read(userDataRepositoryProvider);

    for (int i = 0; i < _questions.length; i++) {
      final userAnswer = _userAnswers[i];
      final correctAnswer = _questions[i].correctAnswerIndex;

      if (userAnswer != -1 && userAnswer != correctAnswer) {
        final question = _questions[i];

        // Determine category based on grammar pattern analysis
        String category = 'grammar';
        final questionText = question.questionText.toLowerCase();

        if (questionText.contains('vocabulary') ||
            questionText.contains('meaning') ||
            questionText.contains('synonym') ||
            questionText.contains('definition')) {
          category = 'vocabulary';
        }

        // Generate tags based on question content
        List<String> tags = [];
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
          explanation: 'Review this ${category} question to improve your understanding.',
        );

        await userDataRepo.addWrongAnswer(wrongAnswer);
      }
    }
  }

  String _determineGrammarPoint(String questionText) {
    final text = questionText.toLowerCase();

    if (text.contains('have') && text.contains('been')) return 'Present Perfect Tense';
    if (text.contains('would') && text.contains('if')) return 'Conditional Sentences';
    if (text.contains('was') && text.contains('by')) return 'Passive Voice';
    if (text.contains(' at ') || text.contains(' on ') || text.contains(' in ')) return 'Prepositions';
    if (text.contains('will') || text.contains('going to')) return 'Future Tense';
    if (text.contains('should') || text.contains('must') || text.contains('have to')) return 'Modal Verbs';

    return 'Grammar Review';
  }

  // Save detailed exam result for future access via '결과보기' button
  Future<void> _saveDetailedExamResult(DateTime examEndTime) async {
    try {
      final userDataRepo = ref.read(userDataRepositoryProvider);

      final examResult = ExamResult.create(
        examRound: widget.round,
        questions: _questions,
        userAnswers: _userAnswers,
        examStartTime: _examStartTime!,
        examEndTime: examEndTime,
      );

      await userDataRepo.saveExamResult(examResult);

      print('✅ Saved detailed exam result for ${widget.round}');
    } catch (e) {
      print('❌ Error saving detailed exam result: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Exam Mode - ${widget.round.replaceAll('ROUND_', 'Round ')}',
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (_questions.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Questions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
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
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _questions.isEmpty
                  ? const Center(
                      child: Text(
                        'No questions available for this round',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : _buildQuestionScreen(),
    );
  }

  Widget _buildQuestionScreen() {
    final currentQuestion = _questions[_currentQuestionIndex];
    final selectedAnswer = _userAnswers[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          const SizedBox(height: 12),

          // Question text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Q${_currentQuestionIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentQuestion.questionText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Answer options
          Expanded(
            child: ListView.builder(
              itemCount: currentQuestion.options.length,
              itemBuilder: (context, index) {
                final isSelected = selectedAnswer == index;
                final optionLetter =
                    String.fromCharCode(65 + index); // A, B, C, D

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _selectAnswer(index),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? AppColors.primaryGradient
                            : LinearGradient(
                                colors: [
                                  Colors.white,
                                  AppColors.backgroundLight
                                ],
                              ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.borderColor,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? AppTheme.subtleShadow
                            : [
                                BoxShadow(
                                  color: AppColors.cardShadow,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        Colors.white,
                                        AppColors.primaryLight
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        AppColors.borderColor,
                                        Colors.grey[300]!
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primaryColor.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                optionLetter,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentQuestion.options[index],
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Navigation buttons
          Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _previousQuestion,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 16),
              Expanded(
                flex: _currentQuestionIndex == 0 ? 1 : 1,
                child: ElevatedButton.icon(
                  onPressed: (selectedAnswer == -1 || _isFinishing)
                      ? null
                      : _currentQuestionIndex == _questions.length - 1
                          ? _finishExam
                          : _nextQuestion,
                  icon: _isFinishing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(_currentQuestionIndex == _questions.length - 1
                          ? Icons.check
                          : Icons.arrow_forward),
                  label: Text(_isFinishing
                      ? 'Saving...'
                      : _currentQuestionIndex == _questions.length - 1
                          ? 'Finish Exam'
                          : 'Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
