import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:qr_scanner_overlay/qr_scanner_overlay.dart';
import 'package:scanit/qrcodescanner.dart';

class CameraScreenTest extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreenTest({required this.camera});

  @override
  _CameraScreenTestState createState() => _CameraScreenTestState();
}

class _CameraScreenTestState extends State<CameraScreenTest> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  Timer? _timer;
  bool isRecording = false;
  bool isProcessingImage = false;
  List<img.Image> images = [];
  List<String> qrCodes = [];
  List<img.Image> qrResults = [];

  List<XFile> originalImages = [];
  List<XFile> imagesWithQrCodes = [];

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startFrameCapture() {
    if (isRecording) return;
    setState(() {
      isRecording = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (isProcessingImage) return;
      try {
        if (_controller.value.isInitialized) {
          isProcessingImage = true;
          await _controller.setFlashMode(FlashMode.off);
          final image = await _controller.takePicture();
          final bytes = await image.readAsBytes();
          await processImage(bytes);
          isProcessingImage = false;
        }
      } catch (e) {
        print(e);
        isProcessingImage = false;
      }
    });
  }

  void stopFrameCapture() {
    if (!isRecording) return;
    setState(() {
      isRecording = false;
    });
    _timer?.cancel();
  }

  Future<void> processImage(Uint8List bytes) async {
    final img.Image? image = img.decodeImage(bytes);
    if (image != null) {
      final img.Image preprocessed = preprocessImage(image);
      setState(() {
        images.add(image);
      });
    }
    final qrScanner = QRCodeScanner();
    final detected = await qrScanner.detectQRCode(bytes);

    if (detected) {
      print("QR code Detected");
      setState(() {
        qrResults.add(img.decodeImage(bytes)!);
      });
    } else {
      print("No QR code detected.");
    }
  }

  img.Image preprocessImage(img.Image image) {
    final img.Image resized = img.copyResize(image, width: 300, height: 300);
    final grayscale = img.grayscale(resized);
    final preProcessed = img.adjustColor(grayscale, contrast: 1.5);
    return preProcessed;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('QR Scanner'),
          backgroundColor: Colors.blue,
        ),
        body: Column(
          children: [
            // Camera preview taking up half of the screen
            Expanded(
              flex: 1,
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FutureBuilder<void>(
                      future: _initializeControllerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return CameraPreview(_controller);
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      },
                    ),
                  ),
                  QRScannerOverlay(
                    scanAreaHeight: 300,
                    scanAreaWidth: 300,
                    overlayColor: Colors.black26,
                  ),
                ]
              ),
            ),
            // Remaining half of the screen
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  // Row with two buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: startFrameCapture,
                        icon: Icon(Icons.camera_alt),
                        label: Text('Start Camera'),
                      ),
                      ElevatedButton.icon(
                        onPressed: stopFrameCapture,
                        icon: Icon(Icons.stop),
                        label: Text('Stop Camera'),
                      ),
                    ],
                  ),
                  // Column with two horizontally scrolling lists
                  Expanded(
                    child: Column(
                      children: [
                        // First horizontal list
                        Expanded(
                          flex: 1,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: images.length,
                            itemBuilder: (context, index) {
                              final img.Image image = images[index];
                              final Uint8List encodedImage = Uint8List.fromList(img.encodeJpg(image));
                              return Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: Container(
                                  height: 100,
                                  width: 200,
                                  child: Image.memory(encodedImage,fit: BoxFit.cover,),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10,),
                        // Second horizontal list
                        Expanded(
                          flex: 1,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: qrResults.length,
                            itemBuilder: (context, index) {
                              final img.Image qrImage = qrResults[index];
                              final Uint8List encodedQrImage = Uint8List.fromList(img.encodeJpg(qrImage));
                              return Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: Container(
                                  height: 10,
                                  width: 100,
                                  child: Image.memory(encodedQrImage,fit: BoxFit.cover,),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
}

class QRPainter extends CustomPainter {
  final List<dynamic> results;

  QRPainter(this.results);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (var result in results) {
      final points = result.points
          .map((e) => Offset(e.x.toDouble(), e.y.toDouble()))
          .toList();
      if (points.length == 4) {
        final path = Path()
          ..moveTo(points[0].dx, points[0].dy)
          ..lineTo(points[1].dx, points[1].dy)
          ..lineTo(points[2].dx, points[2].dy)
          ..lineTo(points[3].dx, points[3].dy)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
