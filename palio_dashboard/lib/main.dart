import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'core/diagnostics/device_info_helper.dart';
import 'core/diagnostics/diagnostics_provider.dart';
import 'core/diagnostics/remote_log_service.dart';
import 'core/ota/ota_update_gate.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/pc_viewer/pc_dashboard_screen.dart';
import 'firebase_options.dart';
import 'shared/theme/app_theme.dart';

/// O app tem dois "modos" conforme a plataforma: no Android é o dashboard
/// veicular conectado via Bluetooth ao OBD2; em Desktop/Web é o PC Viewer
/// que recebe dados via WebSocket do celular (ou simula localmente).
bool get _isPcViewerPlatform =>
    kIsWeb || defaultTargetPlatform != TargetPlatform.android;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final remoteLogService = RemoteLogService();

  FlutterError.onError = (details) {
    remoteLogService.log(
      LogLevel.error,
      'flutter',
      details.exceptionAsString(),
      raw: details.stack,
    );
    FlutterError.presentError(details);
  };

  await runZonedGuarded<Future<void>>(
    () async {
      // O log remoto é só para o app veicular Android — o PC Viewer não
      // toca em Bluetooth/OBD2, então não há nada relevante para logar.
      if (!_isPcViewerPlatform) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        final packageInfo = await PackageInfo.fromPlatform();
        final deviceDescription = await describeDevice();
        await remoteLogService.start(
          appVersion: packageInfo.version,
          deviceInfo: deviceDescription,
        );
      }

      runApp(
        ProviderScope(
          overrides: [
            remoteLogServiceProvider.overrideWithValue(remoteLogService),
          ],
          child: const PalioDashApp(),
        ),
      );
    },
    (error, stack) {
      remoteLogService.log(LogLevel.error, 'zone', error.toString(), raw: stack);
    },
  );
}

class PalioDashApp extends StatelessWidget {
  const PalioDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PalioDash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _isPcViewerPlatform
          ? const PcDashboardScreen()
          : const OtaUpdateGate(child: DashboardScreen()),
    );
  }
}
