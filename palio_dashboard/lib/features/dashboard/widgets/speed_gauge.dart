import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../shared/settings/app_settings.dart';
import '../../../shared/theme/app_theme.dart';

class SpeedGauge extends StatelessWidget {
  final double speedKmh;
  final SpeedUnit unit;

  const SpeedGauge({
    super.key,
    required this.speedKmh,
    this.unit = SpeedUnit.kmh,
  });

  @override
  Widget build(BuildContext context) {
    final maxSpeed = unit == SpeedUnit.kmh ? 220.0 : 140.0;
    final displaySpeed = unit.convert(speedKmh);

    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: maxSpeed,
          interval: unit == SpeedUnit.kmh ? 20 : 20,
          axisLineStyle: const AxisLineStyle(
            thickness: 0.15,
            thicknessUnit: GaugeSizeUnit.factor,
            color: AppTheme.gaugeIdle,
          ),
          majorTickStyle: const MajorTickStyle(color: Colors.white54),
          minorTickStyle: const MinorTickStyle(color: Colors.white24),
          axisLabelStyle: const GaugeTextStyle(color: Colors.white70),
          pointers: [
            NeedlePointer(
              value: displaySpeed.clamp(0, maxSpeed),
              needleColor: AppTheme.accent,
              knobStyle: const KnobStyle(color: AppTheme.accent),
              animationType: AnimationType.linear,
              enableAnimation: true,
              animationDuration: 100,
            ),
          ],
          annotations: [
            GaugeAnnotation(
              positionFactor: 0.6,
              angle: 90,
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displaySpeed.toStringAsFixed(0),
                    style: AppTheme.digitalDisplay(fontSize: 32),
                  ),
                  Text(
                    unit.label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
