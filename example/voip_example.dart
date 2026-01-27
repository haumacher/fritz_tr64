import 'package:flutter_tr64/flutter_tr64.dart';

import 'config.dart';

void main() async {
  final client = await createClient();

  try {
    final voip = client.voip();
    if (voip == null) {
      print('X_VoIP service not available on this device.');
      return;
    }

    // List all SIP clients
    final numberOfClients = await voip.getNumberOfClients();
    print('SIP clients: $numberOfClients');

    for (var i = 0; i < numberOfClients; i++) {
      final c = await voip.getClient3(i);
      print('  [$i] ${c.phoneName}');
      print('      ID:       ${c.clientId}');
      print('      Username: ${c.clientUsername}');
      print('      Registrar: ${c.clientRegistrar}:${c.clientRegistrarPort}');
      print('      Outgoing: ${c.outGoingNumber}');
      final incoming = c.inComingNumbers.map((n) => '${n.number} (${n.type.name})');
      print('      Incoming: ${incoming.join(', ')}');
      print('      Internal: ${c.internalNumber}');
      print('      External registration: ${c.externalRegistration}');
      print('      Delayed call notification: ${c.delayedCallNotification}');
    }
  } finally {
    client.close();
  }
}
