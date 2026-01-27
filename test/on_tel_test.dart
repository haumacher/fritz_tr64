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

    test('getPhonebookEntry passes IDs and returns XML data', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetPhonebookEntry');
          expect(arguments['NewPhonebookID'], '0');
          expect(arguments['NewPhonebookEntryID'], '3');
          return {'NewPhonebookEntryData': '<contact>...</contact>'};
        },
      );

      final xml = await service.getPhonebookEntry(0, 3);
      expect(xml, '<contact>...</contact>');
    });

    test('getPhonebookEntryUID passes IDs and returns XML data', () async {
      final service = OnTelService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetPhonebookEntryUID');
          expect(arguments['NewPhonebookID'], '0');
          expect(arguments['NewPhonebookEntryUniqueID'], '99');
          return {'NewPhonebookEntryData': '<contact uid="99">...</contact>'};
        },
      );

      final xml = await service.getPhonebookEntryUID(0, 99);
      expect(xml, '<contact uid="99">...</contact>');
    });
  });
}
