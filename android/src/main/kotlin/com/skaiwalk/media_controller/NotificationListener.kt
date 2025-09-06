package com.skaiwalk.media_controller

import android.content.Context
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.text.TextUtils

/**
 * NotificationListenerService for accessing media sessions.
 * This service is required to discover active media sessions on the device.
 */
class NotificationListener : NotificationListenerService() {

    companion object {
        /**
         * Checks if the notification listener service is enabled for this app.
         * @param context The application context
         * @return true if the service is enabled, false otherwise
         */
        fun isEnabled(context: Context): Boolean {
            val packageName = context.packageName
            val flat = Settings.Secure.getString(
                context.contentResolver,
                "enabled_notification_listeners"
            )
            if (!TextUtils.isEmpty(flat)) {
                val names = flat.split(":").toTypedArray()
                for (name in names) {
                    val componentName = android.content.ComponentName.unflattenFromString(name)
                    if (componentName != null) {
                        if (TextUtils.equals(packageName, componentName.packageName)) {
                            return true
                        }
                    }
                }
            }
            return false
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        // We don't need to handle notifications directly, 
        // we just need this service to access MediaSessionManager
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // We don't need to handle notification removal
    }
}