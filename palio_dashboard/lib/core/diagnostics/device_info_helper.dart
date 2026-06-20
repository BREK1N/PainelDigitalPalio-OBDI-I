import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Descrição curta do dispositivo (modelo + versão do Android), usada como
/// metadado da sessão de log remoto.
Future<String> describeDevice() async {
  if (kIsWeb) return 'web';

  try {
    final deviceInfo = DeviceInfoPlugin();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await deviceInfo.androidInfo;
      return '${info.manufacturer} ${info.model} (Android ${info.version.release})';
    }
  } catch (_) {
    // Sem informação de dispositivo disponível — não é crítico.
  }
  return defaultTargetPlatform.name;
}
