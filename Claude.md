# PalioDash — Master Prompt Claude Code

## Visão geral do projeto

Você está desenvolvendo o **PalioDash**, um aplicativo Flutter multiplataforma para diagnóstico e monitoramento em tempo real de veículos Fiat Palio Fire Economy (motor 1.0 / 1.4 Flex) via OBD2 Bluetooth.

O projeto tem três entregáveis:
1. **App Android** — dashboard de 7 polegadas, landscape, conecta no adaptador OBD2 via Bluetooth Classic
2. **PC Dashboard** — Flutter Desktop + Web, recebe dados do celular via WebSocket OU simula dados localmente
3. **Sistema OTA** — app verifica GitHub Releases, baixa e instala APK sem intervenção manual

---

## Stack e dependências

### `pubspec.yaml` — dependências obrigatórias

```yaml
name: palio_dashboard
description: OBD2 dashboard para Fiat Palio Fire Economy — Marelli IAW
publish_to: 'none'
version: 1.0.0+1  # IMPORTANTE: o OTA compara este campo

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.19.0'

dependencies:
  flutter:
    sdk: flutter

  # Bluetooth
  flutter_bluetooth_serial: ^0.4.0   # Bluetooth Classic (SPP) — NÃO use flutter_blue (BLE)

  # HTTP / API
  dio: ^5.4.0                        # GitHub Releases API + download APK

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # UI / Gauges
  syncfusion_flutter_gauges: ^25.1.0  # Gauge RPM, velocidade, temperatura
  fl_chart: ^0.67.0                   # Gráficos de linha em tempo real
  google_fonts: ^6.2.1

  # OTA
  open_file: ^3.3.2                   # Abre o APK para instalação
  path_provider: ^2.1.2               # Caminho temporário para salvar APK
  package_info_plus: ^7.0.0           # Lê versão atual do app

  # WebSocket (PC viewer)
  web_socket_channel: ^2.4.0          # Client WebSocket (PC)
  # dart:io WebSocket server nativo — sem dependência extra (Android envia)

  # Persistência
  shared_preferences: ^2.2.3          # Config: device MAC salvo, unidades, tema

  # Permissões
  permission_handler: ^11.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.8
  riverpod_generator: ^2.4.0
```

### `android/app/build.gradle` — obrigatório para OTA

```groovy
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### `android/app/src/main/AndroidManifest.xml` — permissões obrigatórias

```xml
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28"/>

<!-- FileProvider para instalar APK no Android 7+ -->
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths"/>
</provider>
```

---

## Estrutura de arquivos obrigatória

```
lib/
├── main.dart
├── core/
│   ├── bluetooth/
│   │   ├── bt_manager.dart
│   │   └── bt_device_model.dart
│   ├── obd2/
│   │   ├── obd2_service.dart
│   │   ├── marelli_protocol.dart      ← ARQUIVO MAIS CRÍTICO
│   │   ├── pid_definitions.dart
│   │   └── dtc_decoder.dart
│   ├── ota/
│   │   ├── ota_service.dart
│   │   └── ota_installer.dart
│   └── server/
│       └── ws_server.dart
├── features/
│   ├── dashboard/
│   │   ├── dashboard_screen.dart
│   │   ├── dashboard_provider.dart
│   │   └── widgets/
│   │       ├── rpm_gauge.dart
│   │       ├── speed_gauge.dart
│   │       ├── temp_gauge.dart
│   │       ├── lambda_gauge.dart
│   │       └── pid_tile.dart
│   ├── dtc/
│   │   └── dtc_screen.dart
│   ├── settings/
│   │   └── settings_screen.dart
│   └── pc_viewer/
│       └── pc_dashboard_screen.dart
└── shared/
    ├── theme/
    │   └── app_theme.dart
    └── models/
        └── obd_data_model.dart
```

---

## Protocolo Marelli — especificação completa

### ECUs suportadas

| ECU | Motor | Protocolo base | Modo diagnóstico |
|-----|-------|----------------|-----------------|
| IAW 4AF | 1.0 Fire 8v (SOHC) | ISO 9141-2 | Fiat proprietário |
| IAW 4EF | 1.4 Fire 8v (Flex) | ISO 9141-2 | Fiat proprietário |
| IAW 59F | 1.0 Fire 8v (Flex) | ISO 9141-2 | Fiat proprietário |
| IAW 5AF | 1.4 Fire 16v | KWP2000 (ISO 14230) | Fiat proprietário |

### Sequência de inicialização ELM327

```
ATZ\r          → reset completo, aguarda "ELM327 v1.x"
ATE0\r         → desliga echo
ATL0\r         → desliga linefeeds
ATH1\r         → mostra headers (obrigatório para Marelli)
ATSP4\r        → ISO 9141-2 (para 4AF/4EF/59F)
               → use ATSP5 para IAW 5AF (KWP2000 slow init)
ATSI\r         → slow init 5-baud (inicializa a ECU)
ATAT2\r        → adaptive timing mode 2 (mais tolerante)
ATST96\r       → timeout 150ms (0x96 = 150 décimos de ms)
```

### PIDs Marelli proprietários — `pid_definitions.dart`

```dart
// ATENÇÃO: estes são PIDs do modo diagnóstico Fiat/Marelli,
// NÃO são PIDs OBD-II padrão (modo $01).
// O comando base é enviado no formato: [header] [tamanho] [modo] [PID] [checksum]

enum MarelliPid {
  rpm(
    command: '68 6A F1 21 01 C0',   // Fiat init + PID RPM
    name: 'RPM',
    unit: 'rpm',
    min: 0,
    max: 8000,
    formula: MarelliFormulas.rpm,
  ),
  speed(
    command: '68 6A F1 21 02 C1',
    name: 'Velocidade',
    unit: 'km/h',
    min: 0,
    max: 260,
    formula: MarelliFormulas.speed,
  ),
  coolantTemp(
    command: '68 6A F1 21 05 C4',
    name: 'Temp. motor',
    unit: '°C',
    min: -40,
    max: 150,
    formula: MarelliFormulas.temp,
  ),
  intakeTemp(
    command: '68 6A F1 21 0F CE',
    name: 'Temp. admissão',
    unit: '°C',
    min: -40,
    max: 120,
    formula: MarelliFormulas.temp,
  ),
  map(
    command: '68 6A F1 21 0B CA',
    name: 'MAP',
    unit: 'kPa',
    min: 0,
    max: 255,
    formula: MarelliFormulas.map,
  ),
  tps(
    command: '68 6A F1 21 11 D0',
    name: 'TPS',
    unit: '%',
    min: 0,
    max: 100,
    formula: MarelliFormulas.tps,
  ),
  lambda(
    command: '68 6A F1 21 24 E3',
    name: 'Lambda',
    unit: 'λ',
    min: 0.0,
    max: 2.0,
    formula: MarelliFormulas.lambda,
  ),
  injectionTime(
    command: '68 6A F1 21 66 A5',
    name: 'Injeção',
    unit: 'ms',
    min: 0,
    max: 30,
    formula: MarelliFormulas.injection,
  ),
  ignitionAdvance(
    command: '68 6A F1 21 0E CD',
    name: 'Avanço ignição',
    unit: '°',
    min: -64,
    max: 64,
    formula: MarelliFormulas.ignition,
  ),
  batteryVoltage(
    command: '68 6A F1 21 42 01',   // PID voltagem — verificar checksum
    name: 'Bateria',
    unit: 'V',
    min: 0,
    max: 20,
    formula: MarelliFormulas.voltage,
  ),
}
```

**ATENÇÃO sobre os PIDs acima:** Os headers e checksums dos comandos Marelli acima são aproximações baseadas no protocolo ISO 9141-2 com endereçamento Fiat. Os valores reais **devem ser validados** contra datasheets do IAW 4AF/4EF ou ferramentas como FiatECUScan. Implemente `MarelliFormulas` com as fórmulas de conversão documentadas (byte A, byte B → valor real).

### Fórmulas de conversão — `marelli_protocol.dart`

```dart
class MarelliFormulas {
  // RPM = (A * 256 + B) / 4
  static double rpm(List<int> bytes) => (bytes[0] * 256 + bytes[1]) / 4;

  // Velocidade = A (km/h direto)
  static double speed(List<int> bytes) => bytes[0].toDouble();

  // Temperatura = A - 40 (°C)
  static double temp(List<int> bytes) => (bytes[0] - 40).toDouble();

  // MAP = A (kPa)
  static double map(List<int> bytes) => bytes[0].toDouble();

  // TPS = A * 100 / 255 (%)
  static double tps(List<int> bytes) => bytes[0] * 100 / 255;

  // Lambda = (A * 256 + B) / 32768 * 2  (λ)
  static double lambda(List<int> bytes) =>
      (bytes[0] * 256 + bytes[1]) / 32768 * 2;

  // Injeção = (A * 256 + B) / 1000 (ms)
  static double injection(List<int> bytes) =>
      (bytes[0] * 256 + bytes[1]) / 1000;

  // Avanço ignição = A / 2 - 64 (°)
  static double ignition(List<int> bytes) => bytes[0] / 2 - 64;

  // Voltagem = A / 10 (V) — confirmar fator real
  static double voltage(List<int> bytes) => bytes[0] / 10;
}
```

### Parser de resposta ISO 9141-2

```dart
// Resposta típica do ELM327 para Marelli:
// "48 6B 10 61 01 XX XX CS\r\n>"
// onde:
//   48 6B 10 = header (source=ECU, dest=tester, modo)
//   61 01    = resposta positiva ao modo+PID
//   XX XX    = bytes de dados
//   CS       = checksum (XOR ou soma de todos os bytes)

List<int>? parseMarelliResponse(String raw) {
  // Remove prompt ">", espaços e newlines
  // Valida header de resposta (começa com "48 6B")
  // Extrai bytes de dados após "61 XX"
  // Valida checksum
  // Retorna null se inválido (timeout, "NO DATA", "ERROR")
}
```

---

## Bluetooth Manager — `bt_manager.dart`

```dart
// Use flutter_bluetooth_serial (Bluetooth Classic / SPP)
// NÃO use flutter_blue_plus (é BLE — adaptadores ELM327 baratos são Classic)

// Fluxo obrigatório:
// 1. BluetoothState.on → verificar estado
// 2. BluetoothDevice.bondedDevices → listar pareados
// 3. BluetoothConnection.toAddress(mac) → conectar
// 4. connection.input.listen() → stream de bytes brutos
// 5. Acumular bytes no buffer até receber '\r\n>' (fim de resposta ELM327)
// 6. Emitir String completa para o OBD2Service

// IMPORTANTE: o ELM327 é half-duplex — enviar comando, aguardar '>'
// antes de enviar o próximo. Implemente uma fila (Queue) de comandos.
// Timeout por comando: 300ms (ATST default) — ajustável em settings.

// Salvar último MAC em SharedPreferences para reconectar automaticamente.
```

---

## Dashboard UI — especificação visual

### Layout 7 polegadas landscape (1024×600 ou 800×480)

```
┌─────────────────────────────────────────────────────────┐
│  [RPM gauge grande]  [SPEED gauge grande]  [TEMP gauge] │
│                                                         │
│  [TPS %] [MAP kPa] [Lambda λ] [Inj ms] [Avanço °]     │
│                                                         │
│  [Gráfico RPM linha - últimos 60s]    [Status BT] [OTA] │
└─────────────────────────────────────────────────────────┘
```

### Tema visual obrigatório

- Fundo: **preto** (`Color(0xFF0A0A0A)`) — para legibilidade no sol
- Gauges RPM/Speed: estilo automotivo, fundo escuro, ponteiro laranja/vermelho
- Texto: branco com opacidade para dados secundários
- Alerta temperatura alta (>100°C): gauge fica vermelho + vibração
- Fonte: `GoogleFonts.rajdhani()` ou `GoogleFonts.orbitron()` — estilo digital
- Sem AppBar padrão — fullscreen landscape com `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)`

### Gauge RPM — `rpm_gauge.dart`

```dart
// Use SfRadialGauge do syncfusion_flutter_gauges
// Ranges:
//   0–1000: cinza (idle)
//   1000–3000: verde
//   3000–5500: amarelo
//   5500–7000: vermelho (zona de perigo — Palio Fire 1.0 limita ~6500rpm)
// Ponteiro animado com animationDuration: 100ms
// Valor numérico grande no centro do gauge
```

---

## OTA Service — `ota_service.dart`

```dart
// Endpoint GitHub Releases API:
// GET https://api.github.com/repos/SEU_USUARIO/palio_dashboard/releases/latest
//
// Resposta JSON relevante:
// {
//   "tag_name": "v1.2.0",
//   "assets": [
//     {
//       "name": "palio_dashboard.apk",
//       "browser_download_url": "https://github.com/.../palio_dashboard.apk"
//     }
//   ]
// }
//
// Lógica:
// 1. Lê versão atual via PackageInfo.fromPlatform()
// 2. Compara com tag_name da release (semver)
// 3. Se tag_name > versão atual → notifica usuário com dialog
// 4. Usuário confirma → download com Dio + ProgressIndicator
// 5. Salva em getTemporaryDirectory()/update.apk
// 6. Abre com OpenFile.open() → Android instala via FileProvider
//
// Verificar OTA automaticamente:
//   - Na abertura do app (com delay de 5s)
//   - Botão manual em Settings
//
// NUNCA forçar atualização — sempre perguntar ao usuário.

const String githubOwner = 'SEU_USUARIO';          // ← substituir
const String githubRepo  = 'palio_dashboard';       // ← substituir
```

---

## WebSocket Server (Android → PC) — `ws_server.dart`

```dart
// O celular Android roda um servidor WebSocket simples em dart:io
// O PC/web conecta como cliente

// Android (servidor):
import 'dart:io';

class WsServer {
  HttpServer? _server;
  final Set<WebSocket> _clients = {};

  Future<void> start({int port = 8765}) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.transform(WebSocketTransformer()).listen((ws) {
      _clients.add(ws);
      ws.done.then((_) => _clients.remove(ws));
    });
  }

  // Chama isso a cada novo dado do OBD2:
  void broadcast(OBDDataModel data) {
    final json = jsonEncode(data.toJson());
    for (final ws in _clients) {
      ws.add(json);
    }
  }

  Future<void> stop() async => _server?.close();
}

// IP do celular é exibido em Settings para o usuário digitar no PC
// Formato: ws://192.168.x.x:8765
```

---

## PC Dashboard — `pc_dashboard_screen.dart`

```dart
// Dois modos, selecionáveis em runtime:
//
// MODO 1 — WebSocket live:
//   Conecta em ws://IP_CELULAR:8765
//   Recebe OBDDataModel em JSON
//   Mesma UI do Android (gauges idênticos)
//
// MODO 2 — Simulação local:
//   Gera dados fake com timer periódico
//   RPM: senoide entre 800–4000 rpm
//   Velocidade: rampa 0–120 km/h
//   Temperatura: sobe de 20°C até 90°C em 60s
//   Útil para desenvolvimento sem carro
//
// MODO 3 — Replay de log:
//   Lê arquivo JSON gravado pelo Android (feature futura)
//   Reproduz em velocidade 1x ou 2x

// Para selecionar modo: dropdown no topo do PC dashboard
```

---

## Modelo de dados compartilhado — `obd_data_model.dart`

```dart
@freezed  // ou implemente manualmente sem freezed
class OBDDataModel {
  final double rpm;
  final double speedKmh;
  final double coolantTempC;
  final double intakeTempC;
  final double mapKpa;
  final double tpsPercent;
  final double lambda;
  final double injectionMs;
  final double ignitionDeg;
  final double batteryV;
  final DateTime timestamp;
  final List<String> activeDtcs;  // ex: ["P0300", "P0171"]
  final bool engineRunning;
  final ConnectionStatus btStatus;

  Map<String, dynamic> toJson();
  factory OBDDataModel.fromJson(Map<String, dynamic> json);
  factory OBDDataModel.empty();     // valores zerados para estado inicial
  factory OBDDataModel.simulated(); // dados fake para modo PC
}
```

---

## GitHub Actions — `.github/workflows/build_release.yml`

```yaml
name: Build & Release APK

on:
  push:
    tags:
      - 'v*'   # dispara em push de tag como v1.0.0, v1.2.3

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Build APK release
        run: flutter build apk --release --obfuscate --split-debug-info=debug_info/

      - name: Rename APK
        run: mv build/app/outputs/flutter-apk/app-release.apk palio_dashboard.apk

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: palio_dashboard.apk
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Como usar o CI/CD

```bash
# 1. Bumpar versão em pubspec.yaml: version: 1.2.0+2
# 2. Commit e push
git add .
git commit -m "release: v1.2.0"

# 3. Criar e enviar tag — isso dispara o build
git tag v1.2.0
git push origin v1.2.0

# O Actions vai:
# - buildar o APK em ~4 minutos
# - criar Release no GitHub automaticamente
# - o app detecta a nova versão e oferece download
```

---

## Ordem de implementação sugerida

Execute nesta sequência para ter algo testável cedo:

```
FASE 1 — Fundação (sem carro)
  [x] pubspec.yaml + estrutura de pastas
  [x] OBDDataModel + serialização JSON
  [x] Modo simulação no PC dashboard
  [x] UI básica com gauges (dados fake)
  [x] AppTheme dark automotivo

FASE 2 — Conectividade
  [x] BTManager — scan, conectar, stream de bytes
  [x] Fila de comandos AT (half-duplex)
  [x] Parser de resposta ISO 9141-2
  [x] Sequência de init do ELM327
  [x] PID loop para RPM + Velocidade + Temp

FASE 3 — Protocolo completo
  [x] Todos os PIDs Marelli (tabela acima)
  [x] Validação de checksum
  [x] Tratamento de "NO DATA" / timeout
  [x] DTC reader + decoder

FASE 4 — PC Viewer
  [x] WsServer no Android
  [x] Exibir IP do celular em Settings
  [x] PC client WebSocket
  [x] Modo simulação + modo live funcionando

FASE 5 — OTA
  [x] OtaService (check + download)
  [x] OtaInstaller (FileProvider + open_file)
  [x] Dialog de atualização com progresso
  [x] GitHub Actions workflow

FASE 6 — Polimento
  [x] Gráfico de linha RPM (fl_chart)
  [x] Tela DTC com descrições
  [x] Salvar configurações (SharedPrefs)
  [x] Reconexão automática BT
  [x] Teste no carro real — calibrar fórmulas Marelli
```

---

## Alertas e considerações críticas

### Sobre o protocolo Marelli
- Os **PIDs e headers proprietários Fiat/Marelli** precisam ser validados no carro real. Os valores neste documento são baseados em engenharia reversa documentada pela comunidade (FiatECUScan, MultiECUScan). Se uma resposta retornar "NO DATA", ajustar o header ou tentar o PID em modo OBD-II padrão (`01 XX`) como fallback.
- O IAW **5AF usa KWP2000** (ATSP5) — a sequência de init é diferente do 4AF/4EF/59F.
- Sempre implementar **timeout robusto** por PID. A ECU pode não responder a todos os PIDs.

### Sobre Bluetooth no Android
- Android 12+ exige permissão `BLUETOOTH_CONNECT` em runtime — implementar com `permission_handler`.
- Adaptadores ELM327 genéricos (baratos) são Bluetooth **Classic/SPP**, não BLE. Use `flutter_bluetooth_serial`.
- O dispositivo deve estar **pareado** antes de conectar — guiar usuário nas Settings se não estiver.

### Sobre OTA / instalação de APK
- Android 8+ exige que o usuário ative "Instalar de fontes desconhecidas" para este app específico — detectar com `permission_handler` e abrir as configurações se necessário.
- O `FileProvider` no `AndroidManifest.xml` é obrigatório para compartilhar o APK no Android 7+.
- Criar o arquivo `android/app/src/main/res/xml/file_paths.xml`.

### Sobre a UI de 7 polegadas
- Forçar landscape: `SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft])` no `main.dart`.
- Usar `LayoutBuilder` para adaptar o layout a diferentes resoluções (800×480 vs 1024×600).
- Todos os tamanhos de fonte/gauge em função da tela — nada hardcoded em pixels.