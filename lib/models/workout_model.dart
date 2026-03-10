import 'package:reelfit/core/helpers.dart';
import 'package:reelfit/models/exercise_model.dart';

class WorkoutModel {
  final String url;
  final List<ExerciseModel> exercises;
  final String? suggestedPlan;
  final List<String> targetMuscleGroups;
  final String? difficulty;
  final List<String> equipment;

  WorkoutModel({
    required this.url,
    required this.exercises,
    this.suggestedPlan,
    required this.targetMuscleGroups,
    this.difficulty,
    required this.equipment,
  });

  static WorkoutModel fromJson(dynamic json) => WorkoutModel(
        url: Helper.getString(json['url']),
        exercises: ExerciseModel.fromJsonToList(json['exercises']),
        suggestedPlan: Helper.getStringOrNull(json['suggested_plan']),
        targetMuscleGroups: Helper.getStringList(json['target_muscle_groups']),
        difficulty: Helper.getStringOrNull(json['difficulty']),
        equipment: Helper.getStringList(json['equipment']),
      );

  @override
  String toString() =>
      'WorkoutModel(url: $url, exercises: ${exercises.length}, difficulty: $difficulty)';
}
