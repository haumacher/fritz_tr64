import 'package:flutter_tr64/src/device_description.dart';
import 'package:flutter_tr64/src/services/on_tel.dart';
import 'package:test/test.dart';

ServiceDescription _fakeDescription() {
  return ServiceDescription(
    serviceType: 'urn:dslforum-org:service:X_AVM-DE_OnTel:1',
    serviceId: 'urn:X_AVM-DE_OnTel-com:serviceId:X_AVM-DE_OnTel1',
    controlUrl: '/upnp/control/x_contact',
    scpdUrl: '/x_contactSCPD.xml',
  );
}

const _contactXml = '''
<contact>
  <category>1</category>
  <person>
    <realName>Max Mustermann</realName>
    <imageURL>/download.lua?path=/var/fonpix/1.jpg</imageURL>
  </person>
  <telephony>
    <services>
      <email>max@example.com</email>
      <email>work@example.com</email>
    </services>
    <number type="home" quickdial="1" vanity="" prio="0">+4930123456</number>
    <number type="mobile" quickdial="" vanity="" prio="1">+491701234567</number>
  </telephony>
  <uniqueid>42</uniqueid>
</contact>
''';

const _minimalContactXml = '''
<contact>
  <person>
    <realName>Sparse Entry</realName>
  </person>
  <telephony>
    <services/>
  </telephony>
</contact>
''';

void main() {
  group('Phonebook', () {
    test('fromArguments parses all fields', () {
      final phonebook = Phonebook.fromArguments({
        'NewPhonebookURL': 'http://fritz.box/phonebook.xml',
        'NewPhonebookName': 'Telefonbuch',
        'NewPhonebookExtraID': '0',
      });

      expect(phonebook.url, 'http://fritz.box/phonebook.xml');
      expect(phonebook.name, 'Telefonbuch');
      expect(phonebook.extraId, '0');
    });

    test('fromArguments defaults to empty strings for missing keys', () {
      final phonebook = Phonebook.fromArguments({});

      expect(phonebook.url, '');
      expect(phonebook.name, '');
      expect(phonebook.extraId, '');
    });

    test('toString includes name and url', () {
      final phonebook = Phonebook(
        url: 'http://fritz.box/pb.xml',
        name: 'Main',
        extraId: '',
      );
      expect(phonebook.toString(), 'Phonebook(Main, http://fritz.box/pb.xml)');
    });
  });

  group('PhonebookEntry', () {
    test('fromXml parses all fields', () {
      final entry = PhonebookEntry.fromXml(_contactXml);

      expect(entry.name, 'Max Mustermann');
      expect(entry.uniqueId, 42);
      expect(entry.category, 1);
      expect(entry.imageUrl, '/download.lua?path=/var/fonpix/1.jpg');
    });

    test('fromXml parses phone numbers with attributes', () {
      final entry = PhonebookEntry.fromXml(_contactXml);

      expect(entry.numbers, hasLength(2));

      expect(entry.numbers[0].number, '+4930123456');
      expect(entry.numbers[0].type, 'home');
      expect(entry.numbers[0].quickdial, '1');
      expect(entry.numbers[0].prio, 0);

      expect(entry.numbers[1].number, '+491701234567');
      expect(entry.numbers[1].type, 'mobile');
      expect(entry.numbers[1].prio, 1);
    });

    test('fromXml parses emails', () {
      final entry = PhonebookEntry.fromXml(_contactXml);

      expect(entry.emails, ['max@example.com', 'work@example.com']);
    });

    test('fromXml handles minimal contact', () {
      final entry = PhonebookEntry.fromXml(_minimalContactXml);

      expect(entry.name, 'Sparse Entry');
      expect(entry.uniqueId, isNull);
      expect(entry.category, isNull);
      expect(entry.imageUrl, isNull);
      expect(entry.numbers, isEmpty);
      expect(entry.emails, isEmpty);
    });

    test('toString shows name and number count', () {
      final entry = PhonebookEntry.fromXml(_contactXml);
      expect(entry.toString(), 'PhonebookEntry(Max Mustermann, 2 numbers)');
    });
  });

  group('OnTelService', () {
    test('getPhonebookList parses comma-separated IDs', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetPhonebookList');
          return {'NewPhonebookList': '0,1,2'};
        },
      );

      final ids = await service.getPhonebookList();
      expect(ids, [0, 1, 2]);
    });

    test('getPhonebookList returns empty list for empty string', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewPhonebookList': ''};
        },
      );

      final ids = await service.getPhonebookList();
      expect(ids, isEmpty);
    });

    test('getPhonebookList handles single ID', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewPhonebookList': '0'};
        },
      );

      final ids = await service.getPhonebookList();
      expect(ids, [0]);
    });

    test('getCallList returns URL', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetCallList');
          return {'NewCallListURL': 'http://fritz.box/calllist.lua'};
        },
      );

      final url = await service.getCallList();
      expect(url, 'http://fritz.box/calllist.lua');
    });

    test('getPhonebook passes ID and returns Phonebook', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetPhonebook');
          expect(arguments['NewPhonebookID'], '1');
          return {
            'NewPhonebookURL': 'http://fritz.box/pb1.xml',
            'NewPhonebookName': 'Work',
            'NewPhonebookExtraID': '42',
          };
        },
      );

      final pb = await service.getPhonebook(1);
      expect(pb.name, 'Work');
      expect(pb.url, 'http://fritz.box/pb1.xml');
      expect(pb.extraId, '42');
    });

    test('getNumberOfEntries returns count', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetNumberOfEntries');
          expect(arguments, isEmpty);
          return {'NewOnTelNumberOfEntries': '25'};
        },
      );

      final count = await service.getNumberOfEntries();
      expect(count, 25);
    });

    test('getPhonebookEntry passes IDs and returns PhonebookEntry', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetPhonebookEntry');
          expect(arguments['NewPhonebookID'], '0');
          expect(arguments['NewPhonebookEntryID'], '3');
          return {'NewPhonebookEntryData': _contactXml};
        },
      );

      final entry = await service.getPhonebookEntry(0, 3);
      expect(entry.name, 'Max Mustermann');
      expect(entry.uniqueId, 42);
      expect(entry.numbers, hasLength(2));
    });

    test('getPhonebookEntryUID passes IDs and returns PhonebookEntry',
        () async {
      final service = OnTelService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetPhonebookEntryUID');
          expect(arguments['NewPhonebookID'], '0');
          expect(arguments['NewPhonebookEntryUniqueID'], '99');
          return {'NewPhonebookEntryData': _contactXml};
        },
      );

      final entry = await service.getPhonebookEntryUID(0, 99);
      expect(entry.name, 'Max Mustermann');
      expect(entry.uniqueId, 42);
    });
  });
}
