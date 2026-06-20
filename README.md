# PalioDash

Dashboard digital para diagnóstico e monitoramento em tempo real do **Fiat Palio Fire Economy** (motor 1.0 / 1.4 Flex, ECU Marelli IAW) via adaptador OBD2 Bluetooth.

O projeto tem três entregáveis, todos no mesmo código-base Flutter:

1. **App Android** — dashboard estilo painel automotivo (tela de 7", landscape), conecta no adaptador ELM327 via Bluetooth Classic (SPP) e lê os PIDs da ECU Marelli em tempo real.
2. **PC Dashboard** (Windows/Web) — replica a mesma UI recebendo dados do celular via WebSocket, ou roda em modo simulação (sem precisar do carro) para desenvolvimento/demonstração.
3. **Sistema OTA** — o app verifica releases no GitHub, baixa o APK novo e guia a instalação, sem precisar de loja de apps.

> Especificação completa do protocolo, PIDs, fórmulas e arquitetura está em [`Claude.md`](Claude.md).

## Estrutura do repositório

```
PainelDigitalPalio-OBDI-I/
├── Claude.md              # Especificação técnica completa do projeto
├── TUTORIAL.md            # Como compilar, instalar e usar o app
├── releases/               # APKs prontos para instalar (sem precisar compilar)
├── palio_dashboard/        # Projeto Flutter (app + dashboard PC + lógica OBD2)
└── .github/workflows/      # CI: build automático de APK ao criar uma tag
```

## Instalação rápida (sem compilar)

Baixe o APK mais recente na pasta [`releases/`](releases/) e instale no celular Android (é preciso permitir "instalar de fontes desconhecidas" para o navegador/gerenciador de arquivos usado).

Depois de instalado, o próprio app verifica atualizações futuras automaticamente via GitHub Releases.

## Compilando do código-fonte

Veja o passo a passo completo em [`TUTORIAL.md`](TUTORIAL.md), que cobre:

- Instalar Flutter + Android SDK (inclusive sem Android Studio)
- Compilar o APK para o celular
- Rodar o PC Dashboard (Windows/Web) em modo simulação ou conectado por WebSocket
- Conectar o celular ao adaptador OBD2 Bluetooth e configurar o WebSocket entre celular e PC

## Status do protocolo Marelli

Os PIDs proprietários Fiat/Marelli usados (RPM, velocidade, temperatura, MAP, TPS, lambda, etc.) foram implementados com base em engenharia reversa documentada pela comunidade (FiatECUScan/MultiECUScan) e **ainda precisam ser validados e calibrados no carro real**. Se algum PID retornar "NO DATA" persistentemente, ajuste o header/checksum em `lib/core/obd2/pid_definitions.dart`.

## Licença

Veja [`LICENSE`](LICENSE).
