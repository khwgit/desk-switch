import 'package:desk_switch/models/profile.dart';
import 'package:desk_switch/services/switch/switch_client.dart';
import 'package:desk_switch/services/switch/switch_event.dart';
import 'package:desk_switch/services/switch/switch_server.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:desk_switch/services/switch/switch_client.dart';
export 'package:desk_switch/services/switch/switch_event.dart';
export 'package:desk_switch/services/switch/switch_server.dart';
export 'package:desk_switch/services/switch/switch_state.dart';

part 'switch_service.g.dart';

@riverpod
class SwitchService extends _$SwitchService {
  @override
  List<SwitchEvent> build(Profile profile) {
    return switch (profile) {
      ServerProfile() => ref.watch(
        switchServerProvider(profile).select(
          (state) => state.events,
        ),
      ),
      ClientProfile() => ref.watch(
        switchClientProvider(profile).select(
          (state) => state.events,
        ),
      ),
    };
  }
}
