cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "media_controller")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "media_controller_plugin")

list(APPEND PLUGIN_SOURCES
  "media_controller_plugin.cpp"
  "media_controller_plugin.h"
  "media_controller_plugin_c_api.cpp"
  "include/media_controller/media_controller_plugin_c_api.h"
)

add_library(${PLUGIN_NAME} SHARED
  "include/media_controller/media_controller_plugin_c_api.h"
  "media_controller_plugin_c_api.cpp"
  "media_controller_plugin.cpp"
  "media_controller_plugin.h"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  CXX_STANDARD 20
  CXX_STANDARD_REQUIRED YES
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin RuntimeObject)

set(media_controller_bundled_libraries
  ""
  PARENT_SCOPE
)
