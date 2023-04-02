package com.skaiwalk.media_controller;
import android.annotation.TargetApi;
import android.content.Context;
import android.os.Build.VERSION_CODES;
import android.service.notification.NotificationListenerService;
import androidx.core.app.NotificationManagerCompat;

/**
 * A notification listener service to allows us to grab active media sessions from their
 * notifications.
 * This class is only used on API 21+ because the Android media framework added getActiveSessions
 * in API 21.
 */
@TargetApi(VERSION_CODES.LOLLIPOP)
public class NotificationListener extends NotificationListenerService {
    // Helper method to check if our notification listener is enabled. In order to get active media
    // sessions, we need an enabled notification listener component.
    public static boolean isEnabled(Context context) {
        return NotificationManagerCompat
                .getEnabledListenerPackages(context)
                .contains(context.getPackageName());
    }
}
