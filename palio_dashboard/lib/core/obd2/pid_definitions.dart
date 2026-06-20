import 'marelli_protocol.dart';

/// PIDs do modo diagnóstico proprietário Fiat/Marelli — NÃO são PIDs OBD-II
/// padrão (modo $01). Headers/checksums abaixo são aproximações baseadas em
/// ISO 9141-2 com endereçamento Fiat e PRECISAM ser validados no carro real.
enum MarelliPid {
  rpm(
    command: '68 6A F1 21 01 C0',
    label: 'RPM',
    unit: 'rpm',
    min: 0,
    max: 8000,
    formula: MarelliFormulas.rpm,
  ),
  speed(
    command: '68 6A F1 21 02 C1',
    label: 'Velocidade',
    unit: 'km/h',
    min: 0,
    max: 260,
    formula: MarelliFormulas.speed,
  ),
  coolantTemp(
    command: '68 6A F1 21 05 C4',
    label: 'Temp. motor',
    unit: '°C',
    min: -40,
    max: 150,
    formula: MarelliFormulas.temp,
  ),
  intakeTemp(
    command: '68 6A F1 21 0F CE',
    label: 'Temp. admissão',
    unit: '°C',
    min: -40,
    max: 120,
    formula: MarelliFormulas.temp,
  ),
  map(
    command: '68 6A F1 21 0B CA',
    label: 'MAP',
    unit: 'kPa',
    min: 0,
    max: 255,
    formula: MarelliFormulas.map,
  ),
  tps(
    command: '68 6A F1 21 11 D0',
    label: 'TPS',
    unit: '%',
    min: 0,
    max: 100,
    formula: MarelliFormulas.tps,
  ),
  lambda(
    command: '68 6A F1 21 24 E3',
    label: 'Lambda',
    unit: 'λ',
    min: 0,
    max: 2,
    formula: MarelliFormulas.lambda,
  ),
  injectionTime(
    command: '68 6A F1 21 66 A5',
    label: 'Injeção',
    unit: 'ms',
    min: 0,
    max: 30,
    formula: MarelliFormulas.injection,
  ),
  ignitionAdvance(
    command: '68 6A F1 21 0E CD',
    label: 'Avanço ignição',
    unit: '°',
    min: -64,
    max: 64,
    formula: MarelliFormulas.ignition,
  ),
  batteryVoltage(
    command: '68 6A F1 21 42 01',
    label: 'Bateria',
    unit: 'V',
    min: 0,
    max: 20,
    formula: MarelliFormulas.voltage,
  );

  const MarelliPid({
    required this.command,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.formula,
  });

  final String command;
  final String label;
  final String unit;
  final double min;
  final double max;
  final double Function(List<int> bytes) formula;

  /// PIDs lidos no loop principal do dashboard (Fase 2).
  static const List<MarelliPid> dashboardLoop = [rpm, speed, coolantTemp];
}
