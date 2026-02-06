# media_controller

A Flutter plugin for interacting with active media sessions on Android. Read metadata (title, artist, album, album art), control playback, and listen to real-time state changes.

> **Platform support:** Android only (API 21+).

## Setup

### 1. Register the NotificationListenerService

This plugin requires a `NotificationListenerService` to access active media sessions. You must register it yourself in **your app's** `AndroidManifest.xml` (not the plugin's), inside the `<application>` tag:

```xml
<service
    android:name="com.skaiwalk.media_controller.NotificationListener"
    android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
    android:exported="false">
    <intent-filter>
        <action android:name="android.service.notification.NotificationListenerService" />
    </intent-filter>
</service>
```

> **Why not bundled in the plugin?** Other plugins in your project may also declare a `NotificationListenerService`. Keeping it in the host app avoids duplicate registrations and gives you full control.

### 2. Grant notification access at runtime

The user must manually enable notification access in system settings. Use the built-in helpers:

```dart
final controller = MediaController();

// Check if permission is already granted
bool enabled = await controller.isNotificationListenerEnabled();

// Open the system settings page
await controller.openNotificationListenerSettings();
```

## Usage

```dart
import 'package:media_controller/media_controller.dart';

final controller = MediaController();
```

### Listen to media events

```dart
controller.mediaStream?.listen((data) {
  if (data.containsKey('sessions')) {
    // Session list updated — see "Event types" below
  } else if (data.containsKey('notifyChanged')) {
    // Active sessions changed, re-fetch the list
    controller.getActiveMediaSessions();
  } else {
    // Media info or playback state update
    // data may contain: Title, Artist, Album, AlbumArt, PlaybackState, Package
  }
});
```

### Fetch and select sessions

```dart
// Trigger a session list fetch (result arrives via mediaStream)
await controller.getActiveMediaSessions();

// Select a session by token
await controller.setCurrentMediaSession(token);
```

### Playback controls

```dart
await controller.play();
await controller.pause();
await controller.stop();
await controller.previous();
await controller.next();
```

## Event types

The `mediaStream` emits `Map<String, dynamic>` events. There are three types:

### Session list

Triggered by `getActiveMediaSessions()`.

```json
{
  "sessions": [{
    "tokens":    ["token1", "token2"],
    "packages":  ["com.spotify.music", "com.google.android.youtube"],
    "states":    ["STATE_PLAYING", "STATE_PAUSED"],
    "titles":    ["Song Name", "Video Title"],
    "albumArts": ["<base64 png>", ""]
  }]
}
```

### Notify changed

Fired when the system's active session list changes. Re-fetch sessions when you receive this.

```json
{ "notifyChanged": true }
```

### Media / playback update

Fired when the selected session's metadata or playback state changes.

```json
{
  "Title": "Song Name",
  "Artist": "Artist Name",
  "Album": "Album Name",
  "AlbumArt": "<base64 encoded PNG, max 300x300>",
  "PlaybackState": "STATE_PLAYING",
  "Package": "com.spotify.music"
}
```

Not all fields are present in every event. `PlaybackState` and media info (`Title`, `Artist`, `Album`, `AlbumArt`) may arrive separately.

### Playback states

`STATE_NONE` | `STATE_STOPPED` | `STATE_PAUSED` | `STATE_PLAYING` | `STATE_FAST_FORWARDING` | `STATE_REWINDING` | `STATE_BUFFERING` | `STATE_ERROR` | `STATE_CONNECTING` | `STATE_SKIPPING_TO_PREVIOUS` | `STATE_SKIPPING_TO_NEXT` | `STATE_SKIPPING_TO_QUEUE_ITEM`

## API reference

| Method | Returns | Description |
|---|---|---|
| `getActiveMediaSessions()` | `Future<List<String>>` | Fetch active sessions (result also sent via stream) |
| `setCurrentMediaSession(token)` | `Future<String?>` | Select a session to control and observe |
| `play()` | `Future<void>` | Resume playback |
| `pause()` | `Future<void>` | Pause playback |
| `stop()` | `Future<void>` | Stop playback |
| `previous()` | `Future<void>` | Skip to previous track |
| `next()` | `Future<void>` | Skip to next track |
| `isNotificationListenerEnabled()` | `Future<bool>` | Check if notification access is granted |
| `openNotificationListenerSettings()` | `Future<bool>` | Open system notification listener settings |
| `mediaStream` | `Stream<Map<String, dynamic>>?` | Real-time media event stream |
