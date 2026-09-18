## 0.7.0

* Adds Flutter Swift Package Manager support for the iOS bridge and example.
* Updates the native integrations to Ortto iOS 1.10.1 and Android 1.8.9.
* Corrects the iOS example to request notification permission through Firebase Messaging, opt into foreground presentation, and forward foreground and tap callbacks to Ortto without taking callback ownership away from FlutterFire.
* Registers refreshed Firebase tokens and avoids treating a local token-forwarding call as confirmation that the backend accepted the registration.
* Documents the complete Firebase Messaging permission, token, refresh, foreground, and background setup.

## 0.1.0+1

* Prepare for publishing
