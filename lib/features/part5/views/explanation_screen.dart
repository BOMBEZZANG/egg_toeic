import 'package:flutter/material.dart';
import 'package:egg_toeic/data/models/simple_models.dart';

class ExplanationScreen extends StatelessWidget {
  final SimpleQuestion question;

  const ExplanationScreen({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explanation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(question.questionText),
            const SizedBox(height: 16),
            Text(
              'Correct Answer:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(question.options[question.correctAnswerIndex]),
            const SizedBox(height: 16),
            Text(
              'Explanation:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(question.explanation),
          ],
        ),
      ),
    );
  }
}