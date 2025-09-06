/// Represents the current state of media playback including metadata.
class MediaPlaybackState {
  /// The current playback status.
  final String playbackState;
  
  /// The title of the currently playing media.
  final String? title;
  
  /// The artist of the currently playing media.
  final String? artist;
  
  /// The album of the currently playing media.
  final String? album;
  
  /// The package name of the app controlling playback.
  final String? packageName;
  
  /// The current position in milliseconds (if available).
  final int? positionMs;
  
  /// The total duration in milliseconds (if available).
  final int? durationMs;

  /// Creates a new [MediaPlaybackState] instance.
  const MediaPlaybackState({
    required this.playbackState,
    this.title,
    this.artist,
    this.album,
    this.packageName,
    this.positionMs,
    this.durationMs,
  });

  /// Creates a [MediaPlaybackState] from a map representation.
  factory MediaPlaybackState.fromMap(Map<String, dynamic> map) {
    return MediaPlaybackState(
      playbackState: map['PlaybackState'] as String? ?? 'STATE_NONE',
      title: map['Title'] as String?,
      artist: map['Artist'] as String?,
      album: map['Album'] as String?,
      packageName: map['Package'] as String?,
      positionMs: map['positionMs'] as int?,
      durationMs: map['durationMs'] as int?,
    );
  }

  /// Converts this [MediaPlaybackState] to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'PlaybackState': playbackState,
      if (title != null) 'Title': title,
      if (artist != null) 'Artist': artist,
      if (album != null) 'Album': album,
      if (packageName != null) 'Package': packageName,
      if (positionMs != null) 'positionMs': positionMs,
      if (durationMs != null) 'durationMs': durationMs,
    };
  }

  /// Gets the formatted position as mm:ss string.
  String get formattedPosition {
    if (positionMs == null) return '--:--';
    final seconds = positionMs! ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Gets the formatted duration as mm:ss string.
  String get formattedDuration {
    if (durationMs == null) return '--:--';
    final seconds = durationMs! ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Gets the progress ratio (0.0 to 1.0) if both position and duration are available.
  double? get progress {
    if (positionMs == null || durationMs == null || durationMs == 0) return null;
    return (positionMs! / durationMs!).clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'MediaPlaybackState(playbackState: $playbackState, title: $title, artist: $artist, album: $album, packageName: $packageName, positionMs: $positionMs, durationMs: $durationMs)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaPlaybackState &&
        other.playbackState == playbackState &&
        other.title == title &&
        other.artist == artist &&
        other.album == album &&
        other.packageName == packageName &&
        other.positionMs == positionMs &&
        other.durationMs == durationMs;
  }

  @override
  int get hashCode {
    return playbackState.hashCode ^
        (title?.hashCode ?? 0) ^
        (artist?.hashCode ?? 0) ^
        (album?.hashCode ?? 0) ^
        (packageName?.hashCode ?? 0) ^
        (positionMs?.hashCode ?? 0) ^
        (durationMs?.hashCode ?? 0);
  }
}