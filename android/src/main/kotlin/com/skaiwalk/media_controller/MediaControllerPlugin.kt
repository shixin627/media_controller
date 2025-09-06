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
import android.text.TextUtils
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
        private const val DEBUG = true  // Set to false for release builds
        
        fun playbackStateToName(playbackState: Int): String {
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
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var mContext: Context? = null
    private var currentMediaSession: MediaController? = null
    private var activeSessions: List<MediaController>? = null

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
        mMediaSessionListener?.onCreate(mContext!!)
    }

    private fun addMediaInfo(mediaInfos: MutableMap<String, Any>, key: String, value: String?) {
        if (value != null && !TextUtils.isEmpty(value)) {
            mediaInfos[key] = value
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun fetchPlayState(mController: MediaController): MutableMap<String, Any>? {
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
        val data: MutableMap<String, Any> = HashMap()
        data["PlaybackState"] =
            playbackStateToName(playbackState.state)
        val metadata = mController.metadata
        if (metadata != null) {
            val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE)
            if (title != null) {
                data["Title"] = title
            }
        }
        data["Package"] = mController.packageName
        return data
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
        val mediaInfos: MutableMap<String, Any> = HashMap()
        val mediaMetadata: MediaMetadata? = mController.metadata
        if (mediaMetadata != null) {
            addMediaInfo(
                mediaInfos,
                "Title",
                mediaMetadata.getString(MediaMetadata.METADATA_KEY_TITLE)
            )
            addMediaInfo(
                mediaInfos,
                "Artist",
                mediaMetadata.getString(MediaMetadata.METADATA_KEY_ARTIST)
            )
            addMediaInfo(
                mediaInfos,
                "Album",
                mediaMetadata.getString(MediaMetadata.METADATA_KEY_ALBUM)
            )

        }
        return mediaInfos
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
        try {
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
                "previous" -> {
                    previous()
                    result.success(null)
                }
                "next" -> {
                    next()
                    result.success(null)
                }
                "getActiveMediaSessions" -> {
                    try {
                        activeSessions = mMediaSessionListener?.getActiveSessions(mContext!!)
                        mMediaSessionListener?.activeSessions = activeSessions
                        mMediaSessionListener?.sendSessionsInfoToFlutter(activeSessions)
                        result.success(null)
                    } catch (e: SecurityException) {
                        result.error("permission_denied", "Notification listener access not granted", null)
                    } catch (e: Exception) {
                        result.error("internal_error", "Failed to get active sessions: ${e.message}", null)
                    }
                }
                "setCurrentMediaSession" -> {
                    try {
                        val arguments = call.arguments
                        if (arguments !is Map<*, *>) {
                            result.error("invalid_argument", "Arguments must be a map", null)
                            return
                        }
                        
                        val token = arguments["sessionToken"]
                        if (token == null) {
                            currentMediaSession?.unregisterCallback(mCallback)
                            currentMediaSession = null
                            result.success(null)
                        } else {
                            if (token !is String || token.isEmpty()) {
                                result.error("invalid_argument", "Session token must be a non-empty string", null)
                                return
                            }
                            
                            var resultString: String? = null
                            mMediaSessionListener?.let {
                                currentMediaSession?.unregisterCallback(mCallback)
                                currentMediaSession = it.getMediaSessionByToken(token)
                                if (currentMediaSession != null) {
                                    setupMediaController(currentMediaSession!!)
                                } else {
                                    result.error("invalid_argument", "Invalid session token", null)
                                    return
                                }
                                resultString = currentMediaSession?.sessionToken.toString()
                                currentMediaSession?.let { session ->
                                    val playState: MutableMap<String, Any>? = fetchPlayState(session)
                                    if (playState != null) {
                                        it.mEventSink?.success(playState)
                                    }
                                }
                            }
                            result.success(resultString)
                        }
                    } catch (e: Exception) {
                        result.error("internal_error", "Failed to set media session: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: IllegalStateException) {
            result.error("player_error", e.message, null)
        } catch (e: SecurityException) {
            result.error("permission_denied", e.message, null)
        } catch (e: Exception) {
            result.error("internal_error", "Unexpected error: ${e.message}", null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        try {
            // Clean up media session callback
            currentMediaSession?.unregisterCallback(mCallback)
            currentMediaSession = null
            
            // Stop listening for session changes
            mMediaSessionListener?.onStop()
            
            // Clean up channels
            methodChannel.setMethodCallHandler(null)
            eventChannel.setStreamHandler(null)
            
            if (DEBUG) {
                Log.d(TAG, "MediaControllerPlugin detached and cleaned up")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error during cleanup", e)
        }
    }

    private fun play() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                if (currentMediaSession == null) {
                    throw IllegalStateException("No media session selected")
                }
                currentMediaSession?.transportControls?.play()
                if (DEBUG) {
                    Log.d(TAG, "Play command sent")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sending play command", e)
            throw e
        }
    }

    private fun pause() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                if (currentMediaSession == null) {
                    throw IllegalStateException("No media session selected")
                }
                currentMediaSession?.transportControls?.pause()
                if (DEBUG) {
                    Log.d(TAG, "Pause command sent")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sending pause command", e)
            throw e
        }
    }

    private fun stop() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                if (currentMediaSession == null) {
                    throw IllegalStateException("No media session selected")
                }
                currentMediaSession?.transportControls?.stop()
                if (DEBUG) {
                    Log.d(TAG, "Stop command sent")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sending stop command", e)
            throw e
        }
    }
    
    private fun previous() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                if (currentMediaSession == null) {
                    throw IllegalStateException("No media session selected")
                }
                currentMediaSession?.transportControls?.skipToPrevious()
                if (DEBUG) {
                    Log.d(TAG, "Previous command sent")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sending previous command", e)
            throw e
        }
    }

    private fun next() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                if (currentMediaSession == null) {
                    throw IllegalStateException("No media session selected")
                }
                currentMediaSession?.transportControls?.skipToNext()
                if (DEBUG) {
                    Log.d(TAG, "Next command sent")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sending next command", e)
            throw e
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    val mCallback: MediaController.Callback = object : MediaController.Callback() {
        override fun onPlaybackStateChanged(playbackState: PlaybackState?) {
            if (playbackState != null) {
                onUpdatePlayState()
            }
        }

        override fun onMetadataChanged(metadata: MediaMetadata?) {
            onUpdateMediaInfo()
        }

        override fun onSessionDestroyed() {
            super.onSessionDestroyed()
            currentMediaSession = null
            Log.d(
                TAG,
                "MediaSession has been released",
            )
        }

        private fun onUpdatePlayState() {
            val playState: MutableMap<String, Any>? = fetchPlayState(currentMediaSession!!)
            if (playState != null) {
                mMediaSessionListener?.mEventSink?.let {
                    it.success(playState)
                }
            }
        }

        private fun onUpdateMediaInfo() {
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
//        handleNotificationPermissions(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    }

    override fun onDetachedFromActivity() {
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private class MediaSessionListener {
        var mEventSink: EventChannel.EventSink? = null
        var activeSessions: List<MediaController>? = null

        fun sendSessionsInfoToFlutter(sessions: List<MediaController>?, notifyChanged: Boolean = false) {
            mEventSink?.let {
                val sessionTokens = mutableListOf<String>()
                val sessionPackages = mutableListOf<String>()
                val sessionStates = mutableListOf<String>()
                if (sessions != null) {
                    for (session in sessions) {
                        sessionTokens += session.sessionToken.toString()
                        sessionPackages += session.packageName.toString()
                        val playbackState = session.playbackState
                        sessionStates += if (playbackState != null) {
                            MediaControllerPlugin.playbackStateToName(playbackState.state)
                        } else {
                            "STATE_NONE"
                        }
                    }
                }
                val sessionsInfo: MutableMap<String, Any> = HashMap()

                if (notifyChanged) {
                    sessionsInfo["notifyChanged"] = true
                } else {
                    sessionsInfo["sessions"] = sessionTokens
                    sessionsInfo["packages"] = sessionPackages
                    sessionsInfo["states"] = sessionStates
                }
                it.success(sessionsInfo)
            }
        }
        private val mSessionsChangedListener =
            MediaSessionManager.OnActiveSessionsChangedListener { list: List<MediaController?>? ->
                activeSessions = list as List<MediaController>?
                sendSessionsInfoToFlutter(activeSessions, true)
            }
        private var mMediaSessionManager: MediaSessionManager? = null

        fun getActiveSessions(context: Context): List<MediaController>? {
            return mMediaSessionManager!!.getActiveSessions(
                ComponentName(
                    context,
                    NotificationListener::class.java
                )
            )
        }

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
//        Log.d(
//            TAG,
//            "MediaSession onListen",
//        )
        mMediaSessionListener?.onStart(mContext!!, events!!)

    }

    override fun onCancel(arguments: Any?) {
//        Log.d(
//            TAG,
//            "MediaSession onCancel",
//        )
        mMediaSessionListener?.onStop()
    }
}
