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
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _codeController.dispose();
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
          if (mode == PcDataSourceMode.live ||
              mode == PcDataSourceMode.cloud) ...[
            _buildStatusBadge(data.btStatus),
            _buildEcuBadge(data.ecuResponding),
          ],
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
                  child: Text('WebSocket (mesma rede)'),
                ),
                DropdownMenuItem(
                  value: PcDataSourceMode.cloud,
                  child: Text('Nuvem (redes diferentes)'),
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
          if (mode == PcDataSourceMode.cloud) _buildCodeBar(),
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

  Widget _buildStatusBadge(ConnectionStatus status) {
    final (color, label) = switch (status) {
      ConnectionStatus.connected => (Colors.greenAccent, 'Conectado'),
      ConnectionStatus.connecting => (Colors.amberAccent, 'Conectando...'),
      ConnectionStatus.disconnected => (Colors.redAccent, 'Desconectado'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEcuBadge(bool responding) {
    final color = responding ? Colors.greenAccent : Colors.redAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            responding ? 'ECU respondendo' : 'ECU sem resposta',
            style: TextStyle(color: color, fontSize: 13),
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

  Widget _buildCodeBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _codeController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Código exibido nas Configurações do celular',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(pcCloudCodeProvider.notifier).state =
                  _codeController.text.trim();
              ref.read(pcReconnectTokenProvider.notifier).state++;
            },
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }
}
