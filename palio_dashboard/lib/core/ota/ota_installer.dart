import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

/// Abre o APK baixado para instalação. No Android 8+, requer que o usuário
/// tenha autorizado "Instalar de fontes desconhecidas" para este app — se a
/// permissão faltar, retorna false para que a UI oriente o usuário.
class OtaInstaller {
  Future<bool> install(String apkPath) async {
    if (!await _ensureInstallPermission()) return false;

    final result = await OpenFile.open(apkPath);
    return result.type == ResultType.done;
  }

  Future<bool> _ensureInstallPermission() async {
    final status = await Permission.requestInstallPackages.status;
    if (status.isGranted) return true;

    final requested = await Permission.requestInstallPackages.request();
    return requested.isGranted;
  }

  /// Abre as configurações do sistema para o usuário habilitar manualmente
  /// a instalação de fontes desconhecidas para este app.
  Future<void> openInstallSettings() => openAppSettings();
}
