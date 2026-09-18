import UIKit
import Flutter
import OrttoPushMessagingFCM
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // FlutterAppDelegate forwards notification callbacks to FlutterFire.
        // Keep it as the notification-center delegate so Dart receives
        // onMessage and onMessageOpenedApp events.
        UNUserNotificationCenter.current().delegate = self

        // Tells iOS to provide a push token, if one is available.
        // This is required even before the user grants notification permission.
        UIApplication.shared.registerForRemoteNotifications()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Let Ortto track/deep-link the action, but leave completion ownership
    // with FlutterAppDelegate so FlutterFire also emits onMessageOpenedApp.
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        _ = PushMessaging.shared.userNotificationCenter(
            center,
            didReceive: response,
            withCompletionHandler: {}
        )
        super.userNotificationCenter(
            center,
            didReceive: response,
            withCompletionHandler: completionHandler
        )
    }
}
