import 'package:flutter_tr64/flutter_tr64.dart';

import 'config.dart';

void main() async {
  final client = await createClient();

  try {
    final homePlug = client.homePlug();
    if (homePlug == null) {
      print('X_AVM-DE_Homeplug service not available on this device.');
      return;
    }

    final count = await homePlug.getNumberOfDeviceEntries();
    print('HomePlug devices: $count');

    for (var i = 0; i < count; i++) {
      final entry = await homePlug.getGenericDeviceEntry(i);
      print('  [$i] ${entry.name} (${entry.model})');
      print('      MAC:              ${entry.macAddress}');
      print('      Active:           ${entry.active}');
      print('      Update available: ${entry.updateAvailable}');
      print('      Update result:    ${entry.updateSuccessful ?? '(none)'}');
    }
  } finally {
    client.close();
  }
}
