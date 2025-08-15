import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:desk_switch/core/utils/logger.dart';
import 'package:desk_switch/models/server_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:synchronized/synchronized.dart';

part 'broadcast_service.freezed.dart';
part 'broadcast_service.g.dart';

@freezed
abstract class BroadcastState with _$BroadcastState {
  const factory BroadcastState({
    BroadcastConfig? config,
  }) = _BroadcastState;

  const BroadcastState._();
}

@freezed
abstract class BroadcastConfig with _$BroadcastConfig {
  const factory BroadcastConfig({
    required int port,
    required ServerData server,
  }) = _BroadcastConfig;

  const BroadcastConfig._();
  factory BroadcastConfig.fromJson(Map<String, dynamic> json) =>
      _$BroadcastConfigFromJson(json);
}

@Riverpod(keepAlive: true)
class BroadcastService extends _$BroadcastService {
  // Bonsoir for service advertisement
  BonsoirBroadcast? _broadcast;
  final _lock = Lock();

  @override
  BroadcastState build() {
    ref.onDispose(() => _broadcast?.stop());

    return const BroadcastState();
  }

  /// Start advertisement
  Future<BroadcastConfig?> start({
    required int? port,
    required ServerData server,
  }) async {
    return _lock.synchronized(() async {
      try {
        // Bonsoir advertisement
        final service = BonsoirService(
          name: server.name,
          type: '_deskswitch._tcp',
          port: port ?? await _findAvailablePort(),
          attributes: {
            'id': server.id,
            'ws_host': server.host ?? '',
            'ws_port': server.port.toString(),
          },
        );

        _broadcast = BonsoirBroadcast(service: service);
        await _broadcast!.initialize();
        await _broadcast!.start();

        state = state.copyWith(
          config: BroadcastConfig(
            port: service.port,
            server: server,
          ),
        );
        logger.info('📡 Started broadcasting: ${service.name}:${service.port}');
      } catch (error) {
        logger.error('❌ Failed to start broadcast: $error');
        state = const BroadcastState();
        rethrow;
      }

      return state.config;
    });
  }

  /// Stop Bonsoir advertisement
  Future<void> stop() async {
    return _lock.synchronized(() async {
      try {
        await _broadcast?.stop();
        logger.info('🛑 Stopped broadcasting');
      } catch (error) {
        logger.error('❌ Error stopping broadcast: $error');
        rethrow;
      } finally {
        _broadcast = null;
        state = const BroadcastState();
      }
    });
  }

  /// Find an available port by binding to port 0
  Future<int> _findAvailablePort() async {
    final socket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }
}
