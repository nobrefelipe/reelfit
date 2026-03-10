import 'package:go_router/go_router.dart';
import 'package:reelfit/models/exercise_model.dart';
import 'package:reelfit/views/diet/diet_detail_screen.dart';
import 'package:reelfit/views/home/home_screen.dart';
import 'package:reelfit/views/workouts/exercise_detail_screen.dart';
import 'package:reelfit/views/workouts/workout_detail_screen.dart';

final router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/workout/:videoId',
      builder: (_, state) =>
          WorkoutDetailScreen(videoId: state.pathParameters['videoId']!),
      routes: [
        GoRoute(
          path: 'exercise',
          builder: (_, state) =>
              ExerciseDetailScreen(exercise: state.extra as ExerciseModel),
        ),
      ],
    ),
    GoRoute(
      path: '/diet/:videoId',
      builder: (_, state) =>
          DietDetailScreen(videoId: state.pathParameters['videoId']!),
    ),
  ],
);
