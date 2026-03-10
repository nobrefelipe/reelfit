import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reelfit/controllers/extract_controller.dart';
import 'package:reelfit/core/ui/_theme.dart';
import 'package:reelfit/core/ui/text.dart';
import 'package:reelfit/models/exercise_model.dart';
import 'package:reelfit/models/video_model.dart';
import 'package:reelfit/models/workout_model.dart';

class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, required this.videoId});

  final String videoId;

  Widget _noData(BuildContext context) => Scaffold(
        appBar: AppBar(title: UIKText.h4('Workout')),
        body: Center(child: UIKText.body('No workout data available.')),
      );

  @override
  Widget build(BuildContext context) {
    final video = GoRouterState.of(context).extra as VideoModel?;
    if (video != null) {
      final workout = video.asWorkout;
      if (workout == null) return _noData(context);
      return _WorkoutContent(video: video, workout: workout, videoId: videoId);
    }
    return extractResult(
      success: (v) {
        final workout = v.asWorkout;
        if (workout == null) return _noData(context);
        return _WorkoutContent(video: v, workout: workout, videoId: videoId);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: UIKText.h4('Workout')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      failure: (_) => _noData(context),
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
                  _ChipRow(items: workout.targetMuscleGroups, color: DesignTokens.primary),
                  const SizedBox(height: 20),
                ],
                if (workout.equipment.isNotEmpty) ...[
                  UIKText.h5('Equipment'),
                  const SizedBox(height: 8),
                  _ChipRow(items: workout.equipment),
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
                (context, index) => _ExerciseCard(
                  exercise: workout.exercises[index],
                  onTap: () => context.push(
                    '/workout/$videoId/exercise',
                    extra: workout.exercises[index],
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
                child: _DifficultyBadge(difficulty: workout.difficulty!),
              ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final String difficulty;

  Color get _color {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return DesignTokens.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: UIKText.small(difficulty, color: Colors.white),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.items, this.color});

  final List<String> items;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (color ?? Theme.of(context).onSurfaceColor).withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (color ?? Theme.of(context).onSurfaceColor).withAlpha(60),
                ),
              ),
              child: UIKText.small(item, color: color),
            ),
          )
          .toList(),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.onTap});

  final ExerciseModel exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).surfaceColor,
          borderRadius: BorderRadius.circular(DesignTokens.buttonBorderRadius),
          boxShadow: DesignTokens.defaultShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DesignTokens.buttonBorderRadius),
                bottomLeft: Radius.circular(DesignTokens.buttonBorderRadius),
              ),
              child: exercise.imageUrl != null
                  ? Image.network(
                      exercise.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PlaceholderIcon(),
                    )
                  : _PlaceholderIcon(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UIKText.h6(exercise.name),
                    const SizedBox(height: 4),
                    UIKText.small(
                      exercise.targetMuscleGroup,
                      color: DesignTokens.primary,
                    ),
                    const SizedBox(height: 6),
                    _ExerciseStats(exercise: exercise),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      color: DesignTokens.primary.withAlpha(30),
      child: const Icon(Icons.fitness_center, color: DesignTokens.primary),
    );
  }
}

class _ExerciseStats extends StatelessWidget {
  const _ExerciseStats({required this.exercise});

  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (exercise.sets != null && exercise.reps != null) {
      parts.add('${exercise.sets} × ${exercise.reps} reps');
    } else if (exercise.sets != null) {
      parts.add('${exercise.sets} sets');
    } else if (exercise.reps != null) {
      parts.add('${exercise.reps} reps');
    }
    if (exercise.duration != null) parts.add(exercise.duration!);
    if (exercise.rest != null) parts.add('Rest: ${exercise.rest}');

    if (parts.isEmpty) return const SizedBox.shrink();

    return UIKText.small(
      parts.join('  ·  '),
      color: Theme.of(context).onSurfaceColor.withAlpha(150),
    );
  }
}
