import 'package:kvm_helper/kvm_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'injection_service.g.dart';

@riverpod
class InjectionService extends _$InjectionService {
  final KvmHelper _kvm = KvmHelper.instance;

  @override
  void build() {}

  Future<void> injectInput(Input input) async {
    await _kvm.injectInput(input);
  }
}
