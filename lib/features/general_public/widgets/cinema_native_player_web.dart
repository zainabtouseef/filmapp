import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class CinemaNativePlayer extends StatefulWidget {
  final String mediaUrl;
  final bool video;

  const CinemaNativePlayer({
    super.key,
    required this.mediaUrl,
    required this.video,
  });

  @override
  State<CinemaNativePlayer> createState() => _CinemaNativePlayerState();
}

class _CinemaNativePlayerState extends State<CinemaNativePlayer> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'cineconnect-${widget.video ? 'video' : 'audio'}-${DateTime.now().microsecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      if (widget.video) {
        return web.HTMLVideoElement()
          ..src = widget.mediaUrl
          ..controls = true
          ..autoplay = false
          ..preload = 'metadata'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..style.backgroundColor = '#050505';
      }
      return web.HTMLAudioElement()
        ..src = widget.mediaUrl
        ..controls = true
        ..autoplay = false
        ..preload = 'metadata'
        ..style.width = '100%';
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
