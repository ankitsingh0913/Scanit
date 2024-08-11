package com.example.scanit

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity(){
    private val CHANNEL = "com.example.scanit/opencv"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "detectQRCode") {
                    val imageBytes = call.argument<ByteArray>("image")!!
                    val detector = QRCodeDetector()
                    val detected = detector.detectQRCode(imageBytes)
                    result.success(detected)
                } else {
                    result.notImplemented()
                }
            }
    }
}
