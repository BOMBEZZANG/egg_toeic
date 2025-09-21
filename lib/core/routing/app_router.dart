import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:egg_toeic/features/home/views/home_screen.dart';
import 'package:egg_toeic/features/part5/views/part5_mode_selection_screen.dart';
import 'package:egg_toeic/features/part5/views/practice_level_selection_screen.dart';
import 'package:egg_toeic/features/part5/views/exam_level_selection_screen.dart';
import 'package:egg_toeic/features/part5/views/practice_mode_screen.dart';
import 'package:egg_toeic/features/part5/views/exam_mode_screen.dart';
import 'package:egg_toeic/features/part5/views/explanation_screen.dart';
import 'package:egg_toeic/features/part2/views/part2_home_screen.dart';
import 'package:egg_toeic/features/achievements/views/achievements_screen.dart';
import 'package:egg_toeic/features/statistics/views/statistics_screen.dart';
import 'package:egg_toeic/data/models/simple_models.dart';
import 'package:egg_toeic/data/models/wrong_answer_model.dart';

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
            path: 'exam/:level',
            name: 'exam',
            builder: (context, state) {
              final level = int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
              return ExamModeScreen(difficultyLevel: level);
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
        path: '/achievements',
        name: 'achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
    ],
  );
});