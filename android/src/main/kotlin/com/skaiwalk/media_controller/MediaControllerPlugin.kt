package com.skaiwalk.media_controller

import android.annotation.TargetApi
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Build
import android.os.RemoteException
import android.provider.Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS
import android.text.TextUtils
import android.util.Base64
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
import java.io.ByteArrayOutputStream
import java.util.*
import kotlin.toString


/** MediaControllerPlugin */
class MediaControllerPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler,
    ActivityAware {
    companion object {
        val TAG: String? = "MediaControllerPlugin"
        const val METHOD_CHANNEL_NAME = "flutter.io/media_controller/methodChannel"
        const val EVENT_CHANNEL_NAME = "flutter.io/media_controller/eventChannel"
        
        private const val MAX_ART_SIZE = 300

        fun bitmapToBase64(bitmap: Bitmap): String {
            val scaled = if (bitmap.width > MAX_ART_SIZE || bitmap.height > MAX_ART_SIZE) {
                val ratio = minOf(MAX_ART_SIZE.toFloat() / bitmap.width, MAX_ART_SIZE.toFloat() / bitmap.height)
                Bitmap.createScaledBitmap(bitmap, (bitmap.width * ratio).toInt(), (bitmap.height * ratio).toInt(), true)
            } else {
                bitmap
            }
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.PNG, 100, stream)
            val bytes = stream.toByteArray()
            return Base64.encodeToString(bytes, Base64.NO_WRAP)
        }

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
    private var mActivity: Activity? = null
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

            val albumArt = mediaMetadata.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
                ?: mediaMetadata.getBitmap(MediaMetadata.METADATA_KEY_ART)
            if (albumArt != null) {
                mediaInfos["AlbumArt"] = bitmapToBase64(albumArt)
            }
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
            "isNotificationListenerEnabled" -> {
                result.success(NotificationListener.isEnabled(mContext!!))
            }
            "openNotificationListenerSettings" -> {
                if (mActivity != null) {
                    val intent = Intent(ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    mActivity!!.startActivity(intent)
                    result.success(true)
                } else {
                    result.success(false)
                }
            }
            "getActiveMediaSessions" -> {
                activeSessions = mMediaSessionListener?.getActiveSessions(mContext!!)
                mMediaSessionListener?.activeSessions = activeSessions
                mMediaSessionListener?.sendSessionsInfoToFlutter(activeSessions)
                result.success(null)
            }
            "setCurrentMediaSession" -> {
                val arguments = call.arguments
                val token = (arguments as Map<*, *>)["sessionToken"]
                if (token == null) {
                    currentMediaSession?.unregisterCallback(mCallback)
                    currentMediaSession = null
                    result.success(null)
                } else {
                    var resultString: String? = null
                    mMediaSessionListener?.let {
                        currentMediaSession?.unregisterCallback(mCallback)
                        currentMediaSession = it.getMediaSessionByToken(token as String)
                        if (currentMediaSession != null) {
                            setupMediaController(currentMediaSession!!)
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
    private fun previous() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            currentMediaSession?.transportControls?.skipToPrevious()
        }
    }

    private fun next() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            currentMediaSession?.transportControls?.skipToNext()
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
        mActivity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        mActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        mActivity = binding.activity
    }

    override fun onDetachedFromActivity() {
        mActivity = null
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private class MediaSessionListener {
        var mEventSink: EventChannel.EventSink? = null
        var activeSessions: List<MediaController>? = null

        fun sendSessionsInfoToFlutter(sessions: List<MediaController>?, notifyChanged: Boolean = false) {
            val sink = mEventSink ?: return

            // Lightweight event: only notify flag.
            if (notifyChanged) {
                val payload: MutableMap<String, Any> = HashMap()
                payload["notifyChanged"] = true
                sink.success(payload)
                return
            }

            val sessionTokens = mutableListOf<String>()
            val sessionPackages = mutableListOf<String>()
            val sessionStates = mutableListOf<String>()
            val sessionTitles = mutableListOf<String>()
            val sessionAlbumArts = mutableListOf<String>()

            sessions?.forEach { session ->
                sessionTokens += session.sessionToken.toString()
                sessionPackages += session.packageName.toString()
                sessionTitles += session.metadata?.getString(MediaMetadata.METADATA_KEY_TITLE)
                    ?: "Unknown Title"
                val playbackState = session.playbackState
                sessionStates += if (playbackState != null) {
                    MediaControllerPlugin.playbackStateToName(playbackState.state)
                } else {
                    "STATE_NONE"
                }
                val albumArt = session.metadata?.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
                    ?: session.metadata?.getBitmap(MediaMetadata.METADATA_KEY_ART)
                sessionAlbumArts += if (albumArt != null) {
                    MediaControllerPlugin.bitmapToBase64(albumArt)
                } else {
                    ""
                }
            }

            // 2-layer structure: sessions -> List<Map<...>>
            val inner: MutableMap<String, Any> = HashMap()
            inner["tokens"] = sessionTokens
            inner["packages"] = sessionPackages
            inner["states"] = sessionStates
            inner["titles"] = sessionTitles
            inner["albumArts"] = sessionAlbumArts

            val payload: MutableMap<String, Any> = HashMap()
            payload["sessions"] = listOf(inner)

            sink.success(payload)
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
