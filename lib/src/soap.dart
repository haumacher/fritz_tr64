import 'package:xml/xml.dart';

/// Exception thrown when a SOAP fault is returned.
class SoapFaultException implements Exception {
  final String faultCode;
  final String faultString;
  final String? detail;

  SoapFaultException({
    required this.faultCode,
    required this.faultString,
    this.detail,
  });

  @override
  String toString() => 'SoapFaultException: [$faultCode] $faultString'
      '${detail != null ? ' ($detail)' : ''}';
}

/// Builds SOAP 1.1 envelopes for TR-064 requests.
class SoapEnvelope {
  static const _soapNs = 'http://schemas.xmlsoap.org/soap/envelope/';

  /// Build a plain SOAP envelope (no auth headers).
  static String build({
    required String serviceType,
    required String actionName,
    Map<String, String> arguments = const {},
  }) {
    return _buildEnvelope(
      serviceType: serviceType,
      actionName: actionName,
      arguments: arguments,
    );
  }

  /// Build a SOAP envelope with an InitChallenge header.
  static String buildInitChallenge({
    required String serviceType,
    required String actionName,
    required String userId,
    Map<String, String> arguments = const {},
  }) {
    final header = _initChallengeHeader(userId);
    return _buildEnvelope(
      serviceType: serviceType,
      actionName: actionName,
      arguments: arguments,
      headerContent: header,
    );
  }

  /// Build a SOAP envelope with a ClientAuth header.
  static String buildClientAuth({
    required String serviceType,
    required String actionName,
    required String userId,
    required String nonce,
    required String authResponse,
    required String realm,
    Map<String, String> arguments = const {},
  }) {
    final header = _clientAuthHeader(userId, nonce, authResponse, realm);
    return _buildEnvelope(
      serviceType: serviceType,
      actionName: actionName,
      arguments: arguments,
      headerContent: header,
    );
  }

  static String _buildEnvelope({
    required String serviceType,
    required String actionName,
    Map<String, String> arguments = const {},
    String? headerContent,
  }) {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="utf-8"?>');
    buffer.write('<s:Envelope '
        'xmlns:s="$_soapNs" '
        's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">');

    if (headerContent != null) {
      buffer.write('<s:Header>$headerContent</s:Header>');
    }

    buffer.write('<s:Body>');
    buffer.write('<u:$actionName xmlns:u="$serviceType">');
    for (final entry in arguments.entries) {
      buffer.write('<${entry.key}>${_xmlEscape(entry.value)}</${entry.key}>');
    }
    buffer.write('</u:$actionName>');
    buffer.write('</s:Body>');
    buffer.write('</s:Envelope>');

    return buffer.toString();
  }

  static String _initChallengeHeader(String userId) {
    return '<h:InitChallenge '
        'xmlns:h="http://soap-authentication.org/digest/2001/10/" '
        's:mustUnderstand="1">'
        '<UserID>$userId</UserID>'
        '</h:InitChallenge>';
  }

  static String _clientAuthHeader(
    String userId,
    String nonce,
    String authResponse,
    String realm,
  ) {
    return '<h:ClientAuth '
        'xmlns:h="http://soap-authentication.org/digest/2001/10/" '
        's:mustUnderstand="1">'
        '<Nonce>$nonce</Nonce>'
        '<Auth>$authResponse</Auth>'
        '<UserID>$userId</UserID>'
        '<Realm>$realm</Realm>'
        '</h:ClientAuth>';
  }

  static String _xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

/// Parsed SOAP response.
class SoapResponse {
  /// The action arguments from the SOAP body.
  final Map<String, String> arguments;

  /// Challenge info from the response header (if present).
  final ChallengeInfo? challenge;

  SoapResponse({required this.arguments, this.challenge});
}

/// Challenge/auth info from SOAP response headers.
class ChallengeInfo {
  final String nonce;
  final String realm;
  final String? status;

  ChallengeInfo({required this.nonce, required this.realm, this.status});
}

/// Parses SOAP response XML.
SoapResponse parseSoapResponse(String xml) {
  final document = XmlDocument.parse(xml);
  final envelope = document.rootElement;

  // Check for SOAP fault
  final body = envelope.findAllElements('Body',
      namespace: 'http://schemas.xmlsoap.org/soap/envelope/');
  final bodyElement = body.isNotEmpty
      ? body.first
      : envelope.findAllElements('s:Body').first;

  // Extract challenge info from header first — the Fritz!Box includes the
  // challenge even in fault responses (e.g. the InitChallenge step returns a
  // 503 "Auth. failed" fault together with the nonce/realm in the header).
  ChallengeInfo? challenge;
  final headers = envelope.findAllElements('Header',
      namespace: 'http://schemas.xmlsoap.org/soap/envelope/');
  final headerElement = headers.isNotEmpty
      ? headers.first
      : null;

  if (headerElement != null) {
    // Look for Challenge or NextChallenge in the SOAP auth namespace.
    // Must use namespace parameter because the elements have a prefix
    // (e.g. h:Challenge), and without namespace the xml package matches
    // on qualified name only.
    const authNs = 'http://soap-authentication.org/digest/2001/10/';
    final challengeElements = [
      ...headerElement.findAllElements('Challenge', namespace: authNs),
      ...headerElement.findAllElements('NextChallenge', namespace: authNs),
    ];
    if (challengeElements.isNotEmpty) {
      final ce = challengeElements.first;
      final nonce = _getElementText(ce, 'Nonce');
      final realm = _getElementText(ce, 'Realm');
      final status = _getElementText(ce, 'Status');
      if (nonce != null && realm != null) {
        challenge = ChallengeInfo(nonce: nonce, realm: realm, status: status);
      }
    }
  }

  // Check for SOAP fault
  final fault = bodyElement.findAllElements('Fault').toList();
  if (fault.isEmpty) {
    // Also check with namespace prefix
    fault.addAll(bodyElement.findAllElements('s:Fault'));
  }
  if (fault.isNotEmpty) {
    // If a challenge was included alongside the fault (InitChallenge flow),
    // return it instead of throwing so the caller can proceed with auth.
    if (challenge != null) {
      return SoapResponse(arguments: const {}, challenge: challenge);
    }

    final faultElement = fault.first;
    final faultCode =
        _getElementText(faultElement, 'faultcode') ?? 'Unknown';
    final faultString =
        _getElementText(faultElement, 'faultstring') ?? 'Unknown error';
    final detail = _getElementText(faultElement, 'detail');
    throw SoapFaultException(
      faultCode: faultCode,
      faultString: faultString,
      detail: detail,
    );
  }

  // Extract body arguments - find the action response element
  final arguments = <String, String>{};
  final actionResponse = bodyElement.children
      .whereType<XmlElement>()
      .firstOrNull;
  if (actionResponse != null) {
    for (final child in actionResponse.children.whereType<XmlElement>()) {
      arguments[child.localName] = child.innerText;
    }
  }

  return SoapResponse(arguments: arguments, challenge: challenge);
}

String? _getElementText(XmlElement parent, String name) {
  final elements = parent.findAllElements(name);
  if (elements.isEmpty) return null;
  final text = elements.first.innerText;
  return text.isEmpty ? null : text;
}
