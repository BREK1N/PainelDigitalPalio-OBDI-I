import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palio_dashboard/core/diagnostics/remote_log_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late RemoteLogService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(signedIn: false);
    service = RemoteLogService(
      firestore: firestore,
      auth: auth,
      maxBufferSize: 3,
      flushInterval: const Duration(minutes: 5),
    );
  });

  test('start cria documento da sessão e autentica anonimamente', () async {
    await service.start(appVersion: '1.0.0', deviceInfo: 'Test Device');

    expect(auth.currentUser, isNotNull);
    final doc = await firestore
        .collection('device_logs')
        .doc(service.sessionId)
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['appVersion'], '1.0.0');
  });

  test('log acumula em buffer sem gravar imediatamente', () async {
    await service.start();
    service.log(LogLevel.warn, 'bt', 'timeout');

    final entries = await firestore
        .collection('device_logs')
        .doc(service.sessionId)
        .collection('entries')
        .get();
    expect(entries.docs, isEmpty);
  });

  test('flush grava as entradas acumuladas em um lote', () async {
    await service.start();
    service.log(LogLevel.warn, 'bt', 'timeout 1');
    service.log(LogLevel.error, 'obd2', 'parse falhou');
    await service.flush();

    final entries = await firestore
        .collection('device_logs')
        .doc(service.sessionId)
        .collection('entries')
        .get();
    expect(entries.docs, hasLength(1));
    final lines = entries.docs.first.data()['lines'] as List;
    expect(lines, hasLength(2));
    expect(lines[0]['message'], 'timeout 1');
    expect(lines[1]['level'], 'error');
  });

  test('flush automático ao atingir maxBufferSize', () async {
    await service.start();
    service.log(LogLevel.info, 'bt', '1');
    service.log(LogLevel.info, 'bt', '2');
    service.log(LogLevel.info, 'bt', '3');

    // O flush automático é assíncrono (unawaited) — espera o microtask.
    await Future<void>.delayed(Duration.zero);

    final entries = await firestore
        .collection('device_logs')
        .doc(service.sessionId)
        .collection('entries')
        .get();
    expect(entries.docs, hasLength(1));
  });

  test('log antes de start não lança erro (apenas bufferiza)', () {
    expect(() => service.log(LogLevel.info, 'bt', 'antes de start'), returnsNormally);
  });
}
