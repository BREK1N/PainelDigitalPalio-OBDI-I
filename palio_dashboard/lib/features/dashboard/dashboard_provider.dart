import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/diagnostics/diagnostics_provider.dart';
import '../../core/obd2/obd2_service.dart';
import '../../shared/models/obd_data_model.dart';
import '../settings/settings_provider.dart';

enum DataSourceMode { simulation, live }

final dataSourceModeProvider = StateProvider<DataSourceMode>(
  (ref) => DataSourceMode.simulation,
);

/// Emite um [OBDDataModel] a cada 100ms. Em modo simulação gera dados fake;
/// em modo live, reconecta automaticamente ao último adaptador ELM327
/// pareado (MAC salvo em SharedPreferences) e inicia o loop de PIDs.
final obdDataProvider = StreamProvider<OBDDataModel>((ref) {
  final mode = ref.watch(dataSourceModeProvider);
  if (mode == DataSourceMode.live) {
    return _liveObdStream(ref);
  }

  final start = DateTime.now();
  return Stream.periodic(
    const Duration(milliseconds: 100),
    (_) => OBDDataModel.simulated(DateTime.now().difference(start)),
  );
});

Stream<OBDDataModel> _liveObdStream(Ref ref) async* {
  final btManager = ref.watch(btManagerProvider);
  final obd2Service = Obd2Service(
    btManager,
    logSink: ref.read(remoteLogServiceProvider).log,
  );
  ref.onDispose(obd2Service.dispose);

  final lastAddress = await btManager.getLastAddress();
  if (lastAddress == null) {
    yield OBDDataModel.empty().copyWith(
      btStatus: ConnectionStatus.disconnected,
    );
    return;
  }

  yield OBDDataModel.empty().copyWith(btStatus: ConnectionStatus.connecting);

  try {
    await btManager.connect(lastAddress);
    await obd2Service.initialize();
  } catch (_) {
    yield OBDDataModel.empty().copyWith(
      btStatus: ConnectionStatus.disconnected,
    );
    return;
  }

  unawaited(obd2Service.startLoop());
  yield* obd2Service.dataStream;
}
