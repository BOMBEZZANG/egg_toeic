import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:egg_toeic/features/home/views/home_screen.dart';
import 'package:egg_toeic/features/part5/views/part5_mode_selection_screen.dart';
import 'package:egg_toeic/features/part5/views/practice_level_selection_screen.dart';
import 'package:egg_toeic/features/part5/views/exam_level_selection_screen.dart';
import 'package:egg_toeic/features/part5/views/practice_mode_screen.dart';
import 'package:egg_toeic/features/part5/views/practice_date_mode_screen.dart';
import 'package:egg_toeic/features/part5/views/practice_calendar_screen.dart';
import 'package:egg_toeic/features/part5/views/exam_result_screen.dart';
import 'package:egg_toeic/features/bookmarks/views/bookmarks_screen.dart';
import 'package:egg_toeic/features/bookmarks/views/bookmark_hub_screen.dart';
import 'package:egg_toeic/features/bookmarks/views/part6_bookmarks_screen.dart';
import 'package:egg_toeic/features/part5/views/exam_mode_screen.dart';
import 'package:egg_toeic/features/part5/views/explanation_screen.dart';
import 'package:egg_toeic/features/part2/views/part2_home_screen.dart';
import 'package:egg_toeic/features/part6/views/part6_mode_selection_screen.dart';
import 'package:egg_toeic/features/part6/views/part6_exam_round_selection_screen.dart';
import 'package:egg_toeic/features/part6/views/part6_exam_screen.dart';
import 'package:egg_toeic/features/part6/views/part6_exam_result_screen.dart';
import 'package:egg_toeic/features/part6/views/part6_practice_date_mode_screen.dart';
import 'package:egg_toeic/features/statistics/views/statistics_achievements_screen.dart';
import 'package:egg_toeic/features/review/views/review_select_screen.dart';
import 'package:egg_toeic/features/wrong_answers/views/wrong_answers_screen.dart';
import 'package:egg_toeic/features/wrong_answers/views/retake_question_screen.dart';
import 'package:egg_toeic/features/wrong_answers/views/wrong_answer_hub_screen.dart';
import 'package:egg_toeic/features/wrong_answers/views/part6_wrong_answers_screen.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/features/practice/views/practice_hub_screen.dart';
import 'package:egg_toeic/features/exam/views/exam_hub_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      // Practice Hub - Unified practice selection for all parts
      GoRoute(
        path: '/practice-hub',
        name: 'practice-hub',
        builder: (context, state) => const PracticeHubScreen(),
      ),
      // Exam Hub - Unified exam selection for all parts
      GoRoute(
        path: '/exam-hub',
        name: 'exam-hub',
        builder: (context, state) => const ExamHubScreen(),
      ),
      // Shared Practice Calendar - for parts 5 & 6
      GoRoute(
        path: '/practice/part/:partNumber/calendar',
        name: 'practice-part-calendar',
        builder: (context, state) {
          final partNumber = int.tryParse(state.pathParameters['partNumber'] ?? '5') ?? 5;
          return PracticeCalendarScreen(partNumber: partNumber);
        },
      ),
      GoRoute(
        path: '/part5',
        name: 'part5-mode-selection',
        builder: (context, state) => const Part5ModeSelectionScreen(),
        routes: [
          GoRoute(
            path: 'practice-levels',
            name: 'practice-levels',
            builder: (context, state) => const PracticeLevelSelectionScreen(),
          ),
          GoRoute(
            path: 'practice-calendar',
            name: 'practice-calendar',
            builder: (context, state) => const PracticeCalendarScreen(),
          ),
          GoRoute(
            path: 'exam-levels',
            name: 'exam-levels',
            builder: (context, state) => const ExamLevelSelectionScreen(),
          ),
          GoRoute(
            path: 'practice/:level',
            name: 'practice',
            builder: (context, state) {
              final level = int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
              return PracticeModeScreen(difficultyLevel: level);
            },
          ),
          GoRoute(
            path: 'practice/session/:sessionId',
            name: 'practice-session',
            builder: (context, state) {
              final sessionId = state.pathParameters['sessionId'] ?? '';
              // Extract date from session ID (format: firebase_YYYY_MM_DD)
              String date = '2025-09-25'; // fallback
              if (sessionId.startsWith('firebase_')) {
                final datePart = sessionId.substring(9); // Remove 'firebase_'
                date = datePart.replaceAll('_', '-'); // Convert YYYY_MM_DD to YYYY-MM-DD
              }
              return PracticeDateModeScreen(date: date);
            },
          ),
          GoRoute(
            path: 'exam/:round',
            name: 'exam',
            builder: (context, state) {
              final round = state.pathParameters['round'] ?? 'ROUND_1';
              return ExamModeScreen(round: round);
            },
          ),
          GoRoute(
            path: 'exam-result',
            name: 'exam-result',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return ExamResultScreen(
                examRound: extra['examRound'] as String,
                questions: extra['questions'] as List<SimpleQuestion>,
                userAnswers: extra['userAnswers'] as List<int>,
                examStartTime: extra['examStartTime'] as DateTime,
                examEndTime: extra['examEndTime'] as DateTime,
              );
            },
          ),
          GoRoute(
            path: 'explanation',
            name: 'explanation',
            builder: (context, state) {
              final question = state.extra as SimpleQuestion;
              return ExplanationScreen(question: question);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/part2',
        name: 'part2-home',
        builder: (context, state) => const Part2HomeScreen(),
      ),
      GoRoute(
        path: '/part6',
        name: 'part6-mode-selection',
        builder: (context, state) => const Part6ModeSelectionScreen(),
        routes: [
          GoRoute(
            path: 'exam-rounds',
            name: 'part6-exam-rounds',
            builder: (context, state) => const Part6ExamRoundSelectionScreen(),
          ),
          GoRoute(
            path: 'exam/:round',
            name: 'part6-exam',
            builder: (context, state) {
              final round = state.pathParameters['round'] ?? 'ROUND_1';
              return Part6ExamScreen(round: round);
            },
          ),
          GoRoute(
            path: 'exam-result',
            name: 'part6-exam-result',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return Part6ExamResultScreen(
                examRound: extra['examRound'] as String,
                questions: extra['questions'] as List<SimpleQuestion>,
                userAnswers: extra['userAnswers'] as Map<String, int>,
                examStartTime: extra['examStartTime'] as DateTime,
                examEndTime: extra['examEndTime'] as DateTime,
              );
            },
          ),
          GoRoute(
            path: 'practice/session/:sessionId',
            name: 'part6-practice-session',
            builder: (context, state) {
              final sessionId = state.pathParameters['sessionId'] ?? '';
              // Extract date from session ID (format: firebase_YYYY_MM_DD)
              String date = '2025-09-25'; // fallback
              if (sessionId.startsWith('firebase_')) {
                final datePart = sessionId.substring(9); // Remove 'firebase_'
                date = datePart.replaceAll('_', '-'); // Convert YYYY_MM_DD to YYYY-MM-DD
              }
              return Part6PracticeDateModeScreen(date: date);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/statistics-achievements',
        name: 'statistics-achievements',
        builder: (context, state) => const StatisticsAchievementsScreen(),
      ),
      // Bookmark Hub - Main entry point
      GoRoute(
        path: '/bookmark-hub',
        name: 'bookmark-hub',
        builder: (context, state) => const BookmarkHubScreen(),
      ),
      // Bookmarks - Legacy route (will be used for Part 5)
      GoRoute(
        path: '/bookmarks',
        name: 'bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
      // Bookmarks Part 5
      GoRoute(
        path: '/bookmarks/part5',
        name: 'bookmarks-part5',
        builder: (context, state) => const BookmarksScreen(), // Will filter for Part 5
      ),
      // Bookmarks Part 6
      GoRoute(
        path: '/bookmarks/part6',
        name: 'bookmarks-part6',
        builder: (context, state) => const Part6BookmarksScreen(),
      ),
      GoRoute(
        path: '/review-select',
        name: 'review-select',
        builder: (context, state) => const ReviewSelectScreen(),
      ),
      // Wrong Answer Hub - Main entry point
      GoRoute(
        path: '/wrong-answer-hub',
        name: 'wrong-answer-hub',
        builder: (context, state) => const WrongAnswerHubScreen(),
      ),
      // Wrong Answers - Legacy route (for Part 5, will be filtered)
      GoRoute(
        path: '/wrong-answers',
        name: 'wrong-answers',
        builder: (context, state) => const WrongAnswersScreen(),
        routes: [
          GoRoute(
            path: 'retake',
            name: 'retake-question',
            builder: (context, state) {
              final wrongAnswer = state.extra as WrongAnswer;
              return RetakeQuestionScreen(wrongAnswer: wrongAnswer);
            },
          ),
        ],
      ),
      // Wrong Answers Part 5
      GoRoute(
        path: '/wrong-answers/part5',
        name: 'wrong-answers-part5',
        builder: (context, state) => const WrongAnswersScreen(), // Will filter for Part 5
      ),
      // Wrong Answers Part 6
      GoRoute(
        path: '/wrong-answers/part6',
        name: 'wrong-answers-part6',
        builder: (context, state) => const Part6WrongAnswersScreen(),
      ),
    ],
  );
});