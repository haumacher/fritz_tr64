import 'package:flutter_tr64/flutter_tr64.dart';

import 'config.dart';

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
  } finally {
    client.close();
  }
}
