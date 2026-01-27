import 'package:fritz_tr064/src/device_description.dart';
import 'package:fritz_tr064/src/services/x_auth.dart';
import 'package:test/test.dart';

ServiceDescription _fakeDescription() {
  return ServiceDescription(
    serviceType: 'urn:dslforum-org:service:X_AVM-DE_Auth:1',
    serviceId: 'urn:X_AVM-DE_Auth-com:serviceId:X_AVM-DE_Auth1',
    controlUrl: '/upnp/control/x_auth',
    scpdUrl: '/x_authSCPD.xml',
  );
}

Future<String> _unusedFetchUrl(String url) async => '';

void main() {
  group('SecondFactorState', () {
    test('tryParse returns matching enum value', () {
      expect(SecondFactorState.tryParse('disabled'),
          SecondFactorState.disabled);
      expect(SecondFactorState.tryParse('waitingforauth'),
          SecondFactorState.waitingforauth);
      expect(SecondFactorState.tryParse('anotherauthprocess'),
          SecondFactorState.anotherauthprocess);
      expect(SecondFactorState.tryParse('authenticated'),
          SecondFactorState.authenticated);
      expect(SecondFactorState.tryParse('stopped'),
          SecondFactorState.stopped);
      expect(
          SecondFactorState.tryParse('blocked'), SecondFactorState.blocked);
      expect(
          SecondFactorState.tryParse('failure'), SecondFactorState.failure);
    });

    test('tryParse returns null for unknown', () {
      expect(SecondFactorState.tryParse('unknown'), isNull);
      expect(SecondFactorState.tryParse(''), isNull);
    });
  });

  group('AuthMethod', () {
    test('parseAll parses button', () {
      final methods = AuthMethod.parseAll('button');
      expect(methods, hasLength(1));
      expect(methods[0], isA<AuthMethodButton>());
      expect(methods[0].toString(), 'button');
    });

    test('parseAll parses dtmf with sequence', () {
      final methods = AuthMethod.parseAll('dtmf;*11234');
      expect(methods, hasLength(1));
      expect(methods[0], isA<AuthMethodDtmf>());
      expect((methods[0] as AuthMethodDtmf).sequence, '*11234');
      expect(methods[0].toString(), 'dtmf;*11234');
    });

    test('parseAll parses multiple comma-separated methods', () {
      final methods = AuthMethod.parseAll('button, dtmf;*11234');
      expect(methods, hasLength(2));
      expect(methods[0], isA<AuthMethodButton>());
      expect(methods[1], isA<AuthMethodDtmf>());
      expect((methods[1] as AuthMethodDtmf).sequence, '*11234');
    });

    test('parseAll returns empty list for empty string', () {
      final methods = AuthMethod.parseAll('');
      expect(methods, isEmpty);
    });

    test('parseAll preserves unknown methods', () {
      final methods = AuthMethod.parseAll('button, future_method');
      expect(methods, hasLength(2));
      expect(methods[0], isA<AuthMethodButton>());
      expect(methods[1], isA<AuthMethodUnknown>());
      expect((methods[1] as AuthMethodUnknown).raw, 'future_method');
      expect(methods[1].toString(), 'future_method');
    });
  });

  group('AuthConfigResult', () {
    test('fromArguments parses all fields', () {
      final result = AuthConfigResult.fromArguments({
        'NewToken': '2C0A2110-30BA-444e-8B83-566BC3F19C80',
        'NewState': 'waitingforauth',
        'NewMethods': 'button',
      });

      expect(result.token, '2C0A2110-30BA-444e-8B83-566BC3F19C80');
      expect(result.state, SecondFactorState.waitingforauth);
      expect(result.methods, hasLength(1));
      expect(result.methods[0], isA<AuthMethodButton>());
    });

    test('fromArguments parses multiple methods', () {
      final result = AuthConfigResult.fromArguments({
        'NewToken': 'tok',
        'NewState': 'waitingforauth',
        'NewMethods': 'button,dtmf;*99',
      });

      expect(result.methods, hasLength(2));
      expect(result.methods[0], isA<AuthMethodButton>());
      expect(result.methods[1], isA<AuthMethodDtmf>());
      expect((result.methods[1] as AuthMethodDtmf).sequence, '*99');
    });

    test('fromArguments defaults for missing keys', () {
      final result = AuthConfigResult.fromArguments({});

      expect(result.token, '');
      expect(result.state, SecondFactorState.failure);
      expect(result.methods, isEmpty);
    });

    test('fromArguments falls back to failure for unknown state', () {
      final result = AuthConfigResult.fromArguments({
        'NewState': 'bogus',
      });

      expect(result.state, SecondFactorState.failure);
    });

    test('toString includes state and methods', () {
      final result = AuthConfigResult(
        token: 'abc',
        state: SecondFactorState.waitingforauth,
        methods: [const AuthMethodButton()],
      );
      expect(result.toString(),
          'AuthConfigResult(waitingforauth, methods=[button])');
    });
  });

  group('AuthService', () {
    test('getInfo returns true when enabled', () async {
      final service = AuthService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetInfo');
          expect(arguments, isEmpty);
          return {'NewEnabled': '1'};
        },
      );

      final enabled = await service.getInfo();
      expect(enabled, isTrue);
    });

    test('getInfo returns false when disabled', () async {
      final service = AuthService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewEnabled': '0'};
        },
      );

      final enabled = await service.getInfo();
      expect(enabled, isFalse);
    });

    test('getState returns parsed state', () async {
      final service = AuthService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetState');
          expect(arguments, isEmpty);
          return {'NewState': 'authenticated'};
        },
      );

      final state = await service.getState();
      expect(state, SecondFactorState.authenticated);
    });

    test('getState returns failure for unknown state', () async {
      final service = AuthService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewState': 'something_unexpected'};
        },
      );

      final state = await service.getState();
      expect(state, SecondFactorState.failure);
    });

    test('getState returns disabled', () async {
      final service = AuthService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewState': 'disabled'};
        },
      );

      final state = await service.getState();
      expect(state, SecondFactorState.disabled);
    });

    test('setConfig start returns token, state, and methods', () async {
      final service = AuthService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetConfig');
          expect(arguments['NewAction'], 'start');
          return {
            'NewToken': '2C0A2110-30BA-444e-8B83-566BC3F19C80',
            'NewState': 'waitingforauth',
            'NewMethods': 'button',
          };
        },
      );

      final result = await service.setConfig('start');
      expect(result.token, '2C0A2110-30BA-444e-8B83-566BC3F19C80');
      expect(result.state, SecondFactorState.waitingforauth);
      expect(result.methods, hasLength(1));
      expect(result.methods[0], isA<AuthMethodButton>());
    });

    test('setConfig stop returns stopped state', () async {
      final service = AuthService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetConfig');
          expect(arguments['NewAction'], 'stop');
          return {
            'NewToken': '',
            'NewState': 'stopped',
            'NewMethods': '',
          };
        },
      );

      final result = await service.setConfig('stop');
      expect(result.state, SecondFactorState.stopped);
      expect(result.token, '');
      expect(result.methods, isEmpty);
    });

    test('setConfig returns dtmf method', () async {
      final service = AuthService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {
            'NewToken': 'abcd-1234',
            'NewState': 'waitingforauth',
            'NewMethods': 'dtmf;*11234',
          };
        },
      );

      final result = await service.setConfig('start');
      expect(result.methods, hasLength(1));
      expect(result.methods[0], isA<AuthMethodDtmf>());
      expect((result.methods[0] as AuthMethodDtmf).sequence, '*11234');
      expect(result.state, SecondFactorState.waitingforauth);
    });

    test('setConfig returns blocked state', () async {
      final service = AuthService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {
            'NewToken': '',
            'NewState': 'blocked',
            'NewMethods': '',
          };
        },
      );

      final result = await service.setConfig('start');
      expect(result.state, SecondFactorState.blocked);
      expect(result.methods, isEmpty);
    });
  });
}
