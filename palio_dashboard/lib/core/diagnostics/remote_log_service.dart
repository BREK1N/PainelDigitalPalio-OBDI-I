import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum LogLevel { info, warn, error }

/// Assinatura usada por classes de baixo nível (BtManager, Obd2Service) para
/// reportar eventos de diagnóstico sem depender diretamente do Firestore.
typedef LogSink =
    void Function(LogLevel level, String source, String message, {Object? raw});

/// Envia logs de diagnóstico (comandos BT, erros, eventos de ciclo de vida)
/// para o Firestore, para que possam ser inspecionados remotamente — via
/// o Console do Firebase — durante testes no carro real.
///
/// As entradas são acumuladas em memória e enviadas em lotes (a cada
/// [flushInterval] ou ao atingir [maxBufferSize]) para não gerar uma
/// escrita no Firestore por comando OBD2.
class RemoteLogService {
  RemoteLogService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    this.maxBufferSize = 50,
    this.flushInterval = const Duration(seconds: 10),
  }) : _firestoreOverride = firestore,
       _authOverride = auth;

  // Não resolvidos no construtor: `FirebaseFirestore.instance`/
  // `FirebaseAuth.instance` disparam o plugin do Firebase imediatamente,
  // mesmo em plataformas (PC Viewer/web) que nunca chamam `start()`. Por
  // isso só são obtidos de fato dentro de `start()`.
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;

  final int maxBufferSize;
  final Duration flushInterval;

  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final List<Map<String, dynamic>> _buffer = [];
  Timer? _flushTimer;
  bool _sessionStarted = false;

  bool get sessionStarted => _sessionStarted;

  Future<void> start({String? appVersion, String? deviceInfo}) async {
    if (_sessionStarted) return;
    try {
      _firestore = _firestoreOverride ?? FirebaseFirestore.instance;
      _auth = _authOverride ?? FirebaseAuth.instance;
      await _ensureSignedIn();
      await _firestore.collection('device_logs').doc(sessionId).set({
        'startedAt': FieldValue.serverTimestamp(),
        'appVersion': appVersion,
        'deviceInfo': deviceInfo,
      });
      _sessionStarted = true;
      _flushTimer = Timer.periodic(flushInterval, (_) => flush());
    } catch (_) {
      // Sem rede/Firebase indisponível — segue sem logging remoto.
    }
  }

  Future<void> _ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  void log(LogLevel level, String source, String message, {Object? raw}) {
    _buffer.add({
      'ts': DateTime.now().toIso8601String(),
      'level': level.name,
      'source': source,
      'message': message,
      if (raw != null) 'raw': raw.toString(),
    });
    if (_buffer.length >= maxBufferSize) {
      unawaited(flush());
    }
  }

  Future<void> flush() async {
    if (_buffer.isEmpty || !_sessionStarted) return;
    final entries = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();

    try {
      await _firestore
          .collection('device_logs')
          .doc(sessionId)
          .collection('entries')
          .add({'flushedAt': FieldValue.serverTimestamp(), 'lines': entries});
    } catch (_) {
      // Falha de envio não deve travar o app — entradas deste lote são
      // perdidas, mas o app continua funcionando normalmente.
    }
  }

  Future<void> dispose() async {
    _flushTimer?.cancel();
    await flush();
  }
}
