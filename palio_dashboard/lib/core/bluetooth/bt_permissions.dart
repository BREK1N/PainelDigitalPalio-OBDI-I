import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPermissionDeniedException implements Exception {
  const BluetoothPermissionDeniedException();

  @override
  String toString() =>
      'Permissão de Bluetooth negada. Conceda o acesso nas configurações '
      'do Android para conectar ao adaptador OBD2.';
}

/// Solicita as permissões de Bluetooth exigidas pelo Android antes de
/// qualquer chamada ao flutter_bluetooth_serial. No Android 12+ (API 31+),
/// usar a API de Bluetooth sem BLUETOOTH_CONNECT/BLUETOOTH_SCAN concedidos
/// lança uma SecurityException nativa que derruba o app — por isso essas
/// permissões precisam ser garantidas explicitamente aqui, nunca deixadas
/// para o sistema pedir "de surpresa" no meio de uma chamada nativa.
Future<void> ensureBluetoothPermissions() async {
  if (kIsWeb || !Platform.isAndroid) return;

  final permissions = <Permission>[
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
  ];

  final statuses = await permissions.request();
  final allGranted = statuses.values.every((status) => status.isGranted);
  if (!allGranted) {
    throw const BluetoothPermissionDeniedException();
  }
}
