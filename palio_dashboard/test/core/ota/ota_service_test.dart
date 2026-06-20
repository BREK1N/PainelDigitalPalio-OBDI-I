import 'package:flutter_test/flutter_test.dart';
import 'package:palio_dashboard/core/ota/ota_service.dart';

void main() {
  group('isNewerVersion', () {
    test('detecta versão major mais nova', () {
      expect(isNewerVersion(latest: 'v2.0.0', current: '1.0.0'), isTrue);
    });

    test('detecta versão minor mais nova', () {
      expect(isNewerVersion(latest: 'v1.2.0', current: '1.1.5'), isTrue);
    });

    test('detecta versão patch mais nova', () {
      expect(isNewerVersion(latest: 'v1.0.1', current: '1.0.0'), isTrue);
    });

    test('retorna false para mesma versão', () {
      expect(isNewerVersion(latest: 'v1.0.0', current: '1.0.0'), isFalse);
    });

    test('retorna false quando a atual é mais nova', () {
      expect(isNewerVersion(latest: 'v1.0.0', current: '1.2.0'), isFalse);
    });

    test('ignora sufixo de build number', () {
      expect(isNewerVersion(latest: 'v1.0.0', current: '1.0.0+5'), isFalse);
    });

    test('funciona sem prefixo "v"', () {
      expect(isNewerVersion(latest: '1.3.0', current: '1.2.9'), isTrue);
    });
  });
}
