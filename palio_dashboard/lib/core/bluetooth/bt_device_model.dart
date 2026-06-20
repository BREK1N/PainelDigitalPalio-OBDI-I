import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BtDeviceModel {
  final String name;
  final String address;
  final bool isBonded;

  const BtDeviceModel({
    required this.name,
    required this.address,
    required this.isBonded,
  });

  factory BtDeviceModel.fromBluetoothDevice(BluetoothDevice device) =>
      BtDeviceModel(
        name: device.name ?? device.address,
        address: device.address,
        isBonded: device.isBonded,
      );
}
