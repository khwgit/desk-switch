import 'dart:ui';

import 'package:desk_switch/models/input.dart';
import 'package:kvm_helper/kvm_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'injection_service.g.dart';

@Riverpod(keepAlive: true)
class InjectionService extends _$InjectionService {
  final KvmHelper _kvm = KvmHelper.instance;

  @override
  void build() {
    ref.onDispose(() => _kvm.unblockInputs());
  }

  Future<void> switchToLocal(Offset position) async {
    // await injection.unblockInputs({InputType.mouse});
    await injectInput(
      Input.mouse(
        x: position.dx,
        y: position.dy,
        type: MouseInputType.mouseMoved,
        flag: InputFlag.sync.index,
      ),
    );
  }

  Future<void> switchToRemote(Offset position) async {
    // await injection.blockInputs({InputType.mouse});
    await injectInput(
      Input.mouse(
        x: position.dx,
        y: position.dy,
        type: MouseInputType.mouseMoved,
        flag: InputFlag.recenter.index,
      ),
    );
  }

  Future<void> injectInput(Input input) async {
    await _kvm.injectInput(input);
  }

  Future<void> blockInputs([Set<InputType>? types]) async {
    await _kvm.blockInputs(types);
  }

  Future<void> unblockInputs([Set<InputType>? types]) async {
    await _kvm.unblockInputs(types);
  }
}
