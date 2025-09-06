/// Represents metadata information about a media session.
class MediaSessionInfo {
  /// The unique token identifying this media session.
  final String sessionToken;
  
  /// The package name of the app that owns this session.
  final String packageName;
  
  /// The current playback state of this session.
  final String state;
  
  /// The title of the currently playing media (if available).
  final String? title;
  
  /// The artist of the currently playing media (if available).
  final String? artist;
  
  /// The album of the currently playing media (if available).
  final String? album;

  /// Creates a new [MediaSessionInfo] instance.
  const MediaSessionInfo({
    required this.sessionToken,
    required this.packageName,
    required this.state,
    this.title,
    this.artist,
    this.album,
  });

  /// Creates a [MediaSessionInfo] from a map representation.
  factory MediaSessionInfo.fromMap(Map<String, dynamic> map) {
    return MediaSessionInfo(
      sessionToken: map['sessionToken'] as String,
      packageName: map['packageName'] as String,
      state: map['state'] as String,
      title: map['title'] as String?,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
    );
  }

  /// Converts this [MediaSessionInfo] to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'sessionToken': sessionToken,
      'packageName': packageName,
      'state': state,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
    };
  }

  /// Gets a user-friendly display name for this session.
  /// 
  /// Returns the app package name with just the last part of the package identifier.
  String get displayName {
    final parts = packageName.split('.');
    return parts.isNotEmpty ? parts.last : packageName;
  }

  @override
  String toString() {
    return 'MediaSessionInfo(sessionToken: $sessionToken, packageName: $packageName, state: $state, title: $title, artist: $artist, album: $album)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaSessionInfo &&
        other.sessionToken == sessionToken &&
        other.packageName == packageName &&
        other.state == state &&
        other.title == title &&
        other.artist == artist &&
        other.album == album;
  }

  @override
  int get hashCode {
    return sessionToken.hashCode ^
        packageName.hashCode ^
        state.hashCode ^
        (title?.hashCode ?? 0) ^
        (artist?.hashCode ?? 0) ^
        (album?.hashCode ?? 0);
  }
}