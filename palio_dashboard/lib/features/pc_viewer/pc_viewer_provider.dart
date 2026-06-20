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

  final subscription = channel.stream.listen(
    (message) {
      try {
        final json = jsonDecode(message as String) as Map<String, dynamic>;
        controller.add(OBDDataModel.fromJson(json));
      } catch (_) {
        // Mensagem inválida — ignora e mantém último estado.
      }
    },
    onError: (_) {
      controller.add(
        OBDDataModel.empty().copyWith(
          btStatus: ConnectionStatus.disconnected,
        ),
      );
    },
    onDone: () {
      controller.add(
        OBDDataModel.empty().copyWith(
          btStatus: ConnectionStatus.disconnected,
        ),
      );
    },
  );

  ref.onDispose(() {
    subscription.cancel();
    channel.sink.close();
    controller.close();
  });

  return controller.stream;
});
