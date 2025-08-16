#include "include/kvm_helper/kvm_helper_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "kvm_helper_plugin.h"

void KvmHelperPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  kvm_helper::KvmHelperPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
