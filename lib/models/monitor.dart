import 'package:desk_switch/models/device.pb.dart' as pb_device;
import 'package:kvm_helper/kvm_helper.dart';

export 'package:kvm_helper/models/monitor.dart';

// Conversion between Dart Monitor model and protobuf
extension MonitorToProto on Monitor {
  pb_device.Monitor toProto() {
    return pb_device.Monitor()
      ..id = id
      ..name = name
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
  }
}

extension ProtoToMonitor on pb_device.Monitor {
  Monitor toModel() {
    return Monitor(
      id: id,
      name: name,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }
}
