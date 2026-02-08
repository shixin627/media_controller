import Flutter
import UIKit

// MARK: - MediaRemote typedefs
// The callback parameters MUST be @convention(block) because the C functions
// expect Objective-C blocks, not C function pointers.
private typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping @convention(block) (NSDictionary) -> Void) -> Void
private typealias MRMediaRemoteSendCommandFunction = @convention(c) (UInt32, NSDictionary?) -> Bool
private typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
private typealias MRMediaRemoteUnregisterForNowPlayingNotificationsFunction = @convention(c) () -> Void
private typealias MRMediaRemoteGetNowPlayingApplicationPIDFunction = @convention(c) (DispatchQueue, @escaping @convention(block) (Int32) -> Void) -> Void
private typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction = @convention(c) (DispatchQueue, @escaping @convention(block) (Bool) -> Void) -> Void

// MRMediaRemoteCommand values
private let kMRMediaRemoteCommandPlay: UInt32 = 0
private let kMRMediaRemoteCommandPause: UInt32 = 1
private let kMRMediaRemoteCommandTogglePlayPause: UInt32 = 2
private let kMRMediaRemoteCommandStop: UInt32 = 3
private let kMRMediaRemoteCommandNextTrack: UInt32 = 4
private let kMRMediaRemoteCommandPreviousTrack: UInt32 = 5

// NowPlayingInfo keys
private let kMRMediaRemoteNowPlayingInfoTitle = "kMRMediaRemoteNowPlayingInfoTitle"
private let kMRMediaRemoteNowPlayingInfoArtist = "kMRMediaRemoteNowPlayingInfoArtist"
private let kMRMediaRemoteNowPlayingInfoAlbum = "kMRMediaRemoteNowPlayingInfoAlbum"
private let kMRMediaRemoteNowPlayingInfoArtworkData = "kMRMediaRemoteNowPlayingInfoArtworkData"
private let kMRMediaRemoteNowPlayingInfoPlaybackRate = "kMRMediaRemoteNowPlayingInfoPlaybackRate"

// Notification names
private let kMRMediaRemoteNowPlayingInfoDidChangeNotification = "kMRMediaRemoteNowPlayingInfoDidChangeNotification"
private let kMRMediaRemoteNowPlayingApplicationDidChangeNotification = "kMRMediaRemoteNowPlayingApplicationDidChangeNotification"
private let kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification = "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"

public class MediaControllerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private static let methodChannelName = "flutter.io/media_controller/methodChannel"
    private static let eventChannelName = "flutter.io/media_controller/eventChannel"
    private static let maxArtSize: CGFloat = 300

    private var eventSink: FlutterEventSink?
    private var currentBundleId: String = ""
    private var isPlaying: Bool = false

    // MediaRemote function pointers
    private var mrGetNowPlayingInfo: MRMediaRemoteGetNowPlayingInfoFunction?
    private var mrSendCommand: MRMediaRemoteSendCommandFunction?
    private var mrRegisterForNotifications: MRMediaRemoteRegisterForNowPlayingNotificationsFunction?
    private var mrUnregisterForNotifications: MRMediaRemoteUnregisterForNowPlayingNotificationsFunction?
    private var mrGetNowPlayingPID: MRMediaRemoteGetNowPlayingApplicationPIDFunction?
    private var mrGetIsPlaying: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction?

    private var mediaRemoteHandle: UnsafeMutableRawPointer?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MediaControllerPlugin()

        let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)

        instance.loadMediaRemote()
    }

    // MARK: - MediaRemote Loading

    private func loadMediaRemote() {
        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
        guard let handle = dlopen(path, RTLD_NOW) else {
            NSLog("MediaControllerPlugin: Failed to dlopen MediaRemote.framework")
            return
        }
        mediaRemoteHandle = handle

        if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            mrGetNowPlayingInfo = unsafeBitCast(sym, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
        }
        if let sym = dlsym(handle, "MRMediaRemoteSendCommand") {
            mrSendCommand = unsafeBitCast(sym, to: MRMediaRemoteSendCommandFunction.self)
        }
        if let sym = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") {
            mrRegisterForNotifications = unsafeBitCast(sym, to: MRMediaRemoteRegisterForNowPlayingNotificationsFunction.self)
        }
        if let sym = dlsym(handle, "MRMediaRemoteUnregisterForNowPlayingNotifications") {
            mrUnregisterForNotifications = unsafeBitCast(sym, to: MRMediaRemoteUnregisterForNowPlayingNotificationsFunction.self)
        }
        if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationPID") {
            mrGetNowPlayingPID = unsafeBitCast(sym, to: MRMediaRemoteGetNowPlayingApplicationPIDFunction.self)
        }
        if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") {
            mrGetIsPlaying = unsafeBitCast(sym, to: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction.self)
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
            fetchAndSendSessionList()
            result(nil)
        case "setCurrentMediaSession":
            fetchAndSendCurrentMedia()
            if let args = call.arguments as? [String: Any?],
               let token = args["sessionToken"] as? String {
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
        // 1) Set up NotificationCenter observers FIRST so we don't miss
        //    the initial notification fired by the registration call.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingInfoDidChange),
            name: NSNotification.Name(kMRMediaRemoteNowPlayingInfoDidChangeNotification),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingAppDidChange),
            name: NSNotification.Name(kMRMediaRemoteNowPlayingApplicationDidChangeNotification),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(isPlayingDidChange),
            name: NSNotification.Name(kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification),
            object: nil
        )

        // 2) Register with the MediaRemote daemon.
        mrRegisterForNotifications?(DispatchQueue.main)

        // 3) The daemon connection is async — do an initial fetch after
        //    a short delay so the first getActiveMediaSessions() isn't empty.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.fetchAndSendSessionList()
        }
    }

    private func stopObserving() {
        mrUnregisterForNotifications?()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func nowPlayingInfoDidChange(_ notification: Notification) {
        fetchAndSendCurrentMedia()
    }

    @objc private func nowPlayingAppDidChange(_ notification: Notification) {
        fetchAndSendSessionList()
    }

    @objc private func isPlayingDidChange(_ notification: Notification) {
        fetchAndSendPlaybackState()
    }

    // MARK: - Media Remote Commands

    private func sendCommand(_ command: UInt32) {
        _ = mrSendCommand?(command, nil)
    }

    // MARK: - Data Fetching

    private func fetchAndSendSessionList() {
        guard let sink = eventSink, let getNowPlaying = mrGetNowPlayingInfo else { return }

        // On iOS we cannot resolve PID to bundle ID (no NSRunningApplication),
        // so we use the PID itself as a token identifier.
        let resolveBundleId: (@escaping (String) -> Void) -> Void = { [weak self] completion in
            guard let self = self, let getPID = self.mrGetNowPlayingPID else {
                completion("now_playing")
                return
            }
            getPID(DispatchQueue.main) { pid in
                completion(pid > 0 ? "pid_\(pid)" : "now_playing")
            }
        }

        resolveBundleId { [weak self] bundleId in
            guard let self = self else { return }
            self.currentBundleId = bundleId

            getNowPlaying(DispatchQueue.main) { infoRef in
                let info = infoRef as NSDictionary
                let title = info[kMRMediaRemoteNowPlayingInfoTitle] as? String ?? "Unknown Title"
                let playbackRate = info[kMRMediaRemoteNowPlayingInfoPlaybackRate] as? Double ?? 0.0
                let state = playbackRate > 0 ? "STATE_PLAYING" : "STATE_PAUSED"

                var albumArtBase64 = ""
                if let artworkData = info[kMRMediaRemoteNowPlayingInfoArtworkData] as? Data,
                   let image = UIImage(data: artworkData) {
                    albumArtBase64 = self.imageToBase64(image)
                }

                let token = bundleId

                let inner: [String: Any] = [
                    "tokens": [token],
                    "packages": [bundleId],
                    "states": [state],
                    "titles": [title],
                    "albumArts": [albumArtBase64]
                ]
                let payload: [String: Any] = ["sessions": [inner]]
                sink(payload)
            }
        }
    }

    private func fetchAndSendCurrentMedia() {
        guard let sink = eventSink, let getNowPlaying = mrGetNowPlayingInfo else { return }

        getNowPlaying(DispatchQueue.main) { [weak self] infoRef in
            guard let self = self else { return }
            let info = infoRef as NSDictionary
            var data: [String: Any] = [:]

            if let title = info[kMRMediaRemoteNowPlayingInfoTitle] as? String {
                data["Title"] = title
            }
            if let artist = info[kMRMediaRemoteNowPlayingInfoArtist] as? String {
                data["Artist"] = artist
            }
            if let album = info[kMRMediaRemoteNowPlayingInfoAlbum] as? String {
                data["Album"] = album
            }
            if let artworkData = info[kMRMediaRemoteNowPlayingInfoArtworkData] as? Data,
               let image = UIImage(data: artworkData) {
                data["AlbumArt"] = self.imageToBase64(image)
            }

            let playbackRate = info[kMRMediaRemoteNowPlayingInfoPlaybackRate] as? Double ?? 0.0
            data["PlaybackState"] = playbackRate > 0 ? "STATE_PLAYING" : "STATE_PAUSED"
            data["Package"] = self.currentBundleId

            if !data.isEmpty {
                sink(data)
            }
        }
    }

    private func fetchAndSendPlaybackState() {
        guard let sink = eventSink, let getNowPlaying = mrGetNowPlayingInfo else { return }

        let getPlayingState: (@escaping (Bool) -> Void) -> Void = { [weak self] completion in
            guard let self = self, let getIsPlaying = self.mrGetIsPlaying else {
                completion(false)
                return
            }
            getIsPlaying(DispatchQueue.main) { playing in
                completion(playing)
            }
        }

        getPlayingState { [weak self] playing in
            guard let self = self else { return }
            self.isPlaying = playing

            getNowPlaying(DispatchQueue.main) { infoRef in
                let info = infoRef as NSDictionary
                var data: [String: Any] = [:]

                data["PlaybackState"] = playing ? "STATE_PLAYING" : "STATE_PAUSED"
                if let title = info[kMRMediaRemoteNowPlayingInfoTitle] as? String {
                    data["Title"] = title
                }
                data["Package"] = self.currentBundleId

                sink(data)
            }
        }
    }

    // MARK: - Image Helpers

    private func imageToBase64(_ image: UIImage) -> String {
        let maxSize = MediaControllerPlugin.maxArtSize
        var targetImage = image
        if image.size.width > maxSize || image.size.height > maxSize {
            let ratio = min(maxSize / image.size.width, maxSize / image.size.height)
            let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let resized = UIGraphicsGetImageFromCurrentImageContext() {
                targetImage = resized
            }
            UIGraphicsEndImageContext()
        }

        guard let pngData = targetImage.pngData() else { return "" }
        return pngData.base64EncodedString()
    }
}
