import 'package:flutter_test/flutter_test.dart';
import 'package:palio_dashboard/core/obd2/marelli_protocol.dart';

void main() {
  group('parseMarelliResponse', () {
    test('parseia resposta válida e extrai bytes de dados', () {
      // header 48 6B 10, modo+pid 61 01, dados 1F 40, checksum 84
      final result = parseMarelliResponse('48 6B 10 61 01 1F 40 84\r\n>');

      expect(result, isNotNull);
      expect(result!.dataBytes, [0x1F, 0x40]);
      expect(MarelliFormulas.rpm(result.dataBytes), 2000.0);
    });

    test('retorna null para checksum inválido', () {
      final result = parseMarelliResponse('48 6B 10 61 01 1F 40 FF\r\n>');
      expect(result, isNull);
    });

    test('retorna null para header inesperado', () {
      final result = parseMarelliResponse('00 00 10 61 01 1F 40 84\r\n>');
      expect(result, isNull);
    });

    test('retorna null para NO DATA', () {
      expect(parseMarelliResponse('NO DATA\r\n>'), isNull);
    });

    test('retorna null para resposta vazia', () {
      expect(parseMarelliResponse('\r\n>'), isNull);
    });
  });

  group('MarelliFormulas', () {
    test('temp converte byte único com offset -40', () {
      expect(MarelliFormulas.temp([90]), 50.0);
    });

    test('tps converte para percentual', () {
      expect(MarelliFormulas.tps([255]), 100.0);
    });

    test('lambda converte para faixa 0-2', () {
      expect(MarelliFormulas.lambda([128, 0]), closeTo(2.0, 0.001));
    });

    test('ignition converte com offset -64', () {
      expect(MarelliFormulas.ignition([128]), 0.0);
    });
  });
}
