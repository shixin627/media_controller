#ifndef FLUTTER_PLUGIN_MEDIA_CONTROLLER_PLUGIN_H_
#define FLUTTER_PLUGIN_MEDIA_CONTROLLER_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <mutex>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Media.Control.h>
#include <winrt/Windows.Storage.Streams.h>

namespace media_controller {

class MediaControllerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MediaControllerPlugin();
  virtual ~MediaControllerPlugin();

  MediaControllerPlugin(const MediaControllerPlugin &) = delete;
  MediaControllerPlugin &operator=(const MediaControllerPlugin &) = delete;

  // Called by the stream handler
  void OnListen(std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> &&events);
  void OnCancel();

 private:
  using SessionManager =
      winrt::Windows::Media::Control::GlobalSystemMediaTransportControlsSessionManager;
  using Session =
      winrt::Windows::Media::Control::GlobalSystemMediaTransportControlsSession;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void Play();
  void Pause();
  void Stop();
  void Next();
  void Previous();

  void FetchAndSendSessionList();
  void FetchAndSendCurrentMedia();
  void SetCurrentSession(const std::string &token);

  std::string PlaybackStatusToString(
      winrt::Windows::Media::Control::GlobalSystemMediaTransportControlsSessionPlaybackStatus status);
  std::string ThumbnailToBase64(
      winrt::Windows::Storage::Streams::IRandomAccessStreamReference thumbnail);
  void RegisterSessionEvents();
  void UnregisterSessionEvents();

  SessionManager session_manager_{nullptr};
  Session current_session_{nullptr};
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
  std::mutex sink_mutex_;

  winrt::event_token sessions_changed_token_;
  winrt::event_token media_properties_changed_token_;
  winrt::event_token playback_info_changed_token_;
};

// Separate StreamHandler that delegates to the plugin
class MediaControllerStreamHandler
    : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  explicit MediaControllerStreamHandler(MediaControllerPlugin *plugin)
      : plugin_(plugin) {}

 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
      OnListenInternal(
          const flutter::EncodableValue *arguments,
          std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> &&events) override {
    plugin_->OnListen(std::move(events));
    return nullptr;
  }

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
      OnCancelInternal(const flutter::EncodableValue *arguments) override {
    plugin_->OnCancel();
    return nullptr;
  }

 private:
  MediaControllerPlugin *plugin_;
};

}  // namespace media_controller

#endif  // FLUTTER_PLUGIN_MEDIA_CONTROLLER_PLUGIN_H_
