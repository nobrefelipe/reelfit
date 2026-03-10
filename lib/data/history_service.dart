import '../core/atomic_state/result.dart';
import '../core/http/http_client.dart';
import '../models/video_model.dart';

class HistoryService extends APIRequest {
  /// GET /functions/v1/history
  Future<Result<List<VideoModel>>> getHistory() =>
      authGet('/functions/v1/history', VideoModel.fromJsonToList);

  /// POST /functions/v1/history/link
  Future<Result<VideoModel>> linkVideo({required String url}) =>
      authPost('/functions/v1/history/link', VideoModel.fromJson, body: {'url': url});
}
