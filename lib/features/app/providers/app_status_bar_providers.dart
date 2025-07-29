import 'package:desk_switch/core/services/client/receiver_service.dart';
import 'package:desk_switch/features/shared/providers/client_providers.dart';
import 'package:desk_switch/features/shared/providers/server_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_status_bar_providers.g.dart';

/// Provider for client service state
@riverpod
ClientState clientServiceState(Ref ref) {
  return ref.watch(clientProvider);
}

/// Provider for server service state
@riverpod
ServerState serverServiceState(Ref ref) {
  return ref.watch(serverProvider);
}

/// Provider for connected server info
@riverpod
String? connectedServerName(Ref ref) {
  final receiverState = ref.watch(receiverServiceProvider);
  return receiverState.server?.name;
}

/// Provider for app mode (client/server)
@riverpod
AppMode appMode(Ref ref) {
  final clientState = ref.watch(clientProvider);
  final serverState = ref.watch(serverProvider);

  // Determine mode based on service states
  if (serverState == ServerState.running) {
    return AppMode.server;
  } else if (clientState == ClientState.connected ||
      clientState == ClientState.connecting) {
    return AppMode.client;
  }

  // Default to client mode if no services are active
  return AppMode.client;
}

/// Provider for overall app status
@riverpod
AppStatus appStatus(Ref ref) {
  final clientState = ref.watch(clientProvider);
  final serverState = ref.watch(serverProvider);
  final connectedServer = ref.watch(connectedServerNameProvider);

  return AppStatus(
    mode: ref.watch(appModeProvider),
    clientState: clientState,
    serverState: serverState,
    connectedServerName: connectedServer,
  );
}

/// App status model
class AppStatus {
  const AppStatus({
    required this.mode,
    required this.clientState,
    required this.serverState,
    this.connectedServerName,
  });

  final AppMode mode;
  final ClientState clientState;
  final ServerState serverState;
  final String? connectedServerName;

  bool get isClientMode => mode == AppMode.client;
  bool get isServerMode => mode == AppMode.server;
  bool get isConnected => clientState == ClientState.connected;
  bool get isConnecting => clientState == ClientState.connecting;
  bool get isServerRunning => serverState == ServerState.running;
  bool get isServerStarting => serverState == ServerState.starting;
}

/// App mode enum
enum AppMode {
  client,
  server,
}
