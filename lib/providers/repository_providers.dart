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
final practiceSessionMetadataProvider =
    FutureProvider<List<PracticeSessionMetadata>>((ref) async {
  final userDataRepo = ref.read(userDataRepositoryProvider);
  final questionRepo = ref.read(questionRepositoryProvider);

  try {
    // Get available practice dates from Firebase (all dates with questions)
    final availableDates = await questionRepo.getAvailablePracticeDates();
    
    if (availableDates.isEmpty) {
      return [];
    }

    // Get actual learning sessions from user data
    final learningSessions = await userDataRepo.getLearningSessions();
    
    // Group user sessions by date for easy lookup
    final sessionsByDate = <DateTime, List<LearningSession>>{};
    for (final session in learningSessions) {
      if (session.sessionType == 'practice') {
        final dateKey = DateTime(
          session.startTime.year, 
          session.startTime.month, 
          session.startTime.day
        );
        sessionsByDate.putIfAbsent(dateKey, () => []).add(session);
      }
    }

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
        totalQuestions: 10, // Fixed number per practice session
        completedQuestions: completedQuestions.clamp(0, 10),
        accuracy: completedQuestions > 0 ? correctAnswers / completedQuestions : 0.0,
        sessionNumber: sessionNumber,
      ));
    }

    return metadataList;
  } catch (e) {
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
