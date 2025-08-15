import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kvm_helper/kvm_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'capture_service.freezed.dart';
part 'capture_service.g.dart';

@freezed
abstract class CaptureState with _$CaptureState {
  const factory CaptureState({
    Input? input,
    List<Monitor>? monitors,
  }) = _CaptureState;

  const CaptureState._();
}

@riverpod
class CaptureService extends _$CaptureService {
  static const _kvm = KvmHelper.instance;
  StreamSubscription<CaptureState>? _sub;

  @override
  CaptureState build() {
    ref.onDispose(() => _sub?.cancel());

    return const CaptureState();
  }

  Future<void> start() async {
    final stream = CombineLatestStream.combine2(
      _kvm.inputs(),
      _kvm.monitors(),
      (input, monitors) => CaptureState(input: input, monitors: monitors),
    ).asBroadcastStream();

    state = await stream.first;
    _sub = stream.listen((state) => this.state = state);
  }

  Future<void> stop() async {
    await _sub?.cancel();
  }
}
