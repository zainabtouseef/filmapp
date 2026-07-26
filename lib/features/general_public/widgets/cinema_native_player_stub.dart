import 'package:flutter/material.dart';

class CinemaNativePlayer extends StatelessWidget {
  final String mediaUrl;
  final bool video;

  const CinemaNativePlayer({
    super.key,
    required this.mediaUrl,
    required this.video,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SelectableText('Open media in a browser: $mediaUrl'),
    );
  }
}
