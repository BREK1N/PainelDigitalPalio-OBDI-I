/// Fórmulas de conversão dos PIDs proprietários Fiat/Marelli.
/// Fatores baseados em engenharia reversa documentada pela comunidade
/// (FiatECUScan/MultiECUScan) — precisam ser validados no carro real.
class MarelliFormulas {
  MarelliFormulas._();

  static double rpm(List<int> bytes) => (bytes[0] * 256 + bytes[1]) / 4;

  static double speed(List<int> bytes) => bytes[0].toDouble();

  static double temp(List<int> bytes) => (bytes[0] - 40).toDouble();

  static double map(List<int> bytes) => bytes[0].toDouble();

  static double tps(List<int> bytes) => bytes[0] * 100 / 255;

  static double lambda(List<int> bytes) =>
      (bytes[0] * 256 + bytes[1]) / 32768 * 2;

  static double injection(List<int> bytes) =>
      (bytes[0] * 256 + bytes[1]) / 1000;

  static double ignition(List<int> bytes) => bytes[0] / 2 - 64;

  static double voltage(List<int> bytes) => bytes[0] / 10;
}

/// Comandos AT que configuram apenas o chip ELM327 em si — não dependem da
/// ECU do carro estar ligada/respondendo. Se algum desses falhar, o problema
/// é no adaptador/Bluetooth, não na ECU.
/// ATSP4 = ISO 9141-2 (4AF/4EF/59F). Use [kElm327SetupKwp2000] para o IAW 5AF.
const List<String> kElm327SetupIso9141 = [
  'ATZ',
  'ATE0',
  'ATL0',
  'ATH1',
  'ATSP4',
  'ATAT2',
  'ATST96',
];

const List<String> kElm327SetupKwp2000 = [
  'ATZ',
  'ATE0',
  'ATL0',
  'ATH1',
  'ATSP5',
  'ATAT2',
  'ATST96',
];

/// ATZ reinicia o microcontrolador do ELM327 — no hardware real isso demora
/// bem mais que os outros comandos AT (até ~2s em adaptadores genéricos).
const Duration kAtzTimeout = Duration(seconds: 3);

/// true se [raw] contém alguma mensagem de erro textual do ELM327 — usado
/// tanto para validar respostas de PID quanto a resposta do ATSI (que pode
/// "responder" rapidamente com texto de erro em vez de dar timeout quando a
/// ECU está desligada/não conectada).
bool isElmFailureResponse(String raw) {
  final upper = raw.toUpperCase();
  return upper.contains('NO DATA') ||
      upper.contains('ERROR') ||
      upper.contains('UNABLE TO CONNECT') ||
      upper.contains('STOPPED') ||
      upper.contains('?');
}

/// Resultado do parsing de uma resposta ISO 9141-2 do ELM327.
class MarelliParseResult {
  final List<int> dataBytes;

  const MarelliParseResult(this.dataBytes);
}

/// Parseia uma resposta típica do ELM327 para um comando Marelli:
/// "48 6B 10 61 01 XX XX CS\r\n>"
///   48 6B 10 = header (source=ECU, dest=tester, modo)
///   61 01    = resposta positiva ao modo+PID
///   XX XX    = bytes de dados
///   CS       = checksum (soma de todos os bytes anteriores, mod 256)
///
/// Retorna null se a resposta for inválida (timeout, "NO DATA", "ERROR",
/// header incorreto ou checksum inválido).
MarelliParseResult? parseMarelliResponse(String raw) {
  final cleaned = raw.replaceAll('>', '').trim();
  if (cleaned.isEmpty) return null;

  if (isElmFailureResponse(cleaned)) return null;

  final tokens = cleaned.toUpperCase()
      .split(RegExp(r'[\s\r\n]+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.length < 6) return null;

  final bytes = <int>[];
  for (final token in tokens) {
    final value = int.tryParse(token, radix: 16);
    if (value == null || value < 0 || value > 0xFF) return null;
    bytes.add(value);
  }

  // Header de resposta esperado: 48 6B ..
  if (bytes[0] != 0x48 || bytes[1] != 0x6B) return null;

  final checksum = bytes.last;
  final computed = bytes
          .sublist(0, bytes.length - 1)
          .fold<int>(0, (sum, b) => sum + b) &
      0xFF;
  if (computed != checksum) return null;

  // bytes: [header(3), modo+pid resposta(2), dados..., checksum]
  final dataBytes = bytes.sublist(5, bytes.length - 1);
  if (dataBytes.isEmpty) return null;

  return MarelliParseResult(dataBytes);
}
