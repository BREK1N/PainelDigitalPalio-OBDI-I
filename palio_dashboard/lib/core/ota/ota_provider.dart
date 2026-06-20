import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ota_installer.dart';
import 'ota_service.dart';

final otaServiceProvider = Provider<OtaService>((ref) => OtaService());

final otaInstallerProvider = Provider<OtaInstaller>((ref) => OtaInstaller());
