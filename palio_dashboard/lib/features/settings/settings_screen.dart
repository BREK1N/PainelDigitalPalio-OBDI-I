import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ota/ota_dialog.dart';
import '../../shared/settings/app_settings.dart';
import '../../shared/settings/app_settings_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../dashboard/dashboard_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bondedDevicesAsync = ref.watch(bondedDevicesProvider);
    final localIpAsync = ref.watch(localIpProvider);
    final isServerRunning = ref.watch(wsServerRunningProvider);
    final speedUnit = ref.watch(speedUnitProvider);
    final dataSourceMode = ref.watch(dataSourceModeProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Fonte de dados',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SegmentedButton<DataSourceMode>(
                segments: const [
                  ButtonSegment(
                    value: DataSourceMode.simulation,
                    label: Text('Simulação'),
                  ),
                  ButtonSegment(
                    value: DataSourceMode.live,
                    label: Text('Bluetooth (ELM327)'),
                  ),
                ],
                selected: {dataSourceMode},
                onSelectionChanged: (selection) => ref
                    .read(dataSourceModeProvider.notifier)
                    .state = selection.first,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Unidade de velocidade',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SegmentedButton<SpeedUnit>(
                segments: const [
                  ButtonSegment(value: SpeedUnit.kmh, label: Text('km/h')),
                  ButtonSegment(value: SpeedUnit.mph, label: Text('mph')),
                ],
                selected: {speedUnit},
                onSelectionChanged: (selection) =>
                    ref.read(speedUnitProvider.notifier).set(selection.first),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Servidor WebSocket (PC Viewer)',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.surface,
            child: ListTile(
              title: localIpAsync.when(
                data: (ip) => Text(
                  ip != null ? 'ws://$ip:8765' : 'Sem rede Wi-Fi detectada',
                  style: AppTheme.digitalDisplay(fontSize: 16),
                ),
                loading: () => const Text('Detectando IP...'),
                error: (_, __) => const Text('Erro ao detectar IP'),
              ),
              subtitle: const Text(
                'Digite este endereço no PC Dashboard',
                style: TextStyle(color: Colors.white54),
              ),
              trailing: Switch(
                value: isServerRunning,
                activeThumbColor: AppTheme.accent,
                onChanged: (value) async {
                  final server = ref.read(wsServerProvider);
                  if (value) {
                    await server.start();
                  } else {
                    await server.stop();
                  }
                  ref.read(wsServerRunningProvider.notifier).state = value;
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Dispositivos Bluetooth pareados',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          bondedDevicesAsync.when(
            data: (devices) {
              if (devices.isEmpty) {
                return const Text(
                  'Nenhum dispositivo pareado. Pareie o adaptador ELM327 '
                  'nas configurações Bluetooth do Android primeiro.',
                  style: TextStyle(color: Colors.white54),
                );
              }
              return Column(
                children: devices
                    .map(
                      (d) => Card(
                        color: AppTheme.surface,
                        child: ListTile(
                          leading: const Icon(
                            Icons.bluetooth,
                            color: AppTheme.accent,
                          ),
                          title: Text(d.name),
                          subtitle: Text(
                            d.address,
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.white38,
                          ),
                          onTap: () async {
                            await ref
                                .read(btManagerProvider)
                                .setPreferredAddress(d.address);
                            ref.read(dataSourceModeProvider.notifier).state =
                                DataSourceMode.live;
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${d.name} definido para reconexão automática',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text(
              'Erro ao listar dispositivos: $error',
              style: const TextStyle(color: AppTheme.danger),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(bondedDevicesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar lista'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Atualizações',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => checkAndPromptUpdate(context, ref),
            icon: const Icon(Icons.system_update),
            label: const Text('Verificar atualizações'),
          ),
        ],
      ),
    );
  }
}
