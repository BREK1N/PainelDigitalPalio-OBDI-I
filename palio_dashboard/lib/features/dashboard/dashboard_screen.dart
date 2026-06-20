import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/obd_data_model.dart';
import '../../shared/settings/app_settings_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../dtc/dtc_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_provider.dart';
import 'rpm_history_provider.dart';
import 'widgets/lambda_gauge.dart';
import 'widgets/pid_tile.dart';
import 'widgets/rpm_chart.dart';
import 'widgets/rpm_gauge.dart';
import 'widgets/speed_gauge.dart';
import 'widgets/temp_gauge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obdAsync = ref.watch(obdDataProvider);
    final data = obdAsync.value ?? OBDDataModel.empty();
    final rpmHistory = ref.watch(rpmHistoryProvider);
    final speedUnit = ref.watch(speedUnitProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Expanded(child: RpmGauge(rpm: data.rpm)),
                        Expanded(
                          child: SpeedGauge(
                            speedKmh: data.speedKmh,
                            unit: speedUnit,
                          ),
                        ),
                        Expanded(child: TempGauge(tempC: data.coolantTempC)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: PidTile(
                            label: 'TPS',
                            value: data.tpsPercent.toStringAsFixed(0),
                            unit: '%',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PidTile(
                            label: 'MAP',
                            value: data.mapKpa.toStringAsFixed(0),
                            unit: 'kPa',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: LambdaGauge(lambda: data.lambda)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PidTile(
                            label: 'Injeção',
                            value: data.injectionMs.toStringAsFixed(1),
                            unit: 'ms',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PidTile(
                            label: 'Avanço',
                            value: data.ignitionDeg.toStringAsFixed(0),
                            unit: '°',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: RpmChart(spots: rpmHistory),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatusBadge(label: 'BT', status: data.btStatus),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(
                                  Icons.warning_amber,
                                  color: Colors.white54,
                                ),
                                tooltip: 'Códigos de falha',
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const DtcScreen(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white54,
                                ),
                                tooltip: 'Configurações',
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final ConnectionStatus status;

  const _StatusBadge({required this.label, required this.status});

  Color get _color {
    switch (status) {
      case ConnectionStatus.connected:
        return AppTheme.gaugeNormal;
      case ConnectionStatus.connecting:
        return AppTheme.gaugeWarning;
      case ConnectionStatus.disconnected:
        return AppTheme.gaugeDanger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 12, color: _color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
