import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reelfit/controllers/history_controller.dart';
import 'package:reelfit/core/ui/_theme.dart';
import 'package:reelfit/core/ui/text.dart';
import 'package:reelfit/models/video_model.dart';
import 'package:reelfit/models/workout_model.dart';

import 'widgets/chip_row.dart';
import 'widgets/difficulty_badge.dart';
import 'widgets/exercise_card.dart';

class WorkoutDetailScreen extends StatefulWidget {
  const WorkoutDetailScreen({super.key, required this.videoId});

  final String videoId;

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  @override
  void initState() {
    super.initState();
    historyController.findByVideoId(widget.videoId);
  }

  Widget _loadingScaffold() => Scaffold(
    appBar: AppBar(title: UIKText.h4('Workout')),
    body: const Center(child: CircularProgressIndicator()),
  );

  Widget _noData(BuildContext context) => Scaffold(
    appBar: AppBar(title: UIKText.h4('Workout')),
    body: Center(child: UIKText.body('No workout data available.')),
  );

  @override
  Widget build(BuildContext context) {
    return workout(
      loading: _loadingScaffold,
      failure: (_) => _noData(context),
      success: (video) {
        final w = video.asWorkout;
        if (w == null) return _noData(context);
        return _WorkoutContent(video: video, workout: w, videoId: widget.videoId);
      },
    );
  }
}

class _WorkoutContent extends StatelessWidget {
  const _WorkoutContent({
    required this.video,
    required this.workout,
    required this.videoId,
  });

  final VideoModel video;
  final WorkoutModel workout;
  final String videoId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _Header(video: video, workout: workout),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (workout.targetMuscleGroups.isNotEmpty) ...[
                  UIKText.h5('Target muscles'),
                  const SizedBox(height: 8),
                  ChipRow(items: workout.targetMuscleGroups, color: DesignTokens.primary),
                  const SizedBox(height: 20),
                ],
                if (workout.equipment.isNotEmpty) ...[
                  UIKText.h5('Equipment'),
                  const SizedBox(height: 8),
                  ChipRow(items: workout.equipment),
                  const SizedBox(height: 20),
                ],
                if (workout.suggestedPlan != null) ...[
                  UIKText.h5('Suggested plan'),
                  const SizedBox(height: 8),
                  UIKText.body(workout.suggestedPlan!),
                  const SizedBox(height: 20),
                ],
                UIKText.h5('Exercises (${workout.exercises.length})'),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ExerciseCard(
                  exercise: workout.exercises[index],
                  onTap: () => context.go(
                    '/workout/$videoId/exercise/${Uri.encodeComponent(workout.exercises[index].name)}',
                  ),
                ),
                childCount: workout.exercises.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.video, required this.workout});

  final VideoModel video;
  final WorkoutModel workout;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      title: UIKText.h4('Workout'),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              video.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: DesignTokens.surfaceDark,
                child: const Icon(Icons.fitness_center, size: 64, color: DesignTokens.primary),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            if (workout.difficulty != null)
              Positioned(
                bottom: 16,
                left: 16,
                child: DifficultyBadge(difficulty: workout.difficulty!),
              ),
          ],
        ),
      ),
    );
  }
}
