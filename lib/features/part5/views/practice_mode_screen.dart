import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/providers/app_providers.dart';
import 'package:egg_toeic/providers/repository_providers.dart';

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
      final questionRepo = ref.read(questionRepositoryProvider);
      final questions = await questionRepo.getQuestions(
        difficultyLevel: widget.difficultyLevel,
        limit: 10,
      );
      setState(() {
        _questions = questions;
      });
    } catch (e) {
      // Handle error
      print('Error loading questions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Level ${widget.difficultyLevel} Practice'),
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
            // Question Number & Grammar Point
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
            ...List.generate(
              question.options.length,
              (index) => _buildOptionButton(
                context,
                option: question.options[index],
                index: index,
                isSelected: _selectedAnswer == index,
                isCorrect: index == question.correctAnswerIndex,
                isAnswered: _isAnswered,
                onTap: !_isAnswered ? () => _selectAnswer(index) : null,
              ),
            ),

            // Explanation Section
            if (_isAnswered && _showExplanation) ...[
              const SizedBox(height: 24),
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
                  color: isCorrect ? AppColors.successColor : AppColors.errorColor,
                  size: 24,
                ),
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
                icon: Icon(_showExplanation ? Icons.visibility_off : Icons.lightbulb_outline),
                label: Text(_showExplanation ? 'Hide Explanation' : 'Show Explanation'),
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
                label: Text(_currentQuestionIndex < _questions.length - 1 ? 'Next' : 'Finish'),
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

  void _submitAnswer() {
    if (_selectedAnswer == null) return;

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = _selectedAnswer == currentQuestion.correctAnswerIndex;

    setState(() {
      _isAnswered = true;
    });

    // Show feedback haptic
    if (isCorrect) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
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
        content: const Text('Congratulations! You have completed this practice session.'),
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