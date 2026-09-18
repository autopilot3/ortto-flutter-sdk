package com.ortto.messaging.flutter

import android.app.Application
import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.util.Log
import com.ortto.messaging.Ortto
import com.ortto.messaging.OrttoConfig

internal object OrttoFlutterSdkStartup {
    private const val preferencesName = "ortto_flutter_sdk_startup"
    private const val appKeyName = "app_key"
    private const val endpointName = "endpoint"
    private const val skipUnknownContactsName = "skip_unknown_contacts"

    fun save(
        context: Context,
        appKey: String?,
        endpoint: String?,
        shouldSkipNonExistingContacts: Boolean,
    ) {
        if (appKey.isNullOrBlank() || endpoint.isNullOrBlank()) return
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putString(appKeyName, appKey)
            .putString(endpointName, endpoint)
            .putBoolean(skipUnknownContactsName, shouldSkipNonExistingContacts)
            .apply()
    }

    fun restore(application: Application) {
        val preferences = application.getSharedPreferences(
            preferencesName,
            Context.MODE_PRIVATE,
        )
        val appKey = preferences.getString(appKeyName, null)
        val endpoint = preferences.getString(endpointName, null)
        if (appKey.isNullOrBlank() || endpoint.isNullOrBlank()) return

        val config = OrttoConfig(
            appKey,
            endpoint,
            preferences.getBoolean(skipUnknownContactsName, false),
        )
        Ortto.instance().init(config, application)
        Ortto.instance().ensureChannelIsCreated()
    }
}

/** Restores the native SDK before Firebase starts a process-dead app. */
class OrttoFlutterSdkInitProvider : ContentProvider() {
    override fun onCreate(): Boolean {
        val application = context?.applicationContext as? Application
            ?: return false
        return try {
            OrttoFlutterSdkStartup.restore(application)
            true
        } catch (error: RuntimeException) {
            Log.e("OrttoFlutterSdk", "Unable to restore native SDK", error)
            true
        }
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? = null

    override fun getType(uri: Uri): String? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(
        uri: Uri,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = 0
}
