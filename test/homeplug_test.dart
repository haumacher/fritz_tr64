import 'package:flutter_tr64/src/device_description.dart';
import 'package:flutter_tr64/src/services/homeplug.dart';
import 'package:test/test.dart';

ServiceDescription _fakeDescription() {
  return ServiceDescription(
    serviceType: 'urn:dslforum-org:service:X_AVM-DE_Homeplug:1',
    serviceId: 'urn:X_AVM-DE_Homeplug-com:serviceId:X_AVMDE_Homeplug1',
    controlUrl: '/upnp/control/x_homeplug',
    scpdUrl: '/x_homeplugSCPD.xml',
  );
}

Future<String> _unusedFetchUrl(String url) async => '';

void main() {
  group('UpdateSuccessful', () {
    test('tryParse returns matching enum value', () {
      expect(
          UpdateSuccessful.tryParse('unknown'), UpdateSuccessful.unknown);
      expect(UpdateSuccessful.tryParse('failed'), UpdateSuccessful.failed);
      expect(UpdateSuccessful.tryParse('succeeded'),
          UpdateSuccessful.succeeded);
    });

    test('tryParse returns null for unknown or empty', () {
      expect(UpdateSuccessful.tryParse('other'), isNull);
      expect(UpdateSuccessful.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(UpdateSuccessful.unknown.toString(), 'unknown');
      expect(UpdateSuccessful.failed.toString(), 'failed');
      expect(UpdateSuccessful.succeeded.toString(), 'succeeded');
    });
  });

  group('HomePlugDeviceEntry', () {
    test('fromArguments parses all fields', () {
      final entry = HomePlugDeviceEntry.fromArguments({
        'NewMACAddress': 'AA:BB:CC:DD:EE:FF',
        'NewActive': '1',
        'NewName': 'Living Room',
        'NewModel': 'FRITZ!Powerline 1260E',
        'NewUpdateAvailable': '0',
        'NewUpdateSuccessful': 'succeeded',
      });
      expect(entry.macAddress, 'AA:BB:CC:DD:EE:FF');
      expect(entry.active, isTrue);
      expect(entry.name, 'Living Room');
      expect(entry.model, 'FRITZ!Powerline 1260E');
      expect(entry.updateAvailable, isFalse);
      expect(entry.updateSuccessful, UpdateSuccessful.succeeded);
    });

    test('fromArguments defaults for missing keys', () {
      final entry = HomePlugDeviceEntry.fromArguments({});
      expect(entry.macAddress, '');
      expect(entry.active, isFalse);
      expect(entry.name, '');
      expect(entry.model, '');
      expect(entry.updateAvailable, isFalse);
      expect(entry.updateSuccessful, isNull);
    });

    test('toString includes key fields', () {
      final entry = HomePlugDeviceEntry.fromArguments({
        'NewMACAddress': 'AA:BB:CC:DD:EE:FF',
        'NewName': 'Office',
        'NewModel': 'FRITZ!Powerline 1260E',
      });
      final s = entry.toString();
      expect(s, contains('AA:BB:CC:DD:EE:FF'));
      expect(s, contains('Office'));
      expect(s, contains('FRITZ!Powerline 1260E'));
    });
  });

  group('HomePlugService', () {
    test('getNumberOfDeviceEntries returns count', () async {
      final service = HomePlugService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetNumberOfDeviceEntries');
          return {'NewNumberOfEntries': '3'};
        },
        fetchUrl: _unusedFetchUrl,
      );
      expect(await service.getNumberOfDeviceEntries(), 3);
    });

    test('getGenericDeviceEntry sends index and returns parsed entry',
        () async {
      final service = HomePlugService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetGenericDeviceEntry');
          expect(arguments['NewIndex'], '2');
          return {
            'NewMACAddress': '11:22:33:44:55:66',
            'NewActive': '1',
            'NewName': 'Kitchen',
            'NewModel': 'FRITZ!Powerline 546E',
            'NewUpdateAvailable': '1',
            'NewUpdateSuccessful': 'failed',
          };
        },
        fetchUrl: _unusedFetchUrl,
      );
      final entry = await service.getGenericDeviceEntry(2);
      expect(entry.macAddress, '11:22:33:44:55:66');
      expect(entry.active, isTrue);
      expect(entry.name, 'Kitchen');
      expect(entry.model, 'FRITZ!Powerline 546E');
      expect(entry.updateAvailable, isTrue);
      expect(entry.updateSuccessful, UpdateSuccessful.failed);
    });

    test('getSpecificDeviceEntry sends MAC and returns parsed entry',
        () async {
      final service = HomePlugService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetSpecificDeviceEntry');
          expect(arguments['NewMACAddress'], 'AA:BB:CC:DD:EE:FF');
          return {
            'NewActive': '0',
            'NewName': 'Garage',
            'NewModel': 'FRITZ!Powerline 1240E',
            'NewUpdateAvailable': '0',
            'NewUpdateSuccessful': 'unknown',
          };
        },
        fetchUrl: _unusedFetchUrl,
      );
      final entry =
          await service.getSpecificDeviceEntry('AA:BB:CC:DD:EE:FF');
      expect(entry.macAddress, 'AA:BB:CC:DD:EE:FF');
      expect(entry.active, isFalse);
      expect(entry.name, 'Garage');
      expect(entry.model, 'FRITZ!Powerline 1240E');
      expect(entry.updateAvailable, isFalse);
      expect(entry.updateSuccessful, UpdateSuccessful.unknown);
    });

    test('deviceDoUpdate sends MAC address', () async {
      final service = HomePlugService(
        description: _fakeDescription(),
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'DeviceDoUpdate');
          expect(arguments['NewMACAddress'], '11:22:33:44:55:66');
          return {};
        },
        fetchUrl: _unusedFetchUrl,
      );
      await service.deviceDoUpdate('11:22:33:44:55:66');
    });
  });
}
