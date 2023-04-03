package com.skaiwalk.media_controller

import android.annotation.TargetApi
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Build
import android.os.RemoteException
import android.provider.Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat.getSystemService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*


/** MediaControllerPlugin */
class MediaControllerPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler,
    ActivityAware {
    companion object {
        val TAG: String? = "MediaControllerPlugin"
        const val METHOD_CHANNEL_NAME = "flutter.io/media_controller/methodChannel"
        const val EVENT_CHANNEL_NAME = "flutter.io/media_controller/eventChannel"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var mContext: Context? = null
    private lateinit var mediaSessionManager: MediaSessionManager
    private var currentMediaSession: MediaController? = null
    private var activeSessions: List<MediaController>? = null
    private lateinit var mCallback: MediaControllerCallback

    private val mMediaSessionListener =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) MediaSessionListener() else null

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.mContext = flutterPluginBinding.applicationContext
        methodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            METHOD_CHANNEL_NAME
        )
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            EVENT_CHANNEL_NAME
        )
        eventChannel.setStreamHandler(this)
//        mediaSessionManager =
//            getSystemService(mContext!!, MediaSessionManager::class.java) as MediaSessionManager
        mCallback = MediaControllerCallback()
        mMediaSessionListener?.onCreate(mContext!!)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun fetchMediaInfo(mController: MediaController): MutableMap<String, Any>? {
        if (mController == null) {
            Log.e(
                TAG,
                "Failed to update media info, null MediaController."
            )
            return null
        }
        val playbackState: PlaybackState? = mController.playbackState
        if (playbackState == null) {
            Log.e(
                TAG,
                "Failed to update media info, null PlaybackState."
            )
            return null
        }
        val mediaInfos: MutableMap<String, Any> = HashMap()
        mediaInfos["PlaybackState"] =
            playbackStateToName(playbackState.state)

        val mediaMetadata: MediaMetadata? = mController.metadata
        if (mediaMetadata != null) {

        }
        return mediaInfos
    }

    private fun playbackStateToName(playbackState: Int): String {
        return when (playbackState) {
            PlaybackState.STATE_NONE -> "STATE_NONE"
            PlaybackState.STATE_STOPPED -> "STATE_STOPPED"
            PlaybackState.STATE_PAUSED -> "STATE_PAUSED"
            PlaybackState.STATE_PLAYING -> "STATE_PLAYING"
            PlaybackState.STATE_FAST_FORWARDING -> "STATE_FAST_FORWARDING"
            PlaybackState.STATE_REWINDING -> "STATE_REWINDING"
            PlaybackState.STATE_BUFFERING -> "STATE_BUFFERING"
            PlaybackState.STATE_ERROR -> "STATE_ERROR"
            PlaybackState.STATE_CONNECTING -> "STATE_CONNECTING"
            PlaybackState.STATE_SKIPPING_TO_PREVIOUS -> "STATE_SKIPPING_TO_PREVIOUS"
            PlaybackState.STATE_SKIPPING_TO_NEXT -> "STATE_SKIPPING_TO_NEXT"
            PlaybackState.STATE_SKIPPING_TO_QUEUE_ITEM -> "STATE_SKIPPING_TO_QUEUE_ITEM"
            else -> "!Unknown State!"
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun setupMediaController(mController: MediaController) {
        try {
            mController.registerCallback(mCallback)
            // Force update on connect.
            mCallback.onPlaybackStateChanged(mController.playbackState)
            mCallback.onMetadataChanged(mController.metadata)
        } catch (remoteException: RemoteException) {
            Log.e(
                TAG,
                "Failed to create MediaController from session token",
                remoteException
            )
        }
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
//                activeSessions = mediaSessionManager.getActiveSessions(
//                    ComponentName(
//                        mContext!!,
//                        NotificationListener::class.java
//                    )
//                )
//                val sessionTokens = mutableListOf<String>()
//                if (activeSessions != null) {
//                    for (session in activeSessions as MutableList<MediaController>) {
//                        sessionTokens += session.sessionToken.toString()
//                    }
//                }
//                result.success(sessionTokens)
            }
            "setCurrentMediaSession" -> {
                val arguments = call.arguments
                val token = (arguments as Map<*, *>)["sessionToken"] as String
                var resultString: String? = null
//                if (activeSessions != null) {
//                    for (session in activeSessions!!) {
//                        if (session.sessionToken.toString() == token) {
//                            currentMediaSession = session
//                            resultString = session.sessionToken.toString()
//
//                        }
//                    }
//                }
                if (mMediaSessionListener != null) {
                    currentMediaSession = mMediaSessionListener.getMediaSessionByToken(token)
                    setupMediaController(currentMediaSession!!)
                    resultString = currentMediaSession?.sessionToken.toString()
                }
                result.success(resultString)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
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
        override fun onPlaybackStateChanged(playbackState: PlaybackState?) {
            onUpdate()
            if (playbackState != null) {
            }
        }

        override fun onMetadataChanged(metadata: MediaMetadata?) {
            onUpdate()
        }
        override fun onSessionDestroyed() {
            super.onSessionDestroyed()
            currentMediaSession = null
        }

        private fun onUpdate() {
            val mediaInfo: MutableMap<String, Any>? = fetchMediaInfo(currentMediaSession!!)
            if (mediaInfo != null) {
                mMediaSessionListener?.mEventSink?.let {
                    it.success(mediaInfo)
                }
            }
        }
    }

    private fun handleNotificationPermissions(activity: Activity) {
        if (!NotificationListener.isEnabled(mContext!!)) {
            val intent = Intent(ACTION_NOTIFICATION_LISTENER_SETTINGS)
            activity.startActivity(intent)
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        handleNotificationPermissions(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onDetachedFromActivity() {
        TODO("Not yet implemented")
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private class MediaSessionListener {
        var mEventSink: EventChannel.EventSink? = null

        var activeSessions: List<MediaController>? = null
        private val mSessionsChangedListener =
            MediaSessionManager.OnActiveSessionsChangedListener { list: List<MediaController?>? ->
                activeSessions = list as List<MediaController>?

                // send stream to flutter
                mEventSink?.let {
                    val sessionTokens = mutableListOf<String>()
                    if (activeSessions != null) {
                        for (session in activeSessions as MutableList<MediaController>) {
                            sessionTokens += session.sessionToken.toString()
                        }
                    }
                    val sessionsInfo: MutableMap<String, Any> = HashMap()
                    sessionsInfo["sessions"] = sessionTokens
                    it.success(sessionsInfo)
                }

            }
        private var mMediaSessionManager: MediaSessionManager? = null

        fun getMediaSessionByToken(token: String): MediaController? {
            if (activeSessions != null) {
                for (session in activeSessions!!) {
                    if (session.sessionToken.toString() == token) {
                        return session
                    }
                }
            }
            return null
        }

        fun onCreate(context: Context?) {
            mMediaSessionManager =
                getSystemService(context!!, MediaSessionManager::class.java) as MediaSessionManager
        }

        fun onStart(context: Context, eventSink: EventChannel.EventSink) {
            if (!NotificationListener.isEnabled(context)) {
                // To open setting
                return
            }
            if (mMediaSessionManager == null) {
                return
            }
            mEventSink = eventSink
            val listenerComponent = ComponentName(
                context,
                NotificationListener::class.java
            )
            mMediaSessionManager!!.addOnActiveSessionsChangedListener(
                mSessionsChangedListener, listenerComponent
            )
        }

        fun onStop() {
            if (mMediaSessionManager == null) {
                return
            }
            mMediaSessionManager!!.removeOnActiveSessionsChangedListener(mSessionsChangedListener)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        mMediaSessionListener?.onStart(mContext!!, events!!)

    }

    override fun onCancel(arguments: Any?) {
        mMediaSessionListener?.onStop()
    }
}
