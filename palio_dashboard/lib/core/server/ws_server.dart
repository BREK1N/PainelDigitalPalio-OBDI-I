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

/// Retorna o endereço IPv4 da rede Wi-Fi local, usado para exibir ao usuário
/// o endereço ws://IP:porta a ser digitado no PC.
///
/// Android expõe várias interfaces de rede ao mesmo tempo (Wi-Fi, dados
/// móveis, VPN...). Pegar a primeira "qualquer" pode mostrar o IP da
/// interface de dados móveis — inalcançável pelo PC mesmo que ambos estejam
/// na mesma Wi-Fi — fazendo a conexão ficar "conectando" para sempre. Por
/// isso priorizamos a interface chamada "wlan" (padrão do Wi-Fi no Android)
/// e, como reforço, endereços em faixas privadas típicas de rede doméstica.
Future<String?> getLocalIpAddress() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );

  for (final interface in interfaces) {
    if (!interface.name.toLowerCase().contains('wlan')) continue;
    for (final addr in interface.addresses) {
      if (!addr.isLoopback) return addr.address;
    }
  }

  for (final interface in interfaces) {
    for (final addr in interface.addresses) {
      if (!addr.isLoopback && _isPrivateLanAddress(addr.address)) {
        return addr.address;
      }
    }
  }

  for (final interface in interfaces) {
    for (final addr in interface.addresses) {
      if (!addr.isLoopback) return addr.address;
    }
  }
  return null;
}

/// true para faixas de IP típicas de roteador doméstico/Wi-Fi local — usado
/// para descartar o IP de dados móveis quando não há interface "wlan".
bool _isPrivateLanAddress(String address) {
  final parts = address.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.any((p) => p == null)) return false;
  final a = parts[0]!, b = parts[1]!;
  if (a == 192 && b == 168) return true;
  if (a == 10) return true;
  if (a == 172 && b >= 16 && b <= 31) return true;
  return false;
}
