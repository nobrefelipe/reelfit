import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/progress_controller.dart';
import '../../core/atomic_state/atom.dart';
import '../../core/atomic_state/result.dart';
import '../../core/ui/bottom_sheet/ui_kit_bottom_sheet.dart';
import '../../core/ui/buttons/ui_kit_button.dart';
import '../../core/ui/notifications/snackbar/snackbar.dart';
import '../../core/ui/text.dart';
import '../../models/exercise_model.dart';
import '../../models/progress_model.dart';

final _selectedUnit = Atom<String>('kg');

class LogProgressSheet {
  LogProgressSheet._();

  static Future<void> show(BuildContext context, {required ExerciseModel exercise}) {
    _selectedUnit.emit('kg');
    return UIKitBottomSheet.show<void>(
      context,
      title: 'Log Progress',
      content: _LogProgressContent(exercise: exercise),
    );
  }
}

class _LogProgressContent extends StatefulWidget {
  const _LogProgressContent({required this.exercise});

  final ExerciseModel exercise;

  @override
  State<_LogProgressContent> createState() => _LogProgressContentState();
}

class _LogProgressContentState extends State<_LogProgressContent> {
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _valueController.text.trim();
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      UIKShowSnackBar(context, message: 'Enter a valid number', type: UIKSnackBarType.error);
      return;
    }

    final result = await progressController.log(
      exerciseName: widget.exercise.name,
      value: value,
      unit: _selectedUnit.value,
    );

    if (!mounted) return;

    if (result is Success<ProgressModel>) {
      context.pop();
      UIKShowSnackBar(context, message: 'Progress saved', type: UIKSnackBarType.success);
    } else {
      UIKShowSnackBar(
        context,
        message: result.errorMessage.isNotEmpty ? result.errorMessage : 'Failed to save progress',
        type: UIKSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _valueController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: const InputDecoration(
            hintText: 'Enter value',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _selectedUnit((unit) => _UnitSelector(selected: unit)),
        const SizedBox(height: 20),
        UIKButton.primary(
          label: 'Save',
          onTap: _save,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _UnitSelector extends StatelessWidget {
  const _UnitSelector({required this.selected});

  final String selected;

  static const _units = ['kg', 'lbs', 'reps'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UIKText.small(
          'Unit:',
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        for (final unit in _units) ...[
          _UnitChip(label: unit, isSelected: unit == selected),
          if (unit != _units.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectedUnit.emit(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: UIKText.small(
          label,
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
