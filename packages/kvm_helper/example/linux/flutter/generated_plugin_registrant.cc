//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <kvm_helper/kvm_helper_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) kvm_helper_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "KvmHelperPlugin");
  kvm_helper_plugin_register_with_registrar(kvm_helper_registrar);
}
