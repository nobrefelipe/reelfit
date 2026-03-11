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
import 'widgets/workout_skeleton.dart';
import 'widgets/youtube_embed.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      historyController.findByVideoId(widget.videoId);
    });
  }

  Widget _noData(BuildContext context) => Scaffold(
    appBar: AppBar(title: UIKText.h4('Workout')),
    body: Center(child: UIKText.body('No workout data available.')),
  );

  @override
  Widget build(BuildContext context) {
    return workout(
      loading: () => const WorkoutSkeleton(),
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
      appBar: AppBar(
        title: UIKText.h4('Workout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BannerCard(video: video, videoId: videoId, workout: workout),
            const SizedBox(height: 20),
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
            ...List.generate(
              workout.exercises.length,
              (index) => ExerciseCard(
                exercise: workout.exercises[index],
                onTap: () => context.push(
                  '/workout/$videoId/exercise/${Uri.encodeComponent(workout.exercises[index].name)}',
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _BannerCard extends StatefulWidget {
  const _BannerCard({
    required this.video,
    required this.videoId,
    required this.workout,
  });

  final VideoModel video;
  final String videoId;
  final WorkoutModel workout;

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.buttonBorderRadius),
      child: SizedBox(
        height: 220,
        child: _isPlaying
            ? YouTubeEmbed(videoId: widget.videoId)
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.video.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: DesignTokens.surfaceDark,
                      child: const Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: DesignTokens.primary,
                      ),
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
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPlaying = true),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(160),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  if (widget.workout.difficulty != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: DifficultyBadge(difficulty: widget.workout.difficulty!),
                    ),
                ],
              ),
      ),
    );
  }
}
