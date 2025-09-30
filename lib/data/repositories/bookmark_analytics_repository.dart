import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:egg_toeic/core/services/auth_service.dart';

/// Repository for tracking bookmark analytics across all users
class BookmarkAnalyticsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Update global bookmark count when user bookmarks a question
  Future<void> incrementBookmarkCount(String questionId) async {
    try {
      final docRef = _firestore
          .collection('bookmarkAnalytics')
          .doc(questionId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          // Document exists, increment count
          final currentCount = snapshot.data()?['bookmarkCount'] ?? 0;
          transaction.update(docRef, {
            'bookmarkCount': currentCount + 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Document doesn't exist, create it
          transaction.set(docRef, {
            'questionId': questionId,
            'bookmarkCount': 1,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      print('✅ Incremented bookmark count for question: $questionId');
    } catch (e) {
      print('❌ Error incrementing bookmark count: $e');
      // Don't throw - this is analytics, shouldn't block user action
    }
  }

  /// Update global bookmark count when user unbookmarks a question
  Future<void> decrementBookmarkCount(String questionId) async {
    try {
      final docRef = _firestore
          .collection('bookmarkAnalytics')
          .doc(questionId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          final currentCount = snapshot.data()?['bookmarkCount'] ?? 1;
          final newCount = (currentCount - 1).clamp(0, double.infinity).toInt();

          transaction.update(docRef, {
            'bookmarkCount': newCount,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      print('✅ Decremented bookmark count for question: $questionId');
    } catch (e) {
      print('❌ Error decrementing bookmark count: $e');
    }
  }

  /// Get most bookmarked questions (across all users)
  Future<List<Map<String, dynamic>>> getMostBookmarkedQuestions({
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookmarkAnalytics')
          .orderBy('bookmarkCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'questionId': data['questionId'],
          'bookmarkCount': data['bookmarkCount'],
          'lastUpdated': data['lastUpdated'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting most bookmarked questions: $e');
      return [];
    }
  }

  /// Get bookmark count for a specific question
  Future<int> getBookmarkCount(String questionId) async {
    try {
      final doc = await _firestore
          .collection('bookmarkAnalytics')
          .doc(questionId)
          .get();

      if (doc.exists) {
        return doc.data()?['bookmarkCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting bookmark count: $e');
      return 0;
    }
  }

  /// Get bookmark counts for multiple questions
  Future<Map<String, int>> getBookmarkCounts(List<String> questionIds) async {
    try {
      final Map<String, int> counts = {};

      // Firestore 'in' query limited to 10 items, so batch if needed
      for (var i = 0; i < questionIds.length; i += 10) {
        final batch = questionIds.skip(i).take(10).toList();

        final querySnapshot = await _firestore
            .collection('bookmarkAnalytics')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in querySnapshot.docs) {
          counts[doc.id] = doc.data()['bookmarkCount'] ?? 0;
        }
      }

      // Fill in zeros for questions not in analytics
      for (final questionId in questionIds) {
        counts.putIfAbsent(questionId, () => 0);
      }

      return counts;
    } catch (e) {
      print('❌ Error getting bookmark counts: $e');
      return {};
    }
  }

  /// Get total number of bookmarks across all questions
  Future<int> getTotalBookmarks() async {
    try {
      final querySnapshot = await _firestore
          .collection('bookmarkAnalytics')
          .get();

      int total = 0;
      for (final doc in querySnapshot.docs) {
        total += (doc.data()['bookmarkCount'] ?? 0) as int;
      }

      return total;
    } catch (e) {
      print('❌ Error getting total bookmarks: $e');
      return 0;
    }
  }

  /// Get questions bookmarked by at least X users
  Future<List<Map<String, dynamic>>> getPopularQuestions({
    int minimumBookmarks = 5,
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookmarkAnalytics')
          .where('bookmarkCount', isGreaterThanOrEqualTo: minimumBookmarks)
          .orderBy('bookmarkCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'questionId': data['questionId'],
          'bookmarkCount': data['bookmarkCount'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting popular questions: $e');
      return [];
    }
  }
}