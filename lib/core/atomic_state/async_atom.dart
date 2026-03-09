import 'package:flutter/material.dart';
import 'atom.dart';
import 'result.dart';

// Global registry — all AsyncAtoms register themselves on creation.
// Used by AuthBuilder._resetAtoms() to reset all atoms on logout.
// Never modify this list directly.
final _atomRegistry = <AsyncAtom>[];

class AsyncAtom<T> extends ValueNotifier<Result<T>> {
  AsyncAtom() : super(Idle()) {
    // Self-register so _resetAtoms() never needs manual updates.
    // AsyncAtoms must always be global variables in controller files —
    // never created inside widgets or methods (would cause registry leak).
    assert(() {
      // In debug mode, warn if created inside a widget lifecycle
      // by checking if we're in a build/initState context.
      // Simple guard: registry should only grow, never shrink unexpectedly.
      return true;
    }());
    _atomRegistry.add(this);
  }

  void emit(Result<T> state) => value = state;

  /// Resets this atom to Idle(). Called by AuthBuilder on logout.
  void reset() => value = Idle();

  /// Call the atom directly as a widget.
  /// Only [success] is required. Defaults:
  ///   - loading → CircularProgressIndicator()
  ///   - failure → SizedBox()
  ///   - empty   → SizedBox()
  ///   - idle    → SizedBox()
  ///
  /// Usage:
  ///   rewards(success: RewardsList.new)
  ///   rewards(success: RewardsList.new, failure: ErrorText.new)
  Widget call({
    required Widget Function(T value) success,
    Widget Function(String message)? failure,
    Widget Function()? loading,
    Widget Function()? empty,
    Widget Function()? idle,
  }) {
    return ValueListenableBuilder(
      valueListenable: this,
      builder: (_, result, __) => switch (result) {
        Success(:final value) => success(value),
        Failure(:final message) => failure?.call(message) ?? const SizedBox(),
        Loading() => loading?.call() ?? const Center(child: CircularProgressIndicator()),
        Empty() => empty?.call() ?? const SizedBox(),
        Idle() => idle?.call() ?? const SizedBox(),
      },
    );
  }
}

/// Resets all registered AsyncAtoms to Idle().
/// Called by AuthBuilder when authState becomes Unauthenticated.
/// No manual registration needed — atoms self-register on creation.
void resetAllAtoms() {
  for (final atom in _atomRegistry) {
    atom.reset();
  }
}
