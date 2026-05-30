import Flutter
import UIKit
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDu9bGinsC5bUXC9v4soZHBR2cqoY9WMyM")
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    // Channel zum Entfernen von Notifications aus dem iOS-Benachrichtigungscenter.
    // flutter_local_notifications.cancel() entfernt nur eigene lokale Notifications,
    // nicht APNs-Push-Notifications die iOS im Hintergrund anzeigt.
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "eventride/notifications",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "removeAllDeliveredNotifications" {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
