import 'package:fritz_tr064/fritz_tr064.dart';

import 'config.dart';

void main() async {
  final client = await createClient();

  try {
    // Use the OnTel service to list phonebooks
    final onTel = client.onTel();
    if (onTel != null) {
      final phonebookIds = await onTel.getPhonebookList();
      final onlineCount = await onTel.getNumberOfEntries();
      final localCount = phonebookIds.length - onlineCount;
      print('Phonebooks: ${phonebookIds.length} '
          '($localCount local, $onlineCount online)');

      // All phonebooks by ID (works for both local and online)
      for (var i = 0; i < phonebookIds.length; i++) {
        final id = phonebookIds[i];
        final isOnline = i >= localCount;
        final pb = await onTel.getPhonebook(id);
        print('  [$id] ${pb.name} (${isOnline ? 'online' : 'local'})');
        print('       URL: ${pb.url}');
        if (pb.extraId.isNotEmpty) {
          print('       Extra ID: ${pb.extraId}');
        }

        // Online phonebooks have additional sync info (1-based index)
        if (isOnline) {
          final onlineIndex = i - localCount + 1;
          final online = await onTel.getInfoByIndex(onlineIndex);
          print('       Online index: $onlineIndex');
          print('       Service ID: ${online.serviceId}');
          print('       Sync enabled: ${online.enable}');
          print('       Sync URL: ${online.url}');
          print('       Username: ${online.username}');
          print('       Status: ${online.status}');
          if (online.lastConnect.isNotEmpty) {
            print('       Last sync: ${online.lastConnect}');
          }
        }
      }

      // Read the first 3 entries from the first phonebook
      if (phonebookIds.isNotEmpty) {
        final firstId = phonebookIds.first;
        print('First 3 entries from phonebook $firstId:');
        for (var i = 0; i < 3; i++) {
          try {
            final entry = await onTel.getPhonebookEntry(firstId, i);
            final nums = entry.numbers.map((n) => '${n.type.name}:${n.number}');
            print('  [$i] ${entry.name} — ${nums.join(', ')}');
          } on SoapFaultException {
            break;
          }
        }
      }

      // Ensure a "TestTR64" phonebook exists with a "Max Mustermann" contact
      const testBookName = 'TestTR64';
      int? testBookId;

      // Check whether a phonebook named "TestTR64" already exists
      for (final id in phonebookIds) {
        final pb = await onTel.getPhonebook(id);
        if (pb.name == testBookName) {
          testBookId = id;
          break;
        }
      }

      if (testBookId != null) {
        print('Phonebook "$testBookName" already exists (ID $testBookId).');
      } else {
        print('Phonebook "$testBookName" not found — creating it...');
        await onTel.addPhonebook(testBookName);

        // Re-fetch the list and find the new ID
        final updatedIds = await onTel.getPhonebookList();
        for (final id in updatedIds) {
          final pb = await onTel.getPhonebook(id);
          if (pb.name == testBookName) {
            testBookId = id;
            break;
          }
        }
        print('Created phonebook "$testBookName" (ID $testBookId).');
      }

      // Call barring: fetch all entries and print the first 3
      final barringEntries = await onTel.getCallBarringEntries();
      print('Call barring entries: ${barringEntries.length}');
      for (var i = 0; i < barringEntries.length && i < 3; i++) {
        final entry = barringEntries[i];
        final nums = entry.numbers.map((n) => '${n.type.name}:${n.number}');
        print('  [$i] ${entry.name} — ${nums.join(', ')}');
      }

      // Add a call barring entry for +49123456789
      const barringNumber = '+49123456789';
      print('Adding call barring for $barringNumber...');
      final barringEntry = PhonebookEntry(
        name: 'Blocked Number',
        numbers: [PhoneNumber(number: barringNumber, type: PhoneNumberType.home)],
      );
      final barringUid = await onTel.setCallBarringEntry(barringEntry);
      print('Added call barring (uniqueId $barringUid).');

      // Remove the call barring entry we just created
      print('Removing call barring for $barringNumber...');
      await onTel.deleteCallBarringEntryUID(barringUid);
      print('Removed call barring (uniqueId $barringUid).');

      // Check whether "Max Mustermann" already exists in that phonebook
      if (testBookId != null) {
        var found = false;
        for (var i = 0;; i++) {
          try {
            final entry = await onTel.getPhonebookEntry(testBookId, i);
            if (entry.name == 'Max Mustermann') {
              print('Contact "Max Mustermann" already exists (entry $i).');
              found = true;
              break;
            }
          } on SoapFaultException {
            break; // no more entries
          }
        }

        if (!found) {
          print('Contact "Max Mustermann" not found — adding it...');
          final entry = PhonebookEntry(
            name: 'Max Mustermann',
            numbers: [PhoneNumber(number: '+490123456789', type: PhoneNumberType.home)],
          );
          final uid = await onTel.setPhonebookEntryUID(testBookId, entry);
          print('Added "Max Mustermann" (uniqueId $uid).');
        }
      }

      // Retrieve and print the last 10 calls
      print('\nLast 10 calls:');
      final calls = await onTel.getCallListEntries(max: 10);
      if (calls.isEmpty) {
        print('  (no calls)');
      } else {
        for (final c in calls) {
          final typeLabel = switch (c.type) {
            CallType.incoming => 'incoming',
            CallType.missed => 'MISSED',
            CallType.outgoing => 'outgoing',
            CallType.activeIncoming => 'active in',
            CallType.rejected => 'rejected',
            CallType.activeOutgoing => 'active out',
            null => '?',
          };
          final who = c.name.isNotEmpty ? c.name : (c.caller.isNotEmpty ? c.caller : c.called);
          print('  [$typeLabel] ${c.date}  $who  (${c.duration})  via ${c.device}');
        }
      }
    }
  } finally {
    client.close();
  }
}
