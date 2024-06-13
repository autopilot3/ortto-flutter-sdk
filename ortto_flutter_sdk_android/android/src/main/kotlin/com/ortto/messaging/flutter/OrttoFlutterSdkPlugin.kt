package com.ortto.messaging.flutter

import android.app.Activity
import android.app.Application
import android.content.Context
import android.util.Log
import com.google.firebase.messaging.RemoteMessage
import com.ortto.messaging.Ortto
import com.ortto.messaging.OrttoConfig
import com.ortto.messaging.PermissionUtil
import com.ortto.messaging.data.LinkUtm
import com.ortto.messaging.identity.UserID
import com.ortto.messaging.widget.CaptureConfig
import com.ortto.messaging.PushNotificationHandler

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

enum class PushPermission {
    ASK,
    DISABLED,
    GRANTED,
    PREVIOUSLY_DENIED,
    PREVIOUSLY_GRANTED,
}

class OrttoFlutterSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private var tag = "OrttoFlutterSdkPlugin";
    private lateinit var channel: MethodChannel
    private var applicationContext: Context? = null
    private var activity: Activity? = null;

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ortto_flutter_sdk_android")
        channel.setMethodCallHandler(this)
        applicationContext = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformName" -> result.success(getPlatformName())
            "initialize" -> result.success(initialize(call))
            "initializeCapture" -> result.success(initializeCapture(call))
            "identify" -> result.success(identify(call))
            "requestPermissions" -> requestPermissions(result)
            "onMessageReceived" -> onMessageReceived(call)
            "queueWidget" -> {
                queueWidget(call)
                result.success(null)
            }
            "showWidget" -> {
                showWidget(call)
                result.success(null)
            }
            "processNextWidgetFromQueue" -> {
                processNextWidgetFromQueue()
                result.success(null)
            }
            "dispatchPushRequest" -> {
                dispatchPushRequest()
                result.success(null)
            }
            "clearData" -> {
                clearData()
                result.success(null)
            }
            "clearIdentity" -> clearIdentity(result)
            "trackLinkClick" -> trackLinkClick(call, result)
            else -> result.notImplemented()
        }
    }

    // This is the method you want to implement
    private fun getPlatformName(): String {
        return "Android"
    }

    private fun initialize(call: MethodCall): Unit? {
        val config = OrttoConfig(
            call.argument("appKey"),
            call.argument("endpoint"),
            call.argument("shouldSkipNonExistingContacts"),
            call.argument("allowAnonUsers"),
        )

        Ortto.instance().init(config, this.applicationContext as Application)

        return null;
    }

    private fun initializeCapture(call: MethodCall): Unit? {
        val config = CaptureConfig(
            call.argument("dataSourceKey"),
            call.argument("captureJsUrl"),
            call.argument("apiHost"),
        )

        Ortto.instance().initCapture(config)

        if (activity != null) {
            Ortto.instance().capture.setActivity(activity);
        }

        return null;
    }

    private fun identify(call: MethodCall): Unit? {
        val user = UserID.make();
        user.firstName = call.argument("firstName");
        user.lastName = call.argument("lastName");
        user.email = call.argument("email");
        user.acceptsGdpr = call.argument<Boolean>("acceptsGdpr") ?: false;
        user.contactId = call.argument("contactId");
        user.phone = call.argument("phone");
        user.externalId = call.argument("externalId");

        Ortto.instance().identify(user);

        return null;
    }

    private fun clearData() {
        Ortto.instance().clearData()
    }

    private fun dispatchPushRequest() {
        Ortto.instance().dispatchPushRequest()
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        Ortto.instance().requestPermissions(activity, object : PermissionUtil.PermissionAskListener {
            override fun onPermissionAsk() {
                result.success(PushPermission.ASK.name)
            }

            override fun onPermissionDisabled() {
                result.success(PushPermission.DISABLED.name)
            }

            override fun onPermissionGranted() {
                result.success(PushPermission.GRANTED.name)
            }

            override fun onPermissionPreviouslyDenied() {
                result.success(PushPermission.PREVIOUSLY_DENIED.name)
            }

            override fun onPermissionPreviouslyGranted() {
                result.success(PushPermission.PREVIOUSLY_GRANTED.name)
            }
        })
    }

    private fun trackLinkClick(call: MethodCall, result: MethodChannel.Result) {
        val link = call.argument<String>("link");

        Ortto.instance().trackLinkClick(link
        ) {
            Log.d(tag, "trackLinkClick: $it")

            val map = mapOf(
                "utm_campaign" to it.campaign,
                "utm_medium" to it.medium,
                "utm_source" to it.source,
                "utm_content" to it.content
            )

            result.success(map);
        }
    }

    private fun queueWidget(call: MethodCall) {
        val widgetId = call.argument<String>("widgetId");

        Ortto.instance().queueWidget(widgetId);
    }

    private fun showWidget(call: MethodCall) {
        val widgetId = call.argument<String>("widgetId");

        Ortto.instance().showWidget(widgetId);
    }

    private fun processNextWidgetFromQueue() {
        Ortto.instance().capture?.processNextWidgetFromQueue()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun onMessageReceived(call: MethodCall): Boolean {
        val message = call.argument<Map<String, Any>?>("message")
        val context = applicationContext as Context

        // Inline transformation logic
        val notification = message?.get("notification") as? Map<String, Any>
        val data = message?.get("data") as? Map<String, Any>
        val messageParams = mutableMapOf<String, Any>()

        notification?.forEach { (key, value) ->
            messageParams[key] = value
        }
        // Ensuring 'data' params take precedence as they are mainly used in rich push
        data?.forEach { (key, value) ->
            messageParams[key] = value
        }

        // Construct RemoteMessage
        val remoteMessageBuilder = RemoteMessage.Builder("test").apply {
            messageParams.forEach { (key, value) ->
                // if value is null, dont add it
                if (value != null) {
                    addData(key, value.toString())
                }
            }
            (message?.get("messageId") as? String)?.let { messageId = it }
            (message?.get("messageType") as? String)?.let { messageType = it }
            (message?.get("collapseKey") as? String)?.let { collapseKey = it }
            (message?.get("ttl") as? Int)?.let { ttl = it }
        }
        val remoteMessage = remoteMessageBuilder.build()

        val handler = PushNotificationHandler(remoteMessage)

        return handler.handleMessage(context)
    }

    private fun clearIdentity(result: MethodChannel.Result) {
        Ortto.instance().clearIdentity() {
            val responseMap = mapOf("sessionId" to it.sessionId)
            result.success(responseMap)
        }
    }
}