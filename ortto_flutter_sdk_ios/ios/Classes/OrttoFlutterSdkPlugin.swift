import Flutter
import UIKit
import OrttoSDKCore
import OrttoPushMessagingFCM
import OrttoInAppNotifications
import OrttoPushMessaging
import FirebaseMessaging

public class OrttoFlutterSdkPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ortto_flutter_sdk_ios", binaryMessenger: registrar.messenger())
        let instance = OrttoFlutterSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(call)
            result(nil)
        case "initializeCapture":
            initializeCapture(call)
            result(nil)
        case "identify":
            identify(call, result)
        case "clearData":
            clearData()
            result(nil)
        case "dispatchPushRequest":
            dispatchPushRequest()
            result(nil)
        case "requestPermissions":
            // TODO: implement requestPermissions
            result(nil)
        case "registerDeviceToken":
            registerDeviceToken(call)
        case "trackLinkClick":
            trackLinkClick(call, result)
        case "queueWidget":
            queueWidget(call)
            result(nil)
        case "showWidget":
            showWidget(call, result)
        case "processNextWidgetFromQueue":
            processNextWidgetFromQueue()
            result(nil)
        case "onMessageReceived":
            onMessageReceived(call, result)
        case "clearIdentity":
            clearIdentity(call, result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initialize(_ call: FlutterMethodCall) {
        if let configMap = call.arguments as? [String:Any?] {
            Ortto.initialize(
                appKey: (configMap["appKey"] as? String)!,
                endpoint: configMap["endpoint"] as? String
            );
        }
    }

    private func initializeCapture(_ call: FlutterMethodCall) {
        if let configMap = call.arguments as? [String:Any?] {
            try? OrttoCapture.initialize(
                dataSourceKey: (configMap["dataSourceKey"] as? String)!,
                captureJsURL: URL(string: configMap["captureJsUrl"] as? String ?? ""),
                apiHost: URL(string: configMap["apiHost"] as? String ?? "")
            );
        }
    }

    private func identify(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        if let userData = call.arguments as? [String:Any?] {
            var user = UserIdentifier(contactID: userData["contact_id"] as? String, email: userData["email"] as? String, phone: userData["phone"] as? String, externalID: userData["external_id"] as? String, firstName: userData["first_name"] as? String, lastName: userData["last_name"] as? String)
            user.acceptsGDPR = userData["accepts_gdpr"] as? Bool ?? false;

            Ortto.shared.identify(user) { response in
                result(nil)
            }
        }
    }

    private func queueWidget(_ call: FlutterMethodCall) {
        guard let args = call.arguments as? [String:Any?] else {
            return
        }

        if let widgetId = args["widgetId"] as? String {
            OrttoCapture.shared.queueWidget(widgetId)
        }
    }

    private func registerDeviceToken(_ call: FlutterMethodCall) {
        guard let args = call.arguments as? [String:Any?] else {
            return
        }

        if let token = args["token"] as? String {
            PushMessaging.shared.registerDeviceToken(fcmToken: token)
        }
    }

    private func trackLinkClick(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String:Any?] else {
            return
        }

        guard let link = args["link"] as? String else {
            return
        }

        Ortto.shared.trackLinkClick(link) {}

        guard let uri = URL(string: link) else { return }
        guard let components = URLComponents(string: uri.absoluteString) else { return }
        guard let queryItems = components.queryItems else { return }

        var linkUtm: [String: String] = queryItems.reduce(into: [String: String]()) { (result, item) in
            switch item.name {
            case "utm_campaign":
                result[item.name] = item.value
            case "utm_source":
                result[item.name] = item.value
            case "utm_medium":
                result[item.name] = item.value
            case "utm_content":
                result[item.name] = item.value
            default:
                result
            }
        }

        result(linkUtm)
    }

    private func onMessageReceived(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(true)
    }

    private func processNextWidgetFromQueue() {
        OrttoCapture.shared.processNextWidgetFromQueue()
    }

    private func dispatchPushRequest() {
        Ortto.shared.dispatchPushRequest()
    }

    private func clearData() {
        Ortto.shared.clearData()
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let handled = PushMessaging.shared.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)

        if !handled {
            completionHandler()
        }
    }

    private func showWidget(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let widgetId = args["widgetId"] as? String else {
            result([
                "success": false,
                "message": "Invalid or missing widgetId"
            ])
            return
        }

        guard let capture = OrttoCapture.shared else {
            result([
                "success": false,
                "message": "OrttoCapture not initialized"
            ])
            return
        }

        capture.showWidget(widgetId).then { showResult in
            switch showResult {
            case .success:
                result([
                    "success": true,
                    "message": "Widget shown successfully"
                ])
            case .failure(let error):
                if let widgetError = error as? WidgetError {
                    result([
                        "success": false,
                        "message": widgetError.errorDescription ?? "Widget error"
                    ])
                } else {
                    result([
                        "success": false,
                        "message": error.localizedDescription
                    ])
                }
            }
        }
    }

    public func clearIdentity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        Ortto.shared.clearIdentity { response in
            if let response = response {
                let responseDict: [String: Any] = [
                    "sessionId": response.sessionId,
                    "success": true
                ]
                result(responseDict)
            } else {
                result([
                    "success": false,
                    "message": "No identity found or failed to unregister"
                ])
            }
        }
    }
}
