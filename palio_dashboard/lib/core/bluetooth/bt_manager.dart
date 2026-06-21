import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../diagnostics/remote_log_service.dart';
import 'bt_device_model.dart';
import 'bt_permissions.dart';

class BtCommandTimeoutException implements Exception {
  final String command;
  const BtCommandTimeoutException(this.command);

  @override
  String toString() => 'Timeout aguardando resposta para "$command"';
}

class _QueuedCommand {
  final String command;
  final Duration timeout;
  final Completer<String> completer = Completer<String>();

  _QueuedCommand(this.command, this.timeout);
}

/// Gerencia a conexão Bluetooth Classic (SPP) com o adaptador ELM327.
///
/// O ELM327 é half-duplex: só pode haver um comando em voo por vez, e a
/// resposta termina com o prompt '>'. Por isso os comandos passam por uma
/// fila e são processados sequencialmente.
class BtManager {
  static const String _lastAddressKey = 'bt_last_device_address';

  // ATST96 (enviado na configuração do adaptador) define o timeout interno
  // do próprio ELM327 para aguardar a ECU em 0x96 * 4ms = 600ms. Esse
  // timeout do lado Dart tem que ser MAIOR que isso — se for menor (como
  // eram os 300ms antigos), o app desiste e manda o próximo comando
  // enquanto o ELM327 ainda está no meio de uma tentativa de comunicação
  // com a ECU, interrompendo-a (o adaptador responde "STOPPED" à tentativa
  // anterior, atribuído por engano à próxima leitura). Por isso fica bem
  // acima de 600ms, com margem para a latência do próprio Bluetooth.
  static const Duration defaultTimeout = Duration(milliseconds: 1000);

  BtManager({LogSink? logSink}) : _logSink = logSink;

  final LogSink? _logSink;

  BluetoothConnection? _connection;
  StreamSubscription<List<int>>? _inputSubscription;

  final Queue<_QueuedCommand> _queue = Queue<_QueuedCommand>();
  _QueuedCommand? _inFlight;
  Timer? _timeoutTimer;

  final List<int> _buffer = [];

  bool get isConnected => _connection?.isConnected ?? false;

  Future<List<BtDeviceModel>> getBondedDevices() async {
    await ensureBluetoothPermissions();
    final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    return devices.map(BtDeviceModel.fromBluetoothDevice).toList();
  }

  Future<void> connect(String address) async {
    await ensureBluetoothPermissions();
    await disconnect();
    try {
      _connection = await BluetoothConnection.toAddress(address);
    } catch (e) {
      _logSink?.call(LogLevel.error, 'bt', 'Falha ao conectar a $address: $e');
      rethrow;
    }
    _buffer.clear();
    _inputSubscription = _connection!.input?.listen(
      _onBytesReceived,
      onDone: () {
        _logSink?.call(LogLevel.warn, 'bt', 'Conexão Bluetooth perdida');
        disconnect();
      },
    );
    await _saveLastAddress(address);
    _logSink?.call(LogLevel.info, 'bt', 'Conectado a $address');
  }

  Future<void> disconnect() async {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    await _inputSubscription?.cancel();
    _inputSubscription = null;
    await _connection?.finish();
    _connection = null;

    final pendingError = StateError('Conexão Bluetooth encerrada');
    _inFlight?.completer.completeError(pendingError);
    _inFlight = null;
    for (final queued in _queue) {
      queued.completer.completeError(pendingError);
    }
    _queue.clear();
  }

  /// Envia um comando AT/Marelli e aguarda a resposta completa (até o '>').
  /// Comandos são enfileirados — o ELM327 não aceita o próximo enquanto o
  /// anterior não terminar.
  Future<String> sendCommand(
    String command, {
    Duration timeout = defaultTimeout,
  }) {
    if (!isConnected) {
      return Future.error(StateError('Bluetooth não conectado'));
    }
    final queued = _QueuedCommand(command, timeout);
    _queue.add(queued);
    _pumpQueue();
    return queued.completer.future;
  }

  void _pumpQueue() {
    if (_inFlight != null || _queue.isEmpty) return;
    final next = _queue.removeFirst();
    _inFlight = next;
    _buffer.clear();

    _connection!.output.add(ascii.encode('${next.command}\r'));

    _timeoutTimer = Timer(next.timeout, () {
      if (_inFlight == next) {
        _inFlight = null;
        _logSink?.call(
          LogLevel.warn,
          'bt',
          'Timeout aguardando resposta',
          raw: next.command,
        );
        next.completer.completeError(BtCommandTimeoutException(next.command));
        _pumpQueue();
      }
    });
  }

  void _onBytesReceived(List<int> bytes) {
    _buffer.addAll(bytes);
    final text = ascii.decode(_buffer, allowInvalid: true);
    if (!text.contains('>')) return;

    _timeoutTimer?.cancel();
    final current = _inFlight;
    _inFlight = null;
    _buffer.clear();
    current?.completer.complete(text);
    _pumpQueue();
  }

  Future<void> _saveLastAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAddressKey, address);
  }

  Future<String?> getLastAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastAddressKey);
  }

  /// Marca [address] como o dispositivo preferido para reconexão automática,
  /// sem conectar imediatamente — usado ao selecionar um adaptador na tela
  /// de Settings antes de alternar para o modo live.
  Future<void> setPreferredAddress(String address) => _saveLastAddress(address);
}
