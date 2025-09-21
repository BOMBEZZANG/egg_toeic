// Temporary simple repositories for immediate compilation
// TODO: Replace with full repositories after fixing model issues

import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/repositories/question_repository.dart';

abstract class SimpleQuestionRepository {
  Future<List<SimpleQuestion>> getQuestions({
    required int difficultyLevel,
    int limit = 10,
  });

  Future<SimpleQuestion?> getQuestionById(String questionId);
}

abstract class SimpleUserDataRepository {
  Future<SimpleUserProgress> getUserProgress();
  Future<void> updateUserProgress(SimpleUserProgress progress);
}

class SimpleQuestionRepositoryImpl implements QuestionRepository {
  List<SimpleQuestion> _cachedQuestions = [];

  @override
  Future<void> initialize() async {
    // No initialization needed for simple repository
  }

  @override
  Future<void> dispose() async {
    _cachedQuestions.clear();
  }

  @override
  Future<List<SimpleQuestion>> getQuestions({
    required int difficultyLevel,
    int limit = 10,
  }) async {
    // Return sample questions for now
    return [
      SimpleQuestion(
        id: '1',
        questionText: 'The meeting _____ scheduled for 3 PM tomorrow.',
        options: ['is', 'are', 'were', 'be'],
        correctAnswerIndex: 0,
        difficultyLevel: difficultyLevel,
        explanation: '"Is" is the correct form of the verb "to be" for singular subjects.',
        grammarPoint: 'Subject-Verb Agreement',
      ),
      SimpleQuestion(
        id: '2',
        questionText: 'The company _____ its annual report next month.',
        options: ['publish', 'publishes', 'will publish', 'published'],
        correctAnswerIndex: 2,
        difficultyLevel: difficultyLevel,
        explanation: 'Future tense "will publish" indicates an action that will happen in the future.',
        grammarPoint: 'Future Tense',
      ),
    ];
  }

  @override
  Future<SimpleQuestion?> getQuestionById(String questionId) async {
    final questions = await getQuestions(difficultyLevel: 1, limit: 100);
    try {
      return questions.firstWhere((q) => q.id == questionId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SimpleQuestion>> getQuestionsByIds(List<String> questionIds) async {
    final result = <SimpleQuestion>[];
    for (final id in questionIds) {
      final question = await getQuestionById(id);
      if (question != null) {
        result.add(question);
      }
    }
    return result;
  }

  @override
  Future<List<SimpleQuestion>> getRandomQuestions({
    int? difficultyLevel,
    int limit = 10,
  }) async {
    final questions = await getQuestions(
      difficultyLevel: difficultyLevel ?? 1,
      limit: limit,
    );
    questions.shuffle();
    return questions;
  }

  @override
  Future<void> cacheQuestions(List<SimpleQuestion> questions) async {
    _cachedQuestions.addAll(questions);
  }

  @override
  Future<List<SimpleQuestion>> getCachedQuestions() async {
    return _cachedQuestions;
  }
}

class SimpleUserDataRepositoryImpl implements SimpleUserDataRepository {
  @override
  Future<SimpleUserProgress> getUserProgress() async {
    return SimpleUserProgress.initial();
  }

  @override
  Future<void> updateUserProgress(SimpleUserProgress progress) async {
    // TODO: Implement local storage
  }
}