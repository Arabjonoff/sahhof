import UIKit
import Flutter
import flutter_downloader

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    // flutter_downloader setup - KEYIN qo'yish kerak
    FlutterDownloaderPlugin.setPluginRegistrantCallback { registry in
        if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
           GeneratedPluginRegistrant.register(with: registry)
        }
    }

    // Background mode uchun
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}