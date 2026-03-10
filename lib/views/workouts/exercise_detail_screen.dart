import 'package:flutter/material.dart';

import '../../controllers/extract_controller.dart';
import '../../controllers/history_controller.dart';
import '../../controllers/progress_controller.dart';
import '../../core/global_atoms.dart';
import '../../core/ui/text.dart';
import '../../models/exercise_model.dart';
import 'log_progress_sheet.dart';
import 'widgets/hero_image.dart';
import 'widgets/muscle_chip.dart';
import 'widgets/progress_section.dart';
import 'widgets/stats_row.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      historyController.findByVideoId(widget.videoId);
      if (!extractController.isGuest) {
        progressController.load(widget.exerciseName);
      }
    });
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
        if (w == null) return _noData(context);
        final exercise = w.exercises.firstWhere(
          (e) => e.name == widget.exerciseName,
          orElse: () => w.exercises.first,
        );
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroImage(exercise: exercise),
            const SizedBox(height: 20),
            StatsRow(exercise: exercise),
            const SizedBox(height: 16),
            MuscleChip(muscle: exercise.targetMuscleGroup),
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
            ProgressSection(
              exercise: exercise,
              isGuest: isGuest,
              onAdd: isGuest ? null : () => LogProgressSheet.show(context, exercise: exercise),
            ),
          ],
        ),
      ),
    );
  }
}
