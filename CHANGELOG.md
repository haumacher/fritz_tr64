# Changelog

All notable changes to this project will be documented in this file.

## 0.1.0

Initial release.

### Added

- TR-064 client with device discovery via `/tr64desc.xml`
- SOAP envelope building with XML-safe argument escaping
- Content-level digest authentication (InitChallenge / ClientAuth flow)
- HTTPS support with self-signed certificate handling
- Service implementations:
  - DeviceInfo
  - X_AVM-DE_Auth
  - X_AVM-DE_AppSetup
  - X_AVM-DE_RemoteAccess
  - X_AVM-DE_MyFritz
  - X_AVM-DE_OnTel
  - X_AVM-DE_TAM
  - X_VoIP
  - X_AVM-DE_Homeauto
  - X_AVM-DE_Homeplug
