#include "include/media_controller/media_controller_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "media_controller_plugin.h"

void MediaControllerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  media_controller::MediaControllerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
