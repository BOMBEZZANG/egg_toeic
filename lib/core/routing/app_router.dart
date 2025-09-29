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
import 'package:egg_toeic/features/part5/views/exam_result_summary_screen.dart';
import 'package:egg_toeic/features/bookmarks/views/bookmarks_screen.dart';
import 'package:egg_toeic/features/part5/views/exam_mode_screen.dart';
import 'package:egg_toeic/features/part5/views/explanation_screen.dart';
import 'package:egg_toeic/features/part2/views/part2_home_screen.dart';
import 'package:egg_toeic/features/statistics/views/statistics_achievements_screen.dart';
import 'package:egg_toeic/features/review/views/review_select_screen.dart';
import 'package:egg_toeic/features/wrong_answers/views/wrong_answers_screen.dart';
import 'package:egg_toeic/features/wrong_answers/views/retake_question_screen.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';
import 'package:egg_toeic/data/models/learning_session_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
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
            path: 'exam-result-summary',
            name: 'exam-result-summary',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return ExamResultSummaryScreen(
                round: extra['round'] as String,
                session: extra['session'] as LearningSession,
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
        path: '/statistics-achievements',
        name: 'statistics-achievements',
        builder: (context, state) => const StatisticsAchievementsScreen(),
      ),
      GoRoute(
        path: '/bookmarks',
        name: 'bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/review-select',
        name: 'review-select',
        builder: (context, state) => const ReviewSelectScreen(),
      ),
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
    ],
  );
});