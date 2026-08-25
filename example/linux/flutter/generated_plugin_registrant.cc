//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <digimaze_pdf_reader_launcher/digimaze_pdf_reader_launcher_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) digimaze_pdf_reader_launcher_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DigimazePdfReaderLauncherPlugin");
  digimaze_pdf_reader_launcher_plugin_register_with_registrar(digimaze_pdf_reader_launcher_registrar);
}
