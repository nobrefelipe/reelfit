import '../core/atomic_state/result.dart';
import '../core/http/http_client.dart';
import '../models/video_model.dart';

class ExtractService extends APIRequest {
  /// POST /functions/v1/extract
  Future<Result<VideoModel>> extract({required String url}) =>
      authPost('/functions/v1/extract', VideoModel.fromJson, body: {'url': url});
}
