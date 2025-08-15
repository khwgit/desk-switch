import 'dart:async';
import 'dart:io';

import 'package:desk_switch/core/utils/logger.dart';
import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/message.pb.dart' as pb;
import 'package:desk_switch/models/server_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:synchronized/synchronized.dart';

part 'receiver_service.freezed.dart';
part 'receiver_service.g.dart';

@freezed
abstract class ReceiverState with _$ReceiverState {
  const factory ReceiverState({
    ServerData? server,
    Message? message,
  }) = _ReceiverState;

  const ReceiverState._();

  bool get isConnected => server?.status == ServerStatus.connected;
}

@Riverpod(keepAlive: true)
class ReceiverService extends _$ReceiverService {
  // WebSocket connection
  WebSocket? _socket;
  StreamSubscription? _subscription;
  final _lock = Lock();

  @override
  ReceiverState build() {
    ref.onDispose(() => _subscription?.cancel());
    ref.onDispose(() => _socket?.close(WebSocketStatus.goingAway));

    return const ReceiverState();
  }

  /// Connect to a server using WebSocket
  Future<void> connect(ServerData server) async {
    await _lock.synchronized(() async {
      if (state.server?.id == server.id) return;
      if (state.server != null) await disconnect();

      state = state.copyWith(
        server: server.copyWith(
          status: ServerStatus.connecting,
        ),
      );

      try {
        final uri = Uri.parse('ws://${server.host}:${server.port}');

        logger.info(
          '🔌 Connecting to server: ${server.name} at ${uri.host}:${uri.port}',
        );

        _socket = await WebSocket.connect(uri.toString());

        // Listen to incoming messages
        _subscription = _socket!.listen(
          (data) {
            if (data is List<int>) {
              try {
                final message = pb.Message.fromBuffer(data).toModel();
                state = state.copyWith(message: message);
              } catch (e) {
                // Handle parse error
                logger.error('❌ Failed to parse input: $e');
              }
            }
          },
          onDone: () {
            logger.info('🔌 Disconnected from server: ${server.name}');
            state = const ReceiverState();
          },
          onError: (error) {
            logger.error('❌ Connection error to ${server.name}: $error');
            state = const ReceiverState();
          },
          cancelOnError: true,
        );

        state = state.copyWith(
          server: server.copyWith(
            status: ServerStatus.connected,
          ),
        );
        logger.info('✅ Successfully connected to server: ${server.name}');
      } catch (error) {
        logger.error('❌ Failed to connect to server ${server.name}: $error');
        state = state.copyWith(server: null);
        rethrow;
      }
    });
  }

  /// Disconnect from the server
  Future<void> disconnect() async {
    await _lock.synchronized(() async {
      if (state.server == null) return;
      state = state.copyWith.server!(status: ServerStatus.disconnecting);
      await _subscription?.cancel();
      _subscription = null;
      await _socket?.close(WebSocketStatus.goingAway);
      _socket = null;
      logger.info('🔌 Disconnected from server: ${state.server?.name}');
      state = const ReceiverState();
    });
  }

  /// Send a message to the server
  void send(Message message) {
    _socket?.add(message.toProto().writeToBuffer());
  }
}
