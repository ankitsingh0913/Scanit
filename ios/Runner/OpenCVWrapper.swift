import Foundation
import UIKit
import opencv2

@objc class OpenCVWrapper: NSObject {

  @objc static func detectQRCode(from image: UIImage) -> Bool {
    guard let cvImage = OpenCVWrapper.convertUIImageToMat(image) else {
      return false
    }

    let qrCodeDetector = cv2.QRCodeDetector()
    let points = cv2.Mat()
    let result = qrCodeDetector.detect(cvImage, points: points)

    return result
  }

  @objc static func convertUIImageToMat(_ image: UIImage) -> cv2.Mat? {
    guard let cgImage = image.cgImage else {
      return nil
    }

    let mat = cv2.Mat(cgImage: cgImage)
    return mat
  }
}
