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
      final embedUrl = _youtubeEmbedUrl(widget.mediaUrl);
      if (embedUrl != null) {
        return web.HTMLIFrameElement()
          ..src = embedUrl
          ..allow =
              'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
          ..allowFullscreen = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.border = '0'
          ..style.backgroundColor = '#050505';
      }
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

String? _youtubeEmbedUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  String? id;
  if (host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
    id = uri.pathSegments.first;
  } else if (host.contains('youtube.com')) {
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'embed') {
      id = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
    } else if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'shorts') {
      id = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
    } else {
      id = uri.queryParameters['v'];
    }
  }
  if (id == null || id.trim().isEmpty) return null;
  return 'https://www.youtube.com/embed/${Uri.encodeComponent(id)}?rel=0&modestbranding=1';
}
