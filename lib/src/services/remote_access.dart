import 'package:xml/xml.dart';

import '../client.dart';
import '../service.dart';

/// DDNS update mode.
enum DDNSMode {
  /// Update only IPv4 address.
  v4('ddns_v4'),

  /// Update only IPv6 address.
  v6('ddns_v6'),

  /// Update IPv4 and IPv6 address with separate HTTP requests.
  both('ddns_both'),

  /// Update IPv4 and IPv6 address with one request.
  bothTogether('ddns_both_together');

  final String _value;
  const DDNSMode(this._value);

  /// Parse a mode string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static DDNSMode? tryParse(String value) {
    for (final m in values) {
      if (m._value == value) return m;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// DDNS update status for IPv4 or IPv6.
enum DDNSStatus {
  /// DDNS is offline.
  offline('offline'),

  /// Checking the current IP address.
  checking('checking'),

  /// Sending an update to the DDNS provider.
  updating('updating'),

  /// The DDNS record has been updated.
  updated('updated'),

  /// Verifying the DDNS update.
  verifying('verifying'),

  /// The DDNS update completed successfully.
  complete('complete'),

  /// A new IP address was detected.
  newAddress('new-address'),

  /// The DDNS account is disabled at the provider.
  accountDisabled('account-disabled'),

  /// No internet connection available.
  internetNotConnected('internet-not-connected'),

  /// Status is undefined.
  undefined('undefined');

  final String _value;
  const DDNSStatus(this._value);

  /// Parse a status string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown or empty values.
  /// Accepts both "new address" (IPv4) and "new-address" (IPv6).
  static DDNSStatus? tryParse(String value) {
    for (final s in values) {
      if (s._value == value) return s;
    }
    // The spec uses "new address" (space) for StatusIPv4.
    if (value == 'new address') return newAddress;
    return null;
  }

  @override
  String toString() => _value;
}

/// State of the Let's Encrypt certificate.
enum LetsEncryptState {
  /// Let's Encrypt or MyFRITZ is disabled.
  notUsed('not_used'),

  /// Creating certificate.
  getting('get'),

  /// The certificate is valid.
  valid('valid'),

  /// The certificate is invalid.
  invalid('invalid'),

  /// Unknown error.
  unknown('unknown');

  final String _value;
  const LetsEncryptState(this._value);

  /// Parse a state string returned by the Fritz!Box.
  ///
  /// Returns `null` for unrecognised or empty values.
  static LetsEncryptState? tryParse(String value) {
    for (final s in values) {
      if (s._value == value) return s;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// Result of X_AVM-DE_RemoteAccess:GetInfo action.
class RemoteAccessInfo {
  /// Whether remote access is enabled.
  final bool enabled;

  /// HTTPS port for remote access (1-65535).
  final int port;

  /// Username configured for remote access.
  final String username;

  /// Whether Let's Encrypt is enabled.
  final bool letsEncryptEnabled;

  /// State of the Let's Encrypt certificate.
  final LetsEncryptState? letsEncryptState;

  RemoteAccessInfo({
    required this.enabled,
    required this.port,
    required this.username,
    required this.letsEncryptEnabled,
    required this.letsEncryptState,
  });

  factory RemoteAccessInfo.fromArguments(Map<String, String> args) {
    return RemoteAccessInfo(
      enabled: args['NewEnabled'] == '1',
      port: int.tryParse(args['NewPort'] ?? '') ?? 0,
      username: args['NewUsername'] ?? '',
      letsEncryptEnabled: args['NewLetsEncryptEnabled'] == '1',
      letsEncryptState: LetsEncryptState.tryParse(args['NewLetsEncryptState'] ?? ''),
    );
  }

  @override
  String toString() =>
      'RemoteAccessInfo(enabled=$enabled, port=$port, user=$username)';
}

/// Result of X_AVM-DE_RemoteAccess:GetDDNSInfo action.
class DDNSInfo {
  /// The configured DDNS domain name.
  final String domain;

  /// Whether DDNS is enabled.
  final bool enabled;

  /// DDNS update mode.
  final DDNSMode? mode;

  /// Name of the DDNS provider.
  final String providerName;

  /// IPv4 server address for DDNS updates.
  final String serverIPv4;

  /// IPv6 server address for DDNS updates.
  final String serverIPv6;

  /// Current IPv4 DDNS status.
  final DDNSStatus? statusIPv4;

  /// Current IPv6 DDNS status.
  final DDNSStatus? statusIPv6;

  /// The DDNS update URL.
  final String updateURL;

  /// Username for DDNS authentication.
  final String username;

  DDNSInfo({
    required this.domain,
    required this.enabled,
    required this.mode,
    required this.providerName,
    required this.serverIPv4,
    required this.serverIPv6,
    required this.statusIPv4,
    required this.statusIPv6,
    required this.updateURL,
    required this.username,
  });

  factory DDNSInfo.fromArguments(Map<String, String> args) {
    return DDNSInfo(
      domain: args['NewDomain'] ?? '',
      enabled: args['NewEnabled'] == '1',
      mode: DDNSMode.tryParse(args['NewMode'] ?? ''),
      providerName: args['NewProviderName'] ?? '',
      serverIPv4: args['NewServerIPv4'] ?? '',
      serverIPv6: args['NewServerIPv6'] ?? '',
      statusIPv4: DDNSStatus.tryParse(args['NewStatusIPv4'] ?? ''),
      statusIPv6: DDNSStatus.tryParse(args['NewStatusIPv6'] ?? ''),
      updateURL: args['NewUpdateURL'] ?? '',
      username: args['NewUsername'] ?? '',
    );
  }

  @override
  String toString() =>
      'DDNSInfo($domain, enabled=$enabled, mode=$mode)';
}

/// A DDNS provider from the provider list XML.
class DDNSProvider {
  /// Name of the DDNS provider.
  final String providerName;

  /// URL with information about the provider.
  final String infoURL;

  DDNSProvider({
    required this.providerName,
    required this.infoURL,
  });

  @override
  String toString() => 'DDNSProvider($providerName)';
}

XmlElement? _findChild(XmlElement parent, String localName) {
  for (final child in parent.childElements) {
    if (child.localName == localName) return child;
  }
  return null;
}

String _childText(XmlElement parent, String localName) {
  final el = _findChild(parent, localName);
  return el?.innerText ?? '';
}

/// Parse the DDNS provider list XML into a list of [DDNSProvider] objects.
///
/// The XML has the structure:
/// List > Item with child elements ProviderName, InfoURL.
List<DDNSProvider> _parseProviderListXml(String xml) {
  final document = XmlDocument.parse(xml);
  final providers = <DDNSProvider>[];
  for (final item in document.findAllElements('Item')) {
    providers.add(DDNSProvider(
      providerName: _childText(item, 'ProviderName'),
      infoURL: _childText(item, 'InfoURL'),
    ));
  }
  return providers;
}

/// TR-064 X_AVM-DE_RemoteAccess service.
///
/// Service type: urn:dslforum-org:service:X_AVM-DE_RemoteAccess:1
class RemoteAccessService extends Tr64Service {
  RemoteAccessService({
    required super.description,
    required super.callAction,
    required super.fetchUrl,
  });

  /// Get remote access configuration info.
  Future<RemoteAccessInfo> getInfo() async {
    final result = await call('GetInfo');
    return RemoteAccessInfo.fromArguments(result);
  }

  /// Configure a user for remote access from the internet.
  ///
  /// [username] may be a username or email address.
  /// [port] must be in the range 1-65535.
  Future<void> setConfig({
    required bool enabled,
    required int port,
    required String username,
    required String password,
  }) async {
    await call('SetConfig', {
      'NewEnabled': enabled ? '1' : '0',
      'NewPort': port.toString(),
      'NewUsername': username,
      'NewPassword': password,
    });
  }

  /// Get DDNS configuration info.
  Future<DDNSInfo> getDDNSInfo() async {
    final result = await call('GetDDNSInfo');
    return DDNSInfo.fromArguments(result);
  }

  /// Get the raw DDNS provider list as an XML string.
  Future<String> getDDNSProviderList() async {
    final result = await call('GetDDNSProviders');
    return result['NewProviderList'] ?? '';
  }

  /// Get and parse the list of available DDNS providers.
  Future<List<DDNSProvider>> getDDNSProviders() async {
    final xml = await getDDNSProviderList();
    if (xml.isEmpty) return [];
    return _parseProviderListXml(xml);
  }

  /// Configure dynamic DNS.
  ///
  /// [providerName] must match a name from [getDDNSProviders].
  /// For user-defined configurations, use the localized provider name
  /// (e.g. "Benutzerdefiniert" in German).
  Future<void> setDDNSConfig({
    required bool enabled,
    required String providerName,
    required String updateURL,
    required String serverIPv4,
    required String serverIPv6,
    required String domain,
    required String username,
    required String password,
    required DDNSMode mode,
  }) async {
    await call('SetDDNSConfig', {
      'NewEnabled': enabled ? '1' : '0',
      'NewProviderName': providerName,
      'NewUpdateURL': updateURL,
      'NewServerIPv4': serverIPv4,
      'NewServerIPv6': serverIPv6,
      'NewDomain': domain,
      'NewUsername': username,
      'NewPassword': password,
      'NewMode': mode.toString(),
    });
  }

  /// Enable or disable remote access.
  ///
  /// Returns the HTTPS port (may be a newly assigned random port
  /// when enabling, or 0 if no user has internet rights).
  Future<int> setEnable(bool enabled) async {
    final result = await call('SetEnable', {
      'NewEnabled': enabled ? '1' : '0',
    });
    return int.tryParse(result['NewPort'] ?? '') ?? 0;
  }

  /// Enable or disable Let's Encrypt certificate.
  Future<void> setLetsEncryptEnable(bool enabled) async {
    await call('SetLetsEncryptEnable', {
      'NewLetsEncryptEnabled': enabled ? '1' : '0',
    });
  }
}

/// Extension on [Tr64Client] to access the X_AVM-DE_RemoteAccess service.
extension RemoteAccessClientExtension on Tr64Client {
  /// Create a [RemoteAccessService] for remote access configuration.
  ///
  /// Requires [Tr64Client.connect] to have been called first.
  RemoteAccessService? remoteAccess() {
    if (description == null) return null;
    final desc = description!.findByType(
      'urn:dslforum-org:service:X_AVM-DE_RemoteAccess:1',
    );
    if (desc == null) return null;
    return RemoteAccessService(
      description: desc,
      callAction: (serviceType, controlUrl, actionName, arguments) => call(
        serviceType: serviceType,
        controlUrl: controlUrl,
        actionName: actionName,
        arguments: arguments,
      ),
      fetchUrl: fetchUrl,
    );
  }
}
