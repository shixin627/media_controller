# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **New MediaControllerManager class** - Improved API with better error handling and lifecycle management
- **Typed model classes** - MediaSessionInfo, MediaPlaybackState, and PlaybackStatus for type safety
- **Comprehensive API documentation** - All public methods and classes now have detailed documentation
- **Standardized error handling** - PlatformException codes for consistent error reporting
- **PlaybackStatus enum** - Type-safe representation of playback states instead of raw strings
- **Enhanced example app** - Complete rewrite with modern UI, error handling, and better UX
- **Extensive README documentation** - Detailed usage examples, API reference, and troubleshooting
- **Comprehensive test suite** - Unit tests for all major functionality and data models
- **Better Android error handling** - Structured error responses with proper error codes
- **Proper resource management** - Improved cleanup and lifecycle handling
- **NotificationListener service** - Required service for media session discovery

### Changed
- **Improved pubspec.yaml metadata** - Added proper description, homepage, repository, and topics
- **Enhanced README** - Replaced basic template with comprehensive documentation
- **Refactored Dart API** - Better separation of concerns and cleaner architecture
- **Updated analysis options** - Stricter linting rules for better code quality
- **Android implementation improvements** - Better error handling, logging, and resource cleanup

### Deprecated
- **Legacy MediaController class** - Use MediaControllerManager instead for new development

### Fixed
- **Android manifest** - Added missing NotificationListener service declaration
- **Method channel constants** - Centralized channel names for consistency
- **Memory leak prevention** - Proper callback cleanup and resource disposal

## [0.0.1] - 2024-01-XX

### Added
- Initial release with basic media session control functionality
- Support for Android media session management
- Basic playback controls (play, pause, stop, previous, next)
- Media session discovery and selection
- Event stream for media state updates
