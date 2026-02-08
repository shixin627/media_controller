import Cocoa
import FlutterMacOS

// MARK: - MediaRemote typedefs (used only for playback commands)
private typealias MRMediaRemoteSendCommandFunction = @convention(c) (UInt32, NSDictionary?) -> Bool

// MRMediaRemoteCommand values
private let kMRMediaRemoteCommandPlay: UInt32 = 0
private let kMRMediaRemoteCommandPause: UInt32 = 1
private let kMRMediaRemoteCommandTogglePlayPause: UInt32 = 2
private let kMRMediaRemoteCommandStop: UInt32 = 3
private let kMRMediaRemoteCommandNextTrack: UInt32 = 4
private let kMRMediaRemoteCommandPreviousTrack: UInt32 = 5

// Known media app distributed notification names
private let kMusicPlayerInfoNotification = "com.apple.Music.playerInfo"
private let kSpotifyPlayerStateNotification = "com.spotify.client.PlaybackStateChanged"

// Known media app bundle IDs
private let kMusicBundleId = "com.apple.Music"
private let kSpotifyBundleId = "com.spotify.client"

public class MediaControllerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private static let methodChannelName = "flutter.io/media_controller/methodChannel"
    private static let eventChannelName = "flutter.io/media_controller/eventChannel"
    private static let maxArtSize: CGFloat = 300

    private var eventSink: FlutterEventSink?
    private var currentBundleId: String = ""
    private var isPlaying: Bool = false
    private var lastTitle: String = ""
    private var lastArtist: String = ""
    private var lastAlbum: String = ""

    // MediaRemote function pointer (only for commands)
    private var mrSendCommand: MRMediaRemoteSendCommandFunction?
    private var mediaRemoteHandle: UnsafeMutableRawPointer?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MediaControllerPlugin()

        let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger)
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: registrar.messenger)
        eventChannel.setStreamHandler(instance)

        instance.loadMediaRemote()
    }

    // MARK: - MediaRemote Loading (commands only)

    private func loadMediaRemote() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) else {
            NSLog("MediaControllerPlugin: dlopen failed: \(String(cString: dlerror()))")
            return
        }
        mediaRemoteHandle = handle

        if let sym = dlsym(handle, "MRMediaRemoteSendCommand") {
            mrSendCommand = unsafeBitCast(sym, to: MRMediaRemoteSendCommandFunction.self)
        }
    }

    deinit {
        if let handle = mediaRemoteHandle {
            dlclose(handle)
        }
    }

    // MARK: - FlutterPlugin

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "play":
            sendCommand(kMRMediaRemoteCommandPlay)
            result(nil)
        case "pause":
            sendCommand(kMRMediaRemoteCommandPause)
            result(nil)
        case "stop":
            sendCommand(kMRMediaRemoteCommandStop)
            result(nil)
        case "next":
            sendCommand(kMRMediaRemoteCommandNextTrack)
            result(nil)
        case "previous":
            sendCommand(kMRMediaRemoteCommandPreviousTrack)
            result(nil)
        case "isNotificationListenerEnabled":
            result(true)
        case "openNotificationListenerSettings":
            result(false)
        case "getActiveMediaSessions":
            sendSessionListFromRunningApps()
            result(nil)
        case "setCurrentMediaSession":
            if let args = call.arguments as? [String: Any?],
               let token = args["sessionToken"] as? String {
                currentBundleId = token
                sendCurrentMediaInfo()
                result(token)
            } else {
                result(nil)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        startObserving()
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stopObserving()
        self.eventSink = nil
        return nil
    }

    // MARK: - Notification Observing

    private func startObserving() {
        // Listen for distributed notifications from known media apps.
        // This is reliable on all macOS versions including macOS 16+.
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleMediaAppNotification(_:)),
            name: NSNotification.Name(kMusicPlayerInfoNotification),
            object: nil
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleMediaAppNotification(_:)),
            name: NSNotification.Name(kSpotifyPlayerStateNotification),
            object: nil
        )

        // Initial session list based on running apps
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.sendSessionListFromRunningApps()
        }
    }

    private func stopObserving() {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    // MARK: - Distributed Notification Handler

    @objc private func handleMediaAppNotification(_ notification: Notification) {
        guard let sink = eventSink else { return }
        let userInfo = notification.userInfo ?? [:]

        // Determine which app sent the notification
        let bundleId: String
        switch notification.name.rawValue {
        case kMusicPlayerInfoNotification:
            bundleId = kMusicBundleId
        case kSpotifyPlayerStateNotification:
            bundleId = kSpotifyBundleId
        default:
            bundleId = "unknown"
        }
        currentBundleId = bundleId

        // Extract media info from the notification userInfo
        var data: [String: Any] = [:]

        if let name = userInfo["Name"] as? String {
            data["Title"] = name
            lastTitle = name
        }
        if let artist = userInfo["Artist"] as? String {
            data["Artist"] = artist
            lastArtist = artist
        }
        if let album = userInfo["Album"] as? String {
            data["Album"] = album
            lastAlbum = album
        }

        // Map player state
        if let state = userInfo["Player State"] as? String {
            switch state {
            case "Playing":
                data["PlaybackState"] = "STATE_PLAYING"
                isPlaying = true
            case "Paused":
                data["PlaybackState"] = "STATE_PAUSED"
                isPlaying = false
            case "Stopped":
                data["PlaybackState"] = "STATE_PAUSED"
                isPlaying = false
            default:
                data["PlaybackState"] = "STATE_PAUSED"
                isPlaying = false
            }
        }

        data["Package"] = bundleId

        if !data.isEmpty {
            sink(data)
        }

        // Also send an updated session list
        sendSessionListFromRunningApps()
    }

    // MARK: - Media Remote Commands

    private func sendCommand(_ command: UInt32) {
        _ = mrSendCommand?(command, nil)
    }

    // MARK: - Session List from Running Apps

    private func sendSessionListFromRunningApps() {
        guard let sink = eventSink else { return }

        // Check which known media apps are currently running
        let runningApps = NSWorkspace.shared.runningApplications
        let knownMediaApps: [(bundleId: String, name: String)] = [
            (kMusicBundleId, "Music"),
            (kSpotifyBundleId, "Spotify"),
        ]

        var tokens: [String] = []
        var packages: [String] = []
        var states: [String] = []
        var titles: [String] = []
        var albumArts: [String] = []

        for app in knownMediaApps {
            if runningApps.contains(where: { $0.bundleIdentifier == app.bundleId }) {
                tokens.append(app.bundleId)
                packages.append(app.bundleId)
                states.append(
                    (currentBundleId == app.bundleId && isPlaying)
                        ? "STATE_PLAYING" : "STATE_PAUSED"
                )
                titles.append(
                    currentBundleId == app.bundleId && !lastTitle.isEmpty
                        ? lastTitle : app.name
                )
                albumArts.append("")
            }
        }

        // If no known media apps running, show a generic entry
        if tokens.isEmpty {
            tokens.append("now_playing")
            packages.append("")
            states.append("STATE_PAUSED")
            titles.append("No media app detected")
            albumArts.append("")
        }

        let inner: [String: Any] = [
            "tokens": tokens,
            "packages": packages,
            "states": states,
            "titles": titles,
            "albumArts": albumArts,
        ]
        let payload: [String: Any] = ["sessions": [inner]]
        sink(payload)
    }

    // MARK: - Send Current Media Info

    private func sendCurrentMediaInfo() {
        guard let sink = eventSink else { return }

        var data: [String: Any] = [:]
        if !lastTitle.isEmpty { data["Title"] = lastTitle }
        if !lastArtist.isEmpty { data["Artist"] = lastArtist }
        if !lastAlbum.isEmpty { data["Album"] = lastAlbum }
        data["PlaybackState"] = isPlaying ? "STATE_PLAYING" : "STATE_PAUSED"
        data["Package"] = currentBundleId

        if !data.isEmpty {
            sink(data)
        }
    }

    // MARK: - Image Helpers

    private func imageToBase64(_ image: NSImage) -> String {
        let maxSize = MediaControllerPlugin.maxArtSize
        var targetImage = image
        if image.size.width > maxSize || image.size.height > maxSize {
            let ratio = min(maxSize / image.size.width, maxSize / image.size.height)
            let newSize = NSSize(width: image.size.width * ratio, height: image.size.height * ratio)
            let resized = NSImage(size: newSize)
            resized.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: newSize),
                       from: NSRect(origin: .zero, size: image.size),
                       operation: .copy,
                       fraction: 1.0)
            resized.unlockFocus()
            targetImage = resized
        }

        guard let tiffData = targetImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return ""
        }
        return pngData.base64EncodedString()
    }
}
