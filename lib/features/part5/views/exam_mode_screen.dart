import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/providers/app_providers.dart';

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
  bool _showResults = false;
  DateTime? _examStartTime;

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

  void _selectAnswer(int answerIndex) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answerIndex;
    });
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
    await _saveWrongAnswers();
    setState(() {
      _showResults = true;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Exam Mode - ${widget.round.replaceAll('ROUND_', 'Round ')}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (!_showResults && _questions.isNotEmpty)
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
                  : _showResults
                      ? _buildResultsScreen()
                      : _buildQuestionScreen(),
    );
  }

  Widget _buildQuestionScreen() {
    final currentQuestion = _questions[_currentQuestionIndex];
    final selectedAnswer = _userAnswers[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          const SizedBox(height: 20),

          // Question text
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Q${_currentQuestionIndex + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Level ${currentQuestion.difficultyLevel}',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Text(
                        currentQuestion.questionText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Answer options
          Expanded(
            flex: 4,
            child: ListView.builder(
              itemCount: currentQuestion.options.length,
              itemBuilder: (context, index) {
                final isSelected = selectedAnswer == index;
                final optionLetter =
                    String.fromCharCode(65 + index); // A, B, C, D

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _selectAnswer(index),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? AppColors.primaryGradient
                            : LinearGradient(
                                colors: [
                                  Colors.white,
                                  AppColors.backgroundLight
                                ],
                              ),
                        borderRadius: BorderRadius.circular(20),
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
                            width: 40,
                            height: 40,
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
                              borderRadius: BorderRadius.circular(20),
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
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              currentQuestion.options[index],
                              style: TextStyle(
                                fontSize: 16,
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
                  onPressed: selectedAnswer == -1
                      ? null
                      : _currentQuestionIndex == _questions.length - 1
                          ? _finishExam
                          : _nextQuestion,
                  icon: Icon(_currentQuestionIndex == _questions.length - 1
                      ? Icons.check
                      : Icons.arrow_forward),
                  label: Text(_currentQuestionIndex == _questions.length - 1
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

  Widget _buildResultsScreen() {
    final score = _calculateScore();
    final percentage = (score / _questions.length * 100).round();
    final duration = _getExamDuration();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Results header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.withOpacity(0.8), Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Exam Completed!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.round.replaceAll('ROUND_', 'Round '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Score summary
          Row(
            children: [
              Expanded(
                child: _buildScoreCard(
                  '점수',
                  '$score/${_questions.length}',
                  Icons.quiz_rounded,
                  AppColors.secondaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildScoreCard(
                  '정답률',
                  '$percentage%',
                  Icons.percent_rounded,
                  AppColors.successColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildScoreCard(
            '소요 시간',
            '${duration.inMinutes}분 ${duration.inSeconds % 60}초',
            Icons.timer_rounded,
            AppColors.tertiaryColor,
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentQuestionIndex = 0;
                      _userAnswers = List.filled(_questions.length, -1);
                      _showResults = false;
                      _examStartTime = DateTime.now();
                    });
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Retake Exam'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
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

  Widget _buildScoreCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
