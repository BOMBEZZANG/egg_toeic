import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/repositories/base_repository.dart';

// TODO: Switch back to proper models after code generation
typedef Question = SimpleQuestion;

abstract class QuestionRepository extends BaseRepository {
  Future<List<Question>> getQuestions({
    required int difficultyLevel,
    int limit = 10,
  });

  Future<Question?> getQuestionById(String questionId);

  Future<List<Question>> getQuestionsByIds(List<String> questionIds);

  Future<List<Question>> getRandomQuestions({
    int? difficultyLevel,
    int limit = 10,
  });

  Future<void> cacheQuestions(List<Question> questions);

  Future<List<Question>> getCachedQuestions();
}

class QuestionRepositoryImpl implements QuestionRepository {
  final FirebaseFirestore _firestore;
  List<Question> _cachedQuestions = [];

  QuestionRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> initialize() async {
    // Load any cached questions from local storage
    _cachedQuestions = await getCachedQuestions();
  }

  @override
  Future<void> dispose() async {
    _cachedQuestions.clear();
  }

  @override
  Future<List<Question>> getQuestions({
    required int difficultyLevel,
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions_part5')
          .where('difficultyLevel', isEqualTo: difficultyLevel)
          .limit(limit)
          .get();

      final questions = querySnapshot.docs
          .map((doc) => SimpleQuestion.fromFirestore(doc.data(), doc.id))
          .toList();

      // Cache for offline access
      await cacheQuestions(questions);

      return questions;
    } catch (e) {
      // If offline, return cached questions
      return _cachedQuestions
          .where((q) => q.difficultyLevel == difficultyLevel)
          .take(limit)
          .toList();
    }
  }

  @override
  Future<Question?> getQuestionById(String questionId) async {
    try {
      final doc = await _firestore
          .collection('questions_part5')
          .doc(questionId)
          .get();

      if (!doc.exists) return null;

      return SimpleQuestion.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      // Check cache
      try {
        return _cachedQuestions.firstWhere((q) => q.id == questionId);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<List<Question>> getQuestionsByIds(List<String> questionIds) async {
    if (questionIds.isEmpty) return [];

    final questions = <Question>[];

    for (final id in questionIds) {
      final question = await getQuestionById(id);
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  @override
  Future<List<Question>> getRandomQuestions({
    int? difficultyLevel,
    int limit = 10,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection('questions_part5');

      if (difficultyLevel != null) {
        query = query.where('difficultyLevel', isEqualTo: difficultyLevel);
      }

      final snapshot = await query.get();
      final allQuestions = snapshot.docs
          .map((doc) => SimpleQuestion.fromFirestore(doc.data(), doc.id))
          .toList();

      allQuestions.shuffle();

      final selectedQuestions = allQuestions.take(limit).toList();
      await cacheQuestions(selectedQuestions);

      return selectedQuestions;
    } catch (e) {
      // If offline, return cached questions
      var cachedQuestions = _cachedQuestions;
      if (difficultyLevel != null) {
        cachedQuestions = cachedQuestions
            .where((q) => q.difficultyLevel == difficultyLevel)
            .toList();
      }
      cachedQuestions.shuffle();
      return cachedQuestions.take(limit).toList();
    }
  }

  @override
  Future<void> cacheQuestions(List<Question> questions) async {
    _cachedQuestions.addAll(questions);

    // Remove duplicates
    final uniqueIds = <String>{};
    _cachedQuestions = _cachedQuestions
        .where((q) => uniqueIds.add(q.id))
        .toList();

    // Keep only last 100 questions in cache
    if (_cachedQuestions.length > 100) {
      _cachedQuestions = _cachedQuestions
          .skip(_cachedQuestions.length - 100)
          .toList();
    }
  }

  @override
  Future<List<Question>> getCachedQuestions() async {
    // This will be implemented with Hive in local service
    return _cachedQuestions;
  }
}