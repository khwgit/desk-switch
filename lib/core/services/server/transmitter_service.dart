import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desk_switch/core/services/system_service.dart';
import 'package:desk_switch/core/utils/logger.dart';
import 'package:desk_switch/models/client_data.dart';
import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/message.pb.dart' as pb;
import 'package:desk_switch/models/server_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:synchronized/synchronized.dart';

part 'transmitter_service.freezed.dart';
part 'transmitter_service.g.dart';

@freezed
sealed class TransmitterState with _$TransmitterState {
  const factory TransmitterState({
    @Default({}) Map<String, ClientData> clients,
    ServerData? server,
    ClientPackage? package,
  }) = _TransmitterState;

  const TransmitterState._();
}

@riverpod
class TransmitterService extends _$TransmitterService {
  HttpServer? _server;
  final _clientsController = StreamController<List<ClientData>>.broadcast();
  final _lock = Lock();

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
    return _lock.synchronized(() async {
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
                final updatedClients = Map<String, ClientData>.from(
                  state.clients,
                );
                updatedClients.remove(client.id);
                state = state.copyWith(clients: updatedClients);
                _clientsController.add(updatedClients.values.toList());
              },
              onError: (error) {
                logger.error('❌ WebSocket error from ${client.name}: $error');
                final updatedClients = Map<String, ClientData>.from(
                  state.clients,
                );
                updatedClients.remove(client.id);
                state = state.copyWith(clients: updatedClients);
                _clientsController.add(updatedClients.values.toList());
              },
              cancelOnError: true,
            );

            final updatedClients = {...state.clients, client.id: client};
            state = state.copyWith(clients: updatedClients);
            _clientsController.add(updatedClients.values.toList());
            logger.info(
              '🔌 Client connected: ${client.name} ( [32m${state.clients.length} [0m total)',
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
        state = state.copyWith(server: server);
        logger.info(
          '🖥️ Server started: ${server.name} (${server.host}:${server.port}) (Machine ID: ${server.id})',
        );
      } catch (error) {
        logger.error('❌ Failed to start server: $error');
        state = const TransmitterState();
        _clientsController.addError(error);
        rethrow;
      }

      _clientsController.add(state.clients.values.toList());
      return state.server;
    });
  }

  /// Stop WebSocket server
  Future<void> stop() async {
    return _lock.synchronized(() async {
      try {
        // Stop WebSocket server
        await _server?.close(force: true);
        logger.info('🛑 Server stopped');
      } catch (error) {
        logger.error('❌ Error stopping server: $error');
        rethrow;
      } finally {
        _server = null;
        state = const TransmitterState();
      }
    });
  }

  void send(ClientPackage package) async {
    state.clients[package.id]?.socket?.add(
      package.message.toProto().writeToBuffer(),
    );
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
