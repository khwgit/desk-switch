import 'package:desk_switch/services/communication/receiver_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_status_bar_providers.g.dart';

/// Provider for connected server info
@riverpod
String? connectedServerName(Ref ref) {
  final receiverState = ref.watch(receiverServiceProvider);
  return receiverState.server?.name;
}
