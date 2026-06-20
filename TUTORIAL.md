# Tutorial — PalioDash

Este tutorial cobre três caminhos: instalar o APK pronto, compilar do zero (inclusive sem Android Studio), e usar o app (celular + PC).

## 1. Instalar o APK pronto (mais rápido)

1. Baixe o arquivo `.apk` correspondente ao processador do seu celular em [`releases/`](releases/):
   - A maioria dos celulares modernos é `arm64-v8a`.
   - Celulares antigos (32 bits) usam `armeabi-v7a`.
2. Transfira o arquivo para o celular (cabo, Bluetooth, Drive, etc.) e abra-o pelo gerenciador de arquivos.
3. Se aparecer aviso de "fontes desconhecidas", toque em **Configurações** → ative a permissão para o app usado para abrir o arquivo → volte e instale.
4. Abra o PalioDash. Em **Configurações**, pareie o celular com o adaptador OBD2 Bluetooth (ELM327) pelas configurações de Bluetooth do Android primeiro, depois selecione o dispositivo na lista dentro do app.

## 2. Compilar do código-fonte

### 2.1 Pré-requisitos

- Windows 10/11
- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (canal stable)
- Java JDK 17 (pode ser o [Microsoft Build of OpenJDK](https://learn.microsoft.com/java/openjdk/download))
- Android SDK — **não precisa instalar o Android Studio completo**, basta o `cmdline-tools`:
  1. Baixe `commandlinetools-win-*_latest.zip` em https://developer.android.com/studio#command-tools
  2. Extraia para `C:\Users\<voce>\Android\sdk\cmdline-tools\latest\`
  3. Defina as variáveis de ambiente:
     ```powershell
     $env:JAVA_HOME = "C:\caminho\para\jdk-17"
     $env:ANDROID_HOME = "C:\Users\<voce>\Android\sdk"
     $env:PATH = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:PATH"
     ```
  4. Instale os pacotes necessários e aceite as licenças:
     ```powershell
     sdkmanager --sdk_root="$env:ANDROID_HOME" "platform-tools" "platforms;android-34" "build-tools;34.0.0"
     flutter config --android-sdk "$env:ANDROID_HOME"
     flutter doctor --android-licenses
     ```
  5. Confirme com `flutter doctor` — o item "Android toolchain" deve aparecer com `[✓]`.

### 2.2 Compilar o APK

```powershell
cd palio_dashboard
flutter pub get
flutter build apk --release --split-per-abi
```

O resultado fica em `palio_dashboard/build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (celulares modernos, recomendado)
- `app-armeabi-v7a-release.apk` (celulares 32 bits)
- `app-x86_64-release.apk` (emuladores)

> **Nota sobre `flutter_bluetooth_serial`:** esse pacote está sem manutenção desde 2021 e usa `jcenter()` (descontinuado) e `compileSdkVersion 30`, o que quebra com versões atuais do Gradle/AGP. Se o build falhar com erro de `jcenter()` ou de "AAR metadata", edite o arquivo `android/build.gradle` dentro do cache do pub (`%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_bluetooth_serial-0.4.0\android\build.gradle`):
> - troque `jcenter()` por `mavenCentral()`
> - adicione `namespace 'io.github.edufolly.flutterbluetoothserial'` dentro do bloco `android { }`
> - aumente `compileSdkVersion 30` para `compileSdkVersion 36`
>
> Esse patch é local ao cache do pub da sua máquina — se você limpar o cache (`flutter pub cache repair`) ou compilar em outra máquina, precisa reaplicar.

### 2.3 Rodar o PC Dashboard (Windows ou Web)

```powershell
cd palio_dashboard
flutter run -d windows   # requer Visual Studio com "Desktop development with C++"
# ou
flutter run -d chrome    # roda no navegador, sem dependências extras
```

No PC Dashboard, escolha o modo no topo da tela:
- **Simulação**: gera dados falsos (RPM, velocidade, temperatura) sem precisar do carro — ideal para testar a UI.
- **WebSocket (live)**: conecta no celular para ver os dados reais do OBD2 em tempo real.

## 3. Usando o sistema completo (celular + carro + PC)

1. **No celular**: conecte o adaptador ELM327 na porta OBD2 do carro (geralmente sob o volante), ligue a ignição, pareie o adaptador via Bluetooth do Android, abra o PalioDash e selecione o dispositivo em Configurações.
2. O app inicia a leitura dos PIDs automaticamente e mostra os gauges (RPM, velocidade, temperatura, etc.).
3. Para espelhar no PC: em Configurações do app, ative o **servidor WebSocket** — o app mostra o IP do celular, algo como `ws://192.168.0.x:8765`.
4. No PC Dashboard, selecione o modo **WebSocket (live)** e informe esse mesmo endereço. O PC passa a exibir os mesmos dados em tempo real.

## 4. Atualizações (OTA)

O app verifica automaticamente, 5 segundos após abrir, se existe uma versão mais nova publicada nas [Releases do GitHub](../../releases). Você também pode forçar a verificação manualmente em **Configurações → Verificar atualização**. Ao confirmar, o app baixa o novo APK e abre o instalador do Android.

Para publicar uma nova versão (uso interno/dev):

```powershell
# 1. Suba a versão em palio_dashboard/pubspec.yaml, ex: version: 1.1.0+2
git add .
git commit -m "release: v1.1.0"
git tag v1.1.0
git push origin main v1.1.0
```

O workflow em `.github/workflows/build_release.yml` builda o APK e cria a Release automaticamente.

## 5. Solução de problemas

| Problema | Causa provável | Solução |
|---|---|---|
| App não encontra o adaptador OBD2 | Adaptador não pareado | Pareie pelo Bluetooth do Android antes de abrir o app |
| PID retorna "NO DATA" sempre | Header/checksum do PID Marelli incorreto para sua ECU | Ajustar em `lib/core/obd2/pid_definitions.dart`, comparar com FiatECUScan |
| Erro `jcenter()` ao compilar | Pacote `flutter_bluetooth_serial` desatualizado | Ver nota na seção 2.2 |
| PC Dashboard não conecta via WebSocket | IP errado ou celular fora da mesma rede Wi-Fi | Confirme o IP exibido nas Configurações do app e que ambos estão na mesma rede |
| `flutter doctor` não reconhece o Android SDK | Variáveis de ambiente ou `flutter config --android-sdk` não configurados | Repita o passo 2.1.4 |
