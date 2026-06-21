import 'marelli_protocol.dart' show isElmFailureResponse;

/// Comandos AT que configuram o ELM327 para o modo OBD-II padrão (SAE
/// J1979, modo $01) em vez do protocolo proprietário Fiat/Marelli. `ATH0`
/// desliga os headers (resposta mais simples, "41 <PID> ..." direto) e
/// `ATSP0` deixa o próprio ELM327 detectar automaticamente qual protocolo
/// físico (ISO9141-2/KWP2000/CAN/...) o veículo usa para OBD-II padrão —
/// útil porque carros brasileiros a partir do mandato OBDBr-1 (obrigatório
/// para lançamentos 2007-2009) já respondem a PIDs padrão, independente do
/// protocolo proprietário do fabricante.
const List<String> kElm327SetupObd2Standard = [
  'ATZ',
  'ATE0',
  'ATL0',
  'ATH0',
  'ATSP0',
  'ATAT2',
  'ATST96',
];

/// Resultado do parsing de uma resposta OBD-II padrão (modo $01).
class StandardObd2ParseResult {
  final List<int> dataBytes;

  const StandardObd2ParseResult(this.dataBytes);
}

/// Parseia uma resposta OBD-II padrão do ELM327 para uma consulta de PID em
/// modo $01: a resposta positiva começa com `41 <PID>` (modo+0x40, PID
/// ecoado), seguido pelos bytes de dados — sem checksum (o próprio ELM327
/// já valida isso nesse modo, diferente do protocolo proprietário Marelli).
///
/// Procura o par `41 <expectedPid>` em qualquer posição da resposta (não
/// assume que está no início) porque alguns adaptadores clone ignoram
/// `ATH0` e mandam cabeçalho na frente mesmo assim. Retorna `null` se a
/// resposta indicar erro, o par não for encontrado, ou não houver bytes de
/// dados após o par.
StandardObd2ParseResult? parseStandardObd2Response(
  String raw, {
  required int expectedPid,
}) {
  final cleaned = raw.replaceAll('>', '').trim();
  if (cleaned.isEmpty) return null;
  if (isElmFailureResponse(cleaned)) return null;

  final tokens = cleaned
      .toUpperCase()
      .split(RegExp(r'[\s\r\n]+'))
      .where((t) => t.isNotEmpty)
      .toList();

  final bytes = <int>[];
  for (final token in tokens) {
    final value = int.tryParse(token, radix: 16);
    if (value == null || value < 0 || value > 0xFF) return null;
    bytes.add(value);
  }

  for (var i = 0; i < bytes.length - 1; i++) {
    if (bytes[i] == 0x41 && bytes[i + 1] == expectedPid) {
      final dataBytes = bytes.sublist(i + 2);
      if (dataBytes.isEmpty) return null;
      return StandardObd2ParseResult(dataBytes);
    }
  }
  return null;
}
