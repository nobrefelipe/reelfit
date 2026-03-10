import 'package:go_router/go_router.dart';
import 'package:reelfit/views/diet/diet_detail_screen.dart';
import 'package:reelfit/views/home/home_screen.dart';
import 'package:reelfit/views/workouts/exercise_detail_screen.dart';
import 'package:reelfit/views/workouts/workout_detail_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/workout/:videoId',
      builder: (_, state) =>
          WorkoutDetailScreen(videoId: state.pathParameters['videoId']!),
      routes: [
        GoRoute(
          path: 'exercise/:exerciseName',
          builder: (_, state) => ExerciseDetailScreen(
            videoId: state.pathParameters['videoId']!,
            exerciseName: Uri.decodeComponent(state.pathParameters['exerciseName']!),
          ),
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
