import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/extract_controller.dart';
import '../../core/atomic_state/result.dart';
import '../../core/ui/bottom_sheet/ui_kit_bottom_sheet.dart';
import '../../core/ui/buttons/ui_kit_button.dart';
import '../../core/ui/notifications/snackbar/snackbar.dart';
import '../../models/video_model.dart';
import '../auth/sign_in_sheet.dart';

class ExtractSheet {
  ExtractSheet._();

  static Future<void> show(BuildContext context) {
    return UIKitBottomSheet.show(
      context,
      title: 'Extract workout',
      content: const _ExtractContent(),
    );
  }
}

class _ExtractContent extends StatefulWidget {
  const _ExtractContent();

  @override
  State<_ExtractContent> createState() => _ExtractContentState();
}

class _ExtractContentState extends State<_ExtractContent> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onExtract() async {
    final url = _controller.text.trim();
    setState(() => _isLoading = true);
    await extractController.extract(url);
    if (!mounted) return;
    setState(() => _isLoading = false);

    final result = extractResult.value;
    if (result is Success<VideoModel>) {
      final video = result.value;
      context.pop();
      if (video.type == 'workout') {
        context.go('/workout/${video.videoId}');
      } else if (video.type == 'diet') {
        context.go('/diet/${video.videoId}');
      }
      extractController.reset();
    } else if (result is Failure<VideoModel> && result.message == 'guest_limit') {
      extractController.reset();
      context.pop();
      SignInSheet.show(
        context,
        title: "You've used your 3 free extracts",
        subtitle:
            'Sign in with Google to save unlimited workouts and track your progress.',
      );
    } else if (result is Failure<VideoModel>) {
      UIKShowSnackBar(context, message: result.message, type: UIKSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          enabled: !_isLoading,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _onExtract(),
          decoration: const InputDecoration(
            hintText: 'Paste YouTube Shorts URL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        UIKButton.primary(
          label: 'Extract',
          onTap: _isLoading ? null : () async => _onExtract(),
          fullWidth: true,
        ),
      ],
    );
  }
}
