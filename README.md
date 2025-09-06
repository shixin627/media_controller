# media_controller

[![pub package](https://img.shields.io/badge/pub-v0.0.1-blue)](https://pub.dev/packages/media_controller)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A Flutter plugin for controlling media sessions on Android devices. This plugin allows your app to discover, connect to, and control active media sessions from other applications, providing a unified interface for media playback control.

## Features

- 🎵 **Discover Active Media Sessions**: Find all currently active media sessions on the device
- 🎮 **Playback Control**: Play, pause, stop, skip tracks across different media apps
- 📱 **Real-time Updates**: Receive live updates about playback state, metadata, and position
- 📊 **Rich Metadata**: Access track title, artist, album, and artwork information
- 🔒 **Type Safety**: Comprehensive Dart models with null safety support
- 🛡️ **Error Handling**: Standardized error codes and graceful error handling
- 🏗️ **Clean Architecture**: Well-structured API with separation of concerns

## Quick Start

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  media_controller: ^0.0.1
```

Then run:

```bash
$ flutter pub get
```

### Android Setup

Add the notification listener permission to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" />
```

### Basic Usage

```dart
import 'package:media_controller/media_controller.dart';

class MyMediaController {
  final _controller = MediaControllerManager();
  
  Future<void> setupMediaControl() async {
    // Initialize the controller
    await _controller.initialize();
    
    // Listen for media updates
    _controller.mediaUpdates.listen((state) {
      print('Now playing: ${state.title}');
      print('Artist: ${state.artist}');
      print('State: ${state.playbackState}');
    });
    
    // Get active sessions and select one
    final sessions = await _controller.getActiveMediaSessions();
    if (sessions.isNotEmpty) {
      await _controller.setCurrentMediaSession(sessions.first.sessionToken);
      
      // Control playback
      await _controller.play();
      
      // Wait a bit, then pause
      await Future.delayed(Duration(seconds: 5));
      await _controller.pause();
    }
    
    // Don't forget to dispose when done
    await _controller.dispose();
  }
}
```

## API Reference

### MediaControllerManager

The main class for controlling media sessions.

#### Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `initialize()` | Initialize the controller (must be called first) | `Future<void>` |
| `dispose()` | Clean up resources and stop listening | `Future<void>` |
| `getActiveMediaSessions()` | Get list of active media sessions | `Future<List<MediaSessionInfo>>` |
| `setCurrentMediaSession(String token)` | Select a media session to control | `Future<String?>` |
| `play()` | Start or resume playback | `Future<void>` |
| `pause()` | Pause playback | `Future<void>` |
| `stop()` | Stop playback | `Future<void>` |
| `previous()` | Skip to previous track | `Future<void>` |
| `next()` | Skip to next track | `Future<void>` |

#### Properties

| Property | Description | Type |
|----------|-------------|------|
| `mediaUpdates` | Stream of media state updates | `Stream<MediaPlaybackState>` |
| `isInitialized` | Whether the controller is initialized | `bool` |

### Data Models

#### MediaSessionInfo

Represents information about a media session.

```dart
class MediaSessionInfo {
  final String sessionToken;   // Unique session identifier
  final String packageName;    // App package name
  final String state;          // Current playback state
  final String? title;         // Track title (if available)
  final String? artist;        // Artist name (if available)
  final String? album;         // Album name (if available)
  
  String get displayName;      // User-friendly app name
}
```

#### MediaPlaybackState

Represents the current playback state and metadata.

```dart
class MediaPlaybackState {
  final String playbackState;  // Current state (e.g., "STATE_PLAYING")
  final String? title;         // Track title
  final String? artist;        // Artist name
  final String? album;         // Album name
  final String? packageName;   // Controlling app
  final int? positionMs;       // Current position in milliseconds
  final int? durationMs;       // Total duration in milliseconds
  
  // Convenience getters
  String get formattedPosition;  // "mm:ss" format
  String get formattedDuration;  // "mm:ss" format
  double? get progress;          // 0.0 to 1.0 progress ratio
}
```

#### PlaybackStatus

Enum representing playback states with user-friendly display names.

```dart
enum PlaybackStatus {
  idle, stopped, paused, playing, fastForwarding,
  rewinding, buffering, error, connecting,
  skippingToPrevious, skippingToNext, skippingToQueueItem
}

// Convert from platform strings
final status = PlaybackStatusExtension.fromString("STATE_PLAYING");
print(status.displayName); // "Playing"
```

## Error Handling

The plugin uses standardized `PlatformException` codes for consistent error handling:

| Error Code | Description |
|------------|-------------|
| `not_initialized` | Controller must be initialized first |
| `already_initialized` | Controller is already initialized |
| `invalid_argument` | Invalid parameter provided |
| `unsupported_operation` | Feature not supported on this platform |
| `player_error` | Media player operation failed |
| `internal_error` | Unexpected internal error |

```dart
try {
  await controller.play();
} on PlatformException catch (e) {
  switch (e.code) {
    case 'not_initialized':
      print('Please initialize the controller first');
      break;
    case 'player_error':
      print('Playback failed: ${e.message}');
      break;
    default:
      print('Error: ${e.message}');
  }
}
```

## Example App

The included example app demonstrates all features:

- Session discovery and selection
- Real-time playback state updates
- Media control buttons
- Error handling and user feedback
- Proper resource management

Run the example:

```bash
cd example
flutter run
```

## Platform Support

| Platform | Status |
|----------|--------|
| Android | ✅ Supported (API 21+) |
| iOS | ❌ Not yet implemented |
| Web | ❌ Not applicable |
| Desktop | ❌ Not yet implemented |

## Permissions

### Android

The plugin requires notification listener access to discover media sessions. Users must manually grant this permission through Settings > Notification Access.

Your app should guide users to enable this permission:

```dart
// Check if permission is needed and guide user
final sessions = await controller.getActiveMediaSessions();
if (sessions.isEmpty) {
  // Show dialog to guide user to settings
  showPermissionDialog();
}
```

## Roadmap

- [ ] iOS implementation
- [ ] Background notification controls
- [ ] Playlist/queue management
- [ ] Position seeking support
- [ ] Volume control
- [ ] Download/caching capabilities
- [ ] Web platform exploration

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

1. Clone the repository
2. Run `flutter pub get`
3. Run the example app: `cd example && flutter run`
4. Make your changes
5. Add tests and ensure they pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes and versions.

## Support

- 📫 [Issue Tracker](https://github.com/shixin627/media_controller/issues)
- 💬 [Discussions](https://github.com/shixin627/media_controller/discussions)
- 📖 [Documentation](https://pub.dev/documentation/media_controller/latest/)

---

**Note**: This plugin is designed for controlling external media sessions (like music apps). If you need to play media files directly in your app, consider using packages like [just_audio](https://pub.dev/packages/just_audio) or [audioplayers](https://pub.dev/packages/audioplayers).

