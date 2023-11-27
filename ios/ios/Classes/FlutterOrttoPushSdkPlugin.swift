import Flutter
import UIKit
import OrttoSDKCore
import OrttoPushMessagingFCM
import OrttoInAppNotifications
import FirebaseMessaging

public class FlutterOrttoPushSdkPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_ortto_push_sdk_ios", binaryMessenger: registrar.messenger())
        let instance = FlutterOrttoPushSdkPlugin()
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
            identify(call)
            result(nil)
        case "clearData":
            clearData()
            result(nil)
        case "dispatchPushRequest":
            dispatchPushRequest()
            result(nil)
        case "requestPermissions":
            // TODO: implement requestPermissions
            result(nil)
        case "trackLinkClick":
            trackLinkClick(call, result)
        case "queueWidget":
            queueWidget(call)
            result(nil)
        case "showWidget":
            showWidget(call)
            result(nil)
        case "processNextWidgetFromQueue":
            processNextWidgetFromQueue()
            result(nil)
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

    private func identify(_ call: FlutterMethodCall) {
        if let userData = call.arguments as? [String:Any?] {
            var user = UserIdentifier(contactID: userData["contact_id"] as? String, email: userData["email"] as? String, phone: userData["phone"] as? String, externalID: userData["external_id"] as? String, firstName: userData["first_name"] as? String, lastName: userData["last_name"] as? String)
            user.acceptsGDPR = userData["accepts_gdpr"] as? Bool ?? false;

            Ortto.shared.identify(user)
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

    private func showWidget(_ call: FlutterMethodCall) {
        guard let args = call.arguments as? [String:Any?] else {
            return
        }

        if let widgetId = args["widgetId"] as? String {
            OrttoCapture.shared.showWidget(widgetId)
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
            // tell the app that we have finished processing the user’s action / response
            completionHandler()
        }
    }
}
