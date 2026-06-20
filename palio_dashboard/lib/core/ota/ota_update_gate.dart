import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ota_dialog.dart';

/// Envolve a tela inicial e dispara a checagem automática de atualização
/// 5s após o app abrir (conforme spec — nunca força, apenas pergunta).
class OtaUpdateGate extends ConsumerStatefulWidget {
  final Widget child;

  const OtaUpdateGate({super.key, required this.child});

  @override
  ConsumerState<OtaUpdateGate> createState() => _OtaUpdateGateState();
}

class _OtaUpdateGateState extends ConsumerState<OtaUpdateGate> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) checkAndPromptUpdate(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
