import OrttoPushMessagingFCM
import UserNotifications

public enum OrttoNotificationService {
    public static func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool {
        PushMessaging.shared.didReceive(
            request,
            withContentHandler: contentHandler
        )
    }

    public static func serviceExtensionTimeWillExpire() {
        PushMessaging.shared.serviceExtensionTimeWillExpire()
    }
}
