import 'package:fritz_tr064/src/device_description.dart';
import 'package:fritz_tr064/src/services/voip.dart';
import 'package:test/test.dart';

ServiceDescription _fakeDescription() {
  return ServiceDescription(
    serviceType: 'urn:dslforum-org:service:X_VoIP:1',
    serviceId: 'urn:X_VoIP-com:serviceId:X_VoIP1',
    controlUrl: '/upnp/control/x_voip',
    scpdUrl: '/x_voipSCPD.xml',
  );
}

Future<String> _unusedFetchUrl(String url) async => '';

void main() {
  group('VoiceCoding', () {
    test('tryParse returns matching enum value', () {
      expect(VoiceCoding.tryParse('fixed'), VoiceCoding.fixed);
      expect(VoiceCoding.tryParse('auto'), VoiceCoding.auto);
      expect(VoiceCoding.tryParse('compressed'), VoiceCoding.compressed);
      expect(
          VoiceCoding.tryParse('autocompressed'), VoiceCoding.autocompressed);
    });

    test('tryParse returns null for unrecognised or empty', () {
      expect(VoiceCoding.tryParse('G.711'), isNull);
      expect(VoiceCoding.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(VoiceCoding.fixed.toString(), 'fixed');
      expect(VoiceCoding.auto.toString(), 'auto');
      expect(VoiceCoding.compressed.toString(), 'compressed');
      expect(VoiceCoding.autocompressed.toString(), 'autocompressed');
    });
  });

  group('VoIPStatus', () {
    test('tryParse returns matching enum value', () {
      expect(VoIPStatus.tryParse('disabled'), VoIPStatus.disabled);
      expect(VoIPStatus.tryParse('not registered'), VoIPStatus.notRegistered);
      expect(VoIPStatus.tryParse('registered'), VoIPStatus.registered);
      expect(VoIPStatus.tryParse('connected'), VoIPStatus.connected);
      expect(VoIPStatus.tryParse('unknown'), VoIPStatus.unknown);
    });

    test('tryParse returns null for unrecognised or empty', () {
      expect(VoIPStatus.tryParse('Registered'), isNull);
      expect(VoIPStatus.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(VoIPStatus.disabled.toString(), 'disabled');
      expect(VoIPStatus.notRegistered.toString(), 'not registered');
      expect(VoIPStatus.registered.toString(), 'registered');
      expect(VoIPStatus.connected.toString(), 'connected');
      expect(VoIPStatus.unknown.toString(), 'unknown');
    });
  });

  group('VoIPInfo', () {
    test('fromArguments parses all fields', () {
      final info = VoIPInfo.fromArguments({
        'NewFaxT38Enable': '1',
        'NewVoiceCoding': 'fixed',
      });

      expect(info.faxT38Enable, isTrue);
      expect(info.voiceCoding, VoiceCoding.fixed);
    });

    test('fromArguments defaults for missing keys', () {
      final info = VoIPInfo.fromArguments({});

      expect(info.faxT38Enable, isFalse);
      expect(info.voiceCoding, isNull);
    });

    test('toString includes key fields', () {
      final info = VoIPInfo(faxT38Enable: true, voiceCoding: VoiceCoding.auto);
      expect(info.toString(), contains('faxT38=true'));
      expect(info.toString(), contains('coding=auto'));
    });
  });

  group('VoIPInfoEx', () {
    test('fromArguments parses all fields', () {
      final info = VoIPInfoEx.fromArguments({
        'NewVoIPNumberMinChars': '1',
        'NewVoIPNumberMaxChars': '32',
        'NewVoIPNumberAllowedChars': '0123456789',
        'NewVoIPRegistrarMinChars': '1',
        'NewVoIPRegistrarMaxChars': '64',
        'NewVoIPRegistrarAllowedChars': 'abc',
        'NewVoIPSTUNServerMinChars': '0',
        'NewVoIPSTUNServerMaxChars': '128',
        'NewVoIPSTUNServerAllowedChars': 'def',
        'NewVoIPUsernameMinChars': '1',
        'NewVoIPUsernameMaxChars': '48',
        'NewVoIPUsernameAllowedChars': 'ghi',
        'NewVoIPPasswordMinChars': '1',
        'NewVoIPPasswordMaxChars': '32',
        'NewVoIPPasswordAllowedChars': 'jkl',
        'NewX_AVM-DE_ClientUsernameMinChars': '0',
        'NewX_AVM-DE_ClientUsernameMaxChars': '64',
        'NewX_AVM-DE_ClientUsernameAllowedChars': 'mno',
        'NewX_AVM-DE_ClientPasswordMinChars': '0',
        'NewX_AVM-DE_ClientPasswordMaxChars': '64',
        'NewX_AVM-DE_ClientPasswordAllowedChars': 'pqr',
      });

      expect(info.voIPNumberMinChars, 1);
      expect(info.voIPNumberMaxChars, 32);
      expect(info.voIPNumberAllowedChars, '0123456789');
      expect(info.voIPRegistrarMinChars, 1);
      expect(info.voIPRegistrarMaxChars, 64);
      expect(info.voIPSTUNServerMaxChars, 128);
      expect(info.voIPUsernameMaxChars, 48);
      expect(info.voIPPasswordMaxChars, 32);
      expect(info.clientUsernameMinChars, 0);
      expect(info.clientUsernameMaxChars, 64);
      expect(info.clientUsernameAllowedChars, 'mno');
      expect(info.clientPasswordMinChars, 0);
      expect(info.clientPasswordMaxChars, 64);
      expect(info.clientPasswordAllowedChars, 'pqr');
    });

    test('fromArguments defaults for missing keys', () {
      final info = VoIPInfoEx.fromArguments({});

      expect(info.voIPNumberMinChars, 0);
      expect(info.voIPNumberMaxChars, 0);
      expect(info.voIPNumberAllowedChars, '');
      expect(info.clientUsernameMinChars, 0);
      expect(info.clientPasswordAllowedChars, '');
    });
  });

  group('VoIPAccount', () {
    test('fromArguments parses all fields', () {
      final account = VoIPAccount.fromArguments({
        'NewVoIPRegistrar': 'sip.example.com',
        'NewVoIPNumber': '+4930123456',
        'NewVoIPUsername': 'user1',
        'NewVoIPOutboundProxy': 'proxy.example.com',
        'NewVoIPSTUNServer': 'stun.example.com',
        'NewVoIPStatus': 'registered',
      });

      expect(account.registrar, 'sip.example.com');
      expect(account.number, '+4930123456');
      expect(account.username, 'user1');
      expect(account.outboundProxy, 'proxy.example.com');
      expect(account.stunServer, 'stun.example.com');
      expect(account.status, VoIPStatus.registered);
    });

    test('fromArguments defaults for missing keys', () {
      final account = VoIPAccount.fromArguments({});

      expect(account.registrar, '');
      expect(account.number, '');
      expect(account.username, '');
      expect(account.outboundProxy, '');
      expect(account.stunServer, '');
      expect(account.status, isNull);
    });

    test('toString includes number and registrar', () {
      final account = VoIPAccount(
        registrar: 'sip.example.com',
        number: '+49123',
        username: 'u',
        outboundProxy: '',
        stunServer: '',
        status: null,
      );
      expect(account.toString(), 'VoIPAccount(+49123, sip.example.com)');
    });
  });

  group('VoIPClient', () {
    test('fromArguments parses all fields including incoming XML', () {
      final client = VoIPClient.fromArguments({
        'NewX_AVM-DE_ClientIndex': '0',
        'NewX_AVM-DE_ClientUsername': 'sipuser',
        'NewX_AVM-DE_ClientRegistrar': 'fritz.box',
        'NewX_AVM-DE_ClientRegistrarPort': '5060',
        'NewX_AVM-DE_PhoneName': 'Phone 1',
        'NewX_AVM-DE_ClientId': 'client-abc',
        'NewX_AVM-DE_OutGoingNumber': '+4930123456',
        'NewX_AVM-DE_InComingNumbers':
            '<List>'
            '<Item><Number>+4930123456</Number><Type>eVoIP</Type>'
            '<Index>0</Index><Name>Main</Name></Item>'
            '<Item><Number>+4930789</Number><Type>ePOTS</Type>'
            '<Index>1</Index><Name>Fax</Name></Item>'
            '</List>',
        'NewX_AVM-DE_ExternalRegistration': '1',
        'NewX_AVM-DE_InternalNumber': '**620',
        'NewX_AVM-DE_DelayedCallNotification': '0',
      });

      expect(client.clientIndex, 0);
      expect(client.clientUsername, 'sipuser');
      expect(client.clientRegistrar, 'fritz.box');
      expect(client.clientRegistrarPort, 5060);
      expect(client.phoneName, 'Phone 1');
      expect(client.clientId, 'client-abc');
      expect(client.outGoingNumber, '+4930123456');
      expect(client.inComingNumbers, hasLength(2));
      expect(client.inComingNumbers[0].number, '+4930123456');
      expect(client.inComingNumbers[0].type, VoIPNumberType.eVoIP);
      expect(client.inComingNumbers[0].name, 'Main');
      expect(client.inComingNumbers[1].number, '+4930789');
      expect(client.inComingNumbers[1].type, VoIPNumberType.ePOTS);
      expect(client.externalRegistration, isTrue);
      expect(client.internalNumber, '**620');
      expect(client.delayedCallNotification, isFalse);
    });

    test('fromArguments parses eAllCalls with empty fields', () {
      final client = VoIPClient.fromArguments({
        'NewX_AVM-DE_ClientIndex': '1',
        'NewX_AVM-DE_InComingNumbers':
            '<List><Item><Number /><Type>eAllCalls</Type>'
            '<Index /><Name /></Item></List>',
      });

      expect(client.inComingNumbers, hasLength(1));
      expect(client.inComingNumbers[0].type, VoIPNumberType.eAllCalls);
      expect(client.inComingNumbers[0].number, '');
      expect(client.inComingNumbers[0].index, 0);
      expect(client.inComingNumbers[0].name, '');
    });

    test('fromArguments defaults for missing keys', () {
      final client = VoIPClient.fromArguments({});

      expect(client.clientIndex, 0);
      expect(client.clientUsername, '');
      expect(client.clientRegistrar, '');
      expect(client.clientRegistrarPort, 0);
      expect(client.phoneName, '');
      expect(client.clientId, '');
      expect(client.outGoingNumber, '');
      expect(client.inComingNumbers, isEmpty);
      expect(client.externalRegistration, isFalse);
      expect(client.internalNumber, '');
      expect(client.delayedCallNotification, isFalse);
    });
  });

  group('VoIPNumberType', () {
    test('tryParse returns matching enum value', () {
      expect(VoIPNumberType.tryParse('eVoIP'), VoIPNumberType.eVoIP);
      expect(VoIPNumberType.tryParse('ePOTS'), VoIPNumberType.ePOTS);
      expect(VoIPNumberType.tryParse('eISDN'), VoIPNumberType.eISDN);
      expect(VoIPNumberType.tryParse('eGSM'), VoIPNumberType.eGSM);
      expect(VoIPNumberType.tryParse('eNone'), VoIPNumberType.eNone);
      expect(VoIPNumberType.tryParse('eAllCalls'), VoIPNumberType.eAllCalls);
    });

    test('tryParse returns null for unknown', () {
      expect(VoIPNumberType.tryParse('unknown'), isNull);
    });
  });

  group('AlarmClock', () {
    test('fromArguments parses all fields', () {
      final alarm = AlarmClock.fromArguments({
        'NewX_AVM-DE_AlarmClockEnable': '1',
        'NewX_AVM-DE_AlarmClockName': 'Morning',
        'NewX_AVM-DE_AlarmClockFormattedTime': '07:30',
        'NewX_AVM-DE_AlarmClockWeekdays': 'mo,tu,we,th,fr',
        'NewX_AVM-DE_AlarmClockPhoneName': 'FON 1',
      });

      expect(alarm.enable, isTrue);
      expect(alarm.name, 'Morning');
      expect(alarm.time, '07:30');
      expect(alarm.weekdays, 'mo,tu,we,th,fr');
      expect(alarm.phoneName, 'FON 1');
    });

    test('fromArguments defaults for missing keys', () {
      final alarm = AlarmClock.fromArguments({});

      expect(alarm.enable, isFalse);
      expect(alarm.name, '');
      expect(alarm.time, '');
      expect(alarm.weekdays, '');
      expect(alarm.phoneName, '');
    });

    test('toString includes name and time', () {
      final alarm = AlarmClock(
        enable: true,
        name: 'Wake Up',
        time: '06:00',
        weekdays: 'daily',
        phoneName: 'FON 1',
      );
      expect(alarm.toString(), 'AlarmClock(Wake Up, 06:00)');
    });
  });

  group('CountryCode', () {
    test('fromArguments parses all fields', () {
      final cc = CountryCode.fromArguments({
        'NewX_AVM-DE_LKZ': '49',
        'NewX_AVM-DE_LKZPrefix': '00',
      });

      expect(cc.lkz, '49');
      expect(cc.lkzPrefix, '00');
    });

    test('fromArguments defaults for missing keys', () {
      final cc = CountryCode.fromArguments({});

      expect(cc.lkz, '');
      expect(cc.lkzPrefix, '');
    });

    test('toString shows prefix and code', () {
      final cc = CountryCode(lkz: '49', lkzPrefix: '00');
      expect(cc.toString(), 'CountryCode(0049)');
    });
  });

  group('AreaCode', () {
    test('fromArguments parses all fields', () {
      final ac = AreaCode.fromArguments({
        'NewX_AVM-DE_OKZ': '30',
        'NewX_AVM-DE_OKZPrefix': '0',
      });

      expect(ac.okz, '30');
      expect(ac.okzPrefix, '0');
    });

    test('fromArguments defaults for missing keys', () {
      final ac = AreaCode.fromArguments({});

      expect(ac.okz, '');
      expect(ac.okzPrefix, '');
    });

    test('toString shows prefix and code', () {
      final ac = AreaCode(okz: '30', okzPrefix: '0');
      expect(ac.toString(), 'AreaCode(030)');
    });
  });

  group('VoIPService', () {
    test('getInfo returns VoIPInfo', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetInfo');
          expect(arguments, isEmpty);
          return {
            'NewFaxT38Enable': '1',
            'NewVoiceCoding': 'fixed',
          };
        },
      );

      final info = await service.getInfo();
      expect(info.faxT38Enable, isTrue);
      expect(info.voiceCoding, VoiceCoding.fixed);
    });

    test('getInfoEx returns VoIPInfoEx', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetInfoEx');
          return {
            'NewVoIPNumberMinChars': '1',
            'NewVoIPNumberMaxChars': '32',
            'NewVoIPNumberAllowedChars': '0-9',
            'NewVoIPRegistrarMinChars': '1',
            'NewVoIPRegistrarMaxChars': '64',
            'NewVoIPRegistrarAllowedChars': 'a-z',
            'NewVoIPSTUNServerMinChars': '0',
            'NewVoIPSTUNServerMaxChars': '128',
            'NewVoIPSTUNServerAllowedChars': 'a-z',
            'NewVoIPUsernameMinChars': '1',
            'NewVoIPUsernameMaxChars': '48',
            'NewVoIPUsernameAllowedChars': 'a-z',
            'NewVoIPPasswordMinChars': '1',
            'NewVoIPPasswordMaxChars': '32',
            'NewVoIPPasswordAllowedChars': 'a-z',
            'NewX_AVM-DE_ClientUsernameMinChars': '0',
            'NewX_AVM-DE_ClientUsernameMaxChars': '64',
            'NewX_AVM-DE_ClientUsernameAllowedChars': 'a-z',
            'NewX_AVM-DE_ClientPasswordMinChars': '0',
            'NewX_AVM-DE_ClientPasswordMaxChars': '64',
            'NewX_AVM-DE_ClientPasswordAllowedChars': 'a-z',
          };
        },
      );

      final info = await service.getInfoEx();
      expect(info.voIPNumberMinChars, 1);
      expect(info.voIPNumberMaxChars, 32);
      expect(info.clientUsernameMaxChars, 64);
      expect(info.clientPasswordMaxChars, 64);
    });

    test('getExistingVoIPNumbers returns count', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetExistingVoIPNumbers');
          return {'NewExistingVoIPNumbers': '3'};
        },
      );

      final count = await service.getExistingVoIPNumbers();
      expect(count, 3);
    });

    test('getMaxVoIPNumbers returns count', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetMaxVoIPNumbers');
          return {'NewMaxVoIPNumbers': '10'};
        },
      );

      final count = await service.getMaxVoIPNumbers();
      expect(count, 10);
    });

    test('getVoIPAccount passes index and returns VoIPAccount', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetVoIPAccount');
          expect(arguments['NewVoIPAccountIndex'], '0');
          return {
            'NewVoIPRegistrar': 'sip.example.com',
            'NewVoIPNumber': '+4930123456',
            'NewVoIPUsername': 'user1',
            'NewVoIPOutboundProxy': 'proxy.example.com',
            'NewVoIPSTUNServer': 'stun.example.com',
            'NewVoIPStatus': 'registered',
          };
        },
      );

      final account = await service.getVoIPAccount(0);
      expect(account.registrar, 'sip.example.com');
      expect(account.number, '+4930123456');
      expect(account.username, 'user1');
      expect(account.status, VoIPStatus.registered);
    });

    test('getVoIPAccounts parses XML list', () async {
      const accountsXml = '''
<List>
  <Item>
    <Number>+4930111</Number>
    <Registrar>sip1.example.com</Registrar>
    <Username>u1</Username>
    <OutboundProxy>proxy1</OutboundProxy>
    <STUNServer>stun1</STUNServer>
    <Status>connected</Status>
  </Item>
  <Item>
    <Number>+4930222</Number>
    <Registrar>sip2.example.com</Registrar>
    <Username>u2</Username>
    <OutboundProxy></OutboundProxy>
    <STUNServer></STUNServer>
    <Status>disabled</Status>
  </Item>
</List>''';

      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_GetVoIPAccounts');
          return {'NewX_AVM-DE_VoIPAccountList': accountsXml};
        },
      );

      final accounts = await service.getVoIPAccounts();
      expect(accounts, hasLength(2));
      expect(accounts[0].number, '+4930111');
      expect(accounts[0].registrar, 'sip1.example.com');
      expect(accounts[0].username, 'u1');
      expect(accounts[0].status, VoIPStatus.connected);
      expect(accounts[1].number, '+4930222');
      expect(accounts[1].registrar, 'sip2.example.com');
      expect(accounts[1].status, VoIPStatus.disabled);
    });

    test('getVoIPAccounts returns empty list for empty XML', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewX_AVM-DE_VoIPAccountList': ''};
        },
      );

      final accounts = await service.getVoIPAccounts();
      expect(accounts, isEmpty);
    });

    test('getVoIPStatus returns parsed status', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetVoIPStatus');
          expect(arguments['NewVoIPAccountIndex'], '1');
          return {'NewVoIPStatus': 'registered'};
        },
      );

      final status = await service.getVoIPStatus(1);
      expect(status, VoIPStatus.registered);
    });

    test('getVoIPEnableAreaCode returns bool', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetVoIPEnableAreaCode');
          expect(arguments['NewVoIPAccountIndex'], '0');
          return {'NewVoIPEnableAreaCode': '1'};
        },
      );

      final enabled = await service.getVoIPEnableAreaCode(0);
      expect(enabled, isTrue);
    });

    test('setVoIPEnableAreaCode passes index and enable flag', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetVoIPEnableAreaCode');
          expect(arguments['NewVoIPAccountIndex'], '2');
          expect(arguments['NewVoIPEnableAreaCode'], '0');
          return {};
        },
      );

      await service.setVoIPEnableAreaCode(2, false);
    });

    test('getVoIPEnableCountryCode returns bool', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetVoIPEnableCountryCode');
          expect(arguments['NewVoIPAccountIndex'], '0');
          return {'NewVoIPEnableCountryCode': '0'};
        },
      );

      final enabled = await service.getVoIPEnableCountryCode(0);
      expect(enabled, isFalse);
    });

    test('setVoIPEnableCountryCode passes index and enable flag', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetVoIPEnableCountryCode');
          expect(arguments['NewVoIPAccountIndex'], '1');
          expect(arguments['NewVoIPEnableCountryCode'], '1');
          return {};
        },
      );

      await service.setVoIPEnableCountryCode(1, true);
    });

    test('setConfig passes faxT38Enable and voiceCoding', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetConfig');
          expect(arguments['NewFaxT38Enable'], '1');
          expect(arguments['NewVoiceCoding'], 'auto');
          return {};
        },
      );

      await service.setConfig(
          faxT38Enable: true, voiceCoding: VoiceCoding.auto);
    });

    test('getVoIPCommonCountryCode returns CountryCode', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_GetVoIPCommonCountryCode');
          return {
            'NewX_AVM-DE_LKZ': '49',
            'NewX_AVM-DE_LKZPrefix': '00',
          };
        },
      );

      final cc = await service.getVoIPCommonCountryCode();
      expect(cc.lkz, '49');
      expect(cc.lkzPrefix, '00');
    });

    test('setVoIPCommonCountryCode passes lkz and prefix', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_SetVoIPCommonCountryCode');
          expect(arguments['NewX_AVM-DE_LKZ'], '49');
          expect(arguments['NewX_AVM-DE_LKZPrefix'], '00');
          return {};
        },
      );

      await service.setVoIPCommonCountryCode('49', '00');
    });

    test('getVoIPCommonAreaCode returns AreaCode', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_GetVoIPCommonAreaCode');
          return {
            'NewX_AVM-DE_OKZ': '30',
            'NewX_AVM-DE_OKZPrefix': '0',
          };
        },
      );

      final ac = await service.getVoIPCommonAreaCode();
      expect(ac.okz, '30');
      expect(ac.okzPrefix, '0');
    });

    test('setVoIPCommonAreaCode passes okz and prefix', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_SetVoIPCommonAreaCode');
          expect(arguments['NewX_AVM-DE_OKZ'], '30');
          expect(arguments['NewX_AVM-DE_OKZPrefix'], '0');
          return {};
        },
      );

      await service.setVoIPCommonAreaCode('30', '0');
    });

    test('addVoIPAccount passes all parameters', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'AddVoIPAccount');
          expect(arguments['NewVoIPAccountIndex'], '0');
          expect(arguments['NewVoIPRegistrar'], 'sip.example.com');
          expect(arguments['NewVoIPNumber'], '+49123');
          expect(arguments['NewVoIPUsername'], 'user');
          expect(arguments['NewVoIPPassword'], 'pass');
          expect(arguments['NewVoIPOutboundProxy'], 'proxy');
          expect(arguments['NewVoIPSTUNServer'], 'stun');
          return {};
        },
      );

      await service.addVoIPAccount(
        accountIndex: 0,
        registrar: 'sip.example.com',
        number: '+49123',
        username: 'user',
        password: 'pass',
        outboundProxy: 'proxy',
        stunServer: 'stun',
      );
    });

    test('deleteVoIPAccount passes index', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'DeleteVoIPAccount');
          expect(arguments['NewVoIPAccountIndex'], '2');
          return {};
        },
      );

      await service.deleteVoIPAccount(2);
    });

    test('dialGetConfig returns phone name', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_DialGetConfig');
          return {'NewX_AVM-DE_PhoneName': 'FON 1'};
        },
      );

      final name = await service.dialGetConfig();
      expect(name, 'FON 1');
    });

    test('dialHangup calls action', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_DialHangup');
          expect(arguments, isEmpty);
          return {};
        },
      );

      await service.dialHangup();
    });

    test('dialNumber passes phone number', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_DialNumber');
          expect(arguments['NewX_AVM-DE_PhoneNumber'], '+4930123456');
          return {};
        },
      );

      await service.dialNumber('+4930123456');
    });

    test('dialSetConfig passes phone name', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_DialSetConfig');
          expect(arguments['NewX_AVM-DE_PhoneName'], 'FON 2');
          return {};
        },
      );

      await service.dialSetConfig('FON 2');
    });

    test('getNumberOfClients returns count', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_GetNumberOfClients');
          return {'NewX_AVM-DE_NumberOfClients': '5'};
        },
      );

      final count = await service.getNumberOfClients();
      expect(count, 5);
    });

    test('getClient returns VoIPClient via GetClient2', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_GetClient2');
          expect(arguments['NewX_AVM-DE_ClientIndex'], '0');
          return {
            'NewX_AVM-DE_ClientIndex': '0',
            'NewX_AVM-DE_ClientUsername': 'sipuser',
            'NewX_AVM-DE_ClientRegistrar': 'fritz.box',
            'NewX_AVM-DE_ClientRegistrarPort': '5060',
            'NewX_AVM-DE_PhoneName': 'Phone 1',
            'NewX_AVM-DE_ClientId': 'abc',
            'NewX_AVM-DE_OutGoingNumber': '+49123',
            'NewX_AVM-DE_InComingNumbers':
                '<List><Item><Number>+49123</Number><Type>eVoIP</Type>'
                '<Index>0</Index><Name>Line</Name></Item></List>',
            'NewX_AVM-DE_ExternalRegistration': '0',
            'NewX_AVM-DE_InternalNumber': '**620',
            'NewX_AVM-DE_DelayedCallNotification': '0',
          };
        },
      );

      final client = await service.getClient(0);
      expect(client.clientUsername, 'sipuser');
      expect(client.phoneName, 'Phone 1');
      expect(client.internalNumber, '**620');
      expect(client.inComingNumbers, hasLength(1));
      expect(client.inComingNumbers[0].number, '+49123');
    });

    test('getClient3 returns VoIPClient with full info', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_GetClient3');
          expect(arguments['NewX_AVM-DE_ClientIndex'], '1');
          return {
            'NewX_AVM-DE_ClientIndex': '1',
            'NewX_AVM-DE_ClientUsername': 'user2',
            'NewX_AVM-DE_ClientRegistrar': 'external.sip',
            'NewX_AVM-DE_ClientRegistrarPort': '5061',
            'NewX_AVM-DE_PhoneName': 'SIP Phone',
            'NewX_AVM-DE_ClientId': 'client-2',
            'NewX_AVM-DE_OutGoingNumber': '+4930555',
            'NewX_AVM-DE_InComingNumbers':
                '<List>'
                '<Item><Number>+4930555</Number><Type>eVoIP</Type>'
                '<Index>0</Index><Name>Main</Name></Item>'
                '<Item><Number>+4930666</Number><Type>eVoIP</Type>'
                '<Index>1</Index><Name>Second</Name></Item>'
                '</List>',
            'NewX_AVM-DE_ExternalRegistration': '1',
            'NewX_AVM-DE_InternalNumber': '**621',
            'NewX_AVM-DE_DelayedCallNotification': '1',
          };
        },
      );

      final client = await service.getClient3(1);
      expect(client.clientIndex, 1);
      expect(client.clientUsername, 'user2');
      expect(client.clientRegistrar, 'external.sip');
      expect(client.clientRegistrarPort, 5061);
      expect(client.phoneName, 'SIP Phone');
      expect(client.clientId, 'client-2');
      expect(client.outGoingNumber, '+4930555');
      expect(client.inComingNumbers, hasLength(2));
      expect(client.inComingNumbers[0].number, '+4930555');
      expect(client.inComingNumbers[0].type, VoIPNumberType.eVoIP);
      expect(client.inComingNumbers[1].number, '+4930666');
      expect(client.externalRegistration, isTrue);
      expect(client.internalNumber, '**621');
      expect(client.delayedCallNotification, isTrue);
    });

    test('getClientByClientId passes clientId', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_GetClientByClientId');
          expect(arguments['NewX_AVM-DE_ClientId'], 'client-xyz');
          return {
            'NewX_AVM-DE_ClientIndex': '2',
            'NewX_AVM-DE_ClientUsername': '',
            'NewX_AVM-DE_ClientRegistrar': '',
            'NewX_AVM-DE_ClientRegistrarPort': '0',
            'NewX_AVM-DE_PhoneName': 'Found Phone',
            'NewX_AVM-DE_ClientId': 'client-xyz',
            'NewX_AVM-DE_OutGoingNumber': '',
            'NewX_AVM-DE_InComingNumbers': '',
            'NewX_AVM-DE_ExternalRegistration': '0',
            'NewX_AVM-DE_InternalNumber': '',
            'NewX_AVM-DE_DelayedCallNotification': '0',
          };
        },
      );

      final client = await service.getClientByClientId('client-xyz');
      expect(client.clientId, 'client-xyz');
      expect(client.phoneName, 'Found Phone');
    });

    test('getClients returns raw XML', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_GetClients');
          return {'NewX_AVM-DE_ClientList': '<List><Item/></List>'};
        },
      );

      final xml = await service.getClients();
      expect(xml, '<List><Item/></List>');
    });

    test('deleteClient passes clientIndex', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_DeleteClient');
          expect(arguments['NewX_AVM-DE_ClientIndex'], '3');
          return {};
        },
      );

      await service.deleteClient(3);
    });

    test('setClient passes all parameters via SetClient2', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_SetClient2');
          expect(arguments['NewX_AVM-DE_ClientIndex'], '0');
          expect(arguments['NewX_AVM-DE_ClientPassword'], 'secret');
          expect(arguments['NewX_AVM-DE_PhoneName'], 'My Phone');
          expect(arguments['NewX_AVM-DE_ClientId'], 'id1');
          expect(arguments['NewX_AVM-DE_OutGoingNumber'], '+49123');
          return {};
        },
      );

      await service.setClient(
        clientIndex: 0,
        password: 'secret',
        phoneName: 'My Phone',
        clientId: 'id1',
        outGoingNumber: '+49123',
      );
    });

    test('setClient3 passes all parameters including incoming and external',
        () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_SetClient3');
          expect(arguments['NewX_AVM-DE_ClientIndex'], '1');
          expect(arguments['NewX_AVM-DE_ClientPassword'], 'pw');
          expect(arguments['NewX_AVM-DE_PhoneName'], 'Phone');
          expect(arguments['NewX_AVM-DE_ClientId'], 'id2');
          expect(arguments['NewX_AVM-DE_OutGoingNumber'], '+49a');
          expect(arguments['NewX_AVM-DE_InComingNumbers'], '+49a,+49b');
          expect(arguments['NewX_AVM-DE_ExternalRegistration'], '1');
          return {};
        },
      );

      await service.setClient3(
        clientIndex: 1,
        password: 'pw',
        phoneName: 'Phone',
        clientId: 'id2',
        outGoingNumber: '+49a',
        inComingNumbers: '+49a,+49b',
        externalRegistration: true,
      );
    });

    test('setClient4 passes all parameters and returns internalNumber',
        () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_SetClient4');
          expect(arguments['NewX_AVM-DE_ClientIndex'], '0');
          expect(arguments['NewX_AVM-DE_ClientPassword'], 'pw');
          expect(arguments['NewX_AVM-DE_ClientUsername'], 'sipuser');
          expect(arguments['NewX_AVM-DE_PhoneName'], 'P');
          expect(arguments['NewX_AVM-DE_ClientId'], 'cid');
          expect(arguments['NewX_AVM-DE_OutGoingNumber'], '+49x');
          expect(arguments['NewX_AVM-DE_InComingNumbers'], '+49x');
          return {'NewX_AVM-DE_InternalNumber': '**622'};
        },
      );

      final num = await service.setClient4(
        clientIndex: 0,
        password: 'pw',
        clientUsername: 'sipuser',
        phoneName: 'P',
        clientId: 'cid',
        outGoingNumber: '+49x',
        inComingNumbers: '+49x',
      );
      expect(num, '**622');
    });

    test('setDelayedCallNotification passes index and enable', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_SetDelayedCallNotification');
          expect(arguments['NewX_AVM-DE_ClientIndex'], '2');
          expect(arguments['NewX_AVM-DE_DelayedCallNotification'], '1');
          return {};
        },
      );

      await service.setDelayedCallNotification(2, true);
    });

    test('getNumberOfNumbers returns count', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_GetNumberOfNumbers');
          return {'NewNumberOfNumbers': '4'};
        },
      );

      final count = await service.getNumberOfNumbers();
      expect(count, 4);
    });

    test('getNumbers parses XML list', () async {
      const numbersXml = '''
<List>
  <Item>
    <Number>+4930111</Number>
    <Type>eVoIP</Type>
    <Index>0</Index>
    <Name>Main Line</Name>
  </Item>
  <Item>
    <Number>+4930222</Number>
    <Type>ePOTS</Type>
    <Index>1</Index>
    <Name>Fax</Name>
  </Item>
  <Item>
    <Number>+4930333</Number>
    <Type>eISDN</Type>
    <Index>2</Index>
    <Name>ISDN Line</Name>
  </Item>
</List>''';

      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_GetNumbers');
          return {'NewNumberList': numbersXml};
        },
      );

      final numbers = await service.getNumbers();
      expect(numbers, hasLength(3));
      expect(numbers[0].number, '+4930111');
      expect(numbers[0].type, VoIPNumberType.eVoIP);
      expect(numbers[0].index, 0);
      expect(numbers[0].name, 'Main Line');
      expect(numbers[1].number, '+4930222');
      expect(numbers[1].type, VoIPNumberType.ePOTS);
      expect(numbers[1].index, 1);
      expect(numbers[1].name, 'Fax');
      expect(numbers[2].type, VoIPNumberType.eISDN);
    });

    test('getNumbers returns empty list for empty XML', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewNumberList': ''};
        },
      );

      final numbers = await service.getNumbers();
      expect(numbers, isEmpty);
    });

    test('getNumbers skips items with unknown type', () async {
      const numbersXml = '''
<List>
  <Item>
    <Number>+49111</Number>
    <Type>eVoIP</Type>
    <Index>0</Index>
    <Name>Known</Name>
  </Item>
  <Item>
    <Number>+49222</Number>
    <Type>eUnknown</Type>
    <Index>1</Index>
    <Name>Unknown</Name>
  </Item>
</List>''';

      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewNumberList': numbersXml};
        },
      );

      final numbers = await service.getNumbers();
      expect(numbers, hasLength(1));
      expect(numbers[0].name, 'Known');
    });

    test('getPhonePort returns phone name', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_GetPhonePort');
          expect(arguments['NewIndex'], '0');
          return {'NewX_AVM-DE_PhoneName': 'FON 1'};
        },
      );

      final name = await service.getPhonePort(0);
      expect(name, 'FON 1');
    });

    test('getAlarmClock returns AlarmClock', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_GetAlarmClock');
          expect(arguments['NewIndex'], '0');
          return {
            'NewX_AVM-DE_AlarmClockEnable': '1',
            'NewX_AVM-DE_AlarmClockName': 'Morning',
            'NewX_AVM-DE_AlarmClockFormattedTime': '07:30',
            'NewX_AVM-DE_AlarmClockWeekdays': 'mo,tu,we,th,fr',
            'NewX_AVM-DE_AlarmClockPhoneName': 'FON 1',
          };
        },
      );

      final alarm = await service.getAlarmClock(0);
      expect(alarm.enable, isTrue);
      expect(alarm.name, 'Morning');
      expect(alarm.time, '07:30');
      expect(alarm.weekdays, 'mo,tu,we,th,fr');
      expect(alarm.phoneName, 'FON 1');
    });

    test('getNumberOfAlarmClocks returns count', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_GetNumberOfAlarmClocks');
          return {'NewX_AVM-DE_NumberOfAlarmClocks': '2'};
        },
      );

      final count = await service.getNumberOfAlarmClocks();
      expect(count, 2);
    });

    test('setAlarmClockEnable passes index and enable flag', () async {
      final service = VoIPService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'X_AVM-DE_SetAlarmClockEnable');
          expect(arguments['NewIndex'], '1');
          expect(arguments['NewX_AVM-DE_AlarmClockEnable'], '0');
          return {};
        },
      );

      await service.setAlarmClockEnable(1, false);
    });
  });
}
