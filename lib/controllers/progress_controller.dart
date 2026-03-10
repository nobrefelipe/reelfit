import '../core/atomic_state/async_atom.dart';
import '../core/atomic_state/result.dart';
import '../data/progress_service.dart';
import '../models/progress_model.dart';

final progress = AsyncAtom<List<ProgressModel>>();

class ProgressController {
  final _service = ProgressService();

  Future<void> load(String exerciseName) async {
    progress.emit(Loading());
    progress.emit(await _service.getProgress(exerciseName: exerciseName));
  }

  Future<Result<ProgressModel>> log({
    required String exerciseName,
    required double value,
    required String unit,
  }) async {
    final result = await _service.logProgress(
      exerciseName: exerciseName,
      value: value,
      unit: unit,
    );
    if (result is Success<ProgressModel>) load(exerciseName);
    return result;
  }
}

final progressController = ProgressController();
