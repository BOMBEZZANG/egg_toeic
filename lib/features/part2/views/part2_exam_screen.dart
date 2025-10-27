import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/models/exam_result_model.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/providers/app_providers.dart';

class Part2ExamScreen extends ConsumerStatefulWidget {
  final String round;

  const Part2ExamScreen({
    super.key,
    required this.round,
  });

  @override
  ConsumerState<Part2ExamScreen> createState() => _Part2ExamScreenState();
}

class _Part2ExamScreenState extends ConsumerState<Part2ExamScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<SimpleQuestion> _questions = [];
  Map<int, int> _userAnswers = {}; // questionIndex -> selectedAnswer (0=A, 1=B, 2=C)

  int _currentQuestionIndex = 0;
  bool _isPlaying = false;
  bool _canAnswer = false;
  int? _selectedAnswer;

  DateTime? _examStartTime;

  // Audio playback state
  String _currentPlayingAudio = ''; // 'question', 'responseA', 'responseB', 'responseC', or ''

  @override
  void initState() {
    super.initState();
    _examStartTime = DateTime.now();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((event) {
      _onAudioComplete();
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  Future<void> _loadQuestionsAndStart() async {
    final questions = await ref.read(part2ExamQuestionsByRoundProvider(widget.round).future);

    if (questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No questions found for this round')),
        );
        context.pop();
      }
      return;
    }

    setState(() {
      _questions = questions;
    });

    // Try to load saved progress
    await _loadProgress();

    // Start playing the current question (will be from saved progress if exists)
    _playCurrentQuestion();
  }

  Future<void> _playCurrentQuestion() async {
    if (_currentQuestionIndex >= _questions.length) {
      _finishExam();
      return;
    }

    setState(() {
      _canAnswer = true; // ✨ Allow answering immediately
      _selectedAnswer = null;
      _currentPlayingAudio = 'complete';
    });

    final question = _questions[_currentQuestionIndex];

    // Play complete merged audio (question + all responses in one file)
    final completeAudioUrl = question.audioFiles?['complete'] ?? '';

    if (completeAudioUrl.isNotEmpty) {
      await _playAudio(completeAudioUrl, 'complete');
    } else {
      print('⚠️ No audio file found for question ${_currentQuestionIndex + 1}');
    }

    // Audio completed naturally (user didn't select answer during playback)
    setState(() {
      _currentPlayingAudio = '';
    });
  }

  Future<void> _playAudio(String url, String audioType) async {
    if (url.isEmpty) return;

    setState(() {
      _currentPlayingAudio = audioType;
    });

    try {
      await _audioPlayer.play(UrlSource(url));
      // Wait for audio to complete
      await _audioPlayer.onPlayerComplete.first;
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void _onAudioComplete() {
    // Audio completed, handled by the playback sequence
  }

  Future<void> _replayQuestion() async {
    if (_isPlaying) return;

    // Stop current audio first
    await _audioPlayer.stop();

    setState(() {
      _canAnswer = true; // ✨ Allow answering immediately during replay too
      _currentPlayingAudio = 'complete';
    });

    final question = _questions[_currentQuestionIndex];
    final completeAudioUrl = question.audioFiles?['complete'] ?? '';

    if (completeAudioUrl.isNotEmpty) {
      await _playAudio(completeAudioUrl, 'complete');
    }

    setState(() {
      _currentPlayingAudio = '';
    });
  }

  void _selectAnswer(int answerIndex) {
    if (!_canAnswer || _selectedAnswer != null) return;

    // Stop audio immediately when answer is selected
    _audioPlayer.stop();

    setState(() {
      _selectedAnswer = answerIndex;
      _userAnswers[_currentQuestionIndex] = answerIndex;
      _currentPlayingAudio = ''; // Clear playing state
    });

    // Auto-advance to next question after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _playCurrentQuestion();
    } else {
      _finishExam();
    }
  }

  // Save wrong answers for review (with duplicate prevention)
  Future<void> _saveWrongAnswers() async {
    final userDataRepo = ref.read(userDataRepositoryProvider);

    // Get existing wrong answers to check for duplicates
    final existingWrongAnswers = await userDataRepo.getWrongAnswers();
    final existingQuestionIds = existingWrongAnswers.map((wa) => wa.questionId).toSet();

    int newWrongAnswers = 0;
    int skippedDuplicates = 0;

    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final userAnswer = _userAnswers[i];
      final correctAnswer = question.correctAnswerIndex;

      if (userAnswer != null && userAnswer != correctAnswer) {
        // Check if this question is already in wrong answers
        if (existingQuestionIds.contains(question.id)) {
          print('⏭️ Skipping duplicate wrong answer for question: ${question.id}');
          skippedDuplicates++;
          continue; // Skip this question - already in wrong answers
        }

        // Determine category for Part 2 (listening comprehension)
        String category = 'listening';
        final questionType = question.questionType ?? 'unknown';

        String grammarPoint = questionType;
        if (questionType.contains('wh')) {
          grammarPoint = 'WH-Questions';
        } else if (questionType.contains('yes-no')) {
          grammarPoint = 'Yes/No Questions';
        } else if (questionType.contains('tag')) {
          grammarPoint = 'Tag Questions';
        } else if (questionType.contains('statement')) {
          grammarPoint = 'Statements';
        } else if (questionType.contains('choice')) {
          grammarPoint = 'Choice Questions';
        } else if (questionType.contains('suggestion')) {
          grammarPoint = 'Suggestions/Requests';
        }

        final wrongAnswer = WrongAnswer(
          id: '${question.id}_${DateTime.now().millisecondsSinceEpoch}',
          questionId: question.id,
          selectedAnswerIndex: userAnswer,
          correctAnswerIndex: correctAnswer,
          answeredAt: DateTime.now(),
          questionText: question.questionText,
          options: question.options,
          explanation: question.explanation ?? 'No explanation available',
          category: category,
          grammarPoint: grammarPoint,
          difficultyLevel: question.difficultyLevel ?? 2,
          modeType: 'exam',
        );

        await userDataRepo.addWrongAnswer(wrongAnswer);
        newWrongAnswers++;
      }
    }

    print('✅ Saved $newWrongAnswers new wrong answers (skipped $skippedDuplicates duplicates)');
  }

  // Save progress to Firebase when user exits early
  Future<void> _saveProgress() async {
    try {
      print('💾 Saving exam progress: round=${widget.round}, currentIndex=$_currentQuestionIndex, totalAnswered=${_userAnswers.length}');
      final userDataRepo = ref.read(userDataRepositoryProvider);

      final progressData = {
        'examRound': widget.round,
        'partNumber': 2,
        'currentQuestionIndex': _currentQuestionIndex,
        'userAnswers': _userAnswers.map((k, v) => MapEntry(k.toString(), v)),
        'examStartTime': _examStartTime?.toIso8601String(),
        'savedAt': FieldValue.serverTimestamp(),
      };

      print('📤 Progress data: ${progressData.keys.toList()}');
      await userDataRepo.saveExamProgress('part2_${widget.round}', progressData);

      print('✅ Saved Part2 exam progress for ${widget.round} at question ${_currentQuestionIndex + 1}');
    } catch (e) {
      print('❌ Error saving exam progress: $e');
      print('Stack trace: $e');
    }
  }

  // Load saved progress from Firebase
  Future<void> _loadProgress() async {
    try {
      print('🔍 Attempting to load exam progress for part2_${widget.round}');
      final userDataRepo = ref.read(userDataRepositoryProvider);

      final data = await userDataRepo.loadExamProgress('part2_${widget.round}');

      print('📥 Load result: ${data != null ? "Found saved progress" : "No saved progress"}');

      if (data != null) {
        setState(() {
          _currentQuestionIndex = data['currentQuestionIndex'] as int;

          // Restore user answers
          final answersMap = data['userAnswers'] as Map<String, dynamic>;
          _userAnswers = answersMap.map((k, v) => MapEntry(int.parse(k), v as int));

          // Restore exam start time
          if (data['examStartTime'] != null) {
            _examStartTime = DateTime.parse(data['examStartTime'] as String);
          }
        });

        print('✅ Loaded Part2 exam progress: resuming from question ${_currentQuestionIndex + 1}');

        // Show snackbar to inform user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이전 진행 상황에서 계속합니다 (문제 ${_currentQuestionIndex + 1}부터)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('⚠️ Could not load exam progress: $e');
    }
  }

  // Delete progress after exam completion
  Future<void> _deleteProgress() async {
    try {
      final userDataRepo = ref.read(userDataRepositoryProvider);

      await userDataRepo.deleteExamProgress('part2_${widget.round}');

      print('🗑️ Deleted Part2 exam progress for ${widget.round}');
    } catch (e) {
      print('⚠️ Could not delete exam progress: $e');
    }
  }

  // Save detailed exam result for future access
  Future<void> _saveDetailedExamResult(DateTime examEndTime) async {
    try {
      final userDataRepo = ref.read(userDataRepositoryProvider);

      // Convert Map<int, int> to List<int> in the correct order
      final userAnswersList = List.generate(_questions.length, (index) {
        return _userAnswers[index] ?? -1; // -1 if not answered
      });

      final examResult = ExamResult.create(
        examRound: widget.round,
        questions: _questions,
        userAnswers: userAnswersList,
        examStartTime: _examStartTime!,
        examEndTime: examEndTime,
        partNumber: 2,
      );

      print('📝 Creating Part2 exam result: round=${widget.round}, questions=${_questions.length}, correct=${examResult.correctAnswers}, part=${examResult.partNumber}');

      await userDataRepo.saveExamResult(examResult);

      print('✅ Saved detailed Part2 exam result for ${widget.round}');
    } catch (e) {
      print('❌ Error saving detailed Part2 exam result: $e');
    }
  }

  void _finishExam() async {
    final examEndTime = DateTime.now();

    try {
      // Save wrong answers for review
      await _saveWrongAnswers();

      // Save detailed exam result for future access
      await _saveDetailedExamResult(examEndTime);

      // Delete saved progress since exam is now complete
      await _deleteProgress();

      // Invalidate providers to refresh statistics on home screen
      ref.invalidate(userProgressProvider);
      ref.invalidate(examResultsProvider);
      ref.invalidate(combinedStatisticsProvider);

      // Small delay to ensure all data is flushed to disk
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('❌ Error in finish exam: $e');
    }

    // Navigate to result screen
    if (mounted) {
      context.push('/part2/exam-result', extra: {
        'examRound': widget.round,
        'questions': _questions,
        'userAnswers': _userAnswers,
        'examStartTime': _examStartTime!,
        'examEndTime': examEndTime,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(part2ExamQuestionsByRoundProvider(widget.round));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('시험이 끝나지 않았습니다'),
            content: const Text('나가겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('continue'),
                child: const Text('계속풀기'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('save'),
                child: const Text(
                  '네 저장하고 나가기',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        );

        if (result == 'save' && context.mounted) {
          // Save progress before exiting
          await _saveProgress();
          if (context.mounted) {
            context.pop();
          }
        }
        // If 'continue', do nothing (stay on exam page)
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.headphones, color: Color(0xFFFF6F00)),
              const SizedBox(width: 8),
              const Text(
                'Part 2 Exam',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (_questions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6F00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Q${_currentQuestionIndex + 1}/${_questions.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6F00),
                    ),
                  ),
                ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: questionsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading questions: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
          data: (questions) {
            if (_questions.isEmpty && questions.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadQuestionsAndStart();
              });
            }

            if (_questions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return _buildExamContent();
          },
        ),
      ),
    );
  }

  Widget _buildExamContent() {
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    final question = _questions[_currentQuestionIndex];
    final questionNumber = question.questionNumber ?? (_currentQuestionIndex + 7);

    return SafeArea(
      child: Column(
        children: [
          // Progress bar
          Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
            ),
          ),

          const SizedBox(height: 16),

          // Progress text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Progress: ${(_currentQuestionIndex + 1)}/${_questions.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFF6F00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Question number display
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Question number card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF6F00),
                          Color(0xFFFF8F00),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6F00).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Question $questionNumber',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Audio indicator
                        if (_isPlaying)
                          Column(
                            children: [
                              const Icon(
                                Icons.volume_up,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getAudioPlayingText(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          )
                        else if (_canAnswer)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 48,
                          )
                        else
                          const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Answer options
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        _buildAnswerButton('A', 0),
                        const SizedBox(height: 16),
                        _buildAnswerButton('B', 1),
                        const SizedBox(height: 16),
                        _buildAnswerButton('C', 2),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isPlaying ? null : _replayQuestion,
                        icon: const Icon(Icons.replay),
                        label: const Text('Replay Question'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(String letter, int index) {
    final isSelected = _selectedAnswer == index;
    final isDisabled = !_canAnswer || _selectedAnswer != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : () => _selectAnswer(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF6F00)
                : isDisabled
                    ? Colors.grey[200]
                    : Colors.white,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF6F00)
                  : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6F00).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getAudioPlayingText() {
    if (_currentPlayingAudio == 'complete') {
      return 'Playing Audio...';
    }
    return 'Loading...';
  }
}
