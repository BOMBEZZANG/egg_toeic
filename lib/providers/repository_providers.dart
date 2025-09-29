import 'package:egg_toeic/data/models/question_analytics_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egg_toeic/data/repositories/simple_repositories.dart';
import 'package:egg_toeic/data/repositories/temp_user_data_repository.dart';
import 'package:egg_toeic/data/repositories/user_data_repository.dart';
import 'package:egg_toeic/data/repositories/question_repository.dart';
import 'package:egg_toeic/data/repositories/analytics_repository.dart';
import 'package:egg_toeic/data/datasources/remote/analytics_service.dart';
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
  final questionRepo = ref.read(questionRepositoryProvider);

  print('📋 Loading practice session metadata only (no question data)...');

  try {
    // Get available dates from metadata (very fast)
    final availableDates = await questionRepo.getAvailablePracticeDates();

    if (availableDates.isEmpty) {
      print('⚠️ No available practice dates found');
      return [];
    }

    print(
        '📅 Found ${availableDates.length} available practice dates: $availableDates');

    // Create metadata objects without loading questions
    final metadataList = <PracticeSessionMetadata>[];

    for (int i = 0; i < availableDates.length; i++) {
      final dateString = availableDates[i];
      final date = DateTime.parse(dateString);
      final sessionNumber = availableDates.length - i; // Latest first

      // For now, assume 10 questions per session (could be enhanced to get from metadata)
      // In a real implementation, you could get this from the daily metadata doc
      final totalQuestions = 10;

      // Get real user progress data
      final isToday = _isToday(date);
      final daysSinceToday = DateTime.now().difference(date).inDays;

      int completedQuestions;
      double accuracy;

      if (isToday) {
        // For today, get actual user progress from UserDataRepository
        final userDataRepo = ref.read(userDataRepositoryProvider);
        completedQuestions = userDataRepo.getTodaysQuestionCount();
        accuracy = completedQuestions > 0 ? 0.8 : 0.0; // Default accuracy if questions completed
      } else if (daysSinceToday < 7) {
        // For recent days, use a declining pattern (mock data for past days)
        completedQuestions = (10 - daysSinceToday).clamp(0, totalQuestions);
        accuracy = 0.6 + (daysSinceToday * 0.05);
      } else {
        // For older days, assume completed (mock data)
        completedQuestions = totalQuestions;
        accuracy = 0.85;
      }

      metadataList.add(PracticeSessionMetadata(
        id: 'firebase_${dateString.replaceAll('-', '_')}',
        date: date,
        totalQuestions: totalQuestions,
        completedQuestions: completedQuestions.clamp(0, totalQuestions),
        accuracy: accuracy,
        sessionNumber: sessionNumber,
      ));
    }

    print(
        '✅ Generated metadata for ${metadataList.length} practice sessions (no questions loaded)');
    return metadataList;
  } catch (e) {
    print('❌ Error loading practice session metadata: $e');
    // Return fallback mock data
    return _generateFallbackPracticeMetadata();
  }
});

bool _isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

List<PracticeSessionMetadata> _generateFallbackPracticeMetadata() {
  final now = DateTime.now();
  final metadata = <PracticeSessionMetadata>[];

  // Generate last 30 days of practice sessions (fallback mock data)
  for (int i = 0; i < 30; i++) {
    final date = now.subtract(Duration(days: i));
    final sessionNumber = 30 - i;

    metadata.add(PracticeSessionMetadata(
      id: 'practice_$sessionNumber',
      date: date,
      totalQuestions: 10,
      completedQuestions: i == 0 ? 3 : (i < 7 ? (10 - i) : 10),
      accuracy: i == 0 ? 0.0 : (i < 7 ? 0.6 + (i * 0.05) : 0.85),
      sessionNumber: sessionNumber,
    ));
  }

  return metadata;
}

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
  print('🚀 Loading questions for date: $date (with caching)');
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
