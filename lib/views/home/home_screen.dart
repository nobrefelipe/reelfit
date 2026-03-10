import 'package:flutter/material.dart';
import 'package:reelfit/core/ui/text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: UIKText.h4('ReelFit')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
