import 'dart:async';

import 'package:desk_switch/models/profile.dart';
import 'package:desk_switch/services/switch/switch_client.dart';
import 'package:desk_switch/services/switch/switch_server.dart';
import 'package:desk_switch/services/switch/switch_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'switch_service.g.dart';

@riverpod
class SwitchService extends _$SwitchService {
  @override
  Stream<SwitchState> build(Profile profile) {
    final controller = StreamController<SwitchState>();
    ref.onDispose(controller.close);

    switch (profile) {
      case ServerProfile():
        final server = ref.watch(switchServerProvider(profile).notifier);
        ref.listen(
          switchServerUpdaterProvider(profile),
          (prev, next) => server
              .run(prev, next)
              .then((value) => controller.add(next))
              .catchError((error, stack) => controller.addError(error, stack)),
        );
      case ClientProfile():
        final client = ref.watch(switchClientProvider(profile).notifier);
        ref.listen(
          switchClientUpdaterProvider(profile),
          (prev, next) => client
              .run(prev, next)
              .then((value) => controller.add(next))
              .catchError((error, stack) => controller.addError(error, stack)),
        );
    }

    return controller.stream;
  }
}
