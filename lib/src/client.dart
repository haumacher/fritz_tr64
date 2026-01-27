import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth.dart';
import 'device_description.dart';
import 'service.dart';
import 'soap.dart';

/// Main entry point for the TR-064 protocol.
///
/// Connects to a Fritz!Box router, discovers available services,
/// and provides authenticated SOAP action invocation.
class Tr64Client {
  final String host;
  final int port;
  final bool useHttps;
  final Tr64Auth _auth;

  http.Client? _httpClient;
  DeviceDescription? _description;

  /// Create a TR-064 client.
  ///
  /// [host] is the Fritz!Box hostname or IP address.
  /// [port] defaults to 49000 for HTTP or 49443 for HTTPS.
  /// [username] and [password] are the Fritz!Box credentials.
  /// [useHttps] enables HTTPS (with self-signed certificate support).
  Tr64Client({
    required this.host,
    int? port,
    required String username,
    required String password,
    this.useHttps = false,
  })  : port = port ?? (useHttps ? 49443 : 49000),
        _auth = Tr64Auth(userId: username, password: password);

  String get _baseUrl => '${useHttps ? 'https' : 'http'}://$host:$port';

  /// The parsed device description, available after [connect].
  DeviceDescription? get description => _description;

  /// Connect to the Fritz!Box: fetch and parse the device description.
  Future<void> connect() async {
    _httpClient = _createHttpClient();

    final url = Uri.parse('$_baseUrl/tr64desc.xml');
    final response = await _httpClient!.get(url);

    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to fetch device description: ${response.statusCode}',
        uri: url,
      );
    }

    _description = DeviceDescription.parse(response.body);
  }

  /// Invoke a SOAP action on a service with authentication.
  ///
  /// [serviceType] is the full service type URN.
  /// [controlUrl] is the service's control URL path.
  /// [actionName] is the SOAP action to invoke.
  /// [arguments] are the action's input arguments.
  ///
  /// Returns the response arguments as a string map.
  Future<Map<String, String>> call({
    required String serviceType,
    required String controlUrl,
    required String actionName,
    Map<String, String> arguments = const {},
  }) async {
    final client = _httpClient ?? _createHttpClient();
    _httpClient = client;

    final url = Uri.parse('$_baseUrl$controlUrl');
    final soapAction = '$serviceType#$actionName';

    // Step 1: If we have a nonce from a previous call, use it directly
    if (_auth.state.hasCredentials) {
      final response = await _sendAuthenticatedRequest(
        client: client,
        url: url,
        soapAction: soapAction,
        serviceType: serviceType,
        actionName: actionName,
        arguments: arguments,
      );

      // If we got a next challenge, update state for the next call
      if (response.challenge != null) {
        _auth.updateFromChallenge(
          nonce: response.challenge!.nonce,
          realm: response.challenge!.realm,
        );
      }

      return response.arguments;
    }

    // Step 2: No existing auth state - do the full challenge-response flow
    // 2a: Send InitChallenge to get nonce + realm
    final initEnvelope = SoapEnvelope.buildInitChallenge(
      serviceType: serviceType,
      actionName: actionName,
      userId: _auth.userId,
      arguments: arguments,
    );

    final initResponse = await _postSoap(client, url, soapAction, initEnvelope);
    final initParsed = parseSoapResponse(initResponse.body);

    if (initParsed.challenge == null) {
      // No challenge returned means auth might not be required
      return initParsed.arguments;
    }

    // 2b: Compute auth response and send ClientAuth
    _auth.updateFromChallenge(
      nonce: initParsed.challenge!.nonce,
      realm: initParsed.challenge!.realm,
    );

    final authResult = await _sendAuthenticatedRequest(
      client: client,
      url: url,
      soapAction: soapAction,
      serviceType: serviceType,
      actionName: actionName,
      arguments: arguments,
    );

    // Update nonce for next call
    if (authResult.challenge != null) {
      _auth.updateFromChallenge(
        nonce: authResult.challenge!.nonce,
        realm: authResult.challenge!.realm,
      );
    }

    return authResult.arguments;
  }

  /// Find a service by type and create a generic [Tr64Service] wrapper.
  Tr64Service? service(String serviceType) {
    if (_description == null) return null;
    final desc = _description!.findByType(serviceType);
    if (desc == null) return null;
    return Tr64Service(
      description: desc,
      callAction: _callAction,
    );
  }

  /// Close the HTTP client and clear auth state.
  void close() {
    _httpClient?.close();
    _httpClient = null;
    _auth.state.clear();
  }

  // Internal callback for service wrappers
  Future<Map<String, String>> _callAction(
    String serviceType,
    String controlUrl,
    String actionName,
    Map<String, String> arguments,
  ) {
    return call(
      serviceType: serviceType,
      controlUrl: controlUrl,
      actionName: actionName,
      arguments: arguments,
    );
  }

  Future<SoapResponse> _sendAuthenticatedRequest({
    required http.Client client,
    required Uri url,
    required String soapAction,
    required String serviceType,
    required String actionName,
    required Map<String, String> arguments,
  }) async {
    final authResponse = _auth.computeResponse(
      realm: _auth.state.realm!,
      nonce: _auth.state.nonce!,
    );

    final envelope = SoapEnvelope.buildClientAuth(
      serviceType: serviceType,
      actionName: actionName,
      userId: _auth.userId,
      nonce: _auth.state.nonce!,
      authResponse: authResponse,
      realm: _auth.state.realm!,
      arguments: arguments,
    );

    final httpResponse = await _postSoap(client, url, soapAction, envelope);
    return parseSoapResponse(httpResponse.body);
  }

  Future<http.Response> _postSoap(
    http.Client client,
    Uri url,
    String soapAction,
    String envelope,
  ) {
    return client.post(
      url,
      headers: {
        'Content-Type': 'text/xml; charset="utf-8"',
        'SoapAction': soapAction,
      },
      body: envelope,
    );
  }

  http.Client _createHttpClient() {
    if (useHttps) {
      // For HTTPS, use an IOClient that accepts self-signed certificates
      final httpClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;
      return _IoClientAdapter(httpClient);
    }
    return http.Client();
  }
}

/// Adapter that wraps dart:io HttpClient as an http.Client,
/// allowing self-signed certificate handling.
class _IoClientAdapter extends http.BaseClient {
  final HttpClient _inner;

  _IoClientAdapter(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final ioRequest = await _inner.openUrl(request.method, request.url);

    // Copy headers
    request.headers.forEach((name, value) {
      ioRequest.headers.set(name, value);
    });

    // Write body
    final bodyBytes = await request.finalize().toBytes();
    ioRequest.add(bodyBytes);

    final ioResponse = await ioRequest.close();

    final headers = <String, String>{};
    ioResponse.headers.forEach((name, values) {
      headers[name] = values.join(', ');
    });

    return http.StreamedResponse(
      ioResponse,
      ioResponse.statusCode,
      headers: headers,
      reasonPhrase: ioResponse.reasonPhrase,
      request: request,
    );
  }

  @override
  void close() {
    _inner.close();
  }
}
