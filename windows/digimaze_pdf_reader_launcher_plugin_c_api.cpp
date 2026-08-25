#include "include/digimaze_pdf_reader_launcher/digimaze_pdf_reader_launcher_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "digimaze_pdf_reader_launcher_plugin.h"

void DigimazePdfReaderLauncherPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  digimaze_pdf_reader_launcher::DigimazePdfReaderLauncherPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
