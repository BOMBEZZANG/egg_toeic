import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';

class AnonymousUserService {
  static const String _userBoxName = 'user_data';
  static const String _userIdKey = 'anonymous_user_id';
  static const String _answeredQuestionsKey = 'answered_questions';

  static Box? _userBox;

  static Future<void> initialize() async {
    _userBox = await Hive.openBox(_userBoxName);
  }

  static Box get _box {
    if (_userBox == null) {
      throw Exception('AnonymousUserService not initialized. Call initialize() first.');
    }
    return _userBox!;
  }

  /// Gets or creates an anonymous user ID
  static String getAnonymousUserId() {
    String? userId = _box.get(_userIdKey);

    if (userId == null) {
      userId = _generateAnonymousUserId();
      _box.put(_userIdKey, userId);
    }

    return userId;
  }

  /// Generates a unique anonymous user ID
  static String _generateAnonymousUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'anon_${timestamp}_$random';
  }

  /// Checks if user has answered this question before (for first attempt tracking)
  static bool hasAnsweredBefore(String questionId) {
    final answeredQuestions = getAnsweredQuestions();
    return answeredQuestions.contains(questionId);
  }

  /// Marks a question as answered (call after first attempt)
  static Future<void> markAsAnswered(String questionId) async {
    final answeredQuestions = getAnsweredQuestions();

    if (!answeredQuestions.contains(questionId)) {
      answeredQuestions.add(questionId);
      await _box.put(_answeredQuestionsKey, answeredQuestions);
    }
  }

  /// Gets list of all answered question IDs
  static List<String> getAnsweredQuestions() {
    final answeredQuestions = _box.get(_answeredQuestionsKey, defaultValue: <String>[]);
    return List<String>.from(answeredQuestions);
  }

  /// Gets the total number of questions the user has attempted
  static int getTotalAnsweredCount() {
    return getAnsweredQuestions().length;
  }

  /// Checks if this is the user's first time answering any question
  static bool isFirstTimeUser() {
    return getTotalAnsweredCount() == 0;
  }

  /// Clears all user data (for testing or reset functionality)
  static Future<void> clearUserData() async {
    await _box.clear();
  }

  /// Gets user statistics for debugging
  static Map<String, dynamic> getUserStats() {
    return {
      'userId': getAnonymousUserId(),
      'totalAnswered': getTotalAnsweredCount(),
      'answeredQuestions': getAnsweredQuestions(),
      'isFirstTimeUser': isFirstTimeUser(),
    };
  }
}