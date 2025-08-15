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

  Future<void> inject(Input input) async {
    await _kvm.injectInput(input);
  }

  Future<void> block([Set<InputType>? types]) async {
    await _kvm.blockInputs(types);
  }

  Future<void> unblock([Set<InputType>? types]) async {
    await _kvm.unblockInputs(types);
  }
}
