import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// A client for the Fritz!Box web API (lua endpoints).
///
/// This is separate from [Tr64Client] because the web API uses HTTP form
/// submissions and session-based authentication rather than SOAP/digest auth.
///
/// The web API can perform operations that are not available via TR-064,
/// such as enabling internet access for SIP devices and TOTP-based 2FA.
class FritzWebClient {
  final String host;
  final String username;
  final String password;

  http.Client? _httpClient;
  String _sid = '0000000000000000';

  /// Creates a web API client for the given Fritz!Box.
  FritzWebClient({
    required this.host,
    required this.username,
    required this.password,
  });

  String get _baseUrl => 'http://$host';

  /// The current session ID.
  String get sid => _sid;

  /// Whether a valid session is active.
  bool get isLoggedIn => _sid != '0000000000000000';

  /// The underlying HTTP client, created lazily.
  http.Client get httpClient => _httpClient ??= http.Client();

  /// Log in to the Fritz!Box web UI via `login_sid.lua?version=2`.
  ///
  /// Uses PBKDF2 (version 2) or MD5 (version 1) challenge-response
  /// depending on what the Fritz!Box returns.
  Future<void> login() async {
    final challengeResponse = await httpClient.get(
      Uri.parse('$_baseUrl/login_sid.lua?version=2'),
    );
    final challengeXml = challengeResponse.body;

    final sidMatch = RegExp(r'<SID>([^<]+)</SID>').firstMatch(challengeXml);
    final challengeMatch =
        RegExp(r'<Challenge>([^<]+)</Challenge>').firstMatch(challengeXml);

    if (sidMatch == null || challengeMatch == null) {
      throw Exception('Failed to parse login_sid.lua response');
    }

    final currentSid = sidMatch.group(1)!;
    if (currentSid != '0000000000000000') {
      _sid = currentSid;
      return;
    }

    final challenge = challengeMatch.group(1)!;
    final response = _computeResponse(challenge, password);

    final loginResponse = await httpClient.post(
      Uri.parse('$_baseUrl/login_sid.lua?version=2'),
      body: {
        'username': username,
        'response': response,
      },
    );

    final loginSidMatch =
        RegExp(r'<SID>([^<]+)</SID>').firstMatch(loginResponse.body);
    if (loginSidMatch == null) {
      throw Exception('Failed to parse login response');
    }

    final newSid = loginSidMatch.group(1)!;
    if (newSid == '0000000000000000') {
      throw Exception('Login failed - invalid credentials');
    }

    _sid = newSid;
  }

  /// Log out and invalidate the current session.
  Future<void> logout() async {
    if (isLoggedIn) {
      await httpClient.get(
        Uri.parse('$_baseUrl/login_sid.lua?logout=1&sid=$_sid'),
      );
      _sid = '0000000000000000';
    }
  }

  /// Fetch a page from `data.lua` with optional parameters.
  ///
  /// Returns the raw response body.
  Future<String> fetchPage({
    required String page,
    Map<String, String> params = const {},
  }) async {
    final body = <String, String>{
      'xhr': '1',
      'sid': _sid,
      'page': page,
      ...params,
    };
    final resp = await httpClient.post(
      Uri.parse('$_baseUrl/data.lua'),
      body: body,
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch page "$page": ${resp.statusCode}',
      );
    }
    return resp.body;
  }

  /// Submit a form to `data.lua` with `btn_save=`.
  ///
  /// Returns the parsed JSON response. The response typically contains
  /// a `data` object with the result of the form submission.
  Future<Map<String, dynamic>> submitForm({
    required String page,
    required Map<String, String> fields,
  }) async {
    final body = <String, String>{
      'xhr': '1',
      'sid': _sid,
      'page': page,
      'btn_save': '',
      'lang': 'de',
      ...fields,
    };
    final resp = await httpClient.post(
      Uri.parse('$_baseUrl/data.lua'),
      body: body,
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to submit form for page "$page": ${resp.statusCode}',
      );
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Post to `twofactor.lua` with the given fields.
  ///
  /// Returns the parsed JSON response.
  Future<Map<String, dynamic>> postTwoFactor(Map<String, String> fields) async {
    final body = <String, String>{
      'xhr': '1',
      'sid': _sid,
      ...fields,
    };
    final resp = await httpClient.post(
      Uri.parse('$_baseUrl/twofactor.lua'),
      body: body,
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to post to twofactor.lua: ${resp.statusCode}',
      );
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Close the HTTP client and log out.
  Future<void> close() async {
    await logout();
    _httpClient?.close();
    _httpClient = null;
  }

  // -- Login challenge-response helpers --

  static String _computeResponse(String challenge, String password) {
    if (challenge.startsWith('2\$')) {
      return _computePbkdf2Response(challenge, password);
    } else {
      return _computeMd5Response(challenge, password);
    }
  }

  static String _computePbkdf2Response(String challenge, String password) {
    final parts = challenge.split('\$');
    final iter1 = int.parse(parts[1]);
    final salt1 = _hexToBytes(parts[2]);
    final iter2 = int.parse(parts[3]);
    final salt2 = _hexToBytes(parts[4]);

    final hash1 = _pbkdf2(utf8.encode(password), salt1, iter1, 32);
    final hash2 = _pbkdf2(hash1, salt2, iter2, 32);

    return '${parts[4]}\$${_bytesToHex(hash2)}';
  }

  static String _computeMd5Response(String challenge, String password) {
    final input = '$challenge-$password';
    final utf16le = <int>[];
    for (final codeUnit in input.codeUnits) {
      utf16le.add(codeUnit & 0xFF);
      utf16le.add((codeUnit >> 8) & 0xFF);
    }
    final hash = md5.convert(utf16le);
    return '$challenge-${hash.toString()}';
  }

  static List<int> _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmacKey = Hmac(sha256, password);
    final blocks = (keyLength + 31) ~/ 32;
    final result = <int>[];

    for (var block = 1; block <= blocks; block++) {
      final saltBlock = [
        ...salt,
        (block >> 24) & 0xFF,
        (block >> 16) & 0xFF,
        (block >> 8) & 0xFF,
        block & 0xFF,
      ];
      var u = hmacKey.convert(saltBlock).bytes;
      var xor = List<int>.from(u);

      for (var i = 1; i < iterations; i++) {
        u = hmacKey.convert(u).bytes;
        for (var j = 0; j < xor.length; j++) {
          xor[j] ^= u[j];
        }
      }

      result.addAll(xor);
    }

    return result.sublist(0, keyLength);
  }

  static List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
