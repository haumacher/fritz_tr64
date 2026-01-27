import 'package:flutter_tr64/flutter_tr64.dart';

import 'config.dart';

void main() async {
  final client = await createClient();

  try {
    final remote = client.remoteAccess();
    if (remote == null) {
      print('X_AVM-DE_RemoteAccess service not available on this device.');
      return;
    }

    // List all available DDNS providers
    final providers = await remote.getDDNSProviders();
    print('DDNS providers: ${providers.length}');
    for (final p in providers) {
      final info = p.infoURL.isNotEmpty ? ' (${p.infoURL})' : '';
      print('  - ${p.providerName}$info');
    }

    // Look up current DDNS configuration
    print('\nDDNS info:');
    final ddns = await remote.getDDNSInfo();
    print('  Enabled:      ${ddns.enabled}');
    print('  Domain:       ${ddns.domain}');
    print('  Provider:     ${ddns.providerName}');
    print('  Mode:         ${ddns.mode}');
    print('  Username:     ${ddns.username}');
    print('  Update URL:   ${ddns.updateURL}');
    print('  Server IPv4:  ${ddns.serverIPv4}');
    print('  Server IPv6:  ${ddns.serverIPv6}');
    print('  Status IPv4:  ${ddns.statusIPv4 ?? '(none)'}');
    print('  Status IPv6:  ${ddns.statusIPv6 ?? '(none)'}');
  } finally {
    client.close();
  }
}
