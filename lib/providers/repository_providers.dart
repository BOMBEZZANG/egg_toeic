import 'package:egg_toeic/data/models/question_analytics_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egg_toeic/data/repositories/user_data_repository.dart';
import 'package:egg_toeic/data/repositories/question_repository.dart';
import 'package:egg_toeic/data/repositories/analytics_repository.dart';
import 'package:egg_toeic/data/datasources/remote/analytics_service.dart';
import 'package:egg_toeic/data/models/learning_session_model.dart';
import 'package:egg_toeic/data/models/simple_models.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepositoryImpl(); // Switch to Firebase-connected repository
});

// Use the full UserDataRepositoryImpl with Hive persistence
final userDataRepositoryProvider = Provider<UserDataRepository>((ref) {
  return _UserDataRepositorySingleton.instance;
});

// Singleton to ensure we keep the same repository instance
class _UserDataRepositorySingleton {
  static final UserDataRepositoryImpl _instance = UserDataRepositoryImpl();
  static UserDataRepositoryImpl get instance => _instance;
}

// Practice sessions provider - fetches grouped questions by date from Firebase
final practiceSessionsProvider =
    FutureProvider<Map<String, List<Question>>>((ref) async {
  final questionRepo = ref.read(questionRepositoryProvider);
  return await questionRepo.getPracticeSessionsByDate();
});

// Metadata-only practice sessions provider - only gets dates and counts (much faster)
// Legacy provider for Part 5 (backward compatibility)
final practiceSessionMetadataProvider =
    FutureProvider<List<PracticeSessionMetadata>>((ref) async {
  return ref.read(practiceSessionMetadataByPartProvider(5).future);
});

// Part-specific practice session metadata provider
final practiceSessionMetadataByPartProvider =
    FutureProvider.family<List<PracticeSessionMetadata>, int>((ref, partNumber) async {
  final userDataRepo = ref.read(userDataRepositoryProvider);
  final questionRepo = ref.read(questionRepositoryProvider);

  try {
    // Get available practice dates from Firebase based on part number
    List<String> availableDates;
    if (partNumber == 5) {
      availableDates = await questionRepo.getAvailablePracticeDates();
    } else if (partNumber == 6) {
      availableDates = await questionRepo.getAvailablePart6PracticeDates();
    } else {
      return [];
    }

    if (availableDates.isEmpty) {
      return [];
    }

    // Get actual learning sessions from user data
    final learningSessions = await userDataRepo.getLearningSessions();

    print('🔍 Part $partNumber: Total learning sessions found: ${learningSessions.length}');

    // Group user sessions by practice date and filter by part number
    final sessionsByDate = <DateTime, List<LearningSession>>{};
    for (final session in learningSessions) {
      // Debug: Show session type and first question ID
      final firstQuestionId = session.questionIds.isNotEmpty ? session.questionIds.first : 'no questions';
      print('🔍 Part $partNumber: Checking session ${session.id} (type: ${session.sessionType}, first Q: $firstQuestionId)');

      // Accept both 'practice' (Part 5) and 'part6_practice' (Part 6) session types
      if (session.sessionType == 'practice' || session.sessionType == 'part6_practice') {
        // Check if this session is for the requested part
        // Part 5: question IDs start with "PRAC_" and do NOT contain "Part6"
        // Part 6: question IDs contain "Part6"
        bool isCorrectPart = false;
        for (final questionId in session.questionIds) {
          if (partNumber == 5 && questionId.startsWith('PRAC_') && !questionId.contains('Part6')) {
            isCorrectPart = true;
            print('✅ Part 5 match found: $questionId');
            break;
          } else if (partNumber == 6 && questionId.contains('Part6')) {
            isCorrectPart = true;
            print('✅ Part 6 match found: $questionId');
            break;
          }
        }

        if (!isCorrectPart) {
          print('❌ Session ${session.id} does not match Part $partNumber');
          continue;
        }

        // Extract date from session ID (format: practice_YYYY-MM-DD_timestamp)
        final practiceDate = _extractDateFromSessionId(session.id);
        if (practiceDate != null) {
          final dateKey = DateTime(
            practiceDate.year,
            practiceDate.month,
            practiceDate.day
          );
          sessionsByDate.putIfAbsent(dateKey, () => []).add(session);
          print('📅 Part $partNumber Session ${session.id}: extracted date $dateKey (${session.questionsAnswered} questions, ${session.correctAnswers} correct)');
        } else {
          print('⚠️ Could not extract date from session ID: ${session.id}');
        }
      }
    }

    print('📊 Part $partNumber: Total sessions grouped by date: ${sessionsByDate.length} dates with practice data');

    // Create metadata for ALL available dates from Firebase
    final metadataList = <PracticeSessionMetadata>[];

    for (int i = 0; i < availableDates.length; i++) {
      final dateString = availableDates[i];
      final date = DateTime.parse(dateString);
      final dateKey = DateTime(date.year, date.month, date.day);
      final sessionNumber = availableDates.length - i;

      // Check if user has actual practice data for this date
      final userSessions = sessionsByDate[dateKey];

      int completedQuestions = 0;
      int correctAnswers = 0;

      if (userSessions != null && userSessions.isNotEmpty) {
        // User has practiced on this date - use actual data
        for (final session in userSessions) {
          completedQuestions += session.questionsAnswered;
          correctAnswers += session.correctAnswers;
        }
      }

      // Always add the date (since it has questions available)
      metadataList.add(PracticeSessionMetadata(
        id: 'firebase_${dateString.replaceAll('-', '_')}',
        date: date,
        totalQuestions: partNumber == 6 ? 4 : 10, // Part 6 has 4 questions per passage, Part 5 has 10
        completedQuestions: completedQuestions.clamp(0, partNumber == 6 ? 4 : 10),
        accuracy: completedQuestions > 0 ? correctAnswers / completedQuestions : 0.0,
        sessionNumber: sessionNumber,
      ));
    }

    return metadataList;
  } catch (e) {
    print('❌ Error loading Part $partNumber practice metadata: $e');
    // Return empty list on error
    return [];
  }
});


// Metadata-only class for practice sessions (no questions, just info)
class PracticeSessionMetadata {
  final String id;
  final DateTime date;
  final int totalQuestions;
  final int completedQuestions;
  final double accuracy;
  final int sessionNumber;

  PracticeSessionMetadata({
    required this.id,
    required this.date,
    required this.totalQuestions,
    required this.completedQuestions,
    required this.accuracy,
    required this.sessionNumber,
  });
}

// Practice questions by date provider with caching
final practiceQuestionsByDateProvider =
    FutureProvider.family<List<Question>, String>((ref, date) async {
  final questionRepo = ref.read(questionRepositoryProvider);
  return await questionRepo.getPracticeQuestionsByDate(date);
});

// Available exam rounds provider
final availableExamRoundsProvider = FutureProvider<List<String>>((ref) async {
  final questionRepo = ref.read(questionRepositoryProvider);
  return await questionRepo.getAvailableExamRounds();
});

// Exam questions for a specific round provider
final examQuestionsByRoundProvider =
    FutureProvider.family<List<Question>, String>((ref, round) async {
  final questionRepo = ref.read(questionRepositoryProvider);
  return await questionRepo.getExamQuestionsByRound(round);
});

// Part 6 available exam rounds provider
final availablePart6ExamRoundsProvider = FutureProvider<List<String>>((ref) async {
  final questionRepo = ref.read(questionRepositoryProvider);
  return await questionRepo.getAvailablePart6ExamRounds();
});

// Part 6 exam questions for a specific round provider
final part6ExamQuestionsByRoundProvider =
    FutureProvider.family<List<Question>, String>((ref, round) async {
  final questionRepo = ref.read(questionRepositoryProvider);
  return await questionRepo.getPart6ExamQuestionsByRound(round);
});

// Analytics repository provider
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(AnalyticsService());
});

// Question analytics provider - gets analytics for a specific question
final questionAnalyticsProvider =
    FutureProvider.family<QuestionAnalytics?, String>((ref, questionId) async {
  final analyticsRepo = ref.read(analyticsRepositoryProvider);

  // Add timeout to prevent indefinite loading on network issues
  try {
    return await analyticsRepo.getQuestionAnalytics(questionId)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    print('⚠️ Analytics timeout or error for question $questionId: $e');
    return null; // Return null instead of throwing to show "no data" state
  }
});

// Multiple question analytics provider - gets analytics for multiple questions
final multipleQuestionAnalyticsProvider =
    FutureProvider.family<List<QuestionAnalytics>, List<String>>(
        (ref, questionIds) async {
  final analyticsRepo = ref.read(analyticsRepositoryProvider);
  return await analyticsRepo.getMultipleQuestionAnalytics(questionIds);
});

// User performance stats provider
final userPerformanceStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final analyticsRepo = ref.read(analyticsRepositoryProvider);
  return await analyticsRepo.getUserPerformanceStats(userId);
});

// Initialize all repositories
final repositoryInitializerProvider = FutureProvider<void>((ref) async {
  final userDataRepo = ref.read(userDataRepositoryProvider);
  final questionRepo = ref.read(questionRepositoryProvider);

  await Future.wait([
    userDataRepo.initialize(),
    questionRepo.initialize(),
  ]);
});

// Helper function to extract date from session ID
// Session ID formats:
// - Part 5: "practice_YYYY-MM-DD_timestamp"
// - Part 6: "part6_practice_YYYY-MM-DD_timestamp"
// - Firebase: "firebase_YYYY-MM-DD_timestamp" or "firebase_YYYY_MM_DD"
DateTime? _extractDateFromSessionId(String sessionId) {
  try {
    // Split by underscore to get parts
    final parts = sessionId.split('_');
    if (parts.length < 2) return null;

    // Try to find a part that looks like a date (YYYY-MM-DD format)
    for (int i = 1; i < parts.length; i++) {
      final part = parts[i];

      // Try parsing as YYYY-MM-DD format
      if (part.contains('-') && part.length >= 8) {
        try {
          return DateTime.parse(part);
        } catch (e) {
          // Continue to next part if parsing fails
          continue;
        }
      }

      // Try parsing as YYYYMMDD format (8 digits)
      if (part.length == 8 && int.tryParse(part) != null) {
        try {
          final year = int.parse(part.substring(0, 4));
          final month = int.parse(part.substring(4, 6));
          final day = int.parse(part.substring(6, 8));
          return DateTime(year, month, day);
        } catch (e) {
          continue;
        }
      }
    }

    // Check if it's in format firebase_YYYY_MM_DD (parts spread across indices)
    if (parts.length >= 4 && parts[1].length == 4 && int.tryParse(parts[1]) != null) {
      try {
        final year = int.parse(parts[1]);
        final month = int.parse(parts[2]);
        final day = int.parse(parts[3]);
        return DateTime(year, month, day);
      } catch (e) {
        // Fall through
      }
    }

    return null;
  } catch (e) {
    print('⚠️ Error extracting date from session ID "$sessionId": $e');
    return null;
  }
}
