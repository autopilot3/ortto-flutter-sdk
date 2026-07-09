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
        case "getPlatformName":
            result("iOS")
        case "initialize":
            initialize(call, result)
        case "initializeCapture":
            initializeCapture(call, result)
        case "identify":
            identify(call, result)
        case "clearData":
            clearData()
            result(nil)
        case "dispatchPushRequest":
            dispatchPushRequest()
            result(nil)
        case "requestPermissions":
            requestPermissions(result)
        case "registerDeviceToken":
            registerDeviceToken(call, result)
        case "trackLinkClick":
            trackLinkClick(call, result)
        case "queueWidget":
            queueWidget(call, result)
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

    private func initialize(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let configMap = call.arguments as? [String: Any?],
              let appKey = configMap["appKey"] as? String,
              !appKey.isEmpty else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "initialize requires a non-empty appKey",
                details: nil
            ))
            return
        }

        Ortto.initialize(
            appKey: appKey,
            endpoint: configMap["endpoint"] as? String,
            shouldSkipNonExistingContacts: configMap["shouldSkipNonExistingContacts"] as? Bool ?? false
        )
        result(nil)
    }

    private func initializeCapture(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let configMap = call.arguments as? [String: Any?],
              let dataSourceKey = configMap["dataSourceKey"] as? String,
              !dataSourceKey.isEmpty else {
            result(invalidArguments("initializeCapture requires a non-empty dataSourceKey"))
            return
        }

        do {
            try OrttoCapture.initialize(
                dataSourceKey: dataSourceKey,
                captureJsURL: url(from: configMap["captureJsUrl"]),
                apiHost: url(from: configMap["apiHost"])
            )
            result(nil)
        } catch {
            result(FlutterError(
                code: "CAPTURE_INITIALIZATION_ERROR",
                message: error.localizedDescription,
                details: String(describing: error)
            ))
        }
    }

    private func identify(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let userData = call.arguments as? [String: Any?] else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "identify requires an identity map",
                details: nil
            ))
            return
        }

        var user = UserIdentifier(
            contactID: userData["contact_id"] as? String,
            email: userData["email"] as? String,
            phone: userData["phone"] as? String,
            externalID: userData["external_id"] as? String,
            firstName: userData["first_name"] as? String,
            lastName: userData["last_name"] as? String
        )
        user.acceptsGDPR = userData["accepts_gdpr"] as? Bool ?? false

        Ortto.shared.identify(user) { response in
            switch response {
            case .success:
                result(nil)
            case .failure(let error):
                result(FlutterError(
                    code: "IDENTIFY_ERROR",
                    message: error.localizedDescription,
                    details: String(describing: error)
                ))
            }
        }
    }

    private func queueWidget(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any?],
              let widgetId = args["widgetId"] as? String,
              !widgetId.isEmpty else {
            result(invalidArguments("queueWidget requires a non-empty widgetId"))
            return
        }

        OrttoCapture.shared.queueWidget(widgetId)
        result(nil)
    }

    private func registerDeviceToken(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any?],
              let token = args["token"] as? String,
              !token.isEmpty else {
            result(invalidArguments("registerDeviceToken requires a non-empty token"))
            return
        }

        PushMessaging.shared.registerDeviceToken(fcmToken: token)
        result(nil)
    }

    private func trackLinkClick(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any?] else {
            result(invalidArguments("trackLinkClick requires an argument map"))
            return
        }

        guard let link = args["link"] as? String, !link.isEmpty else {
            result(invalidArguments("trackLinkClick requires a non-empty link"))
            return
        }

        guard let components = URLComponents(string: link),
              components.scheme != nil else {
            result(FlutterError(code: "INVALID_LINK", message: "The link is malformed", details: link))
            return
        }

        let trackingValue = components.queryItems?.first(where: { $0.name == "tracking_url" })?.value
        let utmSource = trackingValue.flatMap(decodeBase64URL) ?? link

        let linkUtm = Ortto.shared.retrieveUtmParameters(utmSource) ?? LinkUtm([])

        let response = linkUtmMap(linkUtm)
        guard trackingValue != nil else {
            result(response)
            return
        }

        var completed = false
        let complete: (Any) -> Void = { value in
            DispatchQueue.main.async {
                guard !completed else { return }
                completed = true
                result(value)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            guard !completed else { return }
            completed = true
            result(FlutterError(
                code: "TRACKING_ERROR",
                message: "Link tracking did not complete",
                details: link
            ))
        }

        Ortto.shared.trackLinkClick(link) {
            complete(response)
        }
    }

    private func decodeBase64URL(_ value: String) -> String? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder != 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }

        guard let data = Data(base64Encoded: base64) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func linkUtmMap(_ utm: OrttoSDKCore.LinkUtm) -> [String: Any] {
        [
            "utm_campaign": flutterValue(utm.campaign),
            "utm_medium": flutterValue(utm.medium),
            "utm_source": flutterValue(utm.source),
            "utm_content": flutterValue(utm.content)
        ]
    }

    private func flutterValue(_ value: String?) -> Any {
        if let value = value {
            return value
        }
        return NSNull()
    }

    private func requestPermissions(_ result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    result("ASK")
                case .denied:
                    result("PREVIOUSLY_DENIED")
                case .authorized, .provisional, .ephemeral:
                    result("PREVIOUSLY_GRANTED")
                @unknown default:
                    result(FlutterError(
                        code: "UNKNOWN_PERMISSION_STATUS",
                        message: "iOS returned an unknown notification authorization status",
                        details: settings.authorizationStatus.rawValue
                    ))
                }
            }
        }
    }

    private func invalidArguments(_ message: String) -> FlutterError {
        FlutterError(code: "INVALID_ARGUMENTS", message: message, details: nil)
    }

    private func url(from value: Any?) -> URL? {
        guard let string = value as? String, !string.isEmpty else {
            return nil
        }
        return URL(string: string)
    }

    private func onMessageReceived(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(false)
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
