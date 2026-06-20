import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:palio_dashboard/core/ota/ota_provider.dart';
import 'package:palio_dashboard/core/ota/ota_service.dart';
import 'package:palio_dashboard/features/dashboard/dashboard_provider.dart';
import 'package:palio_dashboard/main.dart';
import 'package:palio_dashboard/shared/models/obd_data_model.dart';

class _NoUpdateOtaService extends OtaService {
  @override
  Future<OtaUpdateInfo?> checkForUpdate() async => null;
}

void main() {
  testWidgets('PalioDash renders dashboard without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          obdDataProvider.overrideWith(
            (ref) => Stream.value(OBDDataModel.empty()),
          ),
          otaServiceProvider.overrideWithValue(_NoUpdateOtaService()),
        ],
        child: const PalioDashApp(),
      ),
    );
    await tester.pump();
    // Deixa o timer de checagem automática de OTA (5s) disparar e resolver.
    await tester.pump(const Duration(seconds: 6));

    expect(find.text('RPM'), findsOneWidget);
  });
}
