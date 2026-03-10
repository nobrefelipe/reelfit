import '../core/atomic_state/result.dart';
import '../core/http/http_client.dart';
import '../core/http/response_extensions.dart';
import '../models/video_model.dart';

class ExtractService extends APIRequest {
  /// POST /functions/v1/extract
  Future<Result<VideoModel>> extract({required String url}) async {
    includeAuthToken = false;
    final response = await post('/functions/v1/extract', body: {'url': url});
    return response.toResult<VideoModel>(VideoModel.fromJson);
  }
}
