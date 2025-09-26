import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egg_toeic/data/repositories/simple_repositories.dart';
import 'package:egg_toeic/data/repositories/temp_user_data_repository.dart';
import 'package:egg_toeic/data/repositories/user_data_repository.dart';
import 'package:egg_toeic/data/repositories/question_repository.dart';
import 'package:egg_toeic/data/models/simple_models.dart';

// TODO: Switch back to full repositories after fixing adapter issues

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepositoryImpl(); // Switch to Firebase-connected repository
});

// Use StateProvider to maintain the same instance
final userDataRepositoryProvider = Provider<UserDataRepository>((ref) {
  print('🔧 Creating TempUserDataRepositoryImpl instance');
  return _TempRepositorySingleton.instance;
});

// Singleton to ensure we keep the same repository instance
class _TempRepositorySingleton {
  static final TempUserDataRepositoryImpl _instance = TempUserDataRepositoryImpl();
  static TempUserDataRepositoryImpl get instance {
    print('🔧 Singleton: Returning instance ${_instance.hashCode}');
    return _instance;
  }
}

// Practice sessions provider - fetches grouped questions by date from Firebase
final practiceSessionsProvider = FutureProvider<Map<String, List<Question>>>((ref) async {
  final questionRepo = ref.read(questionRepositoryProvider);
  return await questionRepo.getPracticeSessionsByDate();
});

// Available exam rounds provider
final availableExamRoundsProvider = FutureProvider<List<String>>((ref) async {
  final questionRepo = ref.read(questionRepositoryProvider);
  return await questionRepo.getAvailableExamRounds();
});

// Exam questions for a specific round provider
final examQuestionsByRoundProvider = FutureProvider.family<List<Question>, String>((ref, round) async {
  final questionRepo = ref.read(questionRepositoryProvider);
  return await questionRepo.getExamQuestionsByRound(round);
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