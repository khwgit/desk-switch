import 'package:desk_switch/models/client_data.dart';
import 'package:desk_switch/models/profile.dart';
import 'package:desk_switch/services/communication/transmitter_service.dart';
import 'package:desk_switch/services/system_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_content_providers.g.dart';

// Provider for clients
@riverpod
Future<List<ClientData>> clients(Ref ref) async {
  return ref.watch(
    transmitterServiceProvider.select(
      (state) => state.clients.values.toList(),
    ),
  );
}

@riverpod
Future<ServerProfile> serverProfile(Ref ref) async {
  final systemService = ref.watch(systemServiceProvider.notifier);
  final machineName = await systemService.getMachineName();
  return ServerProfile(
    name: machineName,
    connectionPort: 8088,
  );
}

// Provider for port configuration state
@riverpod
class PortConfiguration extends _$PortConfiguration {
  @override
  ({bool isAuto, int? manualPort, int? currentPort}) build() {
    return (isAuto: true, manualPort: 8080, currentPort: null);
  }

  void setAutoMode(bool isAuto) {
    state = (
      isAuto: isAuto,
      manualPort: state.manualPort,
      currentPort: state.currentPort,
    );
  }

  void setManualPort(int port) {
    state = (
      isAuto: state.isAuto,
      manualPort: port,
      currentPort: state.currentPort,
    );
  }

  void setCurrentPort(int? port) {
    state = (
      isAuto: state.isAuto,
      manualPort: state.manualPort,
      currentPort: port,
    );
  }
}

// Provider for monitor configuration
@riverpod
class MonitorConfiguration extends _$MonitorConfiguration {
  @override
  List<({String name, String resolution, bool enabled})> build() {
    return [
      (name: 'Primary Display', resolution: '1920x1080', enabled: true),
      (name: 'Secondary Display', resolution: '2560x1440', enabled: true),
      (name: 'External Monitor', resolution: '1366x768', enabled: false),
    ];
  }

  void toggleMonitor(int index) {
    // final monitors = List.from(state);
    // monitors[index] = (
    //   name: monitors[index].name,
    //   resolution: monitors[index].resolution,
    //   enabled: !monitors[index].enabled,
    // );
    // state = monitors;
  }

  void refreshMonitors() {
    // TODO: Implement actual monitor detection
    // For now, just keep the current state
  }
}
