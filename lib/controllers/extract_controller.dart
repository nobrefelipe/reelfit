import '../core/atomic_state/async_atom.dart';
import '../core/atomic_state/atom.dart';
import '../core/atomic_state/auth_state.dart';
import '../core/atomic_state/result.dart';
import '../core/cache/local_cache.dart';
import '../core/global_atoms.dart';
import '../data/extract_service.dart';
import '../models/video_model.dart';
import 'history_controller.dart';

const _guestVideoLimit = 3;

final extractResult = AsyncAtom<VideoModel>();
final guestCount = Atom<int>(0);

class ExtractController {
  final _service = ExtractService();

  void init() {
    guestCount.emit(AppCache().getGuestVideoCount());
  }

  bool get isGuest => authState.value is! Authenticated;

  bool get hasReachedGuestLimit => isGuest && guestCount.value >= _guestVideoLimit;

  Future<void> extract(String url) async {
    if (hasReachedGuestLimit) {
      extractResult.emit(Failure('guest_limit'));
      return;
    }

    extractResult.emit(Loading());
    final result = await _service.extract(url: url);
    extractResult.emit(result);

    if (result is Success<VideoModel>) {
      if (isGuest) {
        await AppCache().saveGuestVideo(result.value.toJson());
        final newCount = guestCount.value + 1;
        await AppCache().setGuestVideoCount(newCount);
        guestCount.emit(newCount);
      } else {
        historyController.refresh(showLoading: false);
      }
    }
  }

  void reset() => extractResult.emit(Idle());
}

final extractController = ExtractController();
