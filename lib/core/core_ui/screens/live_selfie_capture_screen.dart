import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

/// A live, camera-only capture screen for KYC selfies — no gallery/file
/// picker affordance anywhere, so the photo is provably taken right now
/// rather than an arbitrary uploaded image. Pops with the captured
/// [XFile], or `null` if the user backs out.
class LiveSelfieCaptureScreen extends StatefulWidget {
  const LiveSelfieCaptureScreen({super.key});

  @override
  State<LiveSelfieCaptureScreen> createState() =>
      _LiveSelfieCaptureScreenState();
}

class _LiveSelfieCaptureScreenState extends State<LiveSelfieCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _error;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _setUp();
  }

  Future<void> _setUp() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera was found on this device.');
        return;
      }
      final front = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Camera access was denied or is unavailable. Allow camera access and try again.',
      );
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, file);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = 'Could not capture the photo. Try again.';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                if (_error != null) return _errorView();
                final controller = _controller;
                if (controller == null ||
                    snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  );
                }
                return Center(child: CameraPreview(controller));
              },
            ),
            if (_controller != null && _error == null) _faceGuide(),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Center your face in the frame',
                    style:
                        AppTextStyles.caption.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: (_controller != null && _error == null)
                        ? _capture
                        : null,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _capturing ? Colors.white38 : Colors.white,
                        ),
                        child: _capturing
                            ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faceGuide() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 220,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(140),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                color: Colors.white70, size: 40),
            const SizedBox(height: 14),
            Text(
              _error ?? 'Camera unavailable.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              onPressed: () => setState(() {
                _error = null;
                _initFuture = _setUp();
              }),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
