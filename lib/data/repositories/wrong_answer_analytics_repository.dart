import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:egg_toeic/core/services/auth_service.dart';

/// Repository for tracking wrong answer analytics across all users
/// Shows which questions are most commonly missed
class WrongAnswerAnalyticsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Update global wrong answer count when user answers incorrectly
  Future<void> incrementWrongAnswerCount(String questionId) async {
    try {
      final docRef = _firestore
          .collection('wrongAnswerAnalytics')
          .doc(questionId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          // Document exists, increment count
          final currentCount = snapshot.data()?['wrongAnswerCount'] ?? 0;
          transaction.update(docRef, {
            'wrongAnswerCount': currentCount + 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Document doesn't exist, create it
          transaction.set(docRef, {
            'questionId': questionId,
            'wrongAnswerCount': 1,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      print('✅ Incremented wrong answer count for question: $questionId');
    } catch (e) {
      print('❌ Error incrementing wrong answer count: $e');
      // Don't throw - this is analytics, shouldn't block user action
    }
  }

  /// Get most commonly missed questions (across all users)
  Future<List<Map<String, dynamic>>> getMostMissedQuestions({
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('wrongAnswerAnalytics')
          .orderBy('wrongAnswerCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'questionId': data['questionId'],
          'wrongAnswerCount': data['wrongAnswerCount'],
          'lastUpdated': data['lastUpdated'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting most missed questions: $e');
      return [];
    }
  }

  /// Get wrong answer count for a specific question
  Future<int> getWrongAnswerCount(String questionId) async {
    try {
      final doc = await _firestore
          .collection('wrongAnswerAnalytics')
          .doc(questionId)
          .get();

      if (doc.exists) {
        return doc.data()?['wrongAnswerCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting wrong answer count: $e');
      return 0;
    }
  }

  /// Get wrong answer counts for multiple questions
  Future<Map<String, int>> getWrongAnswerCounts(List<String> questionIds) async {
    try {
      final Map<String, int> counts = {};

      // Firestore 'in' query limited to 10 items, so batch if needed
      for (var i = 0; i < questionIds.length; i += 10) {
        final batch = questionIds.skip(i).take(10).toList();

        final querySnapshot = await _firestore
            .collection('wrongAnswerAnalytics')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in querySnapshot.docs) {
          counts[doc.id] = doc.data()['wrongAnswerCount'] ?? 0;
        }
      }

      // Fill in zeros for questions not in analytics
      for (final questionId in questionIds) {
        counts.putIfAbsent(questionId, () => 0);
      }

      return counts;
    } catch (e) {
      print('❌ Error getting wrong answer counts: $e');
      return {};
    }
  }

  /// Get total number of wrong answers across all questions
  Future<int> getTotalWrongAnswers() async {
    try {
      final querySnapshot = await _firestore
          .collection('wrongAnswerAnalytics')
          .get();

      int total = 0;
      for (final doc in querySnapshot.docs) {
        total += (doc.data()['wrongAnswerCount'] ?? 0) as int;
      }

      return total;
    } catch (e) {
      print('❌ Error getting total wrong answers: $e');
      return 0;
    }
  }

  /// Get questions missed by at least X users
  Future<List<Map<String, dynamic>>> getChallengingQuestions({
    int minimumWrongAnswers = 5,
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('wrongAnswerAnalytics')
          .where('wrongAnswerCount', isGreaterThanOrEqualTo: minimumWrongAnswers)
          .orderBy('wrongAnswerCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'questionId': data['questionId'],
          'wrongAnswerCount': data['wrongAnswerCount'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting challenging questions: $e');
      return [];
    }
  }

  /// Get difficulty rating based on wrong answer percentage
  /// Requires questionAnalytics data to calculate percentage
  Future<Map<String, dynamic>> getDifficultyRating(String questionId) async {
    try {
      // Get wrong answer count
      final wrongDoc = await _firestore
          .collection('wrongAnswerAnalytics')
          .doc(questionId)
          .get();

      final wrongCount = wrongDoc.exists
          ? (wrongDoc.data()?['wrongAnswerCount'] ?? 0)
          : 0;

      // Get total attempts from questionAnalytics
      final analyticsDoc = await _firestore
          .collection('questionAnalytics')
          .doc(questionId)
          .get();

      final totalAttempts = analyticsDoc.exists
          ? (analyticsDoc.data()?['totalAttempts'] ?? 0)
          : 0;

      if (totalAttempts == 0) {
        return {
          'questionId': questionId,
          'wrongCount': wrongCount,
          'totalAttempts': 0,
          'wrongPercentage': 0.0,
          'difficulty': 'Unknown',
        };
      }

      final wrongPercentage = (wrongCount / totalAttempts) * 100;

      String difficulty;
      if (wrongPercentage >= 70) {
        difficulty = 'Very Hard';
      } else if (wrongPercentage >= 50) {
        difficulty = 'Hard';
      } else if (wrongPercentage >= 30) {
        difficulty = 'Medium';
      } else {
        difficulty = 'Easy';
      }

      return {
        'questionId': questionId,
        'wrongCount': wrongCount,
        'totalAttempts': totalAttempts,
        'wrongPercentage': wrongPercentage,
        'difficulty': difficulty,
      };
    } catch (e) {
      print('❌ Error getting difficulty rating: $e');
      return {
        'questionId': questionId,
        'wrongCount': 0,
        'totalAttempts': 0,
        'wrongPercentage': 0.0,
        'difficulty': 'Unknown',
      };
    }
  }

  /// Get questions by difficulty level
  Future<List<Map<String, dynamic>>> getQuestionsByDifficulty({
    String difficulty = 'Hard', // 'Easy', 'Medium', 'Hard', 'Very Hard'
    int limit = 20,
  }) async {
    try {
      // This is a more complex query that would require pre-calculation
      // For now, get all questions and filter locally
      final allQuestions = await getMostMissedQuestions(limit: 100);
      final filteredQuestions = <Map<String, dynamic>>[];

      for (final question in allQuestions) {
        final rating = await getDifficultyRating(question['questionId']);
        if (rating['difficulty'] == difficulty) {
          filteredQuestions.add({
            ...question,
            'difficulty': rating['difficulty'],
            'wrongPercentage': rating['wrongPercentage'],
          });
        }

        if (filteredQuestions.length >= limit) break;
      }

      return filteredQuestions;
    } catch (e) {
      print('❌ Error getting questions by difficulty: $e');
      return [];
    }
  }

  /// Get statistics summary
  Future<Map<String, dynamic>> getWrongAnswerStatistics() async {
    try {
      final querySnapshot = await _firestore
          .collection('wrongAnswerAnalytics')
          .orderBy('wrongAnswerCount', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'totalQuestions': 0,
          'totalWrongAnswers': 0,
          'mostMissedQuestionId': null,
          'maxWrongCount': 0,
          'averageWrongCount': 0.0,
        };
      }

      int totalWrongAnswers = 0;
      final mostMissed = querySnapshot.docs.first;

      for (final doc in querySnapshot.docs) {
        totalWrongAnswers += (doc.data()['wrongAnswerCount'] ?? 0) as int;
      }

      return {
        'totalQuestions': querySnapshot.docs.length,
        'totalWrongAnswers': totalWrongAnswers,
        'mostMissedQuestionId': mostMissed.data()['questionId'],
        'maxWrongCount': mostMissed.data()['wrongAnswerCount'],
        'averageWrongCount': totalWrongAnswers / querySnapshot.docs.length,
      };
    } catch (e) {
      print('❌ Error getting statistics: $e');
      return {};
    }
  }
}