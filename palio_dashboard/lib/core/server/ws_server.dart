import 'dart:convert';
import 'dart:io';

import '../../shared/models/obd_data_model.dart';

/// Servidor WebSocket rodando no celular Android. O PC/web conecta como
/// cliente em ws://IP_CELULAR:porta para receber os dados do OBD2 em tempo
/// real, transmitidos a cada novo snapshot via [broadcast].
class WsServer {
  HttpServer? _server;
  final Set<WebSocket> _clients = {};

  bool get isRunning => _server != null;
  int? get port => _server?.port;

  Future<void> start({int port = 8765}) async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.transform(WebSocketTransformer()).listen((ws) {
      _clients.add(ws);
      ws.done.then((_) => _clients.remove(ws));
    });
  }

  void broadcast(OBDDataModel data) {
    final json = jsonEncode(data.toJson());
    for (final ws in _clients) {
      ws.add(json);
    }
  }

  Future<void> stop() async {
    for (final ws in _clients.toList()) {
      await ws.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }
}

/// Retorna o primeiro endereço IPv4 não-loopback da rede local, usado para
/// exibir ao usuário o endereço ws://IP:porta a ser digitado no PC.
Future<String?> getLocalIpAddress() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );
  for (final interface in interfaces) {
    for (final addr in interface.addresses) {
      if (!addr.isLoopback) return addr.address;
    }
  }
  return null;
}
