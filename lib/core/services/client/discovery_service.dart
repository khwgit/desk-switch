import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:desk_switch/core/utils/logger.dart';
import 'package:desk_switch/models/server_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discovery_service.freezed.dart';
part 'discovery_service.g.dart';

enum DiscoveryStateType {
  initial,
  running,
  stopping,
}

@freezed
abstract class DiscoveryState with _$DiscoveryState {
  const factory DiscoveryState({
    @Default(DiscoveryStateType.initial) DiscoveryStateType type,
    @Default({}) Map<String, ServerData> servers,
  }) = _DiscoveryState;

  const DiscoveryState._();
}

@riverpod
class DiscoveryService extends _$DiscoveryService {
  BonsoirDiscovery? _discovery;
  StreamSubscription? _discoverySubscription;

  @override
  DiscoveryState build() {
    return const DiscoveryState();
  }

  /// Start discovery
  Future<void> start() async {
    if (state.type == DiscoveryStateType.running) {
      logger.info('🔍 Discovery already running, returning');
      return;
    }

    logger.info('🚀 Starting discovery');
    state = state.copyWith(type: DiscoveryStateType.running);
    _discovery = BonsoirDiscovery(type: '_deskswitch._tcp');
    await _discovery!.ready;
    _discoverySubscription = _discovery!.eventStream?.listen((event) {
      final service = event.service;
      final id = service?.attributes['id'] ?? service?.name ?? '';
      switch (event.type) {
        case BonsoirDiscoveryEventType.discoveryServiceFound:
          if (service != null) {
            logger.info(
              '📡 Found server: ${service.name}[${service.attributes['id']}]',
            );
            // Use id if available, otherwise fallback to name
            final serverInfo = ServerData(
              id: id,
              name: service.name,
            );
            final updatedServers = Map<String, ServerData>.from(state.servers);
            updatedServers[id] = serverInfo;
            state = state.copyWith(servers: updatedServers);
            // TODO: only resolve when connected?
            service.resolve(_discovery!.serviceResolver);
          }
          break;
        case BonsoirDiscoveryEventType.discoveryServiceLost:
          if (service != null) {
            logger.info('❌ Lost server: ${service.name}');
            final updatedServers = Map<String, ServerData>.from(state.servers);
            updatedServers.remove(id);
            state = state.copyWith(servers: updatedServers);
          }
          break;
        case BonsoirDiscoveryEventType.discoveryServiceResolved:
          if (service is ResolvedBonsoirService) {
            logger.info(
              '🔍 Service resolved: ${service.name}[${service.attributes['id']}] (${service.host}:${service.port})',
            );
            // Use id if available, otherwise fallback to name
            final id = service.attributes['id'] ?? service.name;
            final updatedServer = ServerData(
              id: id,
              name: service.name,
              host: service.host,
              port: int.tryParse(service.attributes['ws_port'] ?? '0'),
            );
            final updatedServers = Map<String, ServerData>.from(state.servers);
            updatedServers[id] = updatedServer;
            state = state.copyWith(servers: updatedServers);
          }
          break;
        case BonsoirDiscoveryEventType.discoveryStarted:
          logger.info('🚀 Discovery started');
          break;
        case BonsoirDiscoveryEventType.discoveryStopped:
          logger.info('🛑 Discovery stopped');
          break;
        case BonsoirDiscoveryEventType.discoveryServiceResolveFailed:
          logger.info(
            '❌ Service resolve failed: ${service?.name ?? 'unknown'}',
          );
          break;
        case BonsoirDiscoveryEventType.unknown:
          logger.info(
            '❓ Unknown discovery event for service: ${service?.name ?? 'unknown'}',
          );
          break;
      }
    });

    await _discovery!.start();
  }

  /// Stop discovery
  Future<void> stop() async {
    if (state.type == DiscoveryStateType.stopping) {
      logger.info('🛑 Discovery already stopping, returning');
      return;
    }

    logger.info('🛑 Stopping discovery');
    state = state.copyWith(type: DiscoveryStateType.stopping);
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;
    await _discovery?.stop();
    _discovery = null;
    state = state.copyWith(
      type: DiscoveryStateType.initial,
      servers: {},
    );
  }
}
