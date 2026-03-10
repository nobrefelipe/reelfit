import '../core/atomic_state/result.dart';
import '../core/http/http_client.dart';
import '../models/progress_model.dart';

class ProgressService extends APIRequest {
  /// GET /functions/v1/progress?exercise={name}
  Future<Result<List<ProgressModel>>> getProgress({required String exerciseName}) =>
      authGet('/functions/v1/progress?exercise=$exerciseName', ProgressModel.fromJsonToList);

  /// POST /functions/v1/progress
  Future<Result<ProgressModel>> logProgress({
    required String exerciseName,
    required double value,
    required String unit,
  }) =>
      authPost('/functions/v1/progress', ProgressModel.fromJson, body: {
        'exercise_name': exerciseName,
        'value': value,
        'unit': unit,
      });
}
