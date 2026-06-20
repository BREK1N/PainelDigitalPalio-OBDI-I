enum SpeedUnit { kmh, mph }

extension SpeedUnitConversion on SpeedUnit {
  String get label => this == SpeedUnit.kmh ? 'km/h' : 'mph';

  double convert(double speedKmh) =>
      this == SpeedUnit.kmh ? speedKmh : speedKmh * 0.621371;
}
