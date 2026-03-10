import 'package:flutter/material.dart';

import '../../../controllers/extract_controller.dart';
import '../../../core/ui/buttons/ui_kit_button.dart';

class ExtractInput extends StatelessWidget {
  const ExtractInput({super.key, required this.urlController});

  final TextEditingController urlController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: urlController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => extractController.extract(urlController.text.trim()),
            decoration: const InputDecoration(
              hintText: 'Paste YouTube Shorts URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          UIKButton.primary(
            label: 'Extract',
            onTap: () async => extractController.extract(urlController.text.trim()),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
