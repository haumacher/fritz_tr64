import 'dart:io';

import 'package:flutter_tr64/flutter_tr64.dart';

/// Reads a `.env` file and returns a map of key-value pairs.
/// Skips blank lines and comments (lines starting with `#`).
Map<String, String> _loadEnv(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Error: .env file not found at "$path".');
    stderr.writeln('Copy .env.example to .env and fill in your Fritz!Box credentials.');
    exit(1);
  }

  final env = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx < 0) continue;
    final key = trimmed.substring(0, idx).trim();
    final value = trimmed.substring(idx + 1).trim();
    env[key] = value;
  }
  return env;
}

void main() async {
  final env = _loadEnv('.env');

  const requiredKeys = ['FRITZBOX_HOST', 'FRITZBOX_USERNAME', 'FRITZBOX_PASSWORD'];
  final missing = requiredKeys.where((k) => !env.containsKey(k) || env[k]!.isEmpty).toList();
  if (missing.isNotEmpty) {
    stderr.writeln('Error: missing required .env keys: ${missing.join(', ')}');
    stderr.writeln('See .env.example for the expected format.');
    exit(1);
  }

  // Create a client for your Fritz!Box
  final client = Tr64Client(
    host: env['FRITZBOX_HOST']!,
    username: env['FRITZBOX_USERNAME']!,
    password: env['FRITZBOX_PASSWORD']!,
  );

  try {
    // Connect: fetches and parses the device description
    await client.connect();

    print('Connected! Found ${client.description!.allServices.length} services.');

    // Use the DeviceInfo service
    final deviceInfo = client.deviceInfo();
    if (deviceInfo != null) {
      final info = await deviceInfo.getInfo();
      print('Model: ${info.modelName}');
      print('Software: ${info.softwareVersion}');
      print('Serial: ${info.serialNumber}');
      print('Uptime: ${info.upTime} seconds');
    }

    // Use the OnTel service to list phonebooks
    final onTel = client.onTel();
    if (onTel != null) {
      final phonebookIds = await onTel.getPhonebookList();
      final totalEntries = await onTel.getNumberOfEntries();
      print('Phonebooks: $phonebookIds ($totalEntries total entries)');
      for (final id in phonebookIds) {
        final phonebook = await onTel.getPhonebook(id);
        print('  [$id] ${phonebook.name} (${phonebook.url})');
      }
    }

    // Or call any service action generically
    final result = await client.call(
      serviceType: 'urn:dslforum-org:service:DeviceInfo:1',
      controlUrl: '/upnp/control/deviceinfo',
      actionName: 'GetSecurityPort',
    );
    print('Security port: ${result['NewSecurityPort']}');
  } finally {
    client.close();
  }
}
