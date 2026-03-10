import '../core/atomic_state/async_atom.dart';
import '../core/atomic_state/auth_state.dart';
import '../core/atomic_state/result.dart';
import '../core/cache/local_cache.dart';
import '../core/global_atoms.dart';
import '../data/history_service.dart';
import '../models/video_model.dart';

final history = AsyncAtom<List<VideoModel>>();
final workout = AsyncAtom<VideoModel>();

class HistoryController {
  final _service = HistoryService();

  bool get isGuest => authState.value is! Authenticated;

  Future<void> load() async {
    if (isGuest) {
      final localMaps = AppCache().getGuestVideos();
      final local = localMaps.map(VideoModel.fromJson).toList();
      history.emit(local.isEmpty ? Empty() : Success(local));
      return;
    }

    final current = history.value;
    if (current is Success<List<VideoModel>> && current.value.isNotEmpty) {
      _service.getHistory().then((r) => history.emit(r));
      return;
    }

    history.emit(Loading());
    history.emit(await _service.getHistory());
  }

  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading) history.emit(Loading());
    history.emit(await _service.getHistory());
  }

  Future<void> findByVideoId(String videoId) async {
    await Future.microtask(() => workout.emit(Loading()));
    if (history.value is! Success<List<VideoModel>>) await load();
    final current = history.value;
    if (current is Success<List<VideoModel>>) {
      try {
        final video = current.value.firstWhere((v) => v.videoId == videoId);
        workout.emit(Success(video));
        return;
      } catch (_) {}
    }
    workout.emit(Failure('Video not found'));
  }

  /// Called after sign-in — migrates local guest videos to the user's DB account.
  Future<void> migrateLocalVideos() async {
    final localMaps = AppCache().getGuestVideos();
    if (localMaps.isEmpty) return;

    for (final videoJson in localMaps) {
      final url = VideoModel.fromJson(videoJson).url;
      await _service.linkVideo(url: url);
    }

    await AppCache().clearGuestVideos();
    await AppCache().setGuestVideoCount(0);
    await refresh(showLoading: false);
  }
}

final historyController = HistoryController();
