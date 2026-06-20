import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard/dashboard_provider.dart';

/// Lista de DTCs ativos. Em modo simulação retorna dados fake para
/// permitir testar a tela sem hardware; em modo live, plugado futuramente
/// ao Obd2Service (Fase 2/4) via `kReadDtcsCommand`.
final dtcListProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final mode = ref.watch(dataSourceModeProvider);
  if (mode == DataSourceMode.live) {
    // TODO: plugar Obd2Service.readDtcs() quando a conexão BT estiver ativa.
    return const [];
  }
  return const ['P0300', 'P0171'];
});
