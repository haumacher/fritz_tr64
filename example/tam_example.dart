import 'package:flutter_tr64/flutter_tr64.dart';

import 'config.dart';

void main() async {
  final client = await createClient();

  try {
    final tam = client.tam();
    if (tam == null) {
      print('X_AVM-DE_TAM service not available on this device.');
      return;
    }

    // List all configured answering machines
    final tamList = await tam.getTAMList();
    print('TAM running: ${tamList.tamRunning}');
    print('Capacity: ${tamList.capacity} seconds');
    print('Answering machines: ${tamList.items.length}\n');

    for (final item in tamList.items) {
      print('--- ${item.name} (index ${item.index}) ---');
      print('Display: ${item.display}');
      print('Enabled: ${item.enable}');

      // Fetch detailed info
      final info = await tam.getInfo(item.index);
      print('Mode: ${info.mode}');
      print('Ring seconds: ${info.ringSeconds}');
      print('Phone numbers: ${info.phoneNumbers.isEmpty ? '(all)' : info.phoneNumbers}');

      // List recorded messages
      final messages = await tam.getMessages(item.index);
      if (messages.isEmpty) {
        print('Messages: none');
      } else {
        print('Messages: ${messages.length}');
        for (final msg in messages) {
          final status = msg.isNew ? 'NEW' : 'read';
          final caller = msg.name.isNotEmpty ? msg.name : msg.number;
          print('  [$status] ${msg.date} - $caller (${msg.duration}s)');
        }
      }
      print('');
    }
  } finally {
    client.close();
  }
}
