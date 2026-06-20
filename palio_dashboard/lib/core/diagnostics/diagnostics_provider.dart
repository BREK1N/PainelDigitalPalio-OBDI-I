import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'remote_log_service.dart';

/// Sobrescrito em main.dart com a instância já iniciada (sessão aberta,
/// sign-in anônimo feito) antes do runApp.
final remoteLogServiceProvider = Provider<RemoteLogService>(
  (ref) => RemoteLogService(),
);
