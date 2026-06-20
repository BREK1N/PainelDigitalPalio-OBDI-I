import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bluetooth/bt_device_model.dart';
import '../../core/bluetooth/bt_manager.dart';
import '../../core/cloud/cloud_relay_service.dart';
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

/// Endereço do dispositivo sendo testado/conectado no momento, usado para
/// mostrar um indicador de carregamento no item da lista em Configurações.
final connectingAddressProvider = StateProvider<String?>((ref) => null);

/// Relé em nuvem (Firestore) usado quando celular e PC não estão na mesma
/// rede local — o WebSocket direto exige isso, a nuvem não.
final cloudRelayServiceProvider = Provider<CloudRelayService>((ref) {
  final service = CloudRelayService();
  ref.onDispose(service.dispose);
  return service;
});

/// PIN da sessão de relé em nuvem ativa no celular, ou null se desativado.
final cloudRelayCodeProvider = StateProvider<String?>((ref) => null);
