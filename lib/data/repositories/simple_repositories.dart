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
    String mode = 'practice',
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
  Future<SimpleQuestion?> getQuestionById(String questionId, {String mode = 'practice'}) async {
    final questions = await getQuestions(difficultyLevel: 1, limit: 100, mode: mode);
    try {
      return questions.firstWhere((q) => q.id == questionId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SimpleQuestion>> getQuestionsByIds(List<String> questionIds, {String mode = 'practice'}) async {
    final result = <SimpleQuestion>[];
    for (final id in questionIds) {
      final question = await getQuestionById(id, mode: mode);
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
    String mode = 'practice',
  }) async {
    final questions = await getQuestions(
      difficultyLevel: difficultyLevel ?? 1,
      limit: limit,
      mode: mode,
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

  @override
  Future<Map<String, List<Question>>> getPracticeSessionsByDate({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    // Return mock data for simple repository
    final now = DateTime.now();
    final sessions = <String, List<Question>>{};

    // Generate mock sessions for last 7 days
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Create mock questions for this date
      sessions[dateString] = [
        SimpleQuestion(
          id: 'mock_${dateString}_1',
          questionText: 'Mock question for $dateString - The meeting _____ scheduled for 3 PM.',
          options: ['is', 'are', 'were', 'be'],
          correctAnswerIndex: 0,
          difficultyLevel: 1,
          explanation: 'Mock explanation for demonstration.',
          grammarPoint: 'Subject-Verb Agreement',
          createdAt: date,
        ),
      ];
    }

    return sessions;
  }

  @override
  Future<List<String>> getAvailablePracticeDates() async {
    // Return mock available dates
    final now = DateTime.now();
    final dates = <String>[];

    // Generate mock dates for last 7 days
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dates.add(dateString);
    }

    return dates;
  }

  @override
  Future<List<Question>> getPracticeQuestionsByDate(String date) async {
    // Return mock questions for the specified date
    return [
      SimpleQuestion(
        id: 'mock_${date}_1',
        questionText: 'Mock question for $date - The meeting _____ scheduled for 3 PM.',
        options: ['is', 'are', 'were', 'be'],
        correctAnswerIndex: 0,
        difficultyLevel: 1,
        explanation: 'Mock explanation for demonstration.',
        grammarPoint: 'Subject-Verb Agreement',
        createdAt: DateTime.parse(date),
      ),
      SimpleQuestion(
        id: 'mock_${date}_2',
        questionText: 'Mock question for $date - She _____ to the office every day.',
        options: ['go', 'goes', 'going', 'gone'],
        correctAnswerIndex: 1,
        difficultyLevel: 1,
        explanation: 'Third person singular requires "goes".',
        grammarPoint: 'Subject-Verb Agreement',
        createdAt: DateTime.parse(date),
      ),
    ];
  }

  @override
  Future<List<String>> getAvailableExamRounds() async {
    // Return mock available exam rounds based on realistic test numbers
    return ['ROUND_1', 'ROUND_2', 'ROUND_3'];
  }

  @override
  Future<List<Question>> getExamQuestionsByRound(String round) async {
    // Extract test number from round (ROUND_1 -> 1, ROUND_2 -> 2)
    final testNumber = int.tryParse(round.replaceAll('ROUND_', '')) ?? 1;

    // Generate mock questions with realistic IDs that include test number
    return [
      SimpleQuestion(
        id: 'EXAM_T${testNumber}_L1_GRAM_Q${DateTime.now().millisecondsSinceEpoch}_0',
        questionText: 'Mock question for $round - The company _____ expanding rapidly.',
        options: ['is', 'are', 'was', 'were'],
        correctAnswerIndex: 0,
        difficultyLevel: 1,
        explanation: 'The company is singular, so "is" is correct.',
        grammarPoint: 'Subject-Verb Agreement',
        createdAt: DateTime.now(),
      ),
      SimpleQuestion(
        id: 'EXAM_T${testNumber}_L2_VOC_Q${DateTime.now().millisecondsSinceEpoch + 1}_0',
        questionText: 'Mock question for $round - He _____ finished the report yet.',
        options: ['has not', 'have not', 'did not', 'will not'],
        correctAnswerIndex: 0,
        difficultyLevel: 2,
        explanation: 'Present perfect with "yet" requires "has not".',
        grammarPoint: 'Present Perfect',
        createdAt: DateTime.now(),
      ),
      SimpleQuestion(
        id: 'EXAM_T${testNumber}_L3_GRAM_Q${DateTime.now().millisecondsSinceEpoch + 2}_0',
        questionText: 'Mock question for $round - The proposal _____ reviewed by the board.',
        options: ['will be', 'would be', 'has been', 'is being'],
        correctAnswerIndex: 0,
        difficultyLevel: 3,
        explanation: 'Future passive voice is correct here.',
        grammarPoint: 'Passive Voice',
        createdAt: DateTime.now(),
      ),
    ];
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