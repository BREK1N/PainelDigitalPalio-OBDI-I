import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/obd2/dtc_decoder.dart';
import '../../shared/theme/app_theme.dart';
import 'dtc_provider.dart';

class DtcScreen extends ConsumerWidget {
  const DtcScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dtcsAsync = ref.watch(dtcListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Códigos de falha (DTC)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dtcListProvider),
          ),
        ],
      ),
      body: dtcsAsync.when(
        data: (codes) {
          if (codes.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma falha ativa',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: codes.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
            itemBuilder: (context, index) {
              final code = codes[index];
              return ListTile(
                leading: const Icon(Icons.warning_amber, color: AppTheme.danger),
                title: Text(
                  code,
                  style: AppTheme.digitalDisplay(fontSize: 18),
                ),
                subtitle: Text(
                  describeDtc(code),
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Erro ao ler DTCs: $error',
            style: const TextStyle(color: AppTheme.danger),
          ),
        ),
      ),
    );
  }
}
