import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../shared/models/obd_data_model.dart';

enum PcDataSourceMode { simulation, live }

final pcModeProvider = StateProvider<PcDataSourceMode>(
  (ref) => PcDataSourceMode.simulation,
);

/// Endereço ws:// digitado pelo usuário (IP do celular exibido em Settings).
final pcWsAddressProvider = StateProvider<String>((ref) => '');

/// Incrementado para forçar reconexão ao endereço atual.
final pcReconnectTokenProvider = StateProvider<int>((ref) => 0);

final pcObdDataProvider = StreamProvider.autoDispose<OBDDataModel>((ref) {
  final mode = ref.watch(pcModeProvider);

  if (mode == PcDataSourceMode.simulation) {
    final start = DateTime.now();
    return Stream.periodic(
      const Duration(milliseconds: 100),
      (_) => OBDDataModel.simulated(DateTime.now().difference(start)),
    );
  }

  ref.watch(pcReconnectTokenProvider);
  final address = ref.watch(pcWsAddressProvider);
  if (address.isEmpty) {
    return Stream.value(
      OBDDataModel.empty().copyWith(btStatus: ConnectionStatus.disconnected),
    );
  }

  final controller = StreamController<OBDDataModel>();
  controller.add(
    OBDDataModel.empty().copyWith(btStatus: ConnectionStatus.connecting),
  );

  late WebSocketChannel channel;
  try {
    channel = WebSocketChannel.connect(Uri.parse(address));
  } catch (_) {
    controller.add(
      OBDDataModel.empty().copyWith(btStatus: ConnectionStatus.disconnected),
    );
    controller.close();
    return controller.stream;
  }

  // O WebSocket do navegador não tem timeout próprio: se o celular não for
  // alcançável (IP errado, fora da rede, servidor desligado), o socket pode
  // ficar parado em "conectando" indefinidamente sem nunca disparar erro.
  var settled = false;
  final connectTimeout = Timer(const Duration(seconds: 8), () {
    if (settled) return;
    settled = true;
    controller.add(
      OBDDataModel.empty().copyWith(btStatus: ConnectionStatus.disconnected),
    );
    channel.sink.close();
  });

  final subscription = channel.stream.listen(
    (message) {
      settled = true;
      connectTimeout.cancel();
      try {
        final json = jsonDecode(message as String) as Map<String, dynamic>;
        controller.add(OBDDataModel.fromJson(json));
      } catch (_) {
        // Mensagem inválida — ignora e mantém último estado.
      }
    },
    onError: (_) {
      settled = true;
      connectTimeout.cancel();
      controller.add(
        OBDDataModel.empty().copyWith(
          btStatus: ConnectionStatus.disconnected,
        ),
      );
    },
    onDone: () {
      settled = true;
      connectTimeout.cancel();
      controller.add(
        OBDDataModel.empty().copyWith(
          btStatus: ConnectionStatus.disconnected,
        ),
      );
    },
  );

  ref.onDispose(() {
    connectTimeout.cancel();
    subscription.cancel();
    channel.sink.close();
    controller.close();
  });

  return controller.stream;
});
