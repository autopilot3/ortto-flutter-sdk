import UIKit
import Flutter
import FirebaseMessaging
import FirebaseCore
import OrttoPushMessagingFCM
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // Configure Firebase
//        FirebaseApp.configure()

        // Set FCM messaging delegate
        Messaging.messaging().delegate = self

        // Set the iOS push notification click handler
        // This is required in order for the Customer.io SDK to handle when a push is clicked.
        UNUserNotificationCenter.current().delegate = self

        // Tells iOS to provide a push token, if one is available.
        // Note: You need to include this line even if your app user has not granted notification permissions.
        UIApplication.shared.registerForRemoteNotifications()
      
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
        func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            
            // push this ?
            
             Messaging.messaging().setAPNSToken(deviceToken, type: .unknown);
         }
    
         // Called when a push notification is clicked.
         override func userNotificationCenter(
             _ center: UNUserNotificationCenter,
             didReceive response: UNNotificationResponse,
             withCompletionHandler completionHandler: @escaping () -> Void
         ) {
             let handled = PushMessaging.shared.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    
             if !handled {
                 completionHandler()
             }
           }
    
           // (Optional, available for iOS 14 and onwards) Add if you want to show your push notifications when your app is in the foreground.
           override func userNotificationCenter(
             _ center: UNUserNotificationCenter,
             willPresent notification: UNNotification,
             withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
           ) {
    //          completionHandler([.list, .banner, .badge, .sound])
             completionHandler([.badge, .sound])
           }
   
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      
      print("fcmToken: \(fcmToken)")
      
      PushMessaging.shared.registerDeviceToken(fcmToken: fcmToken)

  }
}
