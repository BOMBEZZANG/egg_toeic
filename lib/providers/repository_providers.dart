import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egg_toeic/data/repositories/simple_repositories.dart';
import 'package:egg_toeic/data/repositories/temp_user_data_repository.dart';
import 'package:egg_toeic/data/repositories/user_data_repository.dart';
import 'package:egg_toeic/data/repositories/question_repository.dart';

// TODO: Switch back to full repositories after fixing adapter issues

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return SimpleQuestionRepositoryImpl();
});

final userDataRepositoryProvider = Provider<UserDataRepository>((ref) {
  return TempUserDataRepositoryImpl();
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