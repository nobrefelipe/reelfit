import 'package:reelfit/core/helpers.dart';

class ExerciseModel {
  final String name;
  final int? sets;
  final int? reps;
  final String? duration;
  final String? rest;
  final String? notes;
  final String description;
  final String targetMuscleGroup;
  final int? timestampSeconds;
  final String? imageUrl;

  ExerciseModel({
    required this.name,
    this.sets,
    this.reps,
    this.duration,
    this.rest,
    this.notes,
    required this.description,
    required this.targetMuscleGroup,
    this.timestampSeconds,
    this.imageUrl,
  });

  static ExerciseModel fromJson(dynamic json) => ExerciseModel(
        name: Helper.getString(json['name']),
        sets: Helper.getIntOrNull(json['sets']),
        reps: Helper.getIntOrNull(json['reps']),
        duration: Helper.getStringOrNull(json['duration']),
        rest: Helper.getStringOrNull(json['rest']),
        notes: Helper.getStringOrNull(json['notes']),
        description: Helper.getString(json['description']),
        targetMuscleGroup: Helper.getString(json['target_muscle_group']),
        timestampSeconds: Helper.getIntOrNull(json['timestamp_seconds']),
        imageUrl: Helper.getStringOrNull(json['image_url']),
      );

  static List<ExerciseModel> fromJsonToList(dynamic json) {
    if (json == null || json is! List) return [];
    return json.map((item) => fromJson(item)).toList();
  }

  @override
  String toString() =>
      'ExerciseModel(name: $name, sets: $sets, reps: $reps, targetMuscleGroup: $targetMuscleGroup)';
}
