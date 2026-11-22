import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/storage_service.dart';
import '../widgets/face_guide_painter.dart';

class SkinalizCameraScreen extends StatefulWidget {
  final Directory clientDir;
  const SkinalizCameraScreen({super.key, required this.clientDir});

  @override
  State<SkinalizCameraScreen> createState() => _SkinalizCameraScreenState();
}

class _SkinalizCameraScreenState extends State<SkinalizCameraScreen> {
  CameraController? _controller;
  bool _isTakingPicture = false;
  int _selectedCameraIndex = 0;
  bool _showFaceGuide = true;
  int _photosTaken = 0;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  Offset? _focusPoint;
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    if (appCameras.isNotEmpty) {
      _initCamera(appCameras[_selectedCameraIndex]);
    }
  }

  Future<void> _initCamera(CameraDescription cameraDescription) async {
    final prev = _controller;
    if (prev != null) await prev.dispose();

    final newController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: false,
    );

    _controller = newController;

    try {
      await newController.initialize();
      _minZoom = await newController.getMinZoomLevel();
      _maxZoom = await newController.getMaxZoomLevel();
      _currentZoom = _minZoom;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (appCameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % appCameras.length;
    setState(() => _controller = null);
    await _initCamera(appCameras[_selectedCameraIndex]);
  }

  Future<void> _onTapToFocus(
      TapUpDetails details, BoxConstraints constraints) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    setState(() => _focusPoint = details.localPosition);

    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _focusPoint = null);
    });

    try {
      await _controller!.setFocusPoint(offset);
      await _controller!.setExposurePoint(offset);
    } catch (_) {}
  }

  Future<void> _setZoom(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final clamped = zoom.clamp(_minZoom, _maxZoom);
    await _controller!.setZoomLevel(clamped);
    setState(() => _currentZoom = clamped);
  }

  Future<void> _capturePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) return;
    setState(() => _isTakingPicture = true);

    try {
      final XFile tempImage = await _controller!.takePicture();
      await StorageService.saveClientImage(widget.clientDir, tempImage, 'Face');
      if (mounted) setState(() => _photosTaken++);
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientName = StorageService.getFolderName(widget.clientDir.path);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(clientName),
        actions: [
          IconButton(
            icon: Icon(
              _showFaceGuide ? Icons.face : Icons.face_retouching_off,
              color: _showFaceGuide ? Colors.tealAccent : Colors.white54,
            ),
            onPressed: () => setState(() => _showFaceGuide = !_showFaceGuide),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: (_controller == null || !_controller!.value.isInitialized)
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapUp: (details) =>
                            _onTapToFocus(details, constraints),
                        onScaleStart: (_) => _baseZoom = _currentZoom,
                        onScaleUpdate: (details) {
                          if (details.scale != 1.0)
                            _setZoom(_baseZoom * details.scale);
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(child: CameraPreview(_controller!)),
                            if (_showFaceGuide)
                              IgnorePointer(
                                  child:
                                      CustomPaint(painter: FaceGuidePainter())),
                            if (_focusPoint != null)
                              Positioned(
                                left: _focusPoint!.dx - 35,
                                top: _focusPoint!.dy - 35,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.amber, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            if (_maxZoom > _minZoom)
                              Positioned(
                                bottom: 12,
                                left: 24,
                                right: 24,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${_currentZoom.toStringAsFixed(1)}x',
                                        style: const TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Expanded(
                                        child: Slider(
                                          value: _currentZoom,
                                          min: _minZoom,
                                          max: _maxZoom,
                                          activeColor: Colors.amber,
                                          inactiveColor: Colors.white30,
                                          onChanged: _setZoom,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 28),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Badge(
                    isLabelVisible: _photosTaken > 0,
                    label: Text('$_photosTaken'),
                    child: const Icon(Icons.check_circle_outline,
                        color: Colors.tealAccent, size: 32),
                  ),
                ),
                FloatingActionButton.large(
                  onPressed: _isTakingPicture ? null : _capturePhoto,
                  backgroundColor: Colors.white,
                  child: _isTakingPicture
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Icon(Icons.camera_alt,
                          color: Colors.black, size: 36),
                ),
                IconButton(
                  onPressed: appCameras.length > 1 ? _switchCamera : null,
                  icon: const Icon(Icons.cameraswitch,
                      color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
