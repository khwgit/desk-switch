import 'package:kvm_helper/kvm_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_service.g.dart';

@riverpod
class PermissionService extends _$PermissionService {
  final _kvm = KvmHelper.instance;

  @override
  void build() {}

  Future<bool> requestPermission() async {
    return _kvm.requestPermission();
  }

  Future<bool> isPermissionGranted() async {
    return _kvm.isPermissionGranted();
  }
}
