#ifndef FLUTTER_PLUGIN_DIGIMAZE_PDF_READER_LAUNCHER_PLUGIN_H_
#define FLUTTER_PLUGIN_DIGIMAZE_PDF_READER_LAUNCHER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace digimaze_pdf_reader_launcher {

class DigimazePdfReaderLauncherPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  DigimazePdfReaderLauncherPlugin();

  virtual ~DigimazePdfReaderLauncherPlugin();

  // Disallow copy and assign.
  DigimazePdfReaderLauncherPlugin(const DigimazePdfReaderLauncherPlugin&) = delete;
  DigimazePdfReaderLauncherPlugin& operator=(const DigimazePdfReaderLauncherPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace digimaze_pdf_reader_launcher

#endif  // FLUTTER_PLUGIN_DIGIMAZE_PDF_READER_LAUNCHER_PLUGIN_H_
