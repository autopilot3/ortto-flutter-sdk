package com.ortto.messaging.flutter

import android.app.Activity
import android.app.Application
import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.lang.Exception
import com.google.firebase.messaging.RemoteMessage
import com.ortto.messaging.Ortto
import com.ortto.messaging.OrttoConfig
import com.ortto.messaging.PermissionUtil
import com.ortto.messaging.data.LinkUtm
import com.ortto.messaging.identity.UserID
import com.ortto.messaging.widget.CaptureConfig
import com.ortto.messaging.retrofit.RegistrationResponse
import com.ortto.messaging.PushNotificationHandler
import com.ortto.messaging.OrttoCaptureInitException
import androidx.core.app.ActivityCompat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry

enum class PushPermission {
    ASK,
    DISABLED,
    GRANTED,
    PREVIOUSLY_DENIED,
    PREVIOUSLY_GRANTED,
}

class OrttoFlutterSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 4107
    }

    private var tag = "OrttoFlutterSdkPlugin";
    private lateinit var channel: MethodChannel
    private var applicationContext: Context? = null
    private var activity: Activity? = null;
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private val permissionResultListener = PluginRegistry.RequestPermissionsResultListener {
            requestCode, _, grantResults ->
        if (requestCode != NOTIFICATION_PERMISSION_REQUEST_CODE) {
            false
        } else {
            val result = pendingPermissionResult
            pendingPermissionResult = null
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            if (granted) {
                Ortto.instance().dispatchPushRequest()
                result?.success(PushPermission.GRANTED.name)
            } else {
                result?.success(PushPermission.PREVIOUSLY_DENIED.name)
            }
            true
        }
    }

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
            "identify" -> identify(call, result)
            "requestPermissions" -> requestPermissions(result)
            "onMessageReceived" -> result.success(onMessageReceived(call))
            "queueWidget" -> {
                queueWidget(call)
                result.success(null)
            }
            "showWidget" -> showWidget(call, result)
            "registerDeviceToken" -> registerDeviceToken(call, result)
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
        val appKey = call.argument<String>("appKey")
        val endpoint = call.argument<String>("endpoint")
        val shouldSkipNonExistingContacts =
            call.argument<Boolean>("shouldSkipNonExistingContacts") ?: false
        val config = OrttoConfig(
            appKey,
            endpoint,
            shouldSkipNonExistingContacts,
        )

        OrttoFlutterSdkStartup.save(
            applicationContext as Context,
            appKey,
            endpoint,
            shouldSkipNonExistingContacts,
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

    private fun identify(call: MethodCall, result: MethodChannel.Result): Unit? {
        val user = UserID.make();
        user.firstName = call.argument("first_name");
        user.lastName = call.argument("last_name");
        user.email = call.argument("email");
        user.acceptsGdpr = call.argument<Boolean>("accepts_gdpr") ?: false;
        user.contactId = call.argument("contact_id");
        user.phone = call.argument("phone");
        user.externalId = call.argument("external_id");

        Ortto.instance().identify(user, object : Ortto.OnIdentifyListener {
            override fun onComplete() {
                result.success(null)
            }

            override fun onError(error: Throwable) {
                result.error("IDENTIFY_ERROR", error.message ?: "Unknown identify error", error.stackTraceToString())
            }
        })

        return null;
    }

    private fun clearData() {
        Ortto.instance().clearData()
    }

    private fun dispatchPushRequest() {
        Ortto.instance().dispatchPushRequest()
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Notification permission requires a foreground activity", null)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("PERMISSION_IN_PROGRESS", "A notification permission request is already in progress", null)
            return
        }

        Ortto.instance().requestPermissions(currentActivity, object : PermissionUtil.PermissionAskListener {
            override fun onPermissionAsk() {
                launchNotificationPermissionRequest(currentActivity, result)
            }

            override fun onPermissionDisabled() {
                result.success(PushPermission.DISABLED.name)
            }

            override fun onPermissionGranted() {
                result.success(PushPermission.GRANTED.name)
            }

            override fun onPermissionPreviouslyDenied() {
                launchNotificationPermissionRequest(currentActivity, result)
            }

            override fun onPermissionPreviouslyGranted() {
                result.success(PushPermission.PREVIOUSLY_GRANTED.name)
            }
        })
    }

    private fun launchNotificationPermissionRequest(
        currentActivity: Activity,
        result: MethodChannel.Result,
    ) {
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            currentActivity,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST_CODE,
        )
    }

    private fun trackLinkClick(call: MethodCall, result: MethodChannel.Result) {
        val link = call.argument<String>("link")
        if (link.isNullOrBlank()) {
            result.error("INVALID_ARGUMENTS", "trackLinkClick requires a non-empty link", null)
            return
        }

        val uri = try {
            Uri.parse(link)
        } catch (error: RuntimeException) {
            result.error("INVALID_LINK", "The link is malformed", error.message)
            return
        }

        if (uri.scheme.isNullOrBlank()) {
            result.error("INVALID_LINK", "The link is malformed", link)
            return
        }

        val directUtm = LinkUtm.fromUri(uri)
        if (uri.getQueryParameter("tracking_url") == null) {
            result.success(linkUtmMap(directUtm))
            return
        }

        val handler = Handler(Looper.getMainLooper())
        var completed = false
        val timeout = Runnable {
            if (!completed) {
                completed = true
                result.error("TRACKING_ERROR", "Link tracking did not complete", link)
            }
        }
        handler.postDelayed(timeout, 30_000)

        Ortto.instance().trackLinkClick(link) {
            handler.post {
                if (!completed) {
                    completed = true
                    handler.removeCallbacks(timeout)
                    result.success(linkUtmMap(it))
                }
            }
        }
    }

    private fun linkUtmMap(utm: LinkUtm): Map<String, String?> = mapOf(
        "utm_campaign" to utm.campaign,
        "utm_medium" to utm.medium,
        "utm_source" to utm.source,
        "utm_content" to utm.content
    )

    private fun registerDeviceToken(call: MethodCall, result: MethodChannel.Result) {
        Ortto.instance().registerDeviceToken(call.argument<String>("token")) {
            result.success(null);
        }
    }

    private fun queueWidget(call: MethodCall) {
        val widgetId = call.argument<String>("widgetId");

        Ortto.instance().queueWidget(widgetId);
    }

    private fun showWidget(call: MethodCall, result: MethodChannel.Result) {
        val widgetId = call.argument<String>("widgetId")

        if (widgetId == null) {
            result.error("INVALID_ARGUMENT", "widgetId is null", null)
            return
        }

        Ortto.instance().showWidget(widgetId, object : Ortto.WidgetCallback {
            override fun onSuccess() {
                val widgetResult = mapOf(
                    "success" to true,
                    "message" to "Widget shown successfully."
                )
                result.success(widgetResult)
            }

            override fun onFailure(t: Throwable) {
                result.error("WIDGET_SHOW_FAILED", t.message, t.stackTraceToString())
            }
        })
    }

    private fun processNextWidgetFromQueue() {
        Ortto.instance().capture?.processNextWidgetFromQueue()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addRequestPermissionsResultListener(permissionResultListener)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addRequestPermissionsResultListener(permissionResultListener)
    }

    override fun onDetachedFromActivity() {
        detachFromActivity()
    }

    private fun detachFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(permissionResultListener)
        activityBinding = null
        activity = null
        pendingPermissionResult?.error(
            "NO_ACTIVITY",
            "The activity detached before notification permission completed",
            null,
        )
        pendingPermissionResult = null
    }

    private fun onMessageReceived(call: MethodCall): Boolean {
        val message = call.argument<Map<String, Any>?>("message")
        val handleNotificationTrigger = call.argument<Boolean>("handleNotificationTrigger") ?: true
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

        return handler.handleMessage(context, handleNotificationTrigger)
    }

    private fun clearIdentity(result: MethodChannel.Result) {
        Ortto.instance().clearIdentity(object : Ortto.ClearIdentityCallback {
            override fun onSuccess(response: RegistrationResponse) {
                Log.d(tag, "clearIdentity.onSuccess: ${response.sessionId}")
                result.success(mapOf("sessionId" to response.sessionId))
            }

            override fun onFailure(error: Throwable) {
                result.error("IDENTITY_ERROR", error.message, error.stackTraceToString())
            }
        })
    }
}
