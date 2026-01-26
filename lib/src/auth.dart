import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Tracks the authentication state for a TR-064 session.
class AuthState {
  String? nonce;
  String? realm;

  AuthState();

  bool get hasCredentials => nonce != null && realm != null;

  void update({required String nonce, required String realm}) {
    this.nonce = nonce;
    this.realm = realm;
  }

  void clear() {
    nonce = null;
    realm = null;
  }
}

/// Handles TR-064 content-level SOAP digest authentication.
///
/// The auth flow is:
/// 1. Send an InitChallenge header → receive Nonce + Realm
/// 2. Compute: secret = MD5(userId:realm:password)
///             response = MD5(secret:nonce)
/// 3. Send a ClientAuth header with the computed response
/// 4. Receive authenticated result + NextChallenge (new nonce for next call)
class Tr64Auth {
  final String userId;
  final String password;
  final AuthState state = AuthState();

  Tr64Auth({required this.userId, required this.password});

  /// Compute the MD5 digest response for authentication.
  ///
  /// secret = MD5("userId:realm:password")
  /// response = MD5("secret:nonce")
  String computeResponse({
    required String realm,
    required String nonce,
  }) {
    final secret = _md5Hex('$userId:$realm:$password');
    return _md5Hex('$secret:$nonce');
  }

  /// Update auth state from a challenge response.
  void updateFromChallenge({required String nonce, required String realm}) {
    state.update(nonce: nonce, realm: realm);
  }

  static String _md5Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }
}
