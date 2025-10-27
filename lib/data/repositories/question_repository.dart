import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/repositories/base_repository.dart';

// TODO: Switch back to proper models after code generation
typedef Question = SimpleQuestion;

abstract class QuestionRepository extends BaseRepository {
  Future<List<Question>> getQuestions({
    required int difficultyLevel,
    int limit = 10,
    String mode = 'practice', // 'practice' or 'exam'
  });

  Future<Question?> getQuestionById(String questionId, {String mode = 'practice'});

  Future<List<Question>> getQuestionsByIds(List<String> questionIds, {String mode = 'practice'});

  Future<List<Question>> getRandomQuestions({
    int? difficultyLevel,
    int limit = 10,
    String mode = 'practice',
  });

  Future<void> cacheQuestions(List<Question> questions);

  Future<List<Question>> getCachedQuestions();

  /// Get practice sessions grouped by date
  Future<Map<String, List<Question>>> getPracticeSessionsByDate({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  /// Get available practice dates from metadata (more efficient)
  Future<List<String>> getAvailablePracticeDates();

  /// Get practice questions for a specific date using metadata
  Future<List<Question>> getPracticeQuestionsByDate(String date);

  /// Get available exam rounds from metadata (more efficient)
  Future<List<String>> getAvailableExamRounds();

  /// Get exam questions for a specific round using metadata
  Future<List<Question>> getExamQuestionsByRound(String round);

  /// Get available Part6 exam rounds from metadata
  Future<List<String>> getAvailablePart6ExamRounds();

  /// Get Part6 exam questions for a specific round
  Future<List<Question>> getPart6ExamQuestionsByRound(String round);

  /// Get available Part6 practice dates from metadata
  Future<List<String>> getAvailablePart6PracticeDates();

  /// Get Part6 practice questions for a specific date
  Future<List<Question>> getPart6PracticeQuestionsByDate(String date);

  /// Get available Part2 exam rounds from metadata
  Future<List<String>> getAvailablePart2ExamRounds();

  /// Get Part2 exam questions for a specific round
  Future<List<Question>> getPart2ExamQuestionsByRound(String round);
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
    String mode = 'practice',
  }) async {
    try {
      // Use correct collection based on mode
      final collectionName = mode == 'exam' ? 'examQuestions' : 'practiceQuestions';
      print('Querying collection: $collectionName');
      print('Difficulty level: $difficultyLevel');
      print('Limit: $limit');
      print('Mode: $mode');

      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('difficultyLevel', isEqualTo: difficultyLevel)
          .where('status', isEqualTo: 'published') // Only get published questions
          .limit(limit)
          .get();

      print('Query completed. Found ${querySnapshot.docs.length} documents');

      final questions = querySnapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => SimpleQuestion.fromFirestore(doc.data()!, doc.id))
          .toList();

      print('Successfully parsed ${questions.length} questions');

      // Cache for offline access
      await cacheQuestions(questions);

      return questions;
    } catch (e) {
      print('Error fetching questions from Firebase: $e');
      print('Error type: ${e.runtimeType}');
      // If offline or error, return cached questions
      final cachedResults = _cachedQuestions
          .where((q) => q.difficultyLevel == difficultyLevel)
          .take(limit)
          .toList();
      print('Returning ${cachedResults.length} cached questions instead');
      return cachedResults;
    }
  }

  @override
  Future<Question?> getQuestionById(String questionId, {String mode = 'practice'}) async {
    try {
      final collectionName = mode == 'exam' ? 'examQuestions' : 'practiceQuestions';
      print('🔍 Fetching question ID: $questionId from collection: $collectionName');

      final doc = await _firestore
          .collection(collectionName)
          .doc(questionId)
          .get();

      if (!doc.exists) {
        print('❌ Question $questionId does not exist in $collectionName');
        return null;
      }

      final question = SimpleQuestion.fromFirestore(doc.data()!, doc.id);
      print('✅ Successfully fetched question: $questionId');
      return question;
    } catch (e) {
      print('❌ Error fetching question $questionId: $e');
      // Check cache
      try {
        final cachedQuestion = _cachedQuestions.firstWhere((q) => q.id == questionId);
        print('✅ Found question $questionId in cache');
        return cachedQuestion;
      } catch (_) {
        print('❌ Question $questionId not found in cache either');
        return null;
      }
    }
  }

  @override
  Future<List<Question>> getQuestionsByIds(List<String> questionIds, {String mode = 'practice'}) async {
    if (questionIds.isEmpty) return [];

    print('🚀 Fetching ${questionIds.length} questions by IDs from both collections: $questionIds');

    // Try to fetch from both practice and exam collections in parallel
    final questions = <Question>[];

    // Create futures for both collections in parallel
    final futures = questionIds.map((id) async {
      // Try practice collection first
      Question? question = await getQuestionById(id, mode: 'practice');

      // If not found in practice, try exam collection
      if (question == null) {
        question = await getQuestionById(id, mode: 'exam');
      }

      if (question == null) {
        print('⚠️ Question $id not found in either collection');
      }

      return question;
    });

    // Wait for all futures to complete
    final results = await Future.wait(futures);

    // Filter out null results
    questions.addAll(results.where((q) => q != null).cast<Question>());

    print('✅ Successfully fetched ${questions.length}/${questionIds.length} questions from both collections');
    return questions;
  }

  @override
  Future<List<Question>> getRandomQuestions({
    int? difficultyLevel,
    int limit = 10,
    String mode = 'practice',
  }) async {
    try {
      final collectionName = mode == 'exam' ? 'examQuestions' : 'practiceQuestions';

      Query<Map<String, dynamic>> query = _firestore.collection(collectionName);

      // Only get published questions
      query = query.where('status', isEqualTo: 'published');

      if (difficultyLevel != null) {
        query = query.where('difficultyLevel', isEqualTo: difficultyLevel);
      }

      final snapshot = await query.get();
      final allQuestions = snapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => SimpleQuestion.fromFirestore(doc.data()!, doc.id))
          .toList();

      allQuestions.shuffle();

      final selectedQuestions = allQuestions.take(limit).toList();
      await cacheQuestions(selectedQuestions);

      return selectedQuestions;
    } catch (e) {
      print('Error fetching random questions from Firebase: $e');
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

  @override
  Future<Map<String, List<Question>>> getPracticeSessionsByDate({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      print('🚀 Using metadata system to fetch practice sessions by date');

      // Get available dates from metadata (much more efficient!)
      final availableDates = await getAvailablePracticeDates();

      if (availableDates.isEmpty) {
        print('⚠️ No available practice dates found in metadata, falling back to old method');
        return await _fallbackGetPracticeSessionsByDate(startDate, endDate, limit);
      }

      // Filter dates based on date range if specified
      var filteredDates = availableDates;

      if (startDate != null || endDate != null) {
        final start = startDate ?? DateTime(2020, 1, 1); // Far past date
        final end = endDate ?? DateTime.now().add(const Duration(days: 1)); // Tomorrow

        filteredDates = availableDates.where((dateString) {
          try {
            final date = DateTime.parse(dateString);
            return date.isAfter(start.subtract(const Duration(days: 1))) &&
                   date.isBefore(end.add(const Duration(days: 1)));
          } catch (e) {
            print('⚠️ Invalid date format: $dateString');
            return false;
          }
        }).toList();
      }

      // Sort dates in descending order (latest first)
      filteredDates.sort((a, b) => b.compareTo(a));

      // Apply limit if specified
      if (limit != null && filteredDates.length > limit) {
        filteredDates = filteredDates.take(limit).toList();
      }

      print('📅 Processing ${filteredDates.length} dates: $filteredDates');

      // Fetch questions for each date using metadata
      final Map<String, List<Question>> groupedByDate = {};

      for (final date in filteredDates) {
        final questions = await getPracticeQuestionsByDate(date);
        if (questions.isNotEmpty) {
          groupedByDate[date] = questions;
        }
      }

      print('✅ Successfully loaded ${groupedByDate.length} practice sessions using metadata system');
      return groupedByDate;

    } catch (e) {
      print('❌ Error with metadata system, falling back to old method: $e');
      return await _fallbackGetPracticeSessionsByDate(startDate, endDate, limit);
    }
  }

  /// Fallback method using the old approach (scanning all questions)
  Future<Map<String, List<Question>>> _fallbackGetPracticeSessionsByDate(
    DateTime? startDate,
    DateTime? endDate,
    int? limit
  ) async {
    try {
      // Default to last 30 days if no range specified
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 30));

      print('Querying practice questions from ${start.toIso8601String()} to ${end.toIso8601String()}');

      // Try to query practice questions first
      Query<Map<String, dynamic>> query = _firestore
          .collection('practiceQuestions')
          .where('status', isEqualTo: 'published')
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      print('Found ${querySnapshot.docs.length} practice questions');

      if (querySnapshot.docs.isEmpty) {
        // No practice questions found, try to get regular questions and create practice sessions
        print('No practice questions found, creating practice sessions from regular questions');
        return _createPracticeSessionsFromRegularQuestions(start, end);
      }

      final questions = querySnapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => SimpleQuestion.fromFirestore(doc.data()!, doc.id))
          .toList();

      // Group questions by date (YYYY-MM-DD format)
      final Map<String, List<Question>> groupedByDate = {};

      for (final question in questions) {
        // Extract date from question ID or use createdAt
        String dateKey;

        // Try to extract date from practice question ID format: PRAC_YYYY_MM_DD_Q1
        if (question.id.startsWith('PRAC_') && question.id.contains('_')) {
          final parts = question.id.split('_');
          if (parts.length >= 4) {
            // PRAC_YYYY_MM_DD format
            final year = parts[1];
            final month = parts[2].padLeft(2, '0');
            final day = parts[3].padLeft(2, '0');
            dateKey = '$year-$month-$day';
          } else {
            // Fallback to createdAt date
            final date = question.createdAt ?? DateTime.now();
            dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          }
        } else {
          // Fallback to createdAt date
          final date = question.createdAt ?? DateTime.now();
          dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }

        groupedByDate.putIfAbsent(dateKey, () => []);
        groupedByDate[dateKey]!.add(question);
      }

      print('Grouped questions into ${groupedByDate.length} dates');
      for (final entry in groupedByDate.entries) {
        print('Date ${entry.key}: ${entry.value.length} questions');
      }

      return groupedByDate;

    } catch (e) {
      print('Error fetching practice sessions by date: $e');
      print('Error type: ${e.runtimeType}');

      // Fallback to creating practice sessions from regular questions
      try {
        final end = endDate ?? DateTime.now();
        final start = startDate ?? end.subtract(const Duration(days: 30));
        return await _createPracticeSessionsFromRegularQuestions(start, end);
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
        // Return empty map on complete failure
        return {};
      }
    }
  }

  @override
  Future<List<String>> getAvailablePracticeDates() async {
    try {
      print('🔍 Fetching available practice dates from metadata...');

      // Get practice summary metadata
      final summaryDoc = await _firestore
          .collection('metadata')
          .doc('practice')
          .get();

      if (!summaryDoc.exists) {
        print('❌ Practice summary metadata not found');
        return [];
      }

      final data = summaryDoc.data()!;
      final List<dynamic> availableDatesRaw = data['availableDates'] ?? [];
      final availableDates = availableDatesRaw.cast<String>();

      print('✅ Found ${availableDates.length} available practice dates: $availableDates');
      return availableDates;

    } catch (e) {
      print('❌ Error fetching available practice dates: $e');
      return [];
    }
  }

  @override
  Future<List<Question>> getPracticeQuestionsByDate(String date) async {
    try {
      print('🔍 Fetching practice questions for date: $date');

      // Get daily metadata for the specific date
      final dailyMetadataDoc = await _firestore
          .collection('metadata')
          .doc('practice')
          .collection('daily')
          .doc(date)
          .get();

      if (!dailyMetadataDoc.exists) {
        print('❌ Daily metadata not found for date: $date - no questions available');
        return []; // Return empty list instead of generating fallback questions
      }

      final dailyData = dailyMetadataDoc.data()!;
      final List<dynamic> questionIdsRaw = dailyData['questionIds'] ?? [];
      final questionIds = questionIdsRaw.cast<String>();

      print('📋 Found ${questionIds.length} question IDs for date $date: $questionIds');

      if (questionIds.isEmpty) {
        print('❌ No question IDs found for date: $date - no questions available');
        return []; // Return empty list instead of generating fallback questions
      }

      // Fetch questions by IDs
      final questions = await getQuestionsByIds(questionIds, mode: 'practice');
      print('✅ Successfully fetched ${questions.length} questions for date $date');

      // If we got no questions from the metadata IDs, return empty list
      if (questions.isEmpty) {
        print('⚠️ No questions found from metadata IDs for date $date - no questions available');
        return []; // Return empty list instead of generating fallback questions
      }

      return questions;

    } catch (e) {
      print('❌ Error fetching practice questions for date $date: $e - no questions available');
      return []; // Return empty list instead of generating fallback questions
    }
  }

  /// Generate fallback practice questions for a specific date when metadata fails
  Future<List<Question>> _generateFallbackQuestionsForDate(String date) async {
    try {
      print('🔄 Generating fallback questions for date: $date');

      // Get random questions from practiceQuestions collection
      final questions = await getRandomQuestions(limit: 10, mode: 'practice');

      if (questions.isNotEmpty) {
        print('✅ Generated ${questions.length} fallback questions for date $date');
        return questions;
      }

      // If practiceQuestions is empty, try to get from other collections
      return await _generateFallbackFromOtherCollections();

    } catch (e) {
      print('❌ Error generating fallback questions: $e');
      return [];
    }
  }

  /// Generate questions from other collections when practiceQuestions is not available
  Future<List<Question>> _generateFallbackFromOtherCollections() async {
    try {
      print('🔄 Generating fallback from other collections');

      // Try different collections
      final collections = ['examQuestions', 'questions_part5', 'part5_questions', 'questions'];

      for (final collectionName in collections) {
        try {
          final snapshot = await _firestore
              .collection(collectionName)
              .limit(10)
              .get();

          if (snapshot.docs.isNotEmpty) {
            final questions = snapshot.docs
                .where((doc) => doc.data() != null)
                .map((doc) => SimpleQuestion.fromFirestore(doc.data()!, doc.id))
                .toList();

            print('✅ Generated ${questions.length} questions from collection: $collectionName');
            return questions;
          }
        } catch (e) {
          print('❌ Failed to get questions from $collectionName: $e');
          continue;
        }
      }

      print('❌ No questions found in any collection');
      return [];

    } catch (e) {
      print('❌ Error generating fallback from other collections: $e');
      return [];
    }
  }

  Future<Map<String, List<Question>>> _createPracticeSessionsFromRegularQuestions(DateTime start, DateTime end) async {
    try {
      print('Creating practice sessions from regular questions');

      // Get questions from regular collection (questions_part5 or whatever exists)
      final collections = ['questions_part5', 'part5_questions', 'questions'];
      Query<Map<String, dynamic>>? workingQuery;

      // Try different collection names
      for (final collectionName in collections) {
        try {
          final testQuery = _firestore.collection(collectionName).limit(1);
          final testSnapshot = await testQuery.get();
          if (testSnapshot.docs.isNotEmpty) {
            workingQuery = _firestore
                .collection(collectionName)
                .orderBy(FieldPath.documentId)
                .limit(100); // Get up to 100 questions
            print('Using collection: $collectionName');
            break;
          }
        } catch (e) {
          print('Collection $collectionName not accessible: $e');
          continue;
        }
      }

      if (workingQuery == null) {
        print('No accessible question collections found');
        return {};
      }

      final querySnapshot = await workingQuery.get();
      print('Found ${querySnapshot.docs.length} regular questions for practice sessions');

      if (querySnapshot.docs.isEmpty) {
        return {};
      }

      final allQuestions = querySnapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => SimpleQuestion.fromFirestore(doc.data()!, doc.id))
          .toList();

      // Create practice sessions by grouping 10 questions per day
      final Map<String, List<Question>> practiceSessionsByDate = {};
      final now = DateTime.now();

      // Create sessions for the last 10 days
      for (int i = 0; i < 10; i++) {
        final sessionDate = now.subtract(Duration(days: i));
        final dateKey = '${sessionDate.year}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}';

        // Get 10 random questions for each session, mixing difficulty levels
        final sessionQuestions = <Question>[];
        final shuffledQuestions = List<Question>.from(allQuestions)..shuffle();

        // Try to get a good mix: 3 level 1, 4 level 2, 3 level 3
        final level1 = shuffledQuestions.where((q) => q.difficultyLevel == 1).take(3).toList();
        final level2 = shuffledQuestions.where((q) => q.difficultyLevel == 2).take(4).toList();
        final level3 = shuffledQuestions.where((q) => q.difficultyLevel == 3).take(3).toList();

        sessionQuestions.addAll(level1);
        sessionQuestions.addAll(level2);
        sessionQuestions.addAll(level3);

        // Fill remaining spots if needed
        while (sessionQuestions.length < 10 && sessionQuestions.length < shuffledQuestions.length) {
          final remainingQuestions = shuffledQuestions.where((q) => !sessionQuestions.contains(q));
          if (remainingQuestions.isNotEmpty) {
            sessionQuestions.add(remainingQuestions.first);
          } else {
            break;
          }
        }

        if (sessionQuestions.isNotEmpty) {
          practiceSessionsByDate[dateKey] = sessionQuestions;
        }
      }

      print('Created ${practiceSessionsByDate.length} practice sessions');
      return practiceSessionsByDate;

    } catch (e) {
      print('Error creating practice sessions from regular questions: $e');
      return {};
    }
  }

  @override
  Future<List<String>> getAvailableExamRounds() async {
    try {
      print('🔍 Fetching available exam rounds by scanning question IDs...');

      // Get all exam questions and extract unique test numbers from IDs
      final querySnapshot = await _firestore
          .collection('examQuestions')
          .where('status', isEqualTo: 'published')
          .get();

      final Set<String> uniqueRounds = {};

      for (final doc in querySnapshot.docs) {
        final questionId = doc.id;
        // Extract test number from ID format: EXAM_T2_L2_GRAM_Q1758868836258_0
        final testNumber = _extractTestNumberFromId(questionId);
        if (testNumber != null) {
          uniqueRounds.add('ROUND_$testNumber');
        }
      }

      final availableRounds = uniqueRounds.toList();

      // Sort rounds in order (ROUND_1, ROUND_2, etc.)
      availableRounds.sort((a, b) {
        final aNum = int.tryParse(a.replaceAll('ROUND_', '')) ?? 0;
        final bNum = int.tryParse(b.replaceAll('ROUND_', '')) ?? 0;
        return aNum.compareTo(bNum);
      });

      print('✅ Found ${availableRounds.length} available exam rounds: $availableRounds');
      return availableRounds;

    } catch (e) {
      print('❌ Error fetching available exam rounds: $e');
      // Fallback to metadata if available
      try {
        final summaryDoc = await _firestore
            .collection('metadata')
            .doc('exam')
            .get();

        if (summaryDoc.exists) {
          final data = summaryDoc.data()!;
          final List<dynamic> availableRoundsRaw = data['availableRounds'] ?? [];
          return availableRoundsRaw.cast<String>();
        }
      } catch (metadataError) {
        print('❌ Metadata fallback also failed: $metadataError');
      }
      return [];
    }
  }

  @override
  Future<List<Question>> getExamQuestionsByRound(String round) async {
    try {
      print('🔍 Fetching exam questions for round: $round');

      // Extract test number from round (ROUND_1 -> 1, ROUND_2 -> 2)
      final testNumber = int.tryParse(round.replaceAll('ROUND_', ''));
      if (testNumber == null) {
        print('❌ Invalid round format: $round');
        return [];
      }

      print('🎯 Looking for questions with test number: T$testNumber');

      // Get all exam questions and filter by test number in ID
      final querySnapshot = await _firestore
          .collection('examQuestions')
          .where('status', isEqualTo: 'published')
          .get();

      final List<Question> roundQuestions = [];

      for (final doc in querySnapshot.docs) {
        final questionId = doc.id;
        final questionTestNumber = _extractTestNumberFromId(questionId);

        // Filter questions that match the requested test number
        if (questionTestNumber == testNumber) {
          try {
            final question = SimpleQuestion.fromFirestore(doc.data(), doc.id);
            roundQuestions.add(question);
            print('✅ Added question: $questionId (T$questionTestNumber)');
          } catch (e) {
            print('⚠️ Failed to parse question $questionId: $e');
          }
        }
      }

      print('✅ Found ${roundQuestions.length} questions for round $round (T$testNumber)');

      // Sort questions by question number if possible
      roundQuestions.sort((a, b) {
        final aNum = _extractQuestionNumberFromId(a.id) ?? 0;
        final bNum = _extractQuestionNumberFromId(b.id) ?? 0;
        return aNum.compareTo(bNum);
      });

      if (roundQuestions.isEmpty) {
        print('⚠️ No questions found for round $round, generating fallback');
        return await _generateFallbackQuestionsForRound(round);
      }

      return roundQuestions;

    } catch (e) {
      print('❌ Error fetching exam questions for round $round: $e');
      return await _generateFallbackQuestionsForRound(round);
    }
  }

  /// Generate fallback exam questions for a specific round when metadata fails
  Future<List<Question>> _generateFallbackQuestionsForRound(String round) async {
    try {
      print('🔄 Generating fallback questions for round: $round');

      // Get random questions from examQuestions collection
      final questions = await getRandomQuestions(limit: 20, mode: 'exam');

      if (questions.isNotEmpty) {
        print('✅ Generated ${questions.length} fallback questions for round $round');
        return questions;
      }

      // If examQuestions is empty, try to get from other collections
      return await _generateFallbackFromOtherCollections();

    } catch (e) {
      print('❌ Error generating fallback questions: $e');
      return [];
    }
  }

  /// Extract test number from question ID
  /// Format: EXAM_T2_L2_GRAM_Q1758868836258_0 -> returns 2
  int? _extractTestNumberFromId(String questionId) {
    try {
      // Split by underscore and find the part that starts with 'T'
      final parts = questionId.split('_');
      for (final part in parts) {
        if (part.startsWith('T') && part.length > 1) {
          final testNumberStr = part.substring(1); // Remove 'T'
          return int.tryParse(testNumberStr);
        }
      }
      return null;
    } catch (e) {
      print('⚠️ Error extracting test number from ID $questionId: $e');
      return null;
    }
  }

  /// Extract question number from question ID for sorting
  /// Format: EXAM_T2_L2_GRAM_Q1758868836258_0 -> returns timestamp for sorting
  int? _extractQuestionNumberFromId(String questionId) {
    try {
      // Try to extract timestamp from Q part for rough ordering
      final qIndex = questionId.indexOf('Q');
      if (qIndex != -1 && qIndex < questionId.length - 1) {
        final afterQ = questionId.substring(qIndex + 1);
        // Split by underscore to get just the timestamp part
        final timestampPart = afterQ.split('_')[0];
        return int.tryParse(timestampPart);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<String>> getAvailablePart6ExamRounds() async {
    try {
      print('🔍 Fetching available Part6 exam rounds by scanning question IDs...');

      // Get all Part6 exam questions and extract unique test numbers from IDs
      final querySnapshot = await _firestore
          .collection('part6examQuestions')
          .where('status', isEqualTo: 'published')
          .get();

      final Set<String> uniqueRounds = {};

      for (final doc in querySnapshot.docs) {
        final questionId = doc.id;
        // Extract test number from ID format: Part6_EXAM_T1_P6_Q131
        final testNumber = _extractPart6TestNumberFromId(questionId);
        if (testNumber != null) {
          uniqueRounds.add('ROUND_$testNumber');
        }
      }

      final availableRounds = uniqueRounds.toList();

      // Sort rounds in order (ROUND_1, ROUND_2, etc.)
      availableRounds.sort((a, b) {
        final aNum = int.tryParse(a.replaceAll('ROUND_', '')) ?? 0;
        final bNum = int.tryParse(b.replaceAll('ROUND_', '')) ?? 0;
        return aNum.compareTo(bNum);
      });

      print('✅ Found ${availableRounds.length} available Part6 exam rounds: $availableRounds');
      return availableRounds;

    } catch (e) {
      print('❌ Error fetching available Part6 exam rounds: $e');
      return [];
    }
  }

  @override
  Future<List<Question>> getPart6ExamQuestionsByRound(String round) async {
    try {
      print('🔍 Fetching Part6 exam questions for round: $round');

      // Extract test number from round (ROUND_1 -> 1, ROUND_2 -> 2)
      final testNumber = int.tryParse(round.replaceAll('ROUND_', ''));
      if (testNumber == null) {
        print('❌ Invalid round format: $round');
        return [];
      }

      print('🎯 Looking for Part6 questions with test number: T$testNumber');

      // Get all Part6 exam questions and filter by test number in ID
      final querySnapshot = await _firestore
          .collection('part6examQuestions')
          .where('status', isEqualTo: 'published')
          .get();

      final List<Question> roundQuestions = [];

      for (final doc in querySnapshot.docs) {
        final questionId = doc.id;
        final questionTestNumber = _extractPart6TestNumberFromId(questionId);

        // Filter questions that match the requested test number
        if (questionTestNumber == testNumber) {
          try {
            final question = SimpleQuestion.fromFirestore(doc.data(), doc.id);
            roundQuestions.add(question);
            print('✅ Added Part6 question: $questionId (T$questionTestNumber)');
          } catch (e) {
            print('⚠️ Failed to parse Part6 question $questionId: $e');
          }
        }
      }

      print('✅ Found ${roundQuestions.length} Part6 questions for round $round (T$testNumber)');

      // Sort questions by question number extracted from ID
      roundQuestions.sort((a, b) {
        final aNum = _extractPart6QuestionNumberFromId(a.id) ?? 0;
        final bNum = _extractPart6QuestionNumberFromId(b.id) ?? 0;
        return aNum.compareTo(bNum);
      });

      return roundQuestions;

    } catch (e) {
      print('❌ Error fetching Part6 exam questions for round $round: $e');
      return [];
    }
  }

  /// Extract test number from Part6 question ID
  /// Format: Part6_EXAM_T1_P6_Q131 -> returns 1
  int? _extractPart6TestNumberFromId(String questionId) {
    try {
      // Split by underscore and find the part that starts with 'T'
      final parts = questionId.split('_');
      for (final part in parts) {
        if (part.startsWith('T') && part.length > 1) {
          final testNumberStr = part.substring(1); // Remove 'T'
          return int.tryParse(testNumberStr);
        }
      }
      return null;
    } catch (e) {
      print('⚠️ Error extracting test number from Part6 ID $questionId: $e');
      return null;
    }
  }

  /// Extract question number from Part6 question ID for sorting
  /// Format: Part6_EXAM_T1_P6_Q131 -> returns 131
  int? _extractPart6QuestionNumberFromId(String questionId) {
    try {
      // Find the part that starts with 'Q' and extract the number after it
      final parts = questionId.split('_');
      for (final part in parts) {
        if (part.startsWith('Q') && part.length > 1) {
          final questionNumberStr = part.substring(1); // Remove 'Q'
          return int.tryParse(questionNumberStr);
        }
      }
      return null;
    } catch (e) {
      print('⚠️ Error extracting question number from Part6 ID $questionId: $e');
      return null;
    }
  }

  @override
  Future<List<String>> getAvailablePart6PracticeDates() async {
    try {
      print('🔍 Fetching available Part6 practice dates from metadata...');

      // Get Part6 practice summary metadata
      final summaryDoc = await _firestore
          .collection('metadata')
          .doc('part6_practice')
          .get();

      if (!summaryDoc.exists) {
        print('❌ Part6 practice summary metadata not found');
        return [];
      }

      final data = summaryDoc.data()!;
      final List<dynamic> availableDatesRaw = data['availableDates'] ?? [];
      final availableDates = availableDatesRaw.cast<String>();

      print('✅ Found ${availableDates.length} available Part6 practice dates: $availableDates');
      return availableDates;

    } catch (e) {
      print('❌ Error fetching available Part6 practice dates: $e');
      return [];
    }
  }

  @override
  Future<List<Question>> getPart6PracticeQuestionsByDate(String date) async {
    try {
      print('🔍 Fetching Part6 practice questions for date: $date');

      // Get daily metadata for the specific date
      final dailyMetadataDoc = await _firestore
          .collection('metadata')
          .doc('part6_practice')
          .collection('daily')
          .doc(date)
          .get();

      if (!dailyMetadataDoc.exists) {
        print('❌ Daily Part6 practice metadata not found for date: $date - no questions available');
        return [];
      }

      final dailyData = dailyMetadataDoc.data()!;
      final List<dynamic> questionIdsRaw = dailyData['questionIds'] ?? [];
      final questionIds = questionIdsRaw.cast<String>();

      print('📋 Found ${questionIds.length} Part6 practice question IDs for date $date: $questionIds');

      if (questionIds.isEmpty) {
        print('❌ No Part6 practice question IDs found for date: $date - no questions available');
        return [];
      }

      // Fetch questions by IDs from part6practiceQuestions collection
      final questions = <Question>[];
      for (final questionId in questionIds) {
        try {
          final doc = await _firestore
              .collection('part6practiceQuestions')
              .doc(questionId)
              .get();

          if (doc.exists) {
            final question = SimpleQuestion.fromFirestore(doc.data()!, doc.id);
            questions.add(question);
          } else {
            print('⚠️ Part6 practice question $questionId not found in collection');
          }
        } catch (e) {
          print('❌ Error fetching Part6 practice question $questionId: $e');
        }
      }

      print('✅ Successfully fetched ${questions.length} Part6 practice questions for date $date');

      // Sort questions by question number if possible
      questions.sort((a, b) {
        final aNum = _extractPart6QuestionNumberFromId(a.id) ?? 0;
        final bNum = _extractPart6QuestionNumberFromId(b.id) ?? 0;
        return aNum.compareTo(bNum);
      });

      return questions;

    } catch (e) {
      print('❌ Error fetching Part6 practice questions for date $date: $e - no questions available');
      return [];
    }
  }

  @override
  Future<List<String>> getAvailablePart2ExamRounds() async {
    try {
      print('🔍 Fetching available Part2 exam rounds from metadata...');

      // Get available rounds from metadata/part2_exam summary
      final summaryDoc = await _firestore
          .collection('metadata')
          .doc('part2_exam')
          .get();

      if (!summaryDoc.exists) {
        print('⚠️ Part2 exam metadata not found, falling back to question scan');
        return await _getAvailablePart2ExamRoundsFallback();
      }

      final data = summaryDoc.data();
      final availableRounds = List<String>.from(data?['availableRounds'] ?? []);

      // Sort rounds in order (test-1, test-2, etc. -> ROUND_1, ROUND_2)
      availableRounds.sort((a, b) {
        final aNum = int.tryParse(a.replaceAll('test-', '')) ?? 0;
        final bNum = int.tryParse(b.replaceAll('test-', '')) ?? 0;
        return aNum.compareTo(bNum);
      });

      // Convert test-1 format to ROUND_1 format
      final formattedRounds = availableRounds.map((round) {
        final testNum = round.replaceAll('test-', '');
        return 'ROUND_$testNum';
      }).toList();

      print('✅ Found ${formattedRounds.length} Part2 exam rounds from metadata: $formattedRounds');
      return formattedRounds;

    } catch (e) {
      print('❌ Error fetching Part2 exam rounds from metadata: $e');
      return await _getAvailablePart2ExamRoundsFallback();
    }
  }

  /// Fallback method to get Part2 exam rounds by scanning question IDs
  Future<List<String>> _getAvailablePart2ExamRoundsFallback() async {
    try {
      print('🔍 Fallback: Scanning Part2 exam question IDs...');

      final querySnapshot = await _firestore
          .collection('part2examQuestions')
          .where('status', isEqualTo: 'published')
          .get();

      final Set<String> uniqueRounds = {};

      for (final doc in querySnapshot.docs) {
        final questionId = doc.id;
        // Extract test number from ID format: Part2_EXAM_T1_P2_Q7
        final testNumber = _extractPart2TestNumberFromId(questionId);
        if (testNumber != null) {
          uniqueRounds.add('ROUND_$testNumber');
        }
      }

      final sortedRounds = uniqueRounds.toList()..sort();
      print('✅ Found ${sortedRounds.length} Part2 exam rounds via fallback: $sortedRounds');
      return sortedRounds;

    } catch (e) {
      print('❌ Error in Part2 exam rounds fallback: $e');
      return [];
    }
  }

  @override
  Future<List<Question>> getPart2ExamQuestionsByRound(String round) async {
    try {
      final roundNumber = round.replaceAll('ROUND_', '');
      final roundId = 'test-$roundNumber';
      print('🔍 Fetching Part2 exam questions for round: $round (roundId: $roundId)');

      // Try to get question IDs from metadata first
      final roundMetadataDoc = await _firestore
          .collection('metadata')
          .doc('part2_exam')
          .collection('rounds')
          .doc(roundId)
          .get();

      List<String> questionIds = [];

      if (roundMetadataDoc.exists) {
        // Get question IDs from metadata
        final data = roundMetadataDoc.data();
        questionIds = List<String>.from(data?['questionIds'] ?? []);
        print('📋 Found ${questionIds.length} question IDs from metadata');
      } else {
        print('⚠️ Metadata not found, falling back to scanning questions');
        // Fallback: scan all questions
        final querySnapshot = await _firestore
            .collection('part2examQuestions')
            .where('status', isEqualTo: 'published')
            .get();

        for (final doc in querySnapshot.docs) {
          if (doc.id.startsWith('Part2_EXAM_T${roundNumber}_')) {
            questionIds.add(doc.id);
          }
        }
      }

      if (questionIds.isEmpty) {
        print('⚠️ No question IDs found for round $round');
        return [];
      }

      // Fetch questions by IDs
      final questions = <Question>[];
      for (final questionId in questionIds) {
        try {
          final doc = await _firestore
              .collection('part2examQuestions')
              .doc(questionId)
              .get();

          if (doc.exists) {
            final data = doc.data();
            questions.add(Question.fromFirestore(data!, questionId));
          } else {
            print('⚠️ Part2 exam question $questionId not found in collection');
          }
        } catch (e) {
          print('❌ Error fetching Part2 exam question $questionId: $e');
        }
      }

      // Sort questions by question number (Q7-Q31 for Part 2)
      questions.sort((a, b) {
        final aNum = _extractPart2QuestionNumberFromId(a.id) ?? 0;
        final bNum = _extractPart2QuestionNumberFromId(b.id) ?? 0;
        return aNum.compareTo(bNum);
      });

      print('✅ Successfully fetched ${questions.length} Part2 exam questions for round $round');
      return questions;

    } catch (e) {
      print('❌ Error fetching Part2 exam questions for round $round: $e');
      return [];
    }
  }

  // Helper method to extract test number from Part2 exam question ID
  // Format: Part2_EXAM_T1_P2_Q7 -> returns "1"
  int? _extractPart2TestNumberFromId(String questionId) {
    final regex = RegExp(r'Part2_EXAM_T(\d+)_');
    final match = regex.firstMatch(questionId);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  // Helper method to extract question number from Part2 question ID
  // Format: Part2_EXAM_T1_P2_Q7 -> returns 7
  int? _extractPart2QuestionNumberFromId(String questionId) {
    final regex = RegExp(r'_Q(\d+)$');
    final match = regex.firstMatch(questionId);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }
}