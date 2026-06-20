import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class PidTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const PidTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '$value $unit',
            style: AppTheme.digitalDisplay(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
