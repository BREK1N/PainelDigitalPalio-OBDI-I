import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../shared/theme/app_theme.dart';

class RpmGauge extends StatelessWidget {
  final double rpm;

  const RpmGauge({super.key, required this.rpm});

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 8000,
          interval: 1000,
          axisLineStyle: const AxisLineStyle(
            thickness: 0.15,
            thicknessUnit: GaugeSizeUnit.factor,
            color: AppTheme.gaugeIdle,
          ),
          majorTickStyle: const MajorTickStyle(color: Colors.white54),
          minorTickStyle: const MinorTickStyle(color: Colors.white24),
          axisLabelStyle: const GaugeTextStyle(color: Colors.white70),
          ranges: [
            GaugeRange(
              startValue: 0,
              endValue: 1000,
              color: AppTheme.gaugeIdle,
              startWidth: 0.15,
              endWidth: 0.15,
              sizeUnit: GaugeSizeUnit.factor,
            ),
            GaugeRange(
              startValue: 1000,
              endValue: 3000,
              color: AppTheme.gaugeNormal,
              startWidth: 0.15,
              endWidth: 0.15,
              sizeUnit: GaugeSizeUnit.factor,
            ),
            GaugeRange(
              startValue: 3000,
              endValue: 5500,
              color: AppTheme.gaugeWarning,
              startWidth: 0.15,
              endWidth: 0.15,
              sizeUnit: GaugeSizeUnit.factor,
            ),
            GaugeRange(
              startValue: 5500,
              endValue: 7000,
              color: AppTheme.gaugeDanger,
              startWidth: 0.15,
              endWidth: 0.15,
              sizeUnit: GaugeSizeUnit.factor,
            ),
          ],
          pointers: [
            NeedlePointer(
              value: rpm.clamp(0, 8000),
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
                    rpm.toStringAsFixed(0),
                    style: AppTheme.digitalDisplay(fontSize: 32),
                  ),
                  const Text(
                    'RPM',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
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
