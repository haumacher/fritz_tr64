import 'package:fritz_tr064/fritz_tr064.dart';

import 'config.dart';

void main() async {
  final client = await createClient();

  try {
    final myFritz = client.myFritz();
    if (myFritz == null) {
      print('X_AVM-DE_MyFritz service not available on this device.');
      return;
    }

    // MyFRITZ account info
    print('MyFRITZ info:');
    final info = await myFritz.getInfo();
    print('  Enabled:            ${info.enabled}');
    print('  DynDNS name:        ${info.dynDNSName}');
    print('  Port:               ${info.port}');
    print('  Device registered:  ${info.deviceRegistered}');
    print('  State:              ${info.state ?? '(none)'}');
    print('  Email:              ${info.email}');

    // Registered services
    final count = await myFritz.getNumberOfServices();
    print('\nRegistered services: $count');
    for (var i = 0; i < count; i++) {
      final svc = await myFritz.getServiceByIndex(i);
      print('  [$i] ${svc.name}');
      print('      Enabled:    ${svc.enabled}');
      print('      Scheme:     ${svc.scheme}');
      print('      Port:       ${svc.port}');
      print('      URL path:   ${svc.urlPath}');
      print('      Type:       ${svc.type}');
      print('      Host:       ${svc.hostName}');
      print('      MAC:        ${svc.macAddress}');
      print('      DynDNS:     ${svc.dynDnsLabel}');
      print('      IPv4:       ${svc.ipv4Addresses}');
      print('      IPv6:       ${svc.ipv6Addresses}');
      print('      IPv6 IIDs:  ${svc.ipv6InterfaceIDs}');
      print('      Fwd warn:   ${svc.ipv4ForwardingWarning?.name ?? '(none)'}');
      print('      Status:     ${svc.status ?? '(none)'}');
    }
  } finally {
    client.close();
  }
}
