import 'package:flutter_tr64/src/device_description.dart';
import 'package:flutter_tr64/src/services/my_fritz.dart';
import 'package:test/test.dart';

ServiceDescription _fakeDescription() {
  return ServiceDescription(
    serviceType: 'urn:dslforum-org:service:X_AVM-DE_MyFritz:1',
    serviceId: 'urn:X_AVM-DE_MyFritz-com:serviceId:X_AVM-DE_MyFritz1',
    controlUrl: '/upnp/control/x_myfritz',
    scpdUrl: '/x_myfritzSCPD.xml',
  );
}

Future<String> _unusedFetchUrl(String url) async => '';

void main() {
  group('MyFritzState', () {
    test('tryParse returns matching enum value', () {
      expect(
          MyFritzState.tryParse('myfritz_disabled'), MyFritzState.myfritzDisabled);
      expect(
          MyFritzState.tryParse('register_failed'), MyFritzState.registerFailed);
      expect(MyFritzState.tryParse('unregister'), MyFritzState.unregister);
      expect(MyFritzState.tryParse('dyndns_unknown'), MyFritzState.dyndnsUnknown);
      expect(MyFritzState.tryParse('dyndns_active'), MyFritzState.dyndnsActive);
      expect(MyFritzState.tryParse('dyndns_update_failed'),
          MyFritzState.dyndnsUpdateFailed);
      expect(MyFritzState.tryParse('dyndns_auth_error'),
          MyFritzState.dyndnsAuthError);
      expect(MyFritzState.tryParse('dyndns_server_unreachable'),
          MyFritzState.dyndnsServerUnreachable);
      expect(MyFritzState.tryParse('dyndns_server_error'),
          MyFritzState.dyndnsServerError);
      expect(MyFritzState.tryParse('dyndns_server_update'),
          MyFritzState.dyndnsServerUpdate);
      expect(MyFritzState.tryParse('dyndns_not_verified'),
          MyFritzState.dyndnsNotVerified);
      expect(
          MyFritzState.tryParse('dyndns_verified'), MyFritzState.dyndnsVerified);
      expect(MyFritzState.tryParse('reserved'), MyFritzState.reserved);
      expect(MyFritzState.tryParse('unknown'), MyFritzState.unknown);
    });

    test('tryParse returns null for unknown or empty', () {
      expect(MyFritzState.tryParse('not_a_state'), isNull);
      expect(MyFritzState.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(MyFritzState.myfritzDisabled.toString(), 'myfritz_disabled');
      expect(MyFritzState.registerFailed.toString(), 'register_failed');
      expect(MyFritzState.unregister.toString(), 'unregister');
      expect(MyFritzState.dyndnsUnknown.toString(), 'dyndns_unknown');
      expect(MyFritzState.dyndnsActive.toString(), 'dyndns_active');
      expect(MyFritzState.dyndnsUpdateFailed.toString(), 'dyndns_update_failed');
      expect(MyFritzState.dyndnsAuthError.toString(), 'dyndns_auth_error');
      expect(MyFritzState.dyndnsServerUnreachable.toString(),
          'dyndns_server_unreachable');
      expect(MyFritzState.dyndnsServerError.toString(), 'dyndns_server_error');
      expect(MyFritzState.dyndnsServerUpdate.toString(), 'dyndns_server_update');
      expect(MyFritzState.dyndnsNotVerified.toString(), 'dyndns_not_verified');
      expect(MyFritzState.dyndnsVerified.toString(), 'dyndns_verified');
      expect(MyFritzState.reserved.toString(), 'reserved');
      expect(MyFritzState.unknown.toString(), 'unknown');
    });
  });

  group('MyFritzStatus', () {
    test('tryParse returns matching enum value', () {
      expect(MyFritzStatus.tryParse(0), MyFritzStatus.notRegistered);
      expect(MyFritzStatus.tryParse(1), MyFritzStatus.registeredDisabled);
      expect(MyFritzStatus.tryParse(10), MyFritzStatus.registerFailed);
      expect(MyFritzStatus.tryParse(99), MyFritzStatus.deviceRegistering);
      expect(MyFritzStatus.tryParse(200), MyFritzStatus.dyndnsUpdateRunning);
      expect(MyFritzStatus.tryParse(250), MyFritzStatus.dyndnsUpdateUnknownError);
      expect(MyFritzStatus.tryParse(251), MyFritzStatus.dyndnsUpdateAuthError);
      expect(MyFritzStatus.tryParse(252), MyFritzStatus.dyndnsUpdateNoInternet);
      expect(
          MyFritzStatus.tryParse(253), MyFritzStatus.dyndnsUpdateNotReachable);
      expect(MyFritzStatus.tryParse(254), MyFritzStatus.dyndnsUpdateBadReply);
      expect(MyFritzStatus.tryParse(255), MyFritzStatus.dyndnsUpdateFailed);
      expect(
          MyFritzStatus.tryParse(300), MyFritzStatus.dyndnsUpdatedValidating);
      expect(MyFritzStatus.tryParse(301), MyFritzStatus.dyndnsUpdatedValidated);
    });

    test('tryParse returns null for unknown', () {
      expect(MyFritzStatus.tryParse(-1), isNull);
      expect(MyFritzStatus.tryParse(999), isNull);
    });

    test('toString returns integer string', () {
      expect(MyFritzStatus.notRegistered.toString(), '0');
      expect(MyFritzStatus.dyndnsUpdateRunning.toString(), '200');
      expect(MyFritzStatus.dyndnsUpdatedValidated.toString(), '301');
    });
  });

  group('IPv4ForwardingWarning', () {
    test('tryParse returns matching enum value', () {
      expect(IPv4ForwardingWarning.tryParse(0), IPv4ForwardingWarning.unknown);
      expect(
          IPv4ForwardingWarning.tryParse(1), IPv4ForwardingWarning.succeeded);
      expect(IPv4ForwardingWarning.tryParse(2), IPv4ForwardingWarning.failed);
    });

    test('tryParse returns null for unknown', () {
      expect(IPv4ForwardingWarning.tryParse(-1), isNull);
      expect(IPv4ForwardingWarning.tryParse(99), isNull);
    });
  });

  group('MyFritzInfo', () {
    test('fromArguments parses all fields', () {
      final info = MyFritzInfo.fromArguments({
        'NewEnabled': '1',
        'NewDynDNSName': 'mybox.myfritz.net',
        'NewPort': '443',
        'NewDeviceRegistered': '1',
        'NewState': 'dyndns_verified',
        'NewEmail': 'user@example.com',
      });

      expect(info.enabled, isTrue);
      expect(info.dynDNSName, 'mybox.myfritz.net');
      expect(info.port, 443);
      expect(info.deviceRegistered, isTrue);
      expect(info.state, MyFritzState.dyndnsVerified);
      expect(info.email, 'user@example.com');
    });

    test('fromArguments defaults for missing keys', () {
      final info = MyFritzInfo.fromArguments({});

      expect(info.enabled, isFalse);
      expect(info.dynDNSName, '');
      expect(info.port, 0);
      expect(info.deviceRegistered, isFalse);
      expect(info.state, isNull);
      expect(info.email, '');
    });

    test('toString includes key fields', () {
      final info = MyFritzInfo(
        enabled: true,
        dynDNSName: 'mybox.myfritz.net',
        port: 443,
        deviceRegistered: true,
        state: MyFritzState.dyndnsVerified,
        email: 'user@example.com',
      );
      expect(info.toString(),
          'MyFritzInfo(enabled=true, dynDNS=mybox.myfritz.net, state=dyndns_verified)');
    });

    test('toString with null state', () {
      final info = MyFritzInfo(
        enabled: false,
        dynDNSName: '',
        port: 0,
        deviceRegistered: false,
        state: null,
        email: '',
      );
      expect(info.toString(),
          'MyFritzInfo(enabled=false, dynDNS=, state=null)');
    });
  });

  group('MyFritzServiceInfo', () {
    test('fromArguments parses all fields', () {
      final info = MyFritzServiceInfo.fromArguments({
        'NewEnabled': '1',
        'NewName': 'Web Server',
        'NewScheme': 'https',
        'NewPort': '443',
        'NewURLPath': '/path',
        'NewType': 'http',
        'NewIPv4ForwardingWarning': '1',
        'NewIPv4Addresses': '192.168.178.20',
        'NewIPv6Addresses': 'fd00::1',
        'NewIPv6InterfaceIDs': '::1',
        'NewMACAddress': 'AA:BB:CC:DD:EE:FF',
        'NewHostName': 'mydevice',
        'NewDynDnsLabel': 'mydevice',
        'NewStatus': '301',
      });

      expect(info.enabled, isTrue);
      expect(info.name, 'Web Server');
      expect(info.scheme, 'https');
      expect(info.port, 443);
      expect(info.urlPath, '/path');
      expect(info.type, 'http');
      expect(info.ipv4ForwardingWarning, IPv4ForwardingWarning.succeeded);
      expect(info.ipv4Addresses, '192.168.178.20');
      expect(info.ipv6Addresses, 'fd00::1');
      expect(info.ipv6InterfaceIDs, '::1');
      expect(info.macAddress, 'AA:BB:CC:DD:EE:FF');
      expect(info.hostName, 'mydevice');
      expect(info.dynDnsLabel, 'mydevice');
      expect(info.status, MyFritzStatus.dyndnsUpdatedValidated);
    });

    test('fromArguments defaults for missing keys', () {
      final info = MyFritzServiceInfo.fromArguments({});

      expect(info.enabled, isFalse);
      expect(info.name, '');
      expect(info.scheme, '');
      expect(info.port, 0);
      expect(info.urlPath, '');
      expect(info.type, '');
      expect(info.ipv4ForwardingWarning, isNull);
      expect(info.ipv4Addresses, '');
      expect(info.ipv6Addresses, '');
      expect(info.ipv6InterfaceIDs, '');
      expect(info.macAddress, '');
      expect(info.hostName, '');
      expect(info.dynDnsLabel, '');
      expect(info.status, isNull);
    });

    test('toString includes key fields', () {
      final info = MyFritzServiceInfo(
        enabled: true,
        name: 'Web Server',
        scheme: 'https',
        port: 443,
        urlPath: '/path',
        type: 'http',
        ipv4ForwardingWarning: IPv4ForwardingWarning.succeeded,
        ipv4Addresses: '192.168.178.20',
        ipv6Addresses: '',
        ipv6InterfaceIDs: '',
        macAddress: '',
        hostName: 'mydevice',
        dynDnsLabel: '',
        status: MyFritzStatus.dyndnsUpdatedValidated,
      );
      expect(info.toString(),
          'MyFritzServiceInfo(name=Web Server, scheme=https, port=443)');
    });
  });

  group('MyFritzService', () {
    test('getInfo returns parsed MyFritzInfo', () async {
      final service = MyFritzService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetInfo');
          expect(arguments, isEmpty);
          return {
            'NewEnabled': '1',
            'NewDynDNSName': 'mybox.myfritz.net',
            'NewPort': '443',
            'NewDeviceRegistered': '1',
            'NewState': 'dyndns_verified',
            'NewEmail': 'user@example.com',
          };
        },
      );

      final info = await service.getInfo();
      expect(info.enabled, isTrue);
      expect(info.dynDNSName, 'mybox.myfritz.net');
      expect(info.port, 443);
      expect(info.deviceRegistered, isTrue);
      expect(info.state, MyFritzState.dyndnsVerified);
      expect(info.email, 'user@example.com');
    });

    test('setMyFritz sends correct arguments', () async {
      final service = MyFritzService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetMyFRITZ');
          expect(arguments['NewEnabled'], '1');
          expect(arguments['NewEmail'], 'user@example.com');
          return {};
        },
      );

      await service.setMyFritz(enabled: true, email: 'user@example.com');
    });

    test('setMyFritz sends 0 when disabling', () async {
      final service = MyFritzService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(arguments['NewEnabled'], '0');
          expect(arguments['NewEmail'], '');
          return {};
        },
      );

      await service.setMyFritz(enabled: false, email: '');
    });

    test('getNumberOfServices returns count', () async {
      final service = MyFritzService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetNumberOfServices');
          expect(arguments, isEmpty);
          return {'NewNumberOfServices': '5'};
        },
      );

      final count = await service.getNumberOfServices();
      expect(count, 5);
    });

    test('getNumberOfServices returns 0 for missing key', () async {
      final service = MyFritzService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {};
        },
      );

      final count = await service.getNumberOfServices();
      expect(count, 0);
    });

    test('getServiceByIndex sends index and returns parsed info', () async {
      final service = MyFritzService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetServiceByIndex');
          expect(arguments['NewIndex'], '2');
          return {
            'NewEnabled': '1',
            'NewName': 'Web Server',
            'NewScheme': 'https',
            'NewPort': '443',
            'NewURLPath': '/',
            'NewType': 'http',
            'NewIPv4ForwardingWarning': '1',
            'NewIPv4Addresses': '192.168.178.20',
            'NewIPv6Addresses': 'fd00::1',
            'NewIPv6InterfaceIDs': '::1',
            'NewMACAddress': 'AA:BB:CC:DD:EE:FF',
            'NewHostName': 'mydevice',
            'NewDynDnsLabel': 'mydevice',
            'NewStatus': '301',
          };
        },
      );

      final info = await service.getServiceByIndex(2);
      expect(info.enabled, isTrue);
      expect(info.name, 'Web Server');
      expect(info.scheme, 'https');
      expect(info.port, 443);
      expect(info.status, MyFritzStatus.dyndnsUpdatedValidated);
    });

    test('setServiceByIndex sends correct arguments', () async {
      final service = MyFritzService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetServiceByIndex');
          expect(arguments['NewIndex'], '0');
          expect(arguments['NewEnabled'], '1');
          expect(arguments['NewName'], 'My Service');
          expect(arguments['NewScheme'], 'https');
          expect(arguments['NewPort'], '8443');
          expect(arguments['NewURLPath'], '/api');
          expect(arguments['NewType'], 'http');
          expect(arguments['NewIPv4Address'], '192.168.178.20');
          expect(arguments['NewIPv6Address'], 'fd00::1');
          expect(arguments['NewIPv6InterfaceID'], '::1');
          expect(arguments['NewMACAddress'], 'AA:BB:CC:DD:EE:FF');
          expect(arguments['NewHostName'], 'mydevice');
          return {};
        },
      );

      await service.setServiceByIndex(
        index: 0,
        enabled: true,
        name: 'My Service',
        scheme: 'https',
        port: 8443,
        urlPath: '/api',
        type: 'http',
        ipv4Address: '192.168.178.20',
        ipv6Address: 'fd00::1',
        ipv6InterfaceID: '::1',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        hostName: 'mydevice',
      );
    });

    test('deleteServiceByIndex sends index', () async {
      final service = MyFritzService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'DeleteServiceByIndex');
          expect(arguments['NewIndex'], '3');
          return {};
        },
      );

      await service.deleteServiceByIndex(3);
    });
  });
}
