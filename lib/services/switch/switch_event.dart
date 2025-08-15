import 'package:desk_switch/models/input.dart';
import 'package:desk_switch/models/workspace.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'switch_event.freezed.dart';

@freezed
sealed class SwitchEvent with _$SwitchEvent {
  /// Input to be injected
  const factory SwitchEvent.inject(Input input) = InjectSwitchEvent;

  /// Block the input to be injected
  const factory SwitchEvent.block() = BlockSwitchEvent;

  /// Unblock the input to be injected
  const factory SwitchEvent.unblock() = UnblockSwitchEvent;

  /// Message to be sent to the device
  const factory SwitchEvent.send(WorkspaceMessage message) = SendSwitchEvent;

  const SwitchEvent._();
}
