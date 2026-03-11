import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class YouTubeEmbed extends StatefulWidget {
  const YouTubeEmbed({super.key, required this.videoId});

  final String videoId;

  @override
  State<YouTubeEmbed> createState() => _YouTubeEmbedState();
}

class _YouTubeEmbedState extends State<YouTubeEmbed> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'yt-${widget.videoId}';
    ui.platformViewRegistry.registerViewFactory(_viewId, (int id) {
      final iframe = web.HTMLIFrameElement()
        ..src =
            'https://www.youtube.com/embed/${widget.videoId}?autoplay=1&playsinline=1'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true
        ..setAttribute('allow', 'autoplay; encrypted-media; fullscreen');
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
