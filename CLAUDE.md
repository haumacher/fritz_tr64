# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

```bash
# Get dependencies
dart pub get

# Run all tests
dart test

# Run a single test file
dart test test/soap_test.dart

# Run tests with name filter
dart test --name "parses action response"

# Analyze code (linting)
dart analyze

# Format code
dart format .
```

## Running Examples

Examples require a `.env` file with Fritz!Box credentials (copy from `.env.example`):

```bash
dart run example/example.dart
dart run example/homeauto_example.dart
```

## Architecture

### Core Components

- **`Tr64Client`** (`lib/src/client.dart`): Main entry point. Handles HTTP connection, device discovery via `/tr64desc.xml`, and authenticated SOAP calls. Supports both HTTP (port 49000) and HTTPS with self-signed certificates (port 49443).

- **`Tr64Auth`** (`lib/src/auth.dart`): Implements TR-064 content-level digest authentication. Flow: InitChallenge → receive nonce/realm → compute MD5 response → ClientAuth. Nonces are cached for subsequent calls.

- **`SoapEnvelope`** (`lib/src/soap.dart`): Builds SOAP 1.1 envelopes with optional auth headers. `parseSoapResponse()` extracts response arguments and challenge info.

- **`DeviceDescription`** (`lib/src/device_description.dart`): Parses the TR-064 device description XML to discover available services.

- **`Tr64Service`** (`lib/src/service.dart`): Base class for service wrappers. Holds service description and provides `call()` method for SOAP actions.

### Service Implementation Pattern

Each TR-064 service (in `lib/src/services/`) follows the same pattern:
1. Data classes for response types with `fromArguments(Map<String, String>)` factory
2. Service class extending `Tr64Service` with typed methods that call SOAP actions
3. Extension on `Tr64Client` to create the service instance (e.g., `client.deviceInfo()`)

Example: `DeviceInfoService` wraps `urn:dslforum-org:service:DeviceInfo:1` and provides `getInfo()`, `getSecurityPort()`, `getDeviceLog()`.

### Adding a New Service

1. Create `lib/src/services/<service_name>.dart`
2. Define response data classes with `fromArguments()` factories
3. Create service class extending `Tr64Service` with typed action methods
4. Add `Tr64Client` extension to instantiate the service
5. Export from `lib/fritz_tr064.dart`
6. Add tests in `test/<service_name>_test.dart`

## Specs Directory

The `specs/` folder contains local copies of AVM's TR-064 service specification PDFs for implementation reference. These are not published to pub.dev.
