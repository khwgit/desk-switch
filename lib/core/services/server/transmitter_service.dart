import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:desk_switch/core/services/system_service.dart';
import 'package:desk_switch/core/utils/logger.dart';
import 'package:desk_switch/models/client_data.dart';
import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/message.pb.dart' as pb;
import 'package:desk_switch/models/server_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transmitter_service.freezed.dart';
part 'transmitter_service.g.dart';

enum TransmitterStateType {
  initial,
  starting,
  running,
  stopping,
}

@freezed
sealed class TransmitterState with _$TransmitterState {
  const factory TransmitterState({
    @Default(TransmitterStateType.initial) TransmitterStateType type,
    @Default([]) List<ClientData> clients,
    ServerData? server,
    ClientPackage? package,
  }) = _TransmitterState;
}

@riverpod
class TransmitterService extends _$TransmitterService {
  HttpServer? _server;
  final _clientsController = StreamController<List<ClientData>>.broadcast();

  @override
  TransmitterState build() {
    ref.onDispose(() {
      _clientsController.close();
    });

    return const TransmitterState();
  }

  Stream<List<ClientData>> clients() => _clientsController.stream;

  /// Start WebSocket server
  Future<ServerData?> start({
    required int? port,
    required String? name,
  }) async {
    if (state.type == TransmitterStateType.running) {
      logger.info('🖥️ Server already running');
      return state.server;
    }

    if (state.type == TransmitterStateType.starting ||
        state.type == TransmitterStateType.stopping) {
      logger.info('🖥️ Server already starting or stopping');
      return null;
    }

    state = state.copyWith(type: TransmitterStateType.starting);

    try {
      // Start WebSocket server
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        port ?? 0,
      );

      _server!.listen((request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          final client = await _verify(request).then(
            (client) => client.copyWith(socket: socket),
            onError: (error) async {
              request.response
                ..statusCode = HttpStatus.badRequest
                ..headers.contentType = ContentType.json
                ..write(jsonEncode({'error': error.toString()}));
              await request.response.close();
            },
          );

          socket.listen(
            (data) {
              if (data is List<int>) {
                try {
                  final package = ClientPackage(
                    id: client.id,
                    message: pb.Message.fromBuffer(data).toModel(),
                  );
                  state = state.copyWith(package: package);
                } catch (e) {
                  // Handle parse error
                  logger.error('❌ Failed to parse message: $e');
                }
              }
            },
            onDone: () {
              state = state.copyWith(
                clients: state.clients
                    .where((data) => data.id != client.id)
                    .toList(),
              );
              _clientsController.add(state.clients);
            },
            onError: (error) {
              logger.error('❌ WebSocket error from ${client.name}: $error');
              state = state.copyWith(
                clients: state.clients
                    .where((data) => data.id != client.id)
                    .toList(),
              );
              _clientsController.add(state.clients);
            },
            cancelOnError: true,
          );

          state = state.copyWith(clients: [...state.clients, client]);
          _clientsController.add(state.clients);
          logger.info(
            '🔌 Client connected: ${client.name} ([32m${state.clients.length}[0m total)',
          );
        } else {
          // Not a websocket request
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
        }
      });

      // Get machine ID from system service
      final systemService = ref.read(systemServiceProvider.notifier);
      final server = ServerData(
        id: await systemService.getMachineId(),
        name: name ?? await systemService.getMachineName(),
        port: _server!.port,
        host: _server!.address.address,
      );
      state = state.copyWith(
        type: TransmitterStateType.running,
        server: server,
      );
      logger.info(
        '🖥️ Server started: ${server.name} (${server.host}:${server.port}) (Machine ID: ${server.id})',
      );
    } catch (error) {
      logger.error('❌ Failed to start server: $error');
      state = const TransmitterState();
      _clientsController.addError(error);
      rethrow;
    }

    _clientsController.add(state.clients);
    return state.server;
  }

  /// Stop WebSocket server
  Future<void> stop() async {
    if (state.type == TransmitterStateType.initial ||
        state.type == TransmitterStateType.stopping) {
      logger.info('🖥️ Server already stopped or stopping');
      return;
    }

    state = state.copyWith(type: TransmitterStateType.stopping);

    try {
      // Stop WebSocket server
      await _server?.close(force: true);
      _server = null;

      state = const TransmitterState();
      logger.info('🛑 Server stopped');
    } catch (error) {
      logger.error('❌ Error stopping server: $error');
      state = const TransmitterState();
      rethrow;
    }
  }

  void send(ClientPackage package) async {
    final client = state.clients.firstWhereOrNull(
      (client) => client.id == package.id,
    );

    if (client == null) return;
    client.socket?.add(package.message.toProto().writeToBuffer());
  }

  /// Verify client
  Future<ClientData> _verify(HttpRequest request) async {
    final clientId = request.headers.value('Desk-Switch-Client-Id');
    if (clientId == null) {
      throw Exception('Client ID is required');
    }

    return ClientData(
      id: clientId,
      name: request.headers.value('Desk-Switch-Client-Name') ?? 'Unknown',
      host: request.connectionInfo?.remoteAddress.address ?? 'unknown',
      port: request.connectionInfo?.remotePort ?? 0,
    );
  }
}
