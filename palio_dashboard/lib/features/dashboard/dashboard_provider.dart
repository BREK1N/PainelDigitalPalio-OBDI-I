import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/diagnostics/diagnostics_provider.dart';
import '../../core/diagnostics/remote_log_service.dart';
import '../../core/obd2/obd2_service.dart';
import '../../shared/models/obd_data_model.dart';
import '../settings/settings_provider.dart';

enum DataSourceMode { simulation, live }

final dataSourceModeProvider = StateProvider<DataSourceMode>(
  (ref) => DataSourceMode.simulation,
);

/// Instância do [Obd2Service] da conexão live atual, para que a UI (botão
/// "Conectar à ECU" no Dashboard) consiga acionar [Obd2Service.connectEcu]
/// como uma etapa separada da conexão com o adaptador OBD2.
final currentObd2ServiceProvider = StateProvider<Obd2Service?>((ref) => null);

/// true enquanto o botão "Conectar à ECU" está aguardando resposta.
final connectingEcuProvider = StateProvider<bool>((ref) => false);

/// Emite um [OBDDataModel] a cada 100ms. Em modo simulação gera dados fake;
/// em modo live, reconecta automaticamente ao último adaptador ELM327
/// pareado (MAC salvo em SharedPreferences) e inicia o loop de PIDs.
final obdDataProvider = StreamProvider<OBDDataModel>((ref) {
  final mode = ref.watch(dataSourceModeProvider);
  final source = mode == DataSourceMode.live
      ? _liveObdStream(ref)
      : _simulatedObdStream();

  return source.map((data) {
    if (ref.read(wsServerRunningProvider)) {
      ref.read(wsServerProvider).broadcast(data);
    }
    final cloudCode = ref.read(cloudRelayCodeProvider);
    if (cloudCode != null) {
      ref.read(cloudRelayServiceProvider).update(data);
    }
    return data;
  });
});

Stream<OBDDataModel> _simulatedObdStream() {
  final start = DateTime.now();
  return Stream.periodic(
    const Duration(milliseconds: 100),
    (_) => OBDDataModel.simulated(DateTime.now().difference(start)),
  );
}

Stream<OBDDataModel> _liveObdStream(Ref ref) async* {
  final btManager = ref.watch(btManagerProvider);
  final obd2Service = Obd2Service(
    btManager,
    logSink: ref.read(remoteLogServiceProvider).log,
  );
  ref.read(currentObd2ServiceProvider.notifier).state = obd2Service;
  ref.onDispose(() {
    ref.read(currentObd2ServiceProvider.notifier).state = null;
    obd2Service.dispose();
  });

  final lastAddress = await btManager.getLastAddress();
  if (lastAddress == null) {
    yield OBDDataModel.empty().copyWith(
      btStatus: ConnectionStatus.disconnected,
    );
    return;
  }

  yield OBDDataModel.empty().copyWith(btStatus: ConnectionStatus.connecting);

  try {
    // Se a tela de Configurações já testou e deixou conectado ao mesmo
    // endereço, não desconecta e reconecta de novo aqui — em adaptadores
    // ELM327 mais baratos, reconectar imediatamente após desconectar pode
    // falhar ou ficar pendurado, deixando o Dashboard sem nunca chegar a
    // "conectado" mesmo com o OBD2 funcionando.
    if (!btManager.isConnected) {
      await btManager.connect(lastAddress);
    }
    await obd2Service.setupAdapter(protocol: EcuProtocol.obd2Standard);
  } catch (e) {
    ref.read(remoteLogServiceProvider).log(
      LogLevel.error,
      'dashboard',
      'Falha ao conectar/configurar o adaptador OBD2: $e',
    );
    yield OBDDataModel.empty().copyWith(
      btStatus: ConnectionStatus.disconnected,
    );
    return;
  }

  // Adaptador conectado — a conexão com a ECU é uma etapa separada,
  // acionada pelo botão "Conectar à ECU" no Dashboard (chama
  // Obd2Service.connectEcu via currentObd2ServiceProvider).
  yield OBDDataModel.empty().copyWith(
    btStatus: ConnectionStatus.connected,
    ecuResponding: false,
  );
  yield* obd2Service.dataStream;
}
