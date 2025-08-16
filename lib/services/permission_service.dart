import 'package:kvm_helper/kvm_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_service.g.dart';

enum PermissionType {
  kvm,
}

@Riverpod(keepAlive: true)
class PermissionService extends _$PermissionService {
  final _kvm = KvmHelper.instance;

  @override
  void build() {}

  Future<bool> request(PermissionType type) async {
    switch (type) {
      case PermissionType.kvm:
        return _kvm.requestPermission();
    }
  }

  Future<bool> isGranted(PermissionType type) async {
    switch (type) {
      case PermissionType.kvm:
        return _kvm.isPermissionGranted();
    }
  }
}
