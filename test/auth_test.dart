import 'package:fritz_tr064/src/auth.dart';
import 'package:test/test.dart';

void main() {
  group('Tr64Auth', () {
    test('computeResponse matches documented example', () {
      // From the TR-064 documentation:
      // uid=admin, pwd=gurkensalat, realm="F!Box SOAP-Auth", nonce=F758BE72FB999CEA
      // secret = MD5("admin:F!Box SOAP-Auth:gurkensalat")
      // response = MD5(secret + ":" + "F758BE72FB999CEA")
      // Expected: b4f67585f22b0af7c4615db5a18faa14

      final auth = Tr64Auth(userId: 'admin', password: 'gurkensalat');
      final response = auth.computeResponse(
        realm: 'F!Box SOAP-Auth',
        nonce: 'F758BE72FB999CEA',
      );

      expect(response, 'b4f67585f22b0af7c4615db5a18faa14');
    });

    test('computeResponse produces consistent results', () {
      final auth = Tr64Auth(userId: 'user', password: 'pass');

      final r1 = auth.computeResponse(realm: 'realm', nonce: 'nonce1');
      final r2 = auth.computeResponse(realm: 'realm', nonce: 'nonce1');

      expect(r1, r2);
    });

    test('computeResponse changes with different nonce', () {
      final auth = Tr64Auth(userId: 'user', password: 'pass');

      final r1 = auth.computeResponse(realm: 'realm', nonce: 'nonce1');
      final r2 = auth.computeResponse(realm: 'realm', nonce: 'nonce2');

      expect(r1, isNot(r2));
    });

    test('computeResponse changes with different realm', () {
      final auth = Tr64Auth(userId: 'user', password: 'pass');

      final r1 = auth.computeResponse(realm: 'realm1', nonce: 'nonce');
      final r2 = auth.computeResponse(realm: 'realm2', nonce: 'nonce');

      expect(r1, isNot(r2));
    });

    test('response is a 32-character hex string', () {
      final auth = Tr64Auth(userId: 'test', password: 'test');
      final response = auth.computeResponse(realm: 'test', nonce: 'test');

      expect(response.length, 32);
      expect(response, matches(RegExp(r'^[0-9a-f]{32}$')));
    });
  });

  group('AuthState', () {
    test('starts without credentials', () {
      final state = AuthState();
      expect(state.hasCredentials, isFalse);
    });

    test('has credentials after update', () {
      final state = AuthState();
      state.update(nonce: 'abc', realm: 'test');

      expect(state.hasCredentials, isTrue);
      expect(state.nonce, 'abc');
      expect(state.realm, 'test');
    });

    test('clear removes credentials', () {
      final state = AuthState();
      state.update(nonce: 'abc', realm: 'test');
      state.clear();

      expect(state.hasCredentials, isFalse);
      expect(state.nonce, isNull);
      expect(state.realm, isNull);
    });
  });

  group('Tr64Auth state management', () {
    test('updateFromChallenge updates internal state', () {
      final auth = Tr64Auth(userId: 'admin', password: 'pass');

      expect(auth.state.hasCredentials, isFalse);

      auth.updateFromChallenge(nonce: 'ABC', realm: 'TestRealm');

      expect(auth.state.hasCredentials, isTrue);
      expect(auth.state.nonce, 'ABC');
      expect(auth.state.realm, 'TestRealm');
    });
  });
}
