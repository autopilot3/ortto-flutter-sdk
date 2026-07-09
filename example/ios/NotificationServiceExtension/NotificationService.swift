//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Mitch Flindell on 16/8/2023.
//

import UserNotifications
import OrttoPushMessagingFCM

class NotificationService: UNNotificationServiceExtension {

    private var handledByOrtto = false

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

        handledByOrtto = PushMessaging.shared.didReceive(request, withContentHandler: contentHandler)

        if !handledByOrtto {
            contentHandler(request.content)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if handledByOrtto {
            PushMessaging.shared.serviceExtensionTimeWillExpire()
        }
    }
}
