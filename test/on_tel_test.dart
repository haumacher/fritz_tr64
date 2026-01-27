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

Future<String> _unusedFetchUrl(String url) async => '';

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
      expect(entry.numbers[0].type, PhoneNumberType.home);
      expect(entry.numbers[0].quickdial, '1');
      expect(entry.numbers[0].prio, 0);

      expect(entry.numbers[1].number, '+491701234567');
      expect(entry.numbers[1].type, PhoneNumberType.mobile);
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

    test('toXml produces valid contact XML', () {
      final entry = PhonebookEntry(
        name: 'Max Mustermann',
        category: 1,
        uniqueId: 42,
        imageUrl: '/img.jpg',
        numbers: [
          PhoneNumber(number: '+4930123456', type: PhoneNumberType.home, quickdial: '1'),
          PhoneNumber(number: '+491701234567', type: PhoneNumberType.mobile, prio: 1),
        ],
        emails: ['max@example.com'],
      );

      final xml = entry.toXml();
      expect(xml, contains('<realName>Max Mustermann</realName>'));
      expect(xml, contains('<category>1</category>'));
      expect(xml, contains('<uniqueid>42</uniqueid>'));
      expect(xml, contains('<imageURL>/img.jpg</imageURL>'));
      expect(xml, contains('type="home"'));
      expect(xml, contains('quickdial="1"'));
      expect(xml, contains('+4930123456'));
      expect(xml, contains('type="mobile"'));
      expect(xml, contains('prio="1"'));
      expect(xml, contains('<email>max@example.com</email>'));
    });

    test('toXml omits optional fields when null/empty', () {
      final entry = PhonebookEntry(name: 'Simple');

      final xml = entry.toXml();
      expect(xml, contains('<realName>Simple</realName>'));
      expect(xml, isNot(contains('<category>')));
      expect(xml, isNot(contains('<uniqueid>')));
      expect(xml, isNot(contains('<imageURL>')));
      expect(xml, isNot(contains('<telephony>')));
    });

    test('toXml roundtrips through fromXml', () {
      final original = PhonebookEntry(
        name: 'Roundtrip Test',
        category: 0,
        numbers: [
          PhoneNumber(number: '+49123', type: PhoneNumberType.work, prio: 1),
        ],
        emails: ['test@example.com'],
      );

      final parsed = PhonebookEntry.fromXml(original.toXml());
      expect(parsed.name, original.name);
      expect(parsed.category, original.category);
      expect(parsed.numbers.length, original.numbers.length);
      expect(parsed.numbers[0].number, original.numbers[0].number);
      expect(parsed.numbers[0].type, original.numbers[0].type);
      expect(parsed.numbers[0].prio, original.numbers[0].prio);
      expect(parsed.emails, original.emails);
    });
  });

  group('OnTelService', () {
    test('getPhonebookList parses comma-separated IDs', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
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
        fetchUrl: _unusedFetchUrl,
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
        fetchUrl: _unusedFetchUrl,
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
        fetchUrl: _unusedFetchUrl,
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
        fetchUrl: _unusedFetchUrl,
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
        fetchUrl: _unusedFetchUrl,
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
        fetchUrl: _unusedFetchUrl,
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
        fetchUrl: _unusedFetchUrl,
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

    test('addPhonebook passes name and optional extraId', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'AddPhonebook');
          expect(arguments['NewPhonebookName'], 'Work');
          expect(arguments['NewPhonebookExtraID'], '7');
          return {};
        },
      );

      await service.addPhonebook('Work', extraId: '7');
    });

    test('addPhonebook sends empty extraId when not provided', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(arguments['NewPhonebookExtraID'], '');
          return {};
        },
      );

      await service.addPhonebook('Personal');
    });

    test('deletePhonebook passes ID', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'DeletePhonebook');
          expect(arguments['NewPhonebookID'], '2');
          return {};
        },
      );

      await service.deletePhonebook(2);
    });

    test('setPhonebookEntry passes ID, entryID, and entry XML', () async {
      final entry = PhonebookEntry(
        name: 'Test',
        numbers: [PhoneNumber(number: '+49123', type: PhoneNumberType.home)],
      );
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetPhonebookEntry');
          expect(arguments['NewPhonebookID'], '0');
          expect(arguments['NewPhonebookEntryID'], '');
          expect(arguments['NewPhonebookEntryData'], entry.toXml());
          return {};
        },
      );

      await service.setPhonebookEntry(0, '', entry);
    });

    test('setPhonebookEntryUID passes ID and entry XML, returns uniqueId',
        () async {
      final entry = PhonebookEntry(
        name: 'Test',
        numbers: [PhoneNumber(number: '+49123', type: PhoneNumberType.home)],
      );
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetPhonebookEntryUID');
          expect(arguments['NewPhonebookID'], '0');
          expect(arguments['NewPhonebookEntryData'], entry.toXml());
          return {'NewPhonebookEntryUniqueID': '55'};
        },
      );

      final uid = await service.setPhonebookEntryUID(0, entry);
      expect(uid, 55);
    });

    test('deletePhonebookEntry passes IDs', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'DeletePhonebookEntry');
          expect(arguments['NewPhonebookID'], '0');
          expect(arguments['NewPhonebookEntryID'], '5');
          return {};
        },
      );

      await service.deletePhonebookEntry(0, 5);
    });

    test('deletePhonebookEntryUID passes IDs', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'DeletePhonebookEntryUID');
          expect(arguments['NewPhonebookID'], '0');
          expect(arguments['NewPhonebookEntryUniqueID'], '42');
          return {};
        },
      );

      await service.deletePhonebookEntryUID(0, 42);
    });

    test('getCallBarringEntry returns PhonebookEntry', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetCallBarringEntry');
          expect(arguments['NewPhonebookEntryID'], '5');
          return {'NewPhonebookEntryData': _contactXml};
        },
      );

      final entry = await service.getCallBarringEntry(5);
      expect(entry.name, 'Max Mustermann');
    });

    test('getCallBarringEntryByNum returns PhonebookEntry', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetCallBarringEntryByNum');
          expect(arguments['NewNumber'], '+491234567');
          return {'NewPhonebookEntryData': _contactXml};
        },
      );

      final entry = await service.getCallBarringEntryByNum('+491234567');
      expect(entry.name, 'Max Mustermann');
    });

    test('getCallBarringList returns URL', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetCallBarringList');
          return {'NewPhonebookURL': 'http://fritz.box/barring.xml'};
        },
      );

      final url = await service.getCallBarringList();
      expect(url, 'http://fritz.box/barring.xml');
    });

    test('getCallBarringEntries fetches and parses phonebook XML', () async {
      const phonebookXml = '''
<?xml version="1.0"?>
<phonebooks>
  <phonebook>
    <contact>
      <person><realName>Spam Caller</realName></person>
      <telephony>
        <number type="home">+49111</number>
      </telephony>
      <uniqueid>10</uniqueid>
    </contact>
    <contact>
      <person><realName>Telemarketer</realName></person>
      <telephony>
        <number type="work">+49222</number>
      </telephony>
      <uniqueid>11</uniqueid>
    </contact>
  </phonebook>
</phonebooks>''';

      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: (url) async {
          expect(url, 'http://fritz.box/barring.xml');
          return phonebookXml;
        },
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetCallBarringList');
          return {'NewPhonebookURL': 'http://fritz.box/barring.xml'};
        },
      );

      final entries = await service.getCallBarringEntries();
      expect(entries, hasLength(2));
      expect(entries[0].name, 'Spam Caller');
      expect(entries[0].uniqueId, 10);
      expect(entries[0].numbers[0].number, '+49111');
      expect(entries[1].name, 'Telemarketer');
      expect(entries[1].uniqueId, 11);
    });

    test('getCallBarringEntries returns empty list for empty URL', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewPhonebookURL': ''};
        },
      );

      final entries = await service.getCallBarringEntries();
      expect(entries, isEmpty);
    });

    test('setCallBarringEntry passes entry XML and returns uniqueId', () async {
      final entry = PhonebookEntry(
        name: 'Blocked',
        numbers: [PhoneNumber(number: '+49999', type: PhoneNumberType.home)],
      );
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetCallBarringEntry');
          expect(arguments['NewPhonebookEntryData'], entry.toXml());
          return {'NewPhonebookEntryUniqueID': '10'};
        },
      );

      final uid = await service.setCallBarringEntry(entry);
      expect(uid, 10);
    });

    test('deleteCallBarringEntryUID passes uniqueId', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'DeleteCallBarringEntryUID');
          expect(arguments['NewPhonebookEntryUniqueID'], '10');
          return {};
        },
      );

      await service.deleteCallBarringEntryUID(10);
    });

    test('getInfoByIndex returns OnlinePhonebookInfo', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetInfoByIndex');
          expect(arguments['NewIndex'], '1');
          return {
            'NewEnable': '1',
            'NewStatus': 'OK',
            'NewLastConnect': '2025-01-01',
            'NewUrl': 'https://remote.example.com/pb',
            'NewServiceId': 'svc1',
            'NewUsername': 'admin',
            'NewName': 'Remote PB',
          };
        },
      );

      final info = await service.getInfoByIndex(1);
      expect(info.enable, isTrue);
      expect(info.status, 'OK');
      expect(info.url, 'https://remote.example.com/pb');
      expect(info.name, 'Remote PB');
    });

    test('setEnableByIndex passes index and enable flag', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetEnableByIndex');
          expect(arguments['NewIndex'], '2');
          expect(arguments['NewEnable'], '1');
          return {};
        },
      );

      await service.setEnableByIndex(2, true);
    });

    test('setConfigByIndex passes all parameters', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetConfigByIndex');
          expect(arguments['NewIndex'], '3');
          expect(arguments['NewEnable'], '0');
          expect(arguments['NewUrl'], 'https://example.com');
          expect(arguments['NewServiceId'], 'svc');
          expect(arguments['NewUsername'], 'user');
          expect(arguments['NewPassword'], 'pass');
          expect(arguments['NewName'], 'Test');
          return {};
        },
      );

      await service.setConfigByIndex(
        index: 3,
        enable: false,
        url: 'https://example.com',
        serviceId: 'svc',
        username: 'user',
        password: 'pass',
        name: 'Test',
      );
    });

    test('deleteByIndex passes index', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'DeleteByIndex');
          expect(arguments['NewIndex'], '4');
          return {};
        },
      );

      await service.deleteByIndex(4);
    });

    test('getDectHandsetList parses comma-separated IDs', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetDECTHandsetList');
          return {'NewDectIDList': '1,2,3'};
        },
      );

      final ids = await service.getDectHandsetList();
      expect(ids, ['1', '2', '3']);
    });

    test('getDectHandsetList returns empty list for empty string', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewDectIDList': ''};
        },
      );

      final ids = await service.getDectHandsetList();
      expect(ids, isEmpty);
    });

    test('getDectHandsetInfo returns name and phonebookId', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetDECTHandsetInfo');
          expect(arguments['NewDectID'], '1');
          return {
            'NewHandsetName': 'Mobilteil 1',
            'NewPhonebookID': '0',
          };
        },
      );

      final info = await service.getDectHandsetInfo('1');
      expect(info.handsetName, 'Mobilteil 1');
      expect(info.phonebookId, 0);
    });

    test('setDectHandsetPhonebook passes dectId and phonebookId', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetDECTHandsetPhonebook');
          expect(arguments['NewDectID'], '2');
          expect(arguments['NewPhonebookID'], '1');
          return {};
        },
      );

      await service.setDectHandsetPhonebook('2', 1);
    });

    test('getNumberOfDeflections returns count', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetNumberOfDeflections');
          return {'NewNumberOfDeflections': '3'};
        },
      );

      final count = await service.getNumberOfDeflections();
      expect(count, 3);
    });

    test('getDeflection returns Deflection with all fields', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetDeflection');
          expect(arguments['NewDeflectionId'], '0');
          return {
            'NewEnable': '1',
            'NewType': 'fromNumber',
            'NewNumber': '12345',
            'NewDeflectionToNumber': '98765',
            'NewMode': 'eImmediately',
            'NewOutgoing': '0',
            'NewPhonebookID': '',
          };
        },
      );

      final d = await service.getDeflection(0);
      expect(d.enable, isTrue);
      expect(d.type, 'fromNumber');
      expect(d.number, '12345');
      expect(d.deflectionToNumber, '98765');
      expect(d.mode, 'eImmediately');
      expect(d.outgoing, '0');
      expect(d.phonebookId, isNull);
    });

    test('getDeflection parses phonebookId when present', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {
            'NewEnable': '0',
            'NewType': 'fromPB',
            'NewNumber': '',
            'NewDeflectionToNumber': '555',
            'NewMode': 'eBusy',
            'NewOutgoing': '',
            'NewPhonebookID': '2',
          };
        },
      );

      final d = await service.getDeflection(1);
      expect(d.phonebookId, 2);
      expect(d.type, 'fromPB');
    });

    test('getDeflections returns XML string', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetDeflections');
          return {'NewDeflectionList': '<List><Item>...</Item></List>'};
        },
      );

      final xml = await service.getDeflections();
      expect(xml, '<List><Item>...</Item></List>');
    });

    test('setDeflectionEnable passes id and enable flag', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetDeflectionEnable');
          expect(arguments['NewDeflectionId'], '1');
          expect(arguments['NewEnable'], '0');
          return {};
        },
      );

      await service.setDeflectionEnable(1, false);
    });

    test('getCallListEntries fetches and parses call list XML', () async {
      const callListXml = '''
<?xml version="1.0"?>
<root>
  <timestamp>123456</timestamp>
  <Call>
    <Id>123</Id>
    <Type>3</Type>
    <Called>0123456789</Called>
    <Caller>SIP: 98765</Caller>
    <CallerNumber>98765</CallerNumber>
    <Name>Max Mustermann</Name>
    <Numbertype/>
    <Device>Mobilteil 1</Device>
    <Port>10</Port>
    <Date>23.09.11 08:13</Date>
    <Duration>0:01</Duration>
    <Count/>
    <Path/>
  </Call>
  <Call>
    <Id>122</Id>
    <Type>1</Type>
    <Caller>012456789</Caller>
    <Called>SIP: 56789</Called>
    <CalledNumber>98765</CalledNumber>
    <Name>Max Mustermann</Name>
    <Numbertype/>
    <Device>Anrufbeantworter 1</Device>
    <Port>40</Port>
    <Date>22.09.11 14:19</Date>
    <Duration>0:01</Duration>
    <Count/>
    <Path>/download.lua?path=/var/media/ftp/USB/FRITZ/voicebox/rec/rec.0.000</Path>
  </Call>
</root>
''';

      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: (url) async {
          expect(url, contains('calllist'));
          expect(url, contains('max=10'));
          return callListXml;
        },
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetCallList');
          return {
            'NewCallListURL':
                'http://fritz.box:49000/calllist.lua?sid=abc',
          };
        },
      );

      final calls = await service.getCallListEntries(max: 10);
      expect(calls, hasLength(2));

      expect(calls[0].id, 123);
      expect(calls[0].type, CallType.outgoing);
      expect(calls[0].called, '0123456789');
      expect(calls[0].caller, 'SIP: 98765');
      expect(calls[0].name, 'Max Mustermann');
      expect(calls[0].device, 'Mobilteil 1');
      expect(calls[0].port, 10);
      expect(calls[0].date, '23.09.11 08:13');
      expect(calls[0].duration, '0:01');
      expect(calls[0].path, '');

      expect(calls[1].id, 122);
      expect(calls[1].type, CallType.incoming);
      expect(calls[1].device, 'Anrufbeantworter 1');
      expect(calls[1].port, 40);
      expect(calls[1].path,
          '/download.lua?path=/var/media/ftp/USB/FRITZ/voicebox/rec/rec.0.000');
    });

    test('getCallListEntries returns empty list for empty URL', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewCallListURL': ''};
        },
      );

      final calls = await service.getCallListEntries();
      expect(calls, isEmpty);
    });

    test('getCallListEntries appends days parameter', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        fetchUrl: (url) async {
          expect(url, contains('days=7'));
          return '<root></root>';
        },
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {
            'NewCallListURL': 'http://fritz.box/calllist.lua?sid=abc',
          };
        },
      );

      final calls = await service.getCallListEntries(days: 7);
      expect(calls, isEmpty);
    });
  });

  group('CallType', () {
    test('tryParse returns matching enum value', () {
      expect(CallType.tryParse(1), CallType.incoming);
      expect(CallType.tryParse(2), CallType.missed);
      expect(CallType.tryParse(3), CallType.outgoing);
      expect(CallType.tryParse(9), CallType.activeIncoming);
      expect(CallType.tryParse(10), CallType.rejected);
      expect(CallType.tryParse(11), CallType.activeOutgoing);
    });

    test('tryParse returns null for unknown value', () {
      expect(CallType.tryParse(0), isNull);
      expect(CallType.tryParse(99), isNull);
      expect(CallType.tryParse(-1), isNull);
    });
  });

  group('CallListEntry', () {
    test('toString includes key fields', () {
      final entry = CallListEntry(
        id: 123,
        type: CallType.outgoing,
        called: '0123456789',
        caller: '98765',
        name: 'Max Mustermann',
        numbertype: 'sip',
        device: 'Mobilteil 1',
        port: 10,
        date: '23.09.11 08:13',
        duration: '0:01',
        path: '',
      );
      expect(entry.toString(),
          'CallListEntry(123, outgoing, Max Mustermann, 23.09.11 08:13)');
    });

    test('toString handles null type', () {
      final entry = CallListEntry(
        id: 1,
        type: null,
        called: '',
        caller: '',
        name: '',
        numbertype: '',
        device: '',
        port: 0,
        date: '',
        duration: '',
        path: '',
      );
      expect(entry.toString(), 'CallListEntry(1, ?, , )');
    });
  });
}
