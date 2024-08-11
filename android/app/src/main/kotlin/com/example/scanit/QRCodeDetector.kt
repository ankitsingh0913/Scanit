package com.example.scanit

import android.graphics.BitmapFactory
import org.opencv.android.Utils
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.objdetect.QRCodeDetector

class QRCodeDetector {

    init {
        System.loadLibrary("opencv_java4")
    }

    fun detectQRCode(imageBytes: ByteArray): Boolean {
        // Decode the image bytes to Bitmap
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
        val mat = Mat(bitmap.height, bitmap.width, CvType.CV_8UC4)
        Utils.bitmapToMat(bitmap, mat)

        val qrCodeDetector = QRCodeDetector()
        val points = Mat()
        val decodedText = qrCodeDetector.detectAndDecode(mat, points)

        return decodedText.isNotEmpty()
    }
}

