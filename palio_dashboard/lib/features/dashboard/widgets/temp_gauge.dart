import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../shared/theme/app_theme.dart';

class TempGauge extends StatelessWidget {
  final double tempC;

  const TempGauge({super.key, required this.tempC});

  bool get _isOverheating => tempC > 100;

  @override
  Widget build(BuildContext context) {
    final needleColor = _isOverheating ? AppTheme.gaugeDanger : AppTheme.accent;
    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: -40,
          maximum: 150,
          interval: 20,
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
              startValue: 100,
              endValue: 150,
              color: AppTheme.gaugeDanger,
              startWidth: 0.15,
              endWidth: 0.15,
              sizeUnit: GaugeSizeUnit.factor,
            ),
          ],
          pointers: [
            NeedlePointer(
              value: tempC.clamp(-40, 150),
              needleColor: needleColor,
              knobStyle: KnobStyle(color: needleColor),
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
                    tempC.toStringAsFixed(0),
                    style: AppTheme.digitalDisplay(
                      fontSize: 32,
                      color: _isOverheating ? AppTheme.danger : Colors.white,
                    ),
                  ),
                  const Text(
                    '°C',
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
