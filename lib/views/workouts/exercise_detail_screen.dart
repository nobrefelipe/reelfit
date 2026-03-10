import 'package:flutter/material.dart';

import '../../controllers/extract_controller.dart';
import '../../controllers/history_controller.dart';
import '../../controllers/progress_controller.dart';
import '../../core/global_atoms.dart';
import '../../core/ui/_theme.dart';
import '../../core/ui/buttons/ui_kit_button.dart';
import '../../core/ui/text.dart';
import '../../models/exercise_model.dart';
import '../../models/progress_model.dart';
import '../auth/sign_in_sheet.dart';
import 'log_progress_sheet.dart';

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.videoId,
    required this.exerciseName,
  });

  final String videoId;
  final String exerciseName;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  @override
  void initState() {
    super.initState();
    authState.addListener(_onAuthChanged);
    historyController.findByVideoId(widget.videoId);
    if (!extractController.isGuest) {
      progressController.load(widget.exerciseName);
    }
  }

  @override
  void dispose() {
    authState.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() => setState(() {});

  Widget _loadingScaffold() => Scaffold(
    appBar: AppBar(title: UIKText.h4('Exercise')),
    body: const Center(child: CircularProgressIndicator()),
  );

  Widget _noData(BuildContext context) => Scaffold(
    appBar: AppBar(title: UIKText.h4('Exercise')),
    body: Center(child: UIKText.body('No exercise data available.')),
  );

  @override
  Widget build(BuildContext context) {
    return workout(
      loading: _loadingScaffold,
      failure: (_) => _noData(context),
      success: (video) {
        final w = video.asWorkout;
        final exercise = w?.exercises.firstWhere(
          (e) => e.name == widget.exerciseName,
          orElse: () => w!.exercises.first,
        );
        if (exercise == null) return _noData(context);
        return _ExerciseContent(exercise: exercise, videoId: widget.videoId);
      },
    );
  }
}

class _ExerciseContent extends StatelessWidget {
  const _ExerciseContent({required this.exercise, required this.videoId});

  final ExerciseModel exercise;
  final String videoId;

  @override
  Widget build(BuildContext context) {
    final isGuest = extractController.isGuest;

    return Scaffold(
      appBar: AppBar(
        title: UIKText.h4(exercise.name),
        actions: [
          if (!isGuest)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => LogProgressSheet.show(context, exercise: exercise),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroImage(exercise: exercise),
            const SizedBox(height: 20),
            _StatsRow(exercise: exercise),
            const SizedBox(height: 16),
            _MuscleChip(muscle: exercise.targetMuscleGroup),
            const SizedBox(height: 20),
            if (exercise.description.isNotEmpty) ...[
              UIKText.h5('Description'),
              const SizedBox(height: 8),
              UIKText.body(exercise.description),
              const SizedBox(height: 20),
            ],
            if (exercise.notes != null) ...[
              UIKText.h5('Notes'),
              const SizedBox(height: 8),
              UIKText.body(exercise.notes!),
              const SizedBox(height: 20),
            ],
            _ProgressSection(exercise: exercise, isGuest: isGuest),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.exercise});

  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.buttonBorderRadius),
      child: exercise.imageUrl != null
          ? Image.network(
              exercise.imageUrl!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _FallbackImage(),
            )
          : const _FallbackImage(),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      color: DesignTokens.primary.withAlpha(30),
      child: const Icon(Icons.fitness_center, size: 64, color: DesignTokens.primary),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.exercise});

  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    final stats = <({String label, String value})>[];

    if (exercise.sets != null && exercise.reps != null) {
      stats.add((label: 'Sets × Reps', value: '${exercise.sets} × ${exercise.reps}'));
    } else if (exercise.sets != null) {
      stats.add((label: 'Sets', value: '${exercise.sets}'));
    } else if (exercise.reps != null) {
      stats.add((label: 'Reps', value: '${exercise.reps}'));
    }
    if (exercise.duration != null) {
      stats.add((label: 'Duration', value: exercise.duration!));
    }
    if (exercise.rest != null) {
      stats.add((label: 'Rest', value: exercise.rest!));
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < stats.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).surfaceColor,
                borderRadius: BorderRadius.circular(DesignTokens.buttonBorderRadius),
                boxShadow: DesignTokens.defaultShadow,
              ),
              child: Column(
                children: [
                  UIKText.small(
                    stats[i].label,
                    color: Theme.of(context).onSurfaceColor.withAlpha(150),
                  ),
                  const SizedBox(height: 4),
                  UIKText.h6(stats[i].value),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.muscle});

  final String muscle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.primary.withAlpha(60)),
      ),
      child: UIKText.small(muscle, color: DesignTokens.primary),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.exercise, required this.isGuest});

  final ExerciseModel exercise;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return _GuestProgressPrompt(exercise: exercise);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UIKText.h5('Progress'),
        const SizedBox(height: 12),
        progress(
          success: _ProgressList.new,
          loading: () => const Center(child: CircularProgressIndicator()),
          empty: () => UIKText.body('No progress logged yet'),
          idle: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _GuestProgressPrompt extends StatelessWidget {
  const _GuestProgressPrompt({required this.exercise});

  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).surfaceColor,
        borderRadius: BorderRadius.circular(DesignTokens.buttonBorderRadius),
        boxShadow: DesignTokens.defaultShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 40, color: DesignTokens.primary),
          const SizedBox(height: 12),
          UIKText.h5('Track your progress'),
          const SizedBox(height: 8),
          UIKText.body(
            'Sign in to log and track your progress over time.',
            textAlign: TextAlign.center,
            color: Theme.of(context).onSurfaceColor.withAlpha(150),
          ),
          const SizedBox(height: 16),
          UIKButton.primary(
            label: 'Sign in',
            onTap: () async => SignInSheet.show(
              context,
              title: 'Track your progress',
              subtitle: 'Sign in to log and track your progress over time.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressList extends StatelessWidget {
  const _ProgressList(this.entries);

  final List<ProgressModel> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UIKText.body(
                '${entry.loggedAt.day}/${entry.loggedAt.month}/${entry.loggedAt.year}',
                color: Theme.of(context).onSurfaceColor.withAlpha(150),
              ),
              UIKText.h6('${entry.value} ${entry.unit}'),
            ],
          ),
        );
      },
    );
  }
}
