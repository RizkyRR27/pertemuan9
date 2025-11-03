import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool isCameraReady = false;
  bool isBackCamera = true;
  String? lastPhotoPath;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
      _controller = CameraController(
        isBackCamera ? cameras!.first : cameras!.last,
        ResolutionPreset.medium
      );
    await _controller!.initialize();
    setState(() {
      isCameraReady = true;
    });
  }

    Future<void> switchCamera() async {
      setState(() {
        isBackCamera = !isBackCamera;
        isCameraReady = false;
      });
      await _controller?.dispose();
      await initCamera();
    }

    Future<String> _getLocalPath() async {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }

    Future<void> takePicture() async {
      if (!_controller!.value.isInitialized) return;
    
      try {
        final image = await _controller!.takePicture();
        final localPath = await _getLocalPath();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '$localPath/$fileName';
      
        await File(image.path).copy(savedPath);
        setState(() {
          lastPhotoPath = savedPath;
        });
      
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo saved to: $savedPath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraReady) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Preview')),
        body: Column(
          children: [
            Expanded(
              child: CameraPreview(_controller!),
            ),
            if (lastPhotoPath != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Last photo: $lastPhotoPath'),
              ),
          ],
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'switch',
              child: const Icon(Icons.switch_camera),
              onPressed: switchCamera,
            ),
            const SizedBox(width: 16),
            FloatingActionButton(
              heroTag: 'capture',
              child: const Icon(Icons.camera_alt),
              onPressed: takePicture,
            ),
          ],
      ),
    );
  }
}