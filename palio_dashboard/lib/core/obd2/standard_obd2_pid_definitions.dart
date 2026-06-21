/// Fórmulas de conversão dos PIDs OBD-II padrão (SAE J1979, modo $01) —
/// idênticas em qualquer carro do mundo que suporte o modo, ao contrário
/// das fórmulas proprietárias Fiat/Marelli (MarelliFormulas).
class StandardObd2Formulas {
  StandardObd2Formulas._();

  static double rpm(List<int> bytes) => (bytes[0] * 256 + bytes[1]) / 4;

  static double speed(List<int> bytes) => bytes[0].toDouble();

  static double temp(List<int> bytes) => (bytes[0] - 40).toDouble();
}

/// PIDs OBD-II padrão (modo $01) usados como primeira camada de tentativa
/// de conexão com a ECU — mais simples e confiável que o protocolo
/// proprietário Marelli quando o veículo suporta (ex.: carros brasileiros
/// no mandato OBDBr-1, lançamentos 2007-2009 em diante).
enum StandardObd2Pid {
  rpm(
    command: '01 0C',
    pidByte: 0x0C,
    label: 'RPM',
    unit: 'rpm',
    min: 0,
    max: 8000,
    formula: StandardObd2Formulas.rpm,
  ),
  speed(
    command: '01 0D',
    pidByte: 0x0D,
    label: 'Velocidade',
    unit: 'km/h',
    min: 0,
    max: 260,
    formula: StandardObd2Formulas.speed,
  ),
  coolantTemp(
    command: '01 05',
    pidByte: 0x05,
    label: 'Temp. motor',
    unit: '°C',
    min: -40,
    max: 150,
    formula: StandardObd2Formulas.temp,
  );

  const StandardObd2Pid({
    required this.command,
    required this.pidByte,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.formula,
  });

  final String command;
  final int pidByte;
  final String label;
  final String unit;
  final double min;
  final double max;
  final double Function(List<int> bytes) formula;

  /// PIDs lidos no loop principal do dashboard quando conectado via OBD-II
  /// padrão.
  static const List<StandardObd2Pid> dashboardLoop = [rpm, speed, coolantTemp];
}
