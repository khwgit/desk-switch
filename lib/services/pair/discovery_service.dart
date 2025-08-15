import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:desk_switch/core/utils/logger.dart';
import 'package:desk_switch/models/server_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:synchronized/synchronized.dart';

part 'discovery_service.freezed.dart';
part 'discovery_service.g.dart';

@freezed
abstract class DiscoveryState with _$DiscoveryState {
  const factory DiscoveryState({
    @Default({}) Map<String, ServerData> servers,
  }) = _DiscoveryState;

  const DiscoveryState._();
}

@Riverpod(keepAlive: true)
class DiscoveryService extends _$DiscoveryService {
  BonsoirDiscovery? _discovery;
  StreamSubscription? _discoverySubscription;
  final _lock = Lock();

  @override
  DiscoveryState build() {
    ref.onDispose(() => _discoverySubscription?.cancel());
    ref.onDispose(() => _discovery?.stop());

    return const DiscoveryState();
  }

  /// Start discovery
  Future<void> start() async {
    await _lock.synchronized(() async {
      if (_discovery?.isReady ?? false) return;
      logger.info('🚀 Starting discovery');
      _discovery = BonsoirDiscovery(type: '_deskswitch._tcp');
      await _discovery!.initialize();
      _discoverySubscription = _discovery!.eventStream?.listen((event) {
        switch (event) {
          case BonsoirDiscoveryServiceFoundEvent(:final service):
            logger.info(
              '📡 Found server: ${service.name}[${service.attributes['id']}]',
            );
            final id = service.id;
            final server = ServerData(id: id, name: service.name);
            state = state.copyWith(servers: {...state.servers, id: server});
            // TODO: only resolve when connected?
            service.resolve(_discovery!.serviceResolver);
            break;
          case BonsoirDiscoveryServiceLostEvent(:final service):
            logger.info('❌ Lost server: ${service.name}');
            state = state.copyWith(
              servers: {...state.servers}..remove(service.id),
            );
            break;
          case BonsoirDiscoveryServiceResolvedEvent(:final service):
            logger.info(
              '🔍 Service resolved: ${service.name}[${service.id}] (${service.host}:${service.port})',
            );
            final server = ServerData(
              id: service.id,
              name: service.name,
              host: service.host,
              port: int.tryParse(service.attributes['ws_port'] ?? '0'),
            );
            state = state.copyWith(
              servers: {...state.servers, server.id: server},
            );
            break;
          case BonsoirDiscoveryServiceUpdatedEvent(:final service):
            logger.info('🔍 Service updated: ${service.name}');
            break;
          case BonsoirDiscoveryStartedEvent():
            logger.info('🚀 Discovery started');
            break;
          case BonsoirDiscoveryStoppedEvent():
            logger.info('🛑 Discovery stopped');
            break;
          case BonsoirDiscoveryServiceResolveFailedEvent():
            logger.info('❌ Service resolve failed');
            break;
          case BonsoirDiscoveryUnknownEvent():
            logger.info('❓ Unknown discovery event');
            break;
        }
      });

      await _discovery!.start();
    });
  }

  /// Stop discovery
  Future<void> stop() async {
    await _lock.synchronized(() async {
      if (_discovery?.isStopped ?? false) return;
      await _discoverySubscription?.cancel();
      _discoverySubscription = null;
      await _discovery?.stop();
      _discovery = null;
      logger.info('🛑 Discovery stopped');
      state = const DiscoveryState();
    });
  }
}

extension on BonsoirService {
  String get id => attributes['id'] ?? name;
}
