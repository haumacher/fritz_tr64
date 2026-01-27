import 'package:fritz_tr064/src/device_description.dart';
import 'package:fritz_tr064/src/services/app_setup.dart';
import 'package:test/test.dart';

ServiceDescription _fakeDescription() {
  return ServiceDescription(
    serviceType: 'urn:dslforum-org:service:X_AVM-DE_AppSetup:1',
    serviceId: 'urn:X_AVM-DE_AppSetup-com:serviceId:X_AVM-DE_AppSetup1',
    controlUrl: '/upnp/control/x_appsetup',
    scpdUrl: '/x_appsetupSCPD.xml',
  );
}

Future<String> _unusedFetchUrl(String url) async => '';

void main() {
  group('AppRight', () {
    test('tryParse returns matching enum value', () {
      expect(AppRight.tryParse('RW'), AppRight.rw);
      expect(AppRight.tryParse('RO'), AppRight.ro);
      expect(AppRight.tryParse('NO'), AppRight.no);
      expect(AppRight.tryParse('UNDEFINED'), AppRight.undefined);
    });

    test('tryParse returns null for unknown or empty', () {
      expect(AppRight.tryParse('unknown'), isNull);
      expect(AppRight.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(AppRight.rw.toString(), 'RW');
      expect(AppRight.ro.toString(), 'RO');
      expect(AppRight.no.toString(), 'NO');
      expect(AppRight.undefined.toString(), 'UNDEFINED');
    });
  });

  group('AppEventId', () {
    test('tryParse returns matching enum value', () {
      expect(AppEventId.tryParse(300), AppEventId.jasonMessage);
      expect(AppEventId.tryParse(500), AppEventId.sipRegisterFailed);
      expect(AppEventId.tryParse(501), AppEventId.sipFailure);
      expect(AppEventId.tryParse(502), AppEventId.possibleFraud);
    });

    test('tryParse returns null for unknown', () {
      expect(AppEventId.tryParse(-1), isNull);
      expect(AppEventId.tryParse(999), isNull);
    });

    test('toString returns integer string', () {
      expect(AppEventId.jasonMessage.toString(), '300');
      expect(AppEventId.sipRegisterFailed.toString(), '500');
    });
  });

  group('AppSetupInfo', () {
    test('fromArguments parses all fields', () {
      final info = AppSetupInfo.fromArguments({
        'NewMinCharsAppId': '1',
        'NewMaxCharsAppId': '256',
        'NewAllowedCharsAppId': 'abc123',
        'NewMinCharsAppDisplayName': '1',
        'NewMaxCharsAppDisplayName': '256',
        'NewMinCharsAppUsername': '1',
        'NewMaxCharsAppUsername': '32',
        'NewAllowedCharsAppUsername': 'azAZ09',
        'NewMinCharsAppPassword': '8',
        'NewMaxCharsAppPassword': '32',
        'NewAllowedCharsAppPassword': 'azAZ09!@',
        'NewMinCharsIPSecIdentifier': '1',
        'NewMaxCharsIPSecIdentifier': '256',
        'NewAllowedCharsIPSecIdentifier': 'azAZ09',
        'NewMinCharsIPSecPreSharedKey': '1',
        'NewMaxCharsIPSecPreSharedKey': '16',
        'NewAllowedCharsIPSecPreSharedKey': 'azAZ09',
        'NewMinCharsIPSecXauthUsername': '1',
        'NewMaxCharsIPSecXauthUsername': '256',
        'NewAllowedCharsIPSecXauthUsername': 'azAZ09',
        'NewMinCharsIPSecXauthPassword': '1',
        'NewMaxCharsIPSecXauthPassword': '128',
        'NewAllowedCharsIPSecXauthPassword': 'azAZ09',
        'NewAllowedCharsCryptAlgos': 'azAZ09-_.',
        'NewAllowedCharsAppAVMAddress': 'azAZ09-_.',
        'NewMinCharsFilter': '0',
        'NewMaxCharsFilter': '1024',
        'NewAllowedCharsFilter': 'azAZ09,+:-_',
      });

      expect(info.minCharsAppId, 1);
      expect(info.maxCharsAppId, 256);
      expect(info.allowedCharsAppId, 'abc123');
      expect(info.minCharsAppDisplayName, 1);
      expect(info.maxCharsAppDisplayName, 256);
      expect(info.minCharsAppUsername, 1);
      expect(info.maxCharsAppUsername, 32);
      expect(info.allowedCharsAppUsername, 'azAZ09');
      expect(info.minCharsAppPassword, 8);
      expect(info.maxCharsAppPassword, 32);
      expect(info.allowedCharsAppPassword, 'azAZ09!@');
      expect(info.minCharsIPSecIdentifier, 1);
      expect(info.maxCharsIPSecIdentifier, 256);
      expect(info.allowedCharsIPSecIdentifier, 'azAZ09');
      expect(info.minCharsIPSecPreSharedKey, 1);
      expect(info.maxCharsIPSecPreSharedKey, 16);
      expect(info.allowedCharsIPSecPreSharedKey, 'azAZ09');
      expect(info.minCharsIPSecXauthUsername, 1);
      expect(info.maxCharsIPSecXauthUsername, 256);
      expect(info.allowedCharsIPSecXauthUsername, 'azAZ09');
      expect(info.minCharsIPSecXauthPassword, 1);
      expect(info.maxCharsIPSecXauthPassword, 128);
      expect(info.allowedCharsIPSecXauthPassword, 'azAZ09');
      expect(info.allowedCharsCryptAlgos, 'azAZ09-_.');
      expect(info.allowedCharsAppAVMAddress, 'azAZ09-_.');
      expect(info.minCharsFilter, 0);
      expect(info.maxCharsFilter, 1024);
      expect(info.allowedCharsFilter, 'azAZ09,+:-_');
    });

    test('fromArguments defaults for missing keys', () {
      final info = AppSetupInfo.fromArguments({});

      expect(info.minCharsAppId, 0);
      expect(info.maxCharsAppId, 0);
      expect(info.allowedCharsAppId, '');
      expect(info.minCharsAppDisplayName, 0);
      expect(info.maxCharsAppDisplayName, 0);
      expect(info.minCharsAppUsername, 0);
      expect(info.maxCharsAppUsername, 0);
      expect(info.allowedCharsAppUsername, '');
      expect(info.minCharsAppPassword, 0);
      expect(info.maxCharsAppPassword, 0);
      expect(info.allowedCharsAppPassword, '');
      expect(info.minCharsIPSecIdentifier, 0);
      expect(info.maxCharsIPSecIdentifier, 0);
      expect(info.allowedCharsIPSecIdentifier, '');
      expect(info.minCharsIPSecPreSharedKey, 0);
      expect(info.maxCharsIPSecPreSharedKey, 0);
      expect(info.allowedCharsIPSecPreSharedKey, '');
      expect(info.minCharsIPSecXauthUsername, 0);
      expect(info.maxCharsIPSecXauthUsername, 0);
      expect(info.allowedCharsIPSecXauthUsername, '');
      expect(info.minCharsIPSecXauthPassword, 0);
      expect(info.maxCharsIPSecXauthPassword, 0);
      expect(info.allowedCharsIPSecXauthPassword, '');
      expect(info.allowedCharsCryptAlgos, '');
      expect(info.allowedCharsAppAVMAddress, '');
      expect(info.minCharsFilter, 0);
      expect(info.maxCharsFilter, 0);
      expect(info.allowedCharsFilter, '');
    });

    test('toString includes key fields', () {
      final info = AppSetupInfo.fromArguments({
        'NewMinCharsAppId': '1',
        'NewMaxCharsAppId': '256',
        'NewMinCharsAppPassword': '8',
        'NewMaxCharsAppPassword': '32',
      });
      expect(info.toString(),
          'AppSetupInfo(appId=1-256, password=8-32)');
    });
  });

  group('AppSetupConfig', () {
    test('fromArguments parses all fields', () {
      final config = AppSetupConfig.fromArguments({
        'NewConfigRight': 'RW',
        'NewAppRight': 'RO',
        'NewNasRight': 'NO',
        'NewPhoneRight': 'RW',
        'NewDialRight': 'UNDEFINED',
        'NewHomeautoRight': 'RO',
        'NewInternetRights': '1',
        'NewAccessFromInternet': '0',
      });

      expect(config.configRight, AppRight.rw);
      expect(config.appRight, AppRight.ro);
      expect(config.nasRight, AppRight.no);
      expect(config.phoneRight, AppRight.rw);
      expect(config.dialRight, AppRight.undefined);
      expect(config.homeautoRight, AppRight.ro);
      expect(config.internetRights, isTrue);
      expect(config.accessFromInternet, isFalse);
    });

    test('fromArguments defaults for missing keys', () {
      final config = AppSetupConfig.fromArguments({});

      expect(config.configRight, isNull);
      expect(config.appRight, isNull);
      expect(config.nasRight, isNull);
      expect(config.phoneRight, isNull);
      expect(config.dialRight, isNull);
      expect(config.homeautoRight, isNull);
      expect(config.internetRights, isFalse);
      expect(config.accessFromInternet, isFalse);
    });

    test('toString includes key fields', () {
      final config = AppSetupConfig(
        configRight: AppRight.rw,
        appRight: AppRight.ro,
        nasRight: AppRight.no,
        phoneRight: AppRight.rw,
        dialRight: AppRight.undefined,
        homeautoRight: AppRight.ro,
        internetRights: true,
        accessFromInternet: false,
      );
      expect(config.toString(),
          'AppSetupConfig(config=RW, app=RO, nas=NO)');
    });
  });

  group('AppRemoteInfo', () {
    test('fromArguments parses all fields', () {
      final info = AppRemoteInfo.fromArguments({
        'NewSubnetMask': '255.255.255.0',
        'NewIPAddress': '192.168.178.1',
        'NewExternalIPAddress': '203.0.113.42',
        'NewExternalIPv6Address': '2001:db8::1',
        'NewRemoteAccessDDNSEnabled': '1',
        'NewRemoteAccessDDNSDomain': 'mybox.dyndns.org',
        'NewMyFritzDynDNSEnabled': '1',
        'NewMyFritzDynDNSName': 'mybox.myfritz.net',
      });

      expect(info.subnetMask, '255.255.255.0');
      expect(info.ipAddress, '192.168.178.1');
      expect(info.externalIPAddress, '203.0.113.42');
      expect(info.externalIPv6Address, '2001:db8::1');
      expect(info.remoteAccessDDNSEnabled, isTrue);
      expect(info.remoteAccessDDNSDomain, 'mybox.dyndns.org');
      expect(info.myFritzDynDNSEnabled, isTrue);
      expect(info.myFritzDynDNSName, 'mybox.myfritz.net');
    });

    test('fromArguments defaults for missing keys', () {
      final info = AppRemoteInfo.fromArguments({});

      expect(info.subnetMask, '');
      expect(info.ipAddress, '');
      expect(info.externalIPAddress, '');
      expect(info.externalIPv6Address, '');
      expect(info.remoteAccessDDNSEnabled, isFalse);
      expect(info.remoteAccessDDNSDomain, '');
      expect(info.myFritzDynDNSEnabled, isFalse);
      expect(info.myFritzDynDNSName, '');
    });

    test('toString includes key fields', () {
      final info = AppRemoteInfo(
        subnetMask: '255.255.255.0',
        ipAddress: '192.168.178.1',
        externalIPAddress: '203.0.113.42',
        externalIPv6Address: '',
        remoteAccessDDNSEnabled: false,
        remoteAccessDDNSDomain: '',
        myFritzDynDNSEnabled: false,
        myFritzDynDNSName: '',
      );
      expect(info.toString(),
          'AppRemoteInfo(ip=192.168.178.1, external=203.0.113.42)');
    });
  });

  group('AppMessageReceiverResult', () {
    test('fromArguments parses all fields', () {
      final result = AppMessageReceiverResult.fromArguments({
        'NewEncryptionSecret': 'secret123',
        'NewBoxSenderId': 'sender456',
      });

      expect(result.encryptionSecret, 'secret123');
      expect(result.boxSenderId, 'sender456');
    });

    test('fromArguments defaults for missing keys', () {
      final result = AppMessageReceiverResult.fromArguments({});

      expect(result.encryptionSecret, '');
      expect(result.boxSenderId, '');
    });

    test('toString includes box sender id', () {
      final result = AppMessageReceiverResult(
        encryptionSecret: 'secret',
        boxSenderId: 'sender123',
      );
      expect(result.toString(),
          'AppMessageReceiverResult(boxSenderId=sender123)');
    });
  });

  group('AppSetupService', () {
    test('getAppMessageFilter sends appId and returns filter list', () async {
      final service = AppSetupService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetAppMessageFilter');
          expect(arguments['NewAppId'], 'myapp123');
          return {'NewFilterList': '<filters><filter/></filters>'};
        },
      );

      final filterList = await service.getAppMessageFilter('myapp123');
      expect(filterList, contains('<filter/>'));
    });

    test('getAppRemoteInfo returns parsed AppRemoteInfo', () async {
      final service = AppSetupService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetAppRemoteInfo');
          expect(arguments, isEmpty);
          return {
            'NewSubnetMask': '255.255.255.0',
            'NewIPAddress': '192.168.178.1',
            'NewExternalIPAddress': '203.0.113.42',
            'NewExternalIPv6Address': '2001:db8::1',
            'NewRemoteAccessDDNSEnabled': '1',
            'NewRemoteAccessDDNSDomain': 'mybox.dyndns.org',
            'NewMyFritzDynDNSEnabled': '0',
            'NewMyFritzDynDNSName': '',
          };
        },
      );

      final info = await service.getAppRemoteInfo();
      expect(info.subnetMask, '255.255.255.0');
      expect(info.ipAddress, '192.168.178.1');
      expect(info.externalIPAddress, '203.0.113.42');
      expect(info.externalIPv6Address, '2001:db8::1');
      expect(info.remoteAccessDDNSEnabled, isTrue);
      expect(info.myFritzDynDNSEnabled, isFalse);
    });

    test('getConfig returns parsed AppSetupConfig', () async {
      final service = AppSetupService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetConfig');
          expect(arguments, isEmpty);
          return {
            'NewConfigRight': 'RW',
            'NewAppRight': 'RO',
            'NewNasRight': 'NO',
            'NewPhoneRight': 'RW',
            'NewDialRight': 'UNDEFINED',
            'NewHomeautoRight': 'RO',
            'NewInternetRights': '1',
            'NewAccessFromInternet': '0',
          };
        },
      );

      final config = await service.getConfig();
      expect(config.configRight, AppRight.rw);
      expect(config.appRight, AppRight.ro);
      expect(config.nasRight, AppRight.no);
      expect(config.internetRights, isTrue);
      expect(config.accessFromInternet, isFalse);
    });

    test('getInfo returns parsed AppSetupInfo', () async {
      final service = AppSetupService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetInfo');
          expect(arguments, isEmpty);
          return {
            'NewMinCharsAppId': '1',
            'NewMaxCharsAppId': '256',
            'NewAllowedCharsAppId': 'azAZ09',
            'NewMinCharsAppDisplayName': '1',
            'NewMaxCharsAppDisplayName': '256',
            'NewMinCharsAppUsername': '1',
            'NewMaxCharsAppUsername': '32',
            'NewAllowedCharsAppUsername': 'azAZ09',
            'NewMinCharsAppPassword': '8',
            'NewMaxCharsAppPassword': '32',
            'NewAllowedCharsAppPassword': 'azAZ09!@',
            'NewMinCharsIPSecIdentifier': '1',
            'NewMaxCharsIPSecIdentifier': '256',
            'NewAllowedCharsIPSecIdentifier': 'azAZ09',
            'NewMinCharsIPSecPreSharedKey': '1',
            'NewMaxCharsIPSecPreSharedKey': '16',
            'NewAllowedCharsIPSecPreSharedKey': 'azAZ09',
            'NewMinCharsIPSecXauthUsername': '1',
            'NewMaxCharsIPSecXauthUsername': '256',
            'NewAllowedCharsIPSecXauthUsername': 'azAZ09',
            'NewMinCharsIPSecXauthPassword': '1',
            'NewMaxCharsIPSecXauthPassword': '128',
            'NewAllowedCharsIPSecXauthPassword': 'azAZ09',
            'NewAllowedCharsCryptAlgos': 'azAZ09-_.',
            'NewAllowedCharsAppAVMAddress': 'azAZ09-_.',
            'NewMinCharsFilter': '0',
            'NewMaxCharsFilter': '1024',
            'NewAllowedCharsFilter': 'azAZ09,+:-_',
          };
        },
      );

      final info = await service.getInfo();
      expect(info.minCharsAppId, 1);
      expect(info.maxCharsAppId, 256);
      expect(info.minCharsAppPassword, 8);
      expect(info.maxCharsAppPassword, 32);
      expect(info.maxCharsFilter, 1024);
    });

    test('registerApp sends correct arguments', () async {
      final service = AppSetupService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'RegisterApp');
          expect(arguments['NewAppId'], 'myapp123');
          expect(arguments['NewAppDisplayName'], 'My App');
          expect(arguments['NewAppDeviceMAC'], 'AA:BB:CC:DD:EE:FF');
          expect(arguments['NewAppUsername'], 'appuser');
          expect(arguments['NewAppPassword'], 'Secret1!pass');
          expect(arguments['NewAppRight'], 'RO');
          expect(arguments['NewNasRight'], 'RW');
          expect(arguments['NewPhoneRight'], 'NO');
          expect(arguments['NewHomeautoRight'], 'RO');
          expect(arguments['NewAppInternetRights'], '1');
          return {};
        },
      );

      await service.registerApp(
        appId: 'myapp123',
        appDisplayName: 'My App',
        appDeviceMAC: 'AA:BB:CC:DD:EE:FF',
        appUsername: 'appuser',
        appPassword: 'Secret1!pass',
        appRight: AppRight.ro,
        nasRight: AppRight.rw,
        phoneRight: AppRight.no,
        homeautoRight: AppRight.ro,
        appInternetRights: true,
      );
    });

    test('registerApp sends 0 when internet rights disabled', () async {
      final service = AppSetupService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(arguments['NewAppInternetRights'], '0');
          return {};
        },
      );

      await service.registerApp(
        appId: 'app1',
        appDisplayName: 'App',
        appDeviceMAC: '',
        appUsername: 'user',
        appPassword: 'Password1!',
        appRight: AppRight.no,
        nasRight: AppRight.no,
        phoneRight: AppRight.no,
        homeautoRight: AppRight.no,
        appInternetRights: false,
      );
    });

    test('resetEvent sends event ID', () async {
      final service = AppSetupService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'ResetEvent');
          expect(arguments['NewEventId'], '500');
          return {};
        },
      );

      await service.resetEvent(500);
    });

    test('setAppMessageFilter sends correct arguments', () async {
      final service = AppSetupService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetAppMessageFilter');
          expect(arguments['NewAppId'], 'myapp123');
          expect(arguments['NewType'], 'aha_ident');
          expect(arguments['NewFilter'], '08761 0000444,34:45:12:43:55');
          return {};
        },
      );

      await service.setAppMessageFilter(
        appId: 'myapp123',
        type: 'aha_ident',
        filter: '08761 0000444,34:45:12:43:55',
      );
    });

    test('setAppMessageReceiver sends arguments and returns result',
        () async {
      final service = AppSetupService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetAppMessageReceiver');
          expect(arguments['NewAppId'], 'myapp123');
          expect(arguments['NewCryptAlgos'], '');
          expect(arguments['NewAppAVMAddress'], 'addr123');
          expect(arguments['NewAppAVMPasswordHash'], 'hash456');
          return {
            'NewEncryptionSecret': 'secret789',
            'NewBoxSenderId': 'box001',
          };
        },
      );

      final result = await service.setAppMessageReceiver(
        appId: 'myapp123',
        cryptAlgos: '',
        appAVMAddress: 'addr123',
        appAVMPasswordHash: 'hash456',
      );
      expect(result.encryptionSecret, 'secret789');
      expect(result.boxSenderId, 'box001');
    });

    test('setAppVPN sends correct arguments', () async {
      final service = AppSetupService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetAppVPN');
          expect(arguments['NewAppId'], 'myapp123');
          expect(arguments['NewIPSecIdentifier'], 'vpnid');
          expect(arguments['NewIPSecPreSharedKey'], 'psk123');
          expect(arguments['NewIPSecXauthUsername'], 'vpnuser');
          expect(arguments['NewIPSecXauthPassword'], 'vpnpass');
          return {};
        },
      );

      await service.setAppVPN(
        appId: 'myapp123',
        ipSecIdentifier: 'vpnid',
        ipSecPreSharedKey: 'psk123',
        ipSecXauthUsername: 'vpnuser',
        ipSecXauthPassword: 'vpnpass',
      );
    });

    test('setAppVPNWithPFS sends correct arguments', () async {
      final service = AppSetupService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetAppVPNwithPFS');
          expect(arguments['NewAppId'], 'myapp123');
          expect(arguments['NewIPSecIdentifier'], 'vpnid');
          expect(arguments['NewIPSecPreSharedKey'], 'psk123');
          expect(arguments['NewIPSecXauthUsername'], 'vpnuser');
          expect(arguments['NewIPSecXauthPassword'], 'vpnpass');
          return {};
        },
      );

      await service.setAppVPNWithPFS(
        appId: 'myapp123',
        ipSecIdentifier: 'vpnid',
        ipSecPreSharedKey: 'psk123',
        ipSecXauthUsername: 'vpnuser',
        ipSecXauthPassword: 'vpnpass',
      );
    });

    test('getBoxSenderId sends appId and returns sender id', () async {
      final service = AppSetupService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetBoxSenderId');
          expect(arguments['NewAppId'], 'myapp123');
          return {'NewBoxSenderId': 'box001'};
        },
      );

      final senderId = await service.getBoxSenderId('myapp123');
      expect(senderId, 'box001');
    });

    test('getBoxSenderId returns empty string for missing key', () async {
      final service = AppSetupService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {};
        },
      );

      final senderId = await service.getBoxSenderId('app1');
      expect(senderId, '');
    });
  });
}
