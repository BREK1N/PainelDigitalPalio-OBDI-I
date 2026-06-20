import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:palio_dashboard/core/server/ws_server.dart';
import 'package:palio_dashboard/shared/models/obd_data_model.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  test('WsServer faz broadcast de OBDDataModel para clientes conectados', () async {
    final server = WsServer();
    await server.start(port: 0);
    addTearDown(server.stop);

    final client = IOWebSocketChannel.connect('ws://127.0.0.1:${server.port}');
    addTearDown(() => client.sink.close());

    // Dá tempo do servidor registrar o handshake do cliente.
    await Future.delayed(const Duration(milliseconds: 100));

    final received = client.stream.first;

    final data = OBDDataModel.empty().copyWith(rpm: 3500);
    server.broadcast(data);

    final message = await received.timeout(const Duration(seconds: 2));
    final json = jsonDecode(message as String) as Map<String, dynamic>;
    final decoded = OBDDataModel.fromJson(json);

    expect(decoded.rpm, 3500);
  });
}
