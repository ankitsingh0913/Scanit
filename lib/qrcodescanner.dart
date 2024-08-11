import 'dart:typed_data';
import 'package:flutter/services.dart';

class QRCodeScanner {
  static const platform = MethodChannel('com.example.scanit/opencv');

  Future<bool> detectQRCode(Uint8List imageBytes) async {
    try {
      final bool detected = await platform.invokeMethod('detectQRCode', {
        'image': imageBytes,
      });
      return detected;
    } on PlatformException catch (e) {
      print("Failed to detect QR code: '${e.message}'.");
      return false;
    }
  }
}

class IOSFunctionality{
  static const MethodChannel _channel = MethodChannel('com.example.opencv');

  static Future<String> detectQRCode(Uint8List imageBytes) async {
    try {
      final result = await _channel.invokeMethod('detectQRCode', {'image': imageBytes});
      return result;
    } catch (e) {
      throw 'Unable to retrieve native data: $e';
    }
  }
}
