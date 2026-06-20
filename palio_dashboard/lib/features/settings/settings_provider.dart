import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bluetooth/bt_device_model.dart';
import '../../core/bluetooth/bt_manager.dart';
import '../../core/diagnostics/diagnostics_provider.dart';
import '../../core/server/ws_server.dart';

final btManagerProvider = Provider<BtManager>((ref) {
  final manager = BtManager(logSink: ref.read(remoteLogServiceProvider).log);
  ref.onDispose(manager.disconnect);
  return manager;
});

final wsServerProvider = Provider<WsServer>((ref) {
  final server = WsServer();
  ref.onDispose(server.stop);
  return server;
});

final bondedDevicesProvider =
    FutureProvider.autoDispose<List<BtDeviceModel>>((ref) {
  return ref.read(btManagerProvider).getBondedDevices();
});

final localIpProvider = FutureProvider.autoDispose<String?>((ref) {
  return getLocalIpAddress();
});

final wsServerRunningProvider = StateProvider<bool>((ref) => false);
