import 'dart:io';

import 'package:fritz_tr064/fritz_tr064.dart';

/// Reads a `.env` file and returns a map of key-value pairs.
/// Skips blank lines and comments (lines starting with `#`).
Map<String, String> loadEnv(String path) {
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

/// Loads `.env`, validates required keys, creates a [Tr64Client], and connects.
Future<Tr64Client> createClient() async {
  final env = loadEnv('.env');

  const requiredKeys = ['FRITZBOX_HOST', 'FRITZBOX_USERNAME', 'FRITZBOX_PASSWORD'];
  final missing = requiredKeys.where((k) => !env.containsKey(k) || env[k]!.isEmpty).toList();
  if (missing.isNotEmpty) {
    stderr.writeln('Error: missing required .env keys: ${missing.join(', ')}');
    stderr.writeln('See .env.example for the expected format.');
    exit(1);
  }

  final client = Tr64Client(
    host: env['FRITZBOX_HOST']!,
    username: env['FRITZBOX_USERNAME']!,
    password: env['FRITZBOX_PASSWORD']!,
  );

  await client.connect();
  return client;
}
