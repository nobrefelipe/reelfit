import 'package:reelfit/core/helpers.dart';

class ProgressModel {
  final String id;
  final String exerciseName;
  final double value;
  final String unit;
  final DateTime loggedAt;

  ProgressModel({
    required this.id,
    required this.exerciseName,
    required this.value,
    required this.unit,
    required this.loggedAt,
  });

  static ProgressModel fromJson(dynamic json) => ProgressModel(
        id: Helper.getString(json['id']),
        exerciseName: Helper.getString(json['exercise_name']),
        value: Helper.getDouble(json['value']),
        unit: Helper.getString(json['unit']),
        loggedAt: DateTime.tryParse(Helper.getString(json['logged_at'])) ?? DateTime.now(),
      );

  static List<ProgressModel> fromJsonToList(dynamic json) {
    if (json == null || json is! List) return [];
    return json.map((item) => fromJson(item)).toList();
  }

  @override
  String toString() =>
      'ProgressModel(id: $id, exerciseName: $exerciseName, value: $value, unit: $unit, loggedAt: $loggedAt)';
}
