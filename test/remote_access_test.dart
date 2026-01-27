import 'package:fritz_tr064/src/device_description.dart';
import 'package:fritz_tr064/src/services/remote_access.dart';
import 'package:test/test.dart';

ServiceDescription _fakeDescription() {
  return ServiceDescription(
    serviceType: 'urn:dslforum-org:service:X_AVM-DE_RemoteAccess:1',
    serviceId: 'urn:X_AVM-DE_RemoteAccess-com:serviceId:X_AVM-DE_RemoteAccess1',
    controlUrl: '/upnp/control/x_remote',
    scpdUrl: '/x_remoteSCPD.xml',
  );
}

Future<String> _unusedFetchUrl(String url) async => '';

void main() {
  group('DDNSMode', () {
    test('tryParse returns matching enum value', () {
      expect(DDNSMode.tryParse('ddns_v4'), DDNSMode.v4);
      expect(DDNSMode.tryParse('ddns_v6'), DDNSMode.v6);
      expect(DDNSMode.tryParse('ddns_both'), DDNSMode.both);
      expect(DDNSMode.tryParse('ddns_both_together'), DDNSMode.bothTogether);
    });

    test('tryParse returns null for unknown', () {
      expect(DDNSMode.tryParse('unknown'), isNull);
      expect(DDNSMode.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(DDNSMode.v4.toString(), 'ddns_v4');
      expect(DDNSMode.v6.toString(), 'ddns_v6');
      expect(DDNSMode.both.toString(), 'ddns_both');
      expect(DDNSMode.bothTogether.toString(), 'ddns_both_together');
    });
  });

  group('DDNSStatus', () {
    test('tryParse returns matching enum value', () {
      expect(DDNSStatus.tryParse('offline'), DDNSStatus.offline);
      expect(DDNSStatus.tryParse('checking'), DDNSStatus.checking);
      expect(DDNSStatus.tryParse('updating'), DDNSStatus.updating);
      expect(DDNSStatus.tryParse('updated'), DDNSStatus.updated);
      expect(DDNSStatus.tryParse('verifying'), DDNSStatus.verifying);
      expect(DDNSStatus.tryParse('complete'), DDNSStatus.complete);
      expect(DDNSStatus.tryParse('new-address'), DDNSStatus.newAddress);
      expect(DDNSStatus.tryParse('account-disabled'), DDNSStatus.accountDisabled);
      expect(DDNSStatus.tryParse('internet-not-connected'), DDNSStatus.internetNotConnected);
      expect(DDNSStatus.tryParse('undefined'), DDNSStatus.undefined);
    });

    test('tryParse accepts "new address" with space (IPv4 variant)', () {
      expect(DDNSStatus.tryParse('new address'), DDNSStatus.newAddress);
    });

    test('tryParse returns null for unknown or empty', () {
      expect(DDNSStatus.tryParse('unknown_value'), isNull);
      expect(DDNSStatus.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(DDNSStatus.offline.toString(), 'offline');
      expect(DDNSStatus.complete.toString(), 'complete');
      expect(DDNSStatus.newAddress.toString(), 'new-address');
      expect(DDNSStatus.accountDisabled.toString(), 'account-disabled');
      expect(DDNSStatus.internetNotConnected.toString(), 'internet-not-connected');
    });
  });

  group('LetsEncryptState', () {
    test('tryParse returns matching enum value', () {
      expect(LetsEncryptState.tryParse('not_used'), LetsEncryptState.notUsed);
      expect(LetsEncryptState.tryParse('get'), LetsEncryptState.getting);
      expect(LetsEncryptState.tryParse('valid'), LetsEncryptState.valid);
      expect(LetsEncryptState.tryParse('invalid'), LetsEncryptState.invalid);
      expect(LetsEncryptState.tryParse('unknown'), LetsEncryptState.unknown);
    });

    test('tryParse returns null for unrecognised or empty', () {
      expect(LetsEncryptState.tryParse('something_else'), isNull);
      expect(LetsEncryptState.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(LetsEncryptState.notUsed.toString(), 'not_used');
      expect(LetsEncryptState.getting.toString(), 'get');
      expect(LetsEncryptState.valid.toString(), 'valid');
      expect(LetsEncryptState.invalid.toString(), 'invalid');
      expect(LetsEncryptState.unknown.toString(), 'unknown');
    });
  });

  group('RemoteAccessInfo', () {
    test('fromArguments parses all fields', () {
      final info = RemoteAccessInfo.fromArguments({
        'NewEnabled': '1',
        'NewPort': '443',
        'NewUsername': 'admin',
        'NewLetsEncryptEnabled': '1',
        'NewLetsEncryptState': 'valid',
      });

      expect(info.enabled, isTrue);
      expect(info.port, 443);
      expect(info.username, 'admin');
      expect(info.letsEncryptEnabled, isTrue);
      expect(info.letsEncryptState, LetsEncryptState.valid);
    });

    test('fromArguments defaults for missing keys', () {
      final info = RemoteAccessInfo.fromArguments({});

      expect(info.enabled, isFalse);
      expect(info.port, 0);
      expect(info.username, '');
      expect(info.letsEncryptEnabled, isFalse);
      expect(info.letsEncryptState, isNull);
    });

    test('fromArguments with disabled state', () {
      final info = RemoteAccessInfo.fromArguments({
        'NewEnabled': '0',
        'NewPort': '8443',
        'NewUsername': 'user@example.com',
        'NewLetsEncryptEnabled': '0',
        'NewLetsEncryptState': 'not_used',
      });

      expect(info.enabled, isFalse);
      expect(info.port, 8443);
      expect(info.username, 'user@example.com');
      expect(info.letsEncryptEnabled, isFalse);
      expect(info.letsEncryptState, LetsEncryptState.notUsed);
    });

    test('toString includes key fields', () {
      final info = RemoteAccessInfo(
        enabled: true,
        port: 443,
        username: 'admin',
        letsEncryptEnabled: true,
        letsEncryptState: LetsEncryptState.valid,
      );
      expect(info.toString(),
          'RemoteAccessInfo(enabled=true, port=443, user=admin)');
    });
  });

  group('DDNSInfo', () {
    test('fromArguments parses all fields', () {
      final info = DDNSInfo.fromArguments({
        'NewDomain': 'mybox.example.com',
        'NewEnabled': '1',
        'NewMode': 'ddns_v4',
        'NewProviderName': 'DynDNS',
        'NewServerIPv4': 'update.dyndns.org',
        'NewServerIPv6': 'update6.dyndns.org',
        'NewStatusIPv4': 'complete',
        'NewStatusIPv6': 'offline',
        'NewUpdateURL': 'https://update.dyndns.org/nic/update?hostname=<domain>&myip=<ipaddr>',
        'NewUsername': 'ddnsuser',
      });

      expect(info.domain, 'mybox.example.com');
      expect(info.enabled, isTrue);
      expect(info.mode, DDNSMode.v4);
      expect(info.providerName, 'DynDNS');
      expect(info.serverIPv4, 'update.dyndns.org');
      expect(info.serverIPv6, 'update6.dyndns.org');
      expect(info.statusIPv4, DDNSStatus.complete);
      expect(info.statusIPv6, DDNSStatus.offline);
      expect(info.updateURL, contains('update.dyndns.org'));
      expect(info.username, 'ddnsuser');
    });

    test('fromArguments defaults for missing keys', () {
      final info = DDNSInfo.fromArguments({});

      expect(info.domain, '');
      expect(info.enabled, isFalse);
      expect(info.mode, isNull);
      expect(info.providerName, '');
      expect(info.serverIPv4, '');
      expect(info.serverIPv6, '');
      expect(info.statusIPv4, isNull);
      expect(info.statusIPv6, isNull);
      expect(info.updateURL, '');
      expect(info.username, '');
    });

    test('fromArguments with bothTogether mode', () {
      final info = DDNSInfo.fromArguments({
        'NewMode': 'ddns_both_together',
      });
      expect(info.mode, DDNSMode.bothTogether);
    });

    test('toString includes key fields', () {
      final info = DDNSInfo(
        domain: 'mybox.example.com',
        enabled: true,
        mode: DDNSMode.v4,
        providerName: 'DynDNS',
        serverIPv4: '',
        serverIPv6: '',
        statusIPv4: null,
        statusIPv6: null,
        updateURL: '',
        username: '',
      );
      expect(info.toString(),
          'DDNSInfo(mybox.example.com, enabled=true, mode=ddns_v4)');
    });

    test('toString with null mode', () {
      final info = DDNSInfo(
        domain: 'test.example.com',
        enabled: false,
        mode: null,
        providerName: '',
        serverIPv4: '',
        serverIPv6: '',
        statusIPv4: null,
        statusIPv6: null,
        updateURL: '',
        username: '',
      );
      expect(info.toString(),
          'DDNSInfo(test.example.com, enabled=false, mode=null)');
    });
  });

  group('DDNSProvider', () {
    test('toString includes provider name', () {
      final provider = DDNSProvider(
        providerName: 'DynDNS',
        infoURL: 'https://www.dyndns.com/',
      );
      expect(provider.toString(), 'DDNSProvider(DynDNS)');
    });
  });

  group('RemoteAccessService', () {
    test('getInfo returns parsed RemoteAccessInfo', () async {
      final service = RemoteAccessService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetInfo');
          expect(arguments, isEmpty);
          return {
            'NewEnabled': '1',
            'NewPort': '443',
            'NewUsername': 'admin',
            'NewLetsEncryptEnabled': '1',
            'NewLetsEncryptState': 'valid',
          };
        },
      );

      final info = await service.getInfo();
      expect(info.enabled, isTrue);
      expect(info.port, 443);
      expect(info.username, 'admin');
      expect(info.letsEncryptEnabled, isTrue);
      expect(info.letsEncryptState, LetsEncryptState.valid);
    });

    test('setConfig sends correct arguments', () async {
      final service = RemoteAccessService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetConfig');
          expect(arguments['NewEnabled'], '1');
          expect(arguments['NewPort'], '8443');
          expect(arguments['NewUsername'], 'admin');
          expect(arguments['NewPassword'], 'secret');
          return {};
        },
      );

      await service.setConfig(
        enabled: true,
        port: 8443,
        username: 'admin',
        password: 'secret',
      );
    });

    test('setConfig sends 0 when disabling', () async {
      final service = RemoteAccessService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(arguments['NewEnabled'], '0');
          return {};
        },
      );

      await service.setConfig(
        enabled: false,
        port: 443,
        username: 'admin',
        password: 'pass',
      );
    });

    test('getDDNSInfo returns parsed DDNSInfo', () async {
      final service = RemoteAccessService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetDDNSInfo');
          expect(arguments, isEmpty);
          return {
            'NewDomain': 'mybox.example.com',
            'NewEnabled': '1',
            'NewMode': 'ddns_v4',
            'NewProviderName': 'DynDNS',
            'NewServerIPv4': 'update.dyndns.org',
            'NewServerIPv6': '',
            'NewStatusIPv4': 'complete',
            'NewStatusIPv6': '',
            'NewUpdateURL': 'https://update.dyndns.org/nic/update',
            'NewUsername': 'ddnsuser',
          };
        },
      );

      final info = await service.getDDNSInfo();
      expect(info.domain, 'mybox.example.com');
      expect(info.enabled, isTrue);
      expect(info.mode, DDNSMode.v4);
      expect(info.providerName, 'DynDNS');
      expect(info.statusIPv4, DDNSStatus.complete);
    });

    test('getDDNSProviderList returns raw XML', () async {
      final service = RemoteAccessService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetDDNSProviders');
          expect(arguments, isEmpty);
          return {
            'NewProviderList': '<List><Item><ProviderName>DynDNS</ProviderName></Item></List>',
          };
        },
      );

      final xml = await service.getDDNSProviderList();
      expect(xml, contains('DynDNS'));
    });

    test('getDDNSProviderList returns empty string when missing', () async {
      final service = RemoteAccessService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {};
        },
      );

      final xml = await service.getDDNSProviderList();
      expect(xml, '');
    });

    test('getDDNSProviders parses provider list XML', () async {
      final service = RemoteAccessService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {
            'NewProviderList': '''
<List>
  <Item>
    <ProviderName>DynDNS</ProviderName>
    <InfoURL>https://www.dyndns.com/</InfoURL>
  </Item>
  <Item>
    <ProviderName>No-IP</ProviderName>
    <InfoURL>https://www.noip.com/</InfoURL>
  </Item>
  <Item>
    <ProviderName>Benutzerdefiniert</ProviderName>
    <InfoURL></InfoURL>
  </Item>
</List>
''',
          };
        },
      );

      final providers = await service.getDDNSProviders();
      expect(providers, hasLength(3));

      expect(providers[0].providerName, 'DynDNS');
      expect(providers[0].infoURL, 'https://www.dyndns.com/');

      expect(providers[1].providerName, 'No-IP');
      expect(providers[1].infoURL, 'https://www.noip.com/');

      expect(providers[2].providerName, 'Benutzerdefiniert');
      expect(providers[2].infoURL, '');
    });

    test('getDDNSProviders returns empty list for empty XML', () async {
      final service = RemoteAccessService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewProviderList': ''};
        },
      );

      final providers = await service.getDDNSProviders();
      expect(providers, isEmpty);
    });

    test('setDDNSConfig sends correct arguments', () async {
      final service = RemoteAccessService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetDDNSConfig');
          expect(arguments['NewEnabled'], '1');
          expect(arguments['NewProviderName'], 'DynDNS');
          expect(arguments['NewUpdateURL'], 'https://update.dyndns.org/nic/update');
          expect(arguments['NewServerIPv4'], 'update.dyndns.org');
          expect(arguments['NewServerIPv6'], '');
          expect(arguments['NewDomain'], 'mybox.example.com');
          expect(arguments['NewUsername'], 'user');
          expect(arguments['NewPassword'], 'pass');
          expect(arguments['NewMode'], 'ddns_v4');
          return {};
        },
      );

      await service.setDDNSConfig(
        enabled: true,
        providerName: 'DynDNS',
        updateURL: 'https://update.dyndns.org/nic/update',
        serverIPv4: 'update.dyndns.org',
        serverIPv6: '',
        domain: 'mybox.example.com',
        username: 'user',
        password: 'pass',
        mode: DDNSMode.v4,
      );
    });

    test('setEnable returns port number', () async {
      final service = RemoteAccessService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetEnable');
          expect(arguments['NewEnabled'], '1');
          return {'NewPort': '443'};
        },
      );

      final port = await service.setEnable(true);
      expect(port, 443);
    });

    test('setEnable returns 0 for missing port', () async {
      final service = RemoteAccessService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(arguments['NewEnabled'], '0');
          return {};
        },
      );

      final port = await service.setEnable(false);
      expect(port, 0);
    });

    test('setLetsEncryptEnable sends correct arguments', () async {
      final service = RemoteAccessService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetLetsEncryptEnable');
          expect(arguments['NewLetsEncryptEnabled'], '1');
          return {};
        },
      );

      await service.setLetsEncryptEnable(true);
    });

    test('setLetsEncryptEnable sends 0 when disabling', () async {
      final service = RemoteAccessService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(arguments['NewLetsEncryptEnabled'], '0');
          return {};
        },
      );

      await service.setLetsEncryptEnable(false);
    });
  });
}
