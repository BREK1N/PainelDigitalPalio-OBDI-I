import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_provider.dart';

const Duration kRpmHistoryWindow = Duration(seconds: 60);

/// Histórico de RPM dos últimos 60s, derivado do stream de dados do OBD2,
/// usado pelo gráfico de linha do dashboard.
class RpmHistoryNotifier extends Notifier<List<FlSpot>> {
  late DateTime _start;

  @override
  List<FlSpot> build() {
    _start = DateTime.now();
    ref.listen(obdDataProvider, (previous, next) {
      final data = next.value;
      if (data == null) return;
      final elapsedSeconds =
          DateTime.now().difference(_start).inMilliseconds / 1000.0;
      state = [...state, FlSpot(elapsedSeconds, data.rpm)]
        ..removeWhere(
          (spot) => elapsedSeconds - spot.x > kRpmHistoryWindow.inSeconds,
        );
    });
    return [];
  }
}

final rpmHistoryProvider = NotifierProvider<RpmHistoryNotifier, List<FlSpot>>(
  RpmHistoryNotifier.new,
);
