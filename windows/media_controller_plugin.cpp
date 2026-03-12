#include "media_controller_plugin.h"

#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <string>
#include <vector>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Media.Control.h>
#include <winrt/Windows.Storage.Streams.h>

namespace media_controller {

using namespace winrt::Windows::Media::Control;
using namespace winrt::Windows::Storage::Streams;
using namespace winrt::Windows::Foundation;
using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::EncodableList;

// Base64 encoding
static const char kBase64Chars[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static std::string Base64Encode(const std::vector<uint8_t> &data) {
  std::string result;
  int i = 0;
  uint8_t bytes3[3];
  uint8_t bytes4[4];
  size_t len = data.size();
  const uint8_t *ptr = data.data();

  while (len--) {
    bytes3[i++] = *(ptr++);
    if (i == 3) {
      bytes4[0] = (bytes3[0] & 0xfc) >> 2;
      bytes4[1] = ((bytes3[0] & 0x03) << 4) + ((bytes3[1] & 0xf0) >> 4);
      bytes4[2] = ((bytes3[1] & 0x0f) << 2) + ((bytes3[2] & 0xc0) >> 6);
      bytes4[3] = bytes3[2] & 0x3f;
      for (i = 0; i < 4; i++) result += kBase64Chars[bytes4[i]];
      i = 0;
    }
  }
  if (i) {
    for (int j = i; j < 3; j++) bytes3[j] = 0;
    bytes4[0] = (bytes3[0] & 0xfc) >> 2;
    bytes4[1] = ((bytes3[0] & 0x03) << 4) + ((bytes3[1] & 0xf0) >> 4);
    bytes4[2] = ((bytes3[1] & 0x0f) << 2) + ((bytes3[2] & 0xc0) >> 6);
    bytes4[3] = bytes3[2] & 0x3f;
    for (int j = 0; j < i + 1; j++) result += kBase64Chars[bytes4[j]];
    while (i++ < 3) result += '=';
  }
  return result;
}

static std::string WStringToString(const std::wstring &wstr) {
  if (wstr.empty()) return "";
  int size = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), (int)wstr.size(),
                                  nullptr, 0, nullptr, nullptr);
  std::string result(size, 0);
  WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), (int)wstr.size(),
                      &result[0], size, nullptr, nullptr);
  return result;
}

// static
void MediaControllerPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<MediaControllerPlugin>();
  auto *plugin_ptr = plugin.get();

  auto method_channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), "flutter.io/media_controller/methodChannel",
      &flutter::StandardMethodCodec::GetInstance());

  method_channel->SetMethodCallHandler(
      [plugin_ptr](const auto &call, auto result) {
        plugin_ptr->HandleMethodCall(call, std::move(result));
      });

  auto event_channel = std::make_unique<flutter::EventChannel<EncodableValue>>(
      registrar->messenger(), "flutter.io/media_controller/eventChannel",
      &flutter::StandardMethodCodec::GetInstance());

  auto stream_handler =
      std::make_unique<MediaControllerStreamHandler>(plugin_ptr);
  event_channel->SetStreamHandler(std::move(stream_handler));

  registrar->AddPlugin(std::move(plugin));
}

MediaControllerPlugin::MediaControllerPlugin() {
  // Flutter already initializes COM as MTA. Use multi_threaded to match.
  try {
    winrt::init_apartment(winrt::apartment_type::multi_threaded);
  } catch (...) {
    // Already initialized, no-op.
  }
  try {
    session_manager_ = SessionManager::RequestAsync().get();
  } catch (...) {
    // WinRT not available or too old Windows version
  }
}

MediaControllerPlugin::~MediaControllerPlugin() {
  UnregisterSessionEvents();
}

void MediaControllerPlugin::OnListen(
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> &&events) {
  std::lock_guard<std::mutex> lock(sink_mutex_);
  event_sink_ = std::move(events);

  if (session_manager_) {
    sessions_changed_token_ = session_manager_.SessionsChanged(
        [this](SessionManager const &, auto const &) {
          try {
            winrt::init_apartment(winrt::apartment_type::multi_threaded);
          } catch (...) {}
          FetchAndSendSessionList();
        });
  }
}

void MediaControllerPlugin::OnCancel() {
  std::lock_guard<std::mutex> lock(sink_mutex_);
  UnregisterSessionEvents();
  if (session_manager_) {
    try {
      session_manager_.SessionsChanged(sessions_changed_token_);
    } catch (...) {}
  }
  event_sink_ = nullptr;
}

void MediaControllerPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto &method = method_call.method_name();

  if (method == "play") {
    Play();
    result->Success();
  } else if (method == "pause") {
    Pause();
    result->Success();
  } else if (method == "stop") {
    Stop();
    result->Success();
  } else if (method == "next") {
    Next();
    result->Success();
  } else if (method == "previous") {
    Previous();
    result->Success();
  } else if (method == "isNotificationListenerEnabled") {
    result->Success(EncodableValue(true));
  } else if (method == "openNotificationListenerSettings") {
    result->Success(EncodableValue(false));
  } else if (method == "getActiveMediaSessions") {
    FetchAndSendSessionList();
    result->Success();
  } else if (method == "setCurrentMediaSession") {
    const auto *args = std::get_if<EncodableMap>(method_call.arguments());
    if (args) {
      auto it = args->find(EncodableValue("sessionToken"));
      if (it != args->end() && !it->second.IsNull()) {
        auto token = std::get<std::string>(it->second);
        SetCurrentSession(token);
        result->Success(EncodableValue(token));
      } else {
        UnregisterSessionEvents();
        current_session_ = nullptr;
        result->Success();
      }
    } else {
      result->Success();
    }
  } else {
    result->NotImplemented();
  }
}

void MediaControllerPlugin::Play() {
  if (current_session_) {
    try { current_session_.TryPlayAsync().get(); } catch (...) {}
  }
}

void MediaControllerPlugin::Pause() {
  if (current_session_) {
    try { current_session_.TryPauseAsync().get(); } catch (...) {}
  }
}

void MediaControllerPlugin::Stop() {
  if (current_session_) {
    try { current_session_.TryStopAsync().get(); } catch (...) {}
  }
}

void MediaControllerPlugin::Next() {
  if (current_session_) {
    try { current_session_.TrySkipNextAsync().get(); } catch (...) {}
  }
}

void MediaControllerPlugin::Previous() {
  if (current_session_) {
    try { current_session_.TrySkipPreviousAsync().get(); } catch (...) {}
  }
}

void MediaControllerPlugin::FetchAndSendSessionList() {
  std::lock_guard<std::mutex> lock(sink_mutex_);
  if (!event_sink_ || !session_manager_) return;

  try {
    auto sessions = session_manager_.GetSessions();

    EncodableList tokens;
    EncodableList packages;
    EncodableList states;
    EncodableList titles;
    EncodableList albumArts;

    for (const auto &session : sessions) {
      auto appId = WStringToString(std::wstring(session.SourceAppUserModelId()));
      tokens.push_back(EncodableValue(appId));
      packages.push_back(EncodableValue(appId));

      try {
        auto playbackInfo = session.GetPlaybackInfo();
        states.push_back(EncodableValue(
            PlaybackStatusToString(playbackInfo.PlaybackStatus())));
      } catch (...) {
        states.push_back(EncodableValue("STATE_NONE"));
      }

      try {
        auto props = session.TryGetMediaPropertiesAsync().get();
        auto title = WStringToString(std::wstring(props.Title()));
        titles.push_back(EncodableValue(title.empty() ? "Unknown Title" : title));

        auto thumbnail = props.Thumbnail();
        if (thumbnail) {
          albumArts.push_back(EncodableValue(ThumbnailToBase64(thumbnail)));
        } else {
          albumArts.push_back(EncodableValue(""));
        }
      } catch (...) {
        titles.push_back(EncodableValue("Unknown Title"));
        albumArts.push_back(EncodableValue(""));
      }
    }

    EncodableMap inner;
    inner[EncodableValue("tokens")] = EncodableValue(tokens);
    inner[EncodableValue("packages")] = EncodableValue(packages);
    inner[EncodableValue("states")] = EncodableValue(states);
    inner[EncodableValue("titles")] = EncodableValue(titles);
    inner[EncodableValue("albumArts")] = EncodableValue(albumArts);

    EncodableList sessionsList;
    sessionsList.push_back(EncodableValue(inner));

    EncodableMap payload;
    payload[EncodableValue("sessions")] = EncodableValue(sessionsList);

    event_sink_->Success(EncodableValue(payload));
  } catch (...) {}
}

void MediaControllerPlugin::FetchAndSendCurrentMedia() {
  std::lock_guard<std::mutex> lock(sink_mutex_);
  if (!event_sink_ || !current_session_) return;

  try {
    EncodableMap data;

    auto props = current_session_.TryGetMediaPropertiesAsync().get();
    auto title = WStringToString(std::wstring(props.Title()));
    if (!title.empty()) data[EncodableValue("Title")] = EncodableValue(title);

    auto artist = WStringToString(std::wstring(props.Artist()));
    if (!artist.empty()) data[EncodableValue("Artist")] = EncodableValue(artist);

    auto album = WStringToString(std::wstring(props.AlbumTitle()));
    if (!album.empty()) data[EncodableValue("Album")] = EncodableValue(album);

    auto thumbnail = props.Thumbnail();
    if (thumbnail) {
      data[EncodableValue("AlbumArt")] =
          EncodableValue(ThumbnailToBase64(thumbnail));
    }

    auto playbackInfo = current_session_.GetPlaybackInfo();
    data[EncodableValue("PlaybackState")] =
        EncodableValue(PlaybackStatusToString(playbackInfo.PlaybackStatus()));

    auto appId = WStringToString(
        std::wstring(current_session_.SourceAppUserModelId()));
    data[EncodableValue("Package")] = EncodableValue(appId);

    event_sink_->Success(EncodableValue(data));
  } catch (...) {}
}

void MediaControllerPlugin::SetCurrentSession(const std::string &token) {
  UnregisterSessionEvents();

  if (!session_manager_) return;

  try {
    auto sessions = session_manager_.GetSessions();
    for (const auto &session : sessions) {
      auto appId = WStringToString(std::wstring(session.SourceAppUserModelId()));
      if (appId == token) {
        current_session_ = session;
        RegisterSessionEvents();
        FetchAndSendCurrentMedia();
        return;
      }
    }
  } catch (...) {}

  current_session_ = nullptr;
}

void MediaControllerPlugin::RegisterSessionEvents() {
  if (!current_session_) return;

  try {
    media_properties_changed_token_ = current_session_.MediaPropertiesChanged(
        [this](Session const &, auto const &) {
          try {
            winrt::init_apartment(winrt::apartment_type::multi_threaded);
          } catch (...) {}
          FetchAndSendCurrentMedia();
        });
    playback_info_changed_token_ = current_session_.PlaybackInfoChanged(
        [this](Session const &, auto const &) {
          try {
            winrt::init_apartment(winrt::apartment_type::multi_threaded);
          } catch (...) {}
          FetchAndSendCurrentMedia();
        });
  } catch (...) {}
}

void MediaControllerPlugin::UnregisterSessionEvents() {
  if (!current_session_) return;

  try {
    current_session_.MediaPropertiesChanged(media_properties_changed_token_);
    current_session_.PlaybackInfoChanged(playback_info_changed_token_);
  } catch (...) {}
}

std::string MediaControllerPlugin::PlaybackStatusToString(
    GlobalSystemMediaTransportControlsSessionPlaybackStatus status) {
  switch (status) {
    case GlobalSystemMediaTransportControlsSessionPlaybackStatus::Playing:
      return "STATE_PLAYING";
    case GlobalSystemMediaTransportControlsSessionPlaybackStatus::Paused:
      return "STATE_PAUSED";
    case GlobalSystemMediaTransportControlsSessionPlaybackStatus::Stopped:
      return "STATE_STOPPED";
    case GlobalSystemMediaTransportControlsSessionPlaybackStatus::Closed:
      return "STATE_NONE";
    case GlobalSystemMediaTransportControlsSessionPlaybackStatus::Opened:
      return "STATE_BUFFERING";
    case GlobalSystemMediaTransportControlsSessionPlaybackStatus::Changing:
      return "STATE_CONNECTING";
    default:
      return "STATE_NONE";
  }
}

std::string MediaControllerPlugin::ThumbnailToBase64(
    IRandomAccessStreamReference thumbnail) {
  try {
    auto stream = thumbnail.OpenReadAsync().get();
    auto size = static_cast<uint32_t>(stream.Size());
    if (size == 0) return "";

    auto buffer = winrt::Windows::Storage::Streams::Buffer(size);
    stream.ReadAsync(buffer, size, InputStreamOptions::None).get();

    auto reader = DataReader::FromBuffer(buffer);
    std::vector<uint8_t> data(size);
    reader.ReadBytes(data);

    return Base64Encode(data);
  } catch (...) {
    return "";
  }
}

}  // namespace media_controller
