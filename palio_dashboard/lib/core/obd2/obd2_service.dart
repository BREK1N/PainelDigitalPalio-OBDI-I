import 'dart:async';

import '../../shared/models/obd_data_model.dart';
import '../bluetooth/bt_manager.dart';
import '../diagnostics/remote_log_service.dart';
import 'marelli_protocol.dart';
import 'pid_definitions.dart';

enum EcuProtocol { iso9141, kwp2000 }

/// Orquestra a inicialização do ELM327 e o loop de leitura de PIDs Marelli,
/// emitindo snapshots de [OBDDataModel] conforme os dados chegam.
class Obd2Service {
  final BtManager btManager;
  final LogSink? _logSink;

  Obd2Service(this.btManager, {LogSink? logSink}) : _logSink = logSink;

  /// PIDs cuja última leitura falhou — evita logar a mesma falha a cada
  /// ciclo (50ms) enquanto o problema persiste.
  final Set<MarelliPid> _loggedFailures = {};

  final StreamController<OBDDataModel> _dataController =
      StreamController<OBDDataModel>.broadcast();

  Stream<OBDDataModel> get dataStream => _dataController.stream;

  OBDDataModel _last = OBDDataModel.empty();

  bool _running = false;

  /// Envia a sequência de inicialização ATZ/ATE0/.../ATSI etc. Lança
  /// [BtCommandTimeoutException] se a ECU não responder a algum comando AT.
  Future<void> initialize({EcuProtocol protocol = EcuProtocol.iso9141}) async {
    final sequence = protocol == EcuProtocol.kwp2000
        ? kElm327InitKwp2000
        : kElm327InitIso9141;
    for (final command in sequence) {
      await btManager.sendCommand(command);
    }
    _last = _last.copyWith(btStatus: ConnectionStatus.connected);
  }

  /// Inicia o loop contínuo de leitura dos PIDs em [pids] (default:
  /// RPM/Velocidade/Temp do motor — Fase 2). Cada ciclo lê todos os PIDs em
  /// sequência e emite um snapshot consolidado de [OBDDataModel].
  Future<void> startLoop({
    List<MarelliPid> pids = MarelliPid.dashboardLoop,
    Duration cycleDelay = const Duration(milliseconds: 50),
  }) async {
    _running = true;
    while (_running) {
      var anyPidSucceeded = false;
      for (final pid in pids) {
        if (!_running) break;
        if (await _readPid(pid)) anyPidSucceeded = true;
      }
      _last = _last.copyWith(ecuResponding: anyPidSucceeded);
      _dataController.add(_last);
      await Future.delayed(cycleDelay);
    }
  }

  void stopLoop() {
    _running = false;
  }

  /// Retorna true se o PID foi lido e parseado com sucesso neste ciclo.
  Future<bool> _readPid(MarelliPid pid) async {
    try {
      final raw = await btManager.sendCommand(pid.command);
      final parsed = parseMarelliResponse(raw);
      if (parsed == null) {
        if (_loggedFailures.add(pid)) {
          _logSink?.call(
            LogLevel.warn,
            'obd2',
            'Falha ao parsear resposta do PID ${pid.name}',
            raw: raw,
          );
        }
        return false;
      }
      _loggedFailures.remove(pid);
      final value = pid.formula(parsed.dataBytes);
      _last = _applyPidValue(pid, value);
      return true;
    } on BtCommandTimeoutException {
      // ECU não respondeu a este PID neste ciclo — já logado pelo BtManager.
      return false;
    }
  }

  OBDDataModel _applyPidValue(MarelliPid pid, double value) {
    switch (pid) {
      case MarelliPid.rpm:
        return _last.copyWith(rpm: value, timestamp: DateTime.now());
      case MarelliPid.speed:
        return _last.copyWith(speedKmh: value, timestamp: DateTime.now());
      case MarelliPid.coolantTemp:
        return _last.copyWith(coolantTempC: value, timestamp: DateTime.now());
      case MarelliPid.intakeTemp:
        return _last.copyWith(intakeTempC: value, timestamp: DateTime.now());
      case MarelliPid.map:
        return _last.copyWith(mapKpa: value, timestamp: DateTime.now());
      case MarelliPid.tps:
        return _last.copyWith(tpsPercent: value, timestamp: DateTime.now());
      case MarelliPid.lambda:
        return _last.copyWith(lambda: value, timestamp: DateTime.now());
      case MarelliPid.injectionTime:
        return _last.copyWith(injectionMs: value, timestamp: DateTime.now());
      case MarelliPid.ignitionAdvance:
        return _last.copyWith(ignitionDeg: value, timestamp: DateTime.now());
      case MarelliPid.batteryVoltage:
        return _last.copyWith(batteryV: value, timestamp: DateTime.now());
    }
  }

  Future<void> dispose() async {
    stopLoop();
    await _dataController.close();
  }
}
