import 'package:equatable/equatable.dart';
import 'package:egg_toeic/data/models/simple_models.dart';

class ExamResult extends Equatable {
  final String id;
  final String examRound;
  final List<SimpleQuestion> questions;
  final List<int> userAnswers;
  final DateTime examStartTime;
  final DateTime examEndTime;
  final int correctAnswers;
  final double accuracy;

  const ExamResult({
    required this.id,
    required this.examRound,
    required this.questions,
    required this.userAnswers,
    required this.examStartTime,
    required this.examEndTime,
    required this.correctAnswers,
    required this.accuracy,
  });

  factory ExamResult.create({
    required String examRound,
    required List<SimpleQuestion> questions,
    required List<int> userAnswers,
    required DateTime examStartTime,
    required DateTime examEndTime,
  }) {
    // Calculate correct answers
    int correctCount = 0;
    for (int i = 0; i < userAnswers.length; i++) {
      if (i < questions.length && userAnswers[i] == questions[i].correctAnswerIndex) {
        correctCount++;
      }
    }

    final accuracy = questions.isNotEmpty ? correctCount / questions.length : 0.0;

    return ExamResult(
      id: 'exam_${examRound}_${examStartTime.millisecondsSinceEpoch}',
      examRound: examRound,
      questions: questions,
      userAnswers: userAnswers,
      examStartTime: examStartTime,
      examEndTime: examEndTime,
      correctAnswers: correctCount,
      accuracy: accuracy,
    );
  }

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      id: json['id'] as String,
      examRound: json['examRound'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((q) => SimpleQuestion.fromJson(Map<String, dynamic>.from(q)))
          .toList(),
      userAnswers: List<int>.from(json['userAnswers'] as List),
      examStartTime: DateTime.parse(json['examStartTime'] as String),
      examEndTime: DateTime.parse(json['examEndTime'] as String),
      correctAnswers: json['correctAnswers'] as int,
      accuracy: (json['accuracy'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examRound': examRound,
      'questions': questions.map((q) => q.toJson()).toList(),
      'userAnswers': userAnswers,
      'examStartTime': examStartTime.toIso8601String(),
      'examEndTime': examEndTime.toIso8601String(),
      'correctAnswers': correctAnswers,
      'accuracy': accuracy,
    };
  }

  @override
  List<Object?> get props => [
        id,
        examRound,
        questions,
        userAnswers,
        examStartTime,
        examEndTime,
        correctAnswers,
        accuracy,
      ];
}