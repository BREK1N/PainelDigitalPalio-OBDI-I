import 'package:flutter_test/flutter_test.dart';
import 'package:palio_dashboard/core/obd2/dtc_decoder.dart';

void main() {
  group('decodeDtcBytes', () {
    test('decodifica P0300', () {
      // P=00, primeiro dígito 0, segundo 3 -> A = 0000 0011 = 0x03
      // terceiro 0, quarto 0 -> B = 0x00
      final codes = decodeDtcBytes([0x03, 0x00]);
      expect(codes, ['P0300']);
    });

    test('decodifica múltiplos códigos e ignora pares zerados', () {
      final codes = decodeDtcBytes([0x03, 0x00, 0x00, 0x00, 0x01, 0x71]);
      expect(codes, ['P0300', 'P0171']);
    });

    test('lista vazia para nenhuma falha', () {
      expect(decodeDtcBytes([0x00, 0x00]), isEmpty);
    });

    test('decodifica letra C (chassis)', () {
      // C=01 -> bits 7-6 = 01 -> A = 0100 0000 = 0x40
      final codes = decodeDtcBytes([0x40, 0x00]);
      expect(codes, ['C0000']);
    });
  });

  group('describeDtc', () {
    test('retorna descrição conhecida', () {
      expect(describeDtc('P0300'), contains('combustão'));
    });

    test('retorna fallback para código desconhecido', () {
      expect(describeDtc('P9999'), 'Descrição não disponível');
    });
  });
}
