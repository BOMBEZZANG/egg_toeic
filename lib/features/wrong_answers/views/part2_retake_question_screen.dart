import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:egg_toeic/providers/app_providers.dart';

class Part2RetakeQuestionScreen extends ConsumerStatefulWidget {
  final WrongAnswer wrongAnswer;

  const Part2RetakeQuestionScreen({
    super.key,
    required this.wrongAnswer,
  });

  @override
  ConsumerState<Part2RetakeQuestionScreen> createState() =>
      _Part2RetakeQuestionScreenState();
}

class _Part2RetakeQuestionScreenState
    extends ConsumerState<Part2RetakeQuestionScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedAnswer;
  bool _showResult = false;
  bool _isPlaying = false;
  bool _hasPlayedOnce = false;
  SimpleQuestion? _question;
  bool _isLoadingQuestion = true;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    try {
      // Fetch Part2 question directly from Firestore
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore
          .collection('part2examQuestions')
          .doc(widget.wrongAnswer.questionId)
          .get();

      if (!doc.exists) {
        throw Exception('Question not found');
      }

      final data = doc.data();
      if (data == null) {
        throw Exception('Question data is null');
      }

      final question = SimpleQuestion.fromFirestore(data, widget.wrongAnswer.questionId);

      if (mounted) {
        setState(() {
          _question = question;
          _isLoadingQuestion = false;
        });
        // Auto-play audio after question is loaded
        if (_question != null) {
          _playAudio();
        }
      }
    } catch (e) {
      print('Error loading question: $e');
      if (mounted) {
        setState(() {
          _isLoadingQuestion = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('문제를 불러오는 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _hasPlayedOnce = true;
        });
      }
    });
  }

  Future<void> _playAudio() async {
    if (_question == null) return;

    final audioUrl = _question!.audioFiles?['complete'] as String?;

    if (audioUrl == null || audioUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오디오를 찾을 수 없습니다')),
        );
      }
      return;
    }

    try {
      setState(() {
        _isPlaying = true;
      });
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오디오 재생 오류: $e')),
        );
      }
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _submitAnswer() {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('답을 선택해주세요')),
      );
      return;
    }

    setState(() {
      _showResult = true;
    });

    // If answered correctly, remove from wrong answers
    if (_selectedAnswer == widget.wrongAnswer.correctAnswerIndex) {
      _removeFromWrongAnswers();
    }
  }

  Future<void> _removeFromWrongAnswers() async {
    await ref
        .read(userDataRepositoryProvider)
        .removeWrongAnswer(widget.wrongAnswer.id);
    ref.invalidate(wrongAnswersProvider);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestion) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.headphones, color: Color(0xFFFF6F00)),
              SizedBox(width: 8),
              Text(
                'Part 2 다시 풀기',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
          ),
        ),
      );
    }

    if (_question == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.headphones, color: Color(0xFFFF6F00)),
              SizedBox(width: 8),
              Text(
                'Part 2 다시 풀기',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: const Center(
          child: Text('문제를 찾을 수 없습니다'),
        ),
      );
    }

    final isCorrect =
        _showResult && _selectedAnswer == widget.wrongAnswer.correctAnswerIndex;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.headphones, color: Color(0xFFFF6F00)),
            const SizedBox(width: 8),
            const Text(
              'Part 2 다시 풀기',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Badge (only before answering)
              if (!_showResult)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6F00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6F00).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.refresh,
                        color: Color(0xFFFF6F00),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '이번엔 맞춰보세요!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Audio Player Card
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
                    const Icon(
                      Icons.headphones_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Listen to the audio',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Play button
                    ElevatedButton.icon(
                      onPressed: _isPlaying ? null : _playAudio,
                      icon: Icon(
                        _isPlaying ? Icons.volume_up : Icons.play_arrow,
                        size: 24,
                      ),
                      label: Text(
                        _isPlaying ? '재생 중...' : (_hasPlayedOnce ? '다시 듣기' : '오디오 듣기'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6F00),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Answer Options
              const Text(
                'Choose your answer:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              ...List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAnswerOption(
                    index,
                    String.fromCharCode(65 + index), // A, B, C
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Submit button (only show before result)
              if (!_showResult)
                ElevatedButton(
                  onPressed: _selectedAnswer != null ? _submitAnswer : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: const Text(
                    '답변 제출',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Result feedback
              if (_showResult) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.successColor.withOpacity(0.1)
                        : AppColors.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCorrect
                          ? AppColors.successColor
                          : AppColors.errorColor,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        size: 48,
                        color: isCorrect
                            ? AppColors.successColor
                            : AppColors.errorColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isCorrect ? '정답입니다! 🎉' : '틀렸습니다',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isCorrect
                              ? AppColors.successColor
                              : AppColors.errorColor,
                        ),
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(height: 8),
                        Text(
                          '정답: ${_getAnswerLetter(widget.wrongAnswer.correctAnswerIndex)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                      if (isCorrect) ...[
                        const SizedBox(height: 8),
                        Text(
                          '오답노트에서 자동으로 제거되었습니다',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Explanation if available
                if (_question?.explanation != null &&
                    _question!.explanation.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.infoColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: AppColors.infoColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '해설',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.infoColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _question!.explanation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                // Back button
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6F00),
                    side: const BorderSide(color: Color(0xFFFF6F00)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '목록으로 돌아가기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildAnswerOption(int index, String letter) {
    final isSelected = _selectedAnswer == index;
    final isCorrect = widget.wrongAnswer.correctAnswerIndex == index;
    final isDisabled = _showResult;

    Color borderColor;
    Color backgroundColor;

    if (_showResult) {
      if (isCorrect) {
        borderColor = AppColors.successColor;
        backgroundColor = AppColors.successColor.withOpacity(0.1);
      } else if (isSelected) {
        borderColor = AppColors.errorColor;
        backgroundColor = AppColors.errorColor.withOpacity(0.1);
      } else {
        borderColor = Colors.grey[300]!;
        backgroundColor = Colors.grey[100]!;
      }
    } else {
      borderColor = isSelected ? const Color(0xFFFF6F00) : Colors.grey[300]!;
      backgroundColor = isSelected
          ? const Color(0xFFFF6F00).withOpacity(0.1)
          : Colors.white;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : () => setState(() => _selectedAnswer = index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected && !_showResult
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  letter,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _showResult
                        ? (isCorrect
                            ? AppColors.successColor
                            : isSelected
                                ? AppColors.errorColor
                                : Colors.grey[600])
                        : (isSelected ? const Color(0xFFFF6F00) : Colors.black87),
                  ),
                ),
                if (_showResult) ...[
                  const SizedBox(width: 12),
                  Icon(
                    isCorrect ? Icons.check_circle : (isSelected ? Icons.cancel : null),
                    color: isCorrect
                        ? AppColors.successColor
                        : AppColors.errorColor,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAnswerLetter(int index) {
    if (index < 0 || index > 2) return '-';
    return String.fromCharCode(65 + index); // A, B, C
  }
}
