import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/obd_data_model.dart';
import '../../shared/theme/app_theme.dart';
import '../dashboard/widgets/lambda_gauge.dart';
import '../dashboard/widgets/pid_tile.dart';
import '../dashboard/widgets/rpm_gauge.dart';
import '../dashboard/widgets/speed_gauge.dart';
import '../dashboard/widgets/temp_gauge.dart';
import 'pc_viewer_provider.dart';

class PcDashboardScreen extends ConsumerStatefulWidget {
  const PcDashboardScreen({super.key});

  @override
  ConsumerState<PcDashboardScreen> createState() => _PcDashboardScreenState();
}

class _PcDashboardScreenState extends ConsumerState<PcDashboardScreen> {
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(pcModeProvider);
    final dataAsync = ref.watch(pcObdDataProvider);
    final data = dataAsync.value ?? OBDDataModel.empty();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('PalioDash — PC Viewer'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<PcDataSourceMode>(
              value: mode,
              dropdownColor: AppTheme.surface,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                  value: PcDataSourceMode.simulation,
                  child: Text('Simulação local'),
                ),
                DropdownMenuItem(
                  value: PcDataSourceMode.live,
                  child: Text('WebSocket (celular)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(pcModeProvider.notifier).state = value;
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (mode == PcDataSourceMode.live) _buildAddressBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Expanded(child: RpmGauge(rpm: data.rpm)),
                        Expanded(child: SpeedGauge(speedKmh: data.speedKmh)),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'ws://192.168.x.x:8765',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(pcWsAddressProvider.notifier).state =
                  _addressController.text.trim();
              ref.read(pcReconnectTokenProvider.notifier).state++;
            },
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }
}
