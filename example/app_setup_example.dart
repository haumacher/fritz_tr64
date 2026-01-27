import 'dart:math';

import 'package:fritz_tr064/fritz_tr064.dart';

import 'config.dart';

String _randomPassword(int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rng = Random.secure();
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}

void main() async {
  final client = await createClient();

  try {
    final appSetup = client.appSetup();
    if (appSetup == null) {
      print('X_AVM-DE_AppSetup service not available on this device.');
      return;
    }

    // Parameter constraints
    print('Parameter constraints:');
    final info = await appSetup.getInfo();
    print('  AppId:           ${info.minCharsAppId}-${info.maxCharsAppId} chars');
    print('  AppDisplayName:  ${info.minCharsAppDisplayName}-${info.maxCharsAppDisplayName} chars');
    print('  AppUsername:     ${info.minCharsAppUsername}-${info.maxCharsAppUsername} chars');
    print('  AppPassword:     ${info.minCharsAppPassword}-${info.maxCharsAppPassword} chars');
    print('  IPSec ID:        ${info.minCharsIPSecIdentifier}-${info.maxCharsIPSecIdentifier} chars');
    print('  IPSec PSK:       ${info.minCharsIPSecPreSharedKey}-${info.maxCharsIPSecPreSharedKey} chars');
    print('  Xauth user:      ${info.minCharsIPSecXauthUsername}-${info.maxCharsIPSecXauthUsername} chars');
    print('  Xauth pass:      ${info.minCharsIPSecXauthPassword}-${info.maxCharsIPSecXauthPassword} chars');
    print('  Filter:          ${info.minCharsFilter}-${info.maxCharsFilter} chars');

    // Current access rights
    print('\nAccess rights:');
    final config = await appSetup.getConfig();
    print('  Config:          ${config.configRight ?? '(none)'}');
    print('  App:             ${config.appRight ?? '(none)'}');
    print('  NAS:             ${config.nasRight ?? '(none)'}');
    print('  Phone:           ${config.phoneRight ?? '(none)'}');
    print('  Dial:            ${config.dialRight ?? '(none)'}');
    print('  Home automation: ${config.homeautoRight ?? '(none)'}');
    print('  Internet rights: ${config.internetRights}');
    print('  From internet:   ${config.accessFromInternet}');

    // Remote access info
    print('\nRemote access info:');
    final remote = await appSetup.getAppRemoteInfo();
    print('  Subnet mask:     ${remote.subnetMask}');
    print('  IP address:      ${remote.ipAddress}');
    print('  External IPv4:   ${remote.externalIPAddress}');
    print('  External IPv6:   ${remote.externalIPv6Address}');
    print('  DDNS enabled:    ${remote.remoteAccessDDNSEnabled}');
    print('  DDNS domain:     ${remote.remoteAccessDDNSDomain}');
    print('  MyFRITZ enabled: ${remote.myFritzDynDNSEnabled}');
    print('  MyFRITZ name:    ${remote.myFritzDynDNSName}');
    // Register an app with phone access
    final password = _randomPassword(16);
    print('\nRegistering app "TestTR64"...');
    await appSetup.registerApp(
      appId: 'TestTR64',
      appDisplayName: 'TestTR64',
      appDeviceMAC: '',
      appUsername: 'testtr64user',
      appPassword: password,
      appRight: AppRight.no,
      nasRight: AppRight.no,
      phoneRight: AppRight.rw,
      homeautoRight: AppRight.no,
      appInternetRights: false,
    );
    print('  Registered successfully.');
    print('  Username: testtr64user');
    print('  Password: $password');

    // Connect with app credentials and retrieve the call log
    final env = loadEnv('.env');
    final appClient = Tr64Client(
      host: env['FRITZBOX_HOST']!,
      username: 'testtr64user',
      password: password,
    );
    try {
      await appClient.connect();

      final onTel = appClient.onTel();
      if (onTel == null) {
        print('\nX_AVM-DE_OnTel service not available.');
      } else {
        final entries = await onTel.getCallListEntries(max: 10);
        print('\nCall log (first ${entries.length} entries):');
        for (final entry in entries) {
          print('  ${entry.date}  ${entry.type?.name ?? '?'}'
              '  ${entry.name.isNotEmpty ? entry.name : entry.caller}'
              '  -> ${entry.called}'
              '  (${entry.duration})');
        }
      }
    } finally {
      appClient.close();
    }
  } finally {
    client.close();
  }
}
