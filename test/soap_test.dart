import 'package:flutter_tr64/src/soap.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('SoapEnvelope', () {
    test('build() creates a valid SOAP envelope with no auth', () {
      final xml = SoapEnvelope.build(
        serviceType: 'urn:dslforum-org:service:DeviceInfo:1',
        actionName: 'GetInfo',
      );

      final doc = XmlDocument.parse(xml);
      final envelope = doc.rootElement;

      expect(envelope.localName, 'Envelope');
      expect(
        envelope.getAttribute('xmlns:s'),
        'http://schemas.xmlsoap.org/soap/envelope/',
      );

      // Should have no Header element
      final headers = envelope.findAllElements('Header',
          namespace: 'http://schemas.xmlsoap.org/soap/envelope/');
      expect(headers, isEmpty);

      // Should have Body with action
      final body = envelope.findElements('s:Body').first;
      final action = body.findElements('u:GetInfo').first;
      expect(
        action.getAttribute('xmlns:u'),
        'urn:dslforum-org:service:DeviceInfo:1',
      );
    });

    test('build() includes arguments', () {
      final xml = SoapEnvelope.build(
        serviceType: 'urn:dslforum-org:service:WANIPConnection:1',
        actionName: 'SetConnectionType',
        arguments: {'NewConnectionType': 'IP_Routed'},
      );

      final doc = XmlDocument.parse(xml);
      final body = doc.rootElement.findElements('s:Body').first;
      final action = body.findElements('u:SetConnectionType').first;
      final arg = action.findElements('NewConnectionType').first;
      expect(arg.innerText, 'IP_Routed');
    });

    test('build() escapes XML special characters in arguments', () {
      final xml = SoapEnvelope.build(
        serviceType: 'urn:dslforum-org:service:Test:1',
        actionName: 'TestAction',
        arguments: {'Param': '<script>&"\'test'},
      );

      // Should be parseable (i.e., properly escaped)
      final doc = XmlDocument.parse(xml);
      final body = doc.rootElement.findElements('s:Body').first;
      final action = body.findElements('u:TestAction').first;
      final param = action.findElements('Param').first;
      expect(param.innerText, '<script>&"\'test');
    });

    test('buildInitChallenge() adds InitChallenge header', () {
      const authNs = 'http://soap-authentication.org/digest/2001/10/';
      final xml = SoapEnvelope.buildInitChallenge(
        serviceType: 'urn:dslforum-org:service:DeviceInfo:1',
        actionName: 'GetInfo',
        userId: 'admin',
      );

      final doc = XmlDocument.parse(xml);
      final header = doc.rootElement.findElements('s:Header').first;
      final challenge = header
          .findAllElements('InitChallenge', namespace: authNs)
          .first;

      expect(challenge.name.namespaceUri, authNs);

      final userId = challenge.findElements('UserID').first;
      expect(userId.innerText, 'admin');
    });

    test('buildClientAuth() adds ClientAuth header', () {
      const authNs = 'http://soap-authentication.org/digest/2001/10/';
      final xml = SoapEnvelope.buildClientAuth(
        serviceType: 'urn:dslforum-org:service:DeviceInfo:1',
        actionName: 'GetInfo',
        userId: 'admin',
        nonce: 'ABC123',
        authResponse: 'digest_value',
        realm: 'F!Box SOAP-Auth',
      );

      final doc = XmlDocument.parse(xml);
      final header = doc.rootElement.findElements('s:Header').first;
      final clientAuth = header
          .findAllElements('ClientAuth', namespace: authNs)
          .first;

      expect(clientAuth.name.namespaceUri, authNs);
      expect(
          clientAuth.findElements('Nonce').first.innerText, 'ABC123');
      expect(
          clientAuth.findElements('Auth').first.innerText, 'digest_value');
      expect(
          clientAuth.findElements('UserID').first.innerText, 'admin');
      expect(clientAuth.findElements('Realm').first.innerText,
          'F!Box SOAP-Auth');
    });
  });

  group('parseSoapResponse', () {
    test('parses action response arguments', () {
      final xml = '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
            s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:GetInfoResponse xmlns:u="urn:dslforum-org:service:DeviceInfo:1">
      <NewModelName>FRITZ!Box 7590</NewModelName>
      <NewSoftwareVersion>7.29</NewSoftwareVersion>
      <NewUpTime>123456</NewUpTime>
    </u:GetInfoResponse>
  </s:Body>
</s:Envelope>''';

      final response = parseSoapResponse(xml);
      expect(response.arguments['NewModelName'], 'FRITZ!Box 7590');
      expect(response.arguments['NewSoftwareVersion'], '7.29');
      expect(response.arguments['NewUpTime'], '123456');
      expect(response.challenge, isNull);
    });

    test('parses challenge info from header', () {
      final xml = '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
            s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Header>
    <h:Challenge xmlns:h="http://soap-authentication.org/digest/2001/10/"
                 s:mustUnderstand="1">
      <Status>Unauthenticated</Status>
      <Nonce>F758BE72FB999CEA</Nonce>
      <Realm>F!Box SOAP-Auth</Realm>
    </h:Challenge>
  </s:Header>
  <s:Body>
    <u:GetInfoResponse xmlns:u="urn:dslforum-org:service:DeviceInfo:1">
    </u:GetInfoResponse>
  </s:Body>
</s:Envelope>''';

      final response = parseSoapResponse(xml);
      expect(response.challenge, isNotNull);
      expect(response.challenge!.nonce, 'F758BE72FB999CEA');
      expect(response.challenge!.realm, 'F!Box SOAP-Auth');
      expect(response.challenge!.status, 'Unauthenticated');
    });

    test('parses NextChallenge from authenticated response', () {
      final xml = '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
            s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Header>
    <h:NextChallenge xmlns:h="http://soap-authentication.org/digest/2001/10/"
                     s:mustUnderstand="1">
      <Status>Authenticated</Status>
      <Nonce>AABBCCDD11223344</Nonce>
      <Realm>F!Box SOAP-Auth</Realm>
    </h:NextChallenge>
  </s:Header>
  <s:Body>
    <u:GetInfoResponse xmlns:u="urn:dslforum-org:service:DeviceInfo:1">
      <NewModelName>FRITZ!Box 7590</NewModelName>
    </u:GetInfoResponse>
  </s:Body>
</s:Envelope>''';

      final response = parseSoapResponse(xml);
      expect(response.challenge, isNotNull);
      expect(response.challenge!.nonce, 'AABBCCDD11223344');
      expect(response.challenge!.status, 'Authenticated');
      expect(response.arguments['NewModelName'], 'FRITZ!Box 7590');
    });

    test('throws SoapFaultException on SOAP fault', () {
      final xml = '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
            s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <s:Fault>
      <faultcode>s:Client</faultcode>
      <faultstring>UPnPError</faultstring>
      <detail>Action not authorized</detail>
    </s:Fault>
  </s:Body>
</s:Envelope>''';

      expect(
        () => parseSoapResponse(xml),
        throwsA(isA<SoapFaultException>()
            .having((e) => e.faultCode, 'faultCode', 's:Client')
            .having(
                (e) => e.faultString, 'faultString', 'UPnPError')
            .having((e) => e.detail, 'detail', 'Action not authorized')),
      );
    });

    test('handles response with empty body', () {
      final xml = '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
            s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:SetConfigResponse xmlns:u="urn:dslforum-org:service:Test:1">
    </u:SetConfigResponse>
  </s:Body>
</s:Envelope>''';

      final response = parseSoapResponse(xml);
      expect(response.arguments, isEmpty);
    });
  });
}
