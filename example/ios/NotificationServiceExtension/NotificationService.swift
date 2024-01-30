//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Mitch Flindell on 16/8/2023.
//

import UserNotifications
import OrttoPushMessagingFCM

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

        self.contentHandler = contentHandler

        let handled = PushMessaging.shared.didReceive(request, withContentHandler: contentHandler)

        if !handled {
            print("Handled!")
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler,
            let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
