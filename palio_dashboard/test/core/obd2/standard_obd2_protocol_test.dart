import 'package:flutter_test/flutter_test.dart';
import 'package:palio_dashboard/core/obd2/standard_obd2_pid_definitions.dart';
import 'package:palio_dashboard/core/obd2/standard_obd2_protocol.dart';

void main() {
  group('parseStandardObd2Response', () {
    test('parseia resposta válida sem header (ATH0)', () {
      final result = parseStandardObd2Response(
        '41 0C 1F 40\r\n>',
        expectedPid: 0x0C,
      );

      expect(result, isNotNull);
      expect(result!.dataBytes, [0x1F, 0x40]);
      expect(StandardObd2Formulas.rpm(result.dataBytes), 2000.0);
    });

    test('encontra o par 41+PID mesmo com header espúrio na frente', () {
      // Simula um adaptador que ignora ATH0 e manda cabeçalho mesmo assim
      // (formato K-line de byte único, não CAN — esse carro não usa CAN).
      final result = parseStandardObd2Response(
        '48 6B 11 41 0C 1F 40\r\n>',
        expectedPid: 0x0C,
      );

      expect(result, isNotNull);
      expect(result!.dataBytes, [0x1F, 0x40]);
    });

    test('retorna null para NO DATA', () {
      expect(
        parseStandardObd2Response('NO DATA\r\n>', expectedPid: 0x0C),
        isNull,
      );
    });

    test('retorna null para ERROR', () {
      expect(
        parseStandardObd2Response('ERROR\r\n>', expectedPid: 0x0C),
        isNull,
      );
    });

    test('retorna null para resposta vazia', () {
      expect(parseStandardObd2Response('\r\n>', expectedPid: 0x0C), isNull);
    });

    test('retorna null quando o PID ecoado não é o esperado', () {
      final result = parseStandardObd2Response(
        '41 0D 50\r\n>',
        expectedPid: 0x0C,
      );
      expect(result, isNull);
    });

    test('retorna null quando não há bytes de dados após o par 41+PID', () {
      final result = parseStandardObd2Response('41 0C\r\n>', expectedPid: 0x0C);
      expect(result, isNull);
    });
  });

  group('StandardObd2Formulas', () {
    test('rpm converte dois bytes', () {
      expect(StandardObd2Formulas.rpm([0x1F, 0x40]), 2000.0);
    });

    test('speed retorna o byte direto', () {
      expect(StandardObd2Formulas.speed([80]), 80.0);
    });

    test('temp converte byte único com offset -40', () {
      expect(StandardObd2Formulas.temp([130]), 90.0);
    });
  });
}
