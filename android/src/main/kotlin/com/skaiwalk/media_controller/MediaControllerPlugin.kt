package com.skaiwalk.media_controller

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.session.MediaController
import android.media.session.MediaSession
import android.media.session.MediaSessionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.view.KeyEvent
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat.getSystemService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


/** MediaControllerPlugin */
class MediaControllerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var mContext: Context? = null
    private lateinit var mediaSessionManager: MediaSessionManager
    private var currentMediaSession: MediaController? = null
    private var activeSessions: List<MediaController>? = null


    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.mContext = flutterPluginBinding.applicationContext;
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "media_controller")
        channel.setMethodCallHandler(this)
        mediaSessionManager =
            getSystemService(mContext!!, MediaSessionManager::class.java) as MediaSessionManager
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "play" -> {
                play()
                result.success(null)
            }
            "pause" -> {
                pause()
                result.success(null)
            }
            "stop" -> {
                stop()
                result.success(null)
            }
            "getActiveMediaSessions" -> {
                activeSessions = mediaSessionManager.getActiveSessions(
                    ComponentName(
                        mContext!!,
                        NotificationListener::class.java
                    )
                )
                val sessionTokens = mutableListOf<String>()
                if (activeSessions != null) {
                    for (session in activeSessions as MutableList<MediaController>) {
                        sessionTokens += session.sessionToken.toString()
                    }
                }
                result.success(sessionTokens)
            }
            "setCurrentMediaSession" -> {
                val arguments = call.arguments
                if (activeSessions != null) {
                    val token = (arguments as Map<*, *>)["sessionToken"] as String
                    for (session in activeSessions!!) {
                        if (session.sessionToken.toString() == token) {
                            currentMediaSession = session
                            result.success(session.sessionToken.toString())
                        }
                    }
                } else {
                    result.success(null)
                }
//                val sessionTokenString = call.argument<String>("sessionToken")
//                var sessionToken: MediaSession? = null
//                if (sessionTokenString != null && sessionTokenString.isNotEmpty()) {
//                    sessionToken = MediaSession(mContext!!, sessionTokenString)
//                }
//                currentMediaSession = sessionToken?.sessionToken?.let {
//                    MediaController(mContext!!, it).apply {
//                        this.registerCallback(MediaControllerCallback())
//                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
//                            this.transportControls.prepare()
//                        }
//                        this.transportControls.play()
//                        result.success(sessionTokenString)
//                    }
//                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun play() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            currentMediaSession?.transportControls?.play()
        }
    }

    private fun pause() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            currentMediaSession?.transportControls?.pause()
        }
    }

    private fun stop() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            currentMediaSession?.transportControls?.stop()
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private inner class MediaControllerCallback : MediaController.Callback() {
        override fun onSessionDestroyed() {
            super.onSessionDestroyed()
            currentMediaSession = null
        }
    }

}
