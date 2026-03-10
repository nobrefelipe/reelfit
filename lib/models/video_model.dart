import 'package:reelfit/core/helpers.dart';
import 'package:reelfit/models/diet_model.dart';
import 'package:reelfit/models/workout_model.dart';

class VideoModel {
  final String url;
  final String type; // 'workout' | 'diet' | 'unknown'
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool cached;

  VideoModel({
    required this.url,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.cached,
  });

  String get videoId {
    final match = RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})').firstMatch(url);
    return match?.group(1) ?? '';
  }

  String get thumbnailUrl => 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

  // Inject url so WorkoutModel and DietModel have access to it
  WorkoutModel? get asWorkout =>
      type == 'workout' ? WorkoutModel.fromJson({...data, 'url': url}) : null;

  DietModel? get asDiet =>
      type == 'diet' ? DietModel.fromJson({...data, 'url': url}) : null;

  static VideoModel fromJson(dynamic json) => VideoModel(
        url: Helper.getString(json['url']),
        type: Helper.getString(json['type']),
        data: Helper.getMap(json['data']),
        createdAt: DateTime.tryParse(Helper.getString(json['created_at'])) ?? DateTime.now(),
        cached: Helper.getBool(json['cached']),
      );

  static List<VideoModel> fromJsonToList(dynamic json) {
    if (json == null || json is! List) return [];
    return json.map((item) => fromJson(item)).toList();
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type,
        'data': data,
        'created_at': createdAt.toIso8601String(),
        'cached': cached,
      };

  @override
  String toString() => 'VideoModel(url: $url, type: $type, cached: $cached)';
}
