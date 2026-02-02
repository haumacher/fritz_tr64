# fritz_tr064

A Dart library for accessing FRITZ!Box routers via the
[TR-064 protocol](https://avm.de/service/schnittstellen/) (SOAP over HTTP
with content-level digest authentication).

> **Disclaimer** — This is **not** an official AVM product.
> FRITZ!Box, FRITZ!, MyFRITZ! and AVM are trademarks of
> [AVM GmbH](https://avm.de). All other trademarks are the property of
> their respective owners.

The library is available on [pub.dev](https://pub.dev/packages/fritz_tr064)

## Features

- Device discovery via TR-064 device description XML
- SOAP envelope building with XML-safe argument escaping
- TR-064 digest authentication (InitChallenge / ClientAuth flow)
- Second-factor authentication support (button press, DTMF)
- Typed service wrappers with Dart enums and data classes

## Getting started

```dart
import 'package:fritz_tr064/fritz_tr064.dart';

void main() async {
  final client = Tr64Client(
    host: 'fritz.box',
    userId: 'admin',
    password: 'secret',
  );

  await client.init();

  final info = client.deviceInfo()!;
  final device = await info.getInfo();
  print('Model: ${device.modelName}, firmware ${device.softwareVersion}');
}
```

## Implementation status

The table below lists all TR-064 services published on the
[AVM interface page](https://fritz.com/pages/schnittstellen).
Checked entries are implemented in this library.

### WAN

| Service | Status |
|---------|--------|
| WANIPConnection | |
| WANPPPConnection | |
| WANFiber | |
| WANCommonInterfaceConfig | |
| WANEthernetLinkConfig | |
| WANDSLInterfaceConfig | |
| WANDSLLinkConfig | |
| X_AVM-DE_WANMobileConnection | |
| X_AVM-DE_Speedtest | |
| X_AVM-DE_RemoteAccess | :white_check_mark: |
| X_AVM-DE_MyFritz | :white_check_mark: |
| X_AVM-DE_HostFilter | |
| Layer3Forwarding | |

### Telephony

| Service | Status |
|---------|--------|
| X_AVM-DE_OnTel | :white_check_mark: |
| X_AVM-DE_TAM | :white_check_mark: |
| X_VoIP | :white_check_mark: |

### Home network

| Service | Status |
|---------|--------|
| LanDeviceHosts | |
| WLANConfiguration | |
| LANHostConfigManagement | |
| LANEthernetInterfaceConfig | |
| X_AVM-DE_Dect | |
| X_AVM-DE_Media | |
| X_AVM-DE_Homeauto | :white_check_mark: |
| X_AVM-DE_Homeplug | :white_check_mark: |

### Storage / NAS

| Service | Status |
|---------|--------|
| X_AVM-DE_Storage | |
| X_AVM-DE_UPnP | |
| X_AVM-DE_WebDAV | |
| X_AVM-DE_Filelinks | |

### System

| Service | Status |
|---------|--------|
| DeviceInfo | :white_check_mark: |
| DeviceConfig | |
| LANConfigSecurity | :white_check_mark: |
| X_AVM-DE_AppSetup | :white_check_mark: |
| ManagementService | |
| X_AVM-DE_USPController | |
| X_AVM-DE_Auth | :white_check_mark: |
| Time | |
| UserInterface | |
