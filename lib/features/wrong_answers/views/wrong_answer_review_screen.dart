import 'package:flutter/material.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';

class WrongAnswerReviewScreen extends StatelessWidget {
  final List<WrongAnswer> wrongAnswers;

  const WrongAnswerReviewScreen({super.key, required this.wrongAnswers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Session'),
      ),
      body: const Center(
        child: Text('Wrong Answer Review Session - To be implemented'),
      ),
    );
  }
}