import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/extract_controller.dart';
import '../../core/atomic_state/result.dart';
import '../../core/ui/bottom_sheet/ui_kit_bottom_sheet.dart';
import '../../core/ui/buttons/ui_kit_button.dart';
import '../../core/ui/notifications/snackbar/snackbar.dart';
import '../../models/video_model.dart';

/// Bottom sheet for extracting fitness data from a YouTube Shorts URL.
/// Navigation after extraction is handled by the caller's listener on
/// [extractResult] — this sheet only pops itself when done.
class ExtractSheet {
  ExtractSheet._();

  static Future<void> show(BuildContext context) {
    extractController.reset();
    return UIKitBottomSheet.show<void>(
      context,
      title: 'Extract from Shorts',
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
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    extractResult.addListener(_onResult);
  }

  @override
  void dispose() {
    extractResult.removeListener(_onResult);
    _urlController.dispose();
    super.dispose();
  }

  void _onResult() {
    if (!mounted) return;
    final result = extractResult.value;
    if (result is Success<VideoModel>) {
      context.pop();
    } else if (result is Failure<VideoModel>) {
      final msg = result.message;
      if (msg == 'guest_limit') {
        context.pop();
      } else {
        UIKShowSnackBar(context, message: msg, type: UIKSnackBarType.error);
      }
    }
  }

  void _extract() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    extractController.extract(url);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: extractResult(
        idle: () => _ExtractBody(
          urlController: _urlController,
          onExtract: _extract,
        ),
        loading: () => _ExtractBody(
          urlController: _urlController,
          onExtract: _extract,
          isLoading: true,
        ),
        success: (_) => _ExtractBody(
          urlController: _urlController,
          onExtract: _extract,
        ),
        failure: (_) => _ExtractBody(
          urlController: _urlController,
          onExtract: _extract,
        ),
        empty: () => _ExtractBody(
          urlController: _urlController,
          onExtract: _extract,
        ),
      ),
    );
  }
}

class _ExtractBody extends StatelessWidget {
  const _ExtractBody({
    required this.urlController,
    required this.onExtract,
    this.isLoading = false,
  });

  final TextEditingController urlController;
  final VoidCallback onExtract;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: urlController,
          enabled: !isLoading,
          autofocus: true,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => onExtract(),
          decoration: const InputDecoration(
            hintText: 'Paste YouTube Shorts URL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        UIKButton.primary(
          label: isLoading ? 'Extracting…' : 'Extract',
          onTap: isLoading ? null : () async => onExtract(),
          isLoading: isLoading,
          fullWidth: true,
        ),
      ],
    );
  }
}
