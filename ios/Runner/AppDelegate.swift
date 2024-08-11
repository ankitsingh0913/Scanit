import UIKit
import Flutter
import opencv2

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?

  override func application(_ application: UIApplication,
                            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(name: "com.example.opencv", binaryMessenger: controller.binaryMessenger)

    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "detectQRCode" {
        guard let args = call.arguments as? [String: Any],
              let imageData = args["image"] as? FlutterStandardTypedData,
              let image = UIImage(data: imageData.data) else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
          return
        }

        let detected = OpenCVWrapper.detectQRCode(from: image)
        result(detected)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
