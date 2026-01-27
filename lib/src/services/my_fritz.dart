import '../client.dart';
import '../service.dart';

/// MyFRITZ registration state.
enum MyFritzState {
  /// MyFRITZ is disabled.
  myfritzDisabled('myfritz_disabled'),

  /// Registration failed.
  registerFailed('register_failed'),

  /// Device is unregistered.
  unregister('unregister'),

  /// DynDNS state is unknown.
  dyndnsUnknown('dyndns_unknown'),

  /// DynDNS is active.
  dyndnsActive('dyndns_active'),

  /// DynDNS update failed.
  dyndnsUpdateFailed('dyndns_update_failed'),

  /// DynDNS authentication error.
  dyndnsAuthError('dyndns_auth_error'),

  /// DynDNS server is unreachable.
  dyndnsServerUnreachable('dyndns_server_unreachable'),

  /// DynDNS server returned an error.
  dyndnsServerError('dyndns_server_error'),

  /// DynDNS server is updating.
  dyndnsServerUpdate('dyndns_server_update'),

  /// DynDNS is not yet verified.
  dyndnsNotVerified('dyndns_not_verified'),

  /// DynDNS has been verified.
  dyndnsVerified('dyndns_verified'),

  /// Reserved state.
  reserved('reserved'),

  /// Unknown state.
  unknown('unknown');

  final String _value;
  const MyFritzState(this._value);

  /// Parse a state string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static MyFritzState? tryParse(String value) {
    for (final s in values) {
      if (s._value == value) return s;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// MyFRITZ registration status (integer values).
enum MyFritzStatus {
  /// Device is not registered.
  notRegistered(0),

  /// Registered but disabled.
  registeredDisabled(1),

  /// Registration failed.
  registerFailed(10),

  /// Device is currently registering.
  deviceRegistering(99),

  /// DynDNS update is running.
  dyndnsUpdateRunning(200),

  /// DynDNS update encountered an unknown error.
  dyndnsUpdateUnknownError(250),

  /// DynDNS update authentication error.
  dyndnsUpdateAuthError(251),

  /// DynDNS update failed due to no internet.
  dyndnsUpdateNoInternet(252),

  /// DynDNS update target is not reachable.
  dyndnsUpdateNotReachable(253),

  /// DynDNS update received a bad reply.
  dyndnsUpdateBadReply(254),

  /// DynDNS update failed.
  dyndnsUpdateFailed(255),

  /// DynDNS updated and validating.
  dyndnsUpdatedValidating(300),

  /// DynDNS updated and validated.
  dyndnsUpdatedValidated(301);

  final int value;
  const MyFritzStatus(this.value);

  /// Parse a status integer returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static MyFritzStatus? tryParse(int value) {
    for (final s in values) {
      if (s.value == value) return s;
    }
    return null;
  }

  @override
  String toString() => value.toString();
}

/// IPv4 forwarding warning for a MyFRITZ service entry.
enum IPv4ForwardingWarning {
  /// Unknown state.
  unknown(0),

  /// Port forwarding succeeded.
  succeeded(1),

  /// Port forwarding failed.
  failed(2);

  final int value;
  const IPv4ForwardingWarning(this.value);

  /// Parse a warning integer returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static IPv4ForwardingWarning? tryParse(int value) {
    for (final w in values) {
      if (w.value == value) return w;
    }
    return null;
  }
}

/// Result of X_AVM-DE_MyFritz:GetInfo action.
class MyFritzInfo {
  /// Whether MyFRITZ is enabled.
  final bool enabled;

  /// The DynDNS name assigned to this device.
  final String dynDNSName;

  /// The configured port.
  final int port;

  /// Whether the device is registered with MyFRITZ.
  final bool deviceRegistered;

  /// Current MyFRITZ state.
  final MyFritzState? state;

  /// Email address associated with MyFRITZ.
  final String email;

  MyFritzInfo({
    required this.enabled,
    required this.dynDNSName,
    required this.port,
    required this.deviceRegistered,
    required this.state,
    required this.email,
  });

  factory MyFritzInfo.fromArguments(Map<String, String> args) {
    return MyFritzInfo(
      enabled: args['NewEnabled'] == '1',
      dynDNSName: args['NewDynDNSName'] ?? '',
      port: int.tryParse(args['NewPort'] ?? '') ?? 0,
      deviceRegistered: args['NewDeviceRegistered'] == '1',
      state: MyFritzState.tryParse(args['NewState'] ?? ''),
      email: args['NewEmail'] ?? '',
    );
  }

  @override
  String toString() =>
      'MyFritzInfo(enabled=$enabled, dynDNS=$dynDNSName, state=$state)';
}

/// Result of X_AVM-DE_MyFritz:GetServiceByIndex action.
class MyFritzServiceInfo {
  /// Whether this service is enabled.
  final bool enabled;

  /// Name of the service.
  final String name;

  /// URL scheme (e.g. "https").
  final String scheme;

  /// Port number.
  final int port;

  /// URL path.
  final String urlPath;

  /// Service type.
  final String type;

  /// IPv4 forwarding warning.
  final IPv4ForwardingWarning? ipv4ForwardingWarning;

  /// Comma-separated IPv4 addresses.
  final String ipv4Addresses;

  /// Comma-separated IPv6 addresses.
  final String ipv6Addresses;

  /// Comma-separated IPv6 interface IDs.
  final String ipv6InterfaceIDs;

  /// MAC address of the device.
  final String macAddress;

  /// Host name.
  final String hostName;

  /// DynDNS label.
  final String dynDnsLabel;

  /// Current status.
  final MyFritzStatus? status;

  MyFritzServiceInfo({
    required this.enabled,
    required this.name,
    required this.scheme,
    required this.port,
    required this.urlPath,
    required this.type,
    required this.ipv4ForwardingWarning,
    required this.ipv4Addresses,
    required this.ipv6Addresses,
    required this.ipv6InterfaceIDs,
    required this.macAddress,
    required this.hostName,
    required this.dynDnsLabel,
    required this.status,
  });

  factory MyFritzServiceInfo.fromArguments(Map<String, String> args) {
    return MyFritzServiceInfo(
      enabled: args['NewEnabled'] == '1',
      name: args['NewName'] ?? '',
      scheme: args['NewScheme'] ?? '',
      port: int.tryParse(args['NewPort'] ?? '') ?? 0,
      urlPath: args['NewURLPath'] ?? '',
      type: args['NewType'] ?? '',
      ipv4ForwardingWarning: IPv4ForwardingWarning.tryParse(
        int.tryParse(args['NewIPv4ForwardingWarning'] ?? '') ?? -1,
      ),
      ipv4Addresses: args['NewIPv4Addresses'] ?? '',
      ipv6Addresses: args['NewIPv6Addresses'] ?? '',
      ipv6InterfaceIDs: args['NewIPv6InterfaceIDs'] ?? '',
      macAddress: args['NewMACAddress'] ?? '',
      hostName: args['NewHostName'] ?? '',
      dynDnsLabel: args['NewDynDnsLabel'] ?? '',
      status: MyFritzStatus.tryParse(
        int.tryParse(args['NewStatus'] ?? '') ?? -1,
      ),
    );
  }

  @override
  String toString() =>
      'MyFritzServiceInfo(name=$name, scheme=$scheme, port=$port)';
}

/// TR-064 X_AVM-DE_MyFritz service.
///
/// Service type: urn:dslforum-org:service:X_AVM-DE_MyFritz:1
class MyFritzService extends Tr64Service {
  MyFritzService({
    required super.description,
    required super.callAction,
    required super.fetchUrl,
  });

  /// Get MyFRITZ configuration info.
  Future<MyFritzInfo> getInfo() async {
    final result = await call('GetInfo');
    return MyFritzInfo.fromArguments(result);
  }

  /// Enable or disable MyFRITZ and set the associated email.
  Future<void> setMyFritz({
    required bool enabled,
    required String email,
  }) async {
    await call('SetMyFRITZ', {
      'NewEnabled': enabled ? '1' : '0',
      'NewEmail': email,
    });
  }

  /// Get the number of registered MyFRITZ services.
  Future<int> getNumberOfServices() async {
    final result = await call('GetNumberOfServices');
    return int.tryParse(result['NewNumberOfServices'] ?? '') ?? 0;
  }

  /// Get a MyFRITZ service entry by index.
  Future<MyFritzServiceInfo> getServiceByIndex(int index) async {
    final result = await call('GetServiceByIndex', {
      'NewIndex': index.toString(),
    });
    return MyFritzServiceInfo.fromArguments(result);
  }

  /// Add or update a MyFRITZ service entry by index.
  Future<void> setServiceByIndex({
    required int index,
    required bool enabled,
    required String name,
    required String scheme,
    required int port,
    required String urlPath,
    required String type,
    required String ipv4Address,
    required String ipv6Address,
    required String ipv6InterfaceID,
    required String macAddress,
    required String hostName,
  }) async {
    await call('SetServiceByIndex', {
      'NewIndex': index.toString(),
      'NewEnabled': enabled ? '1' : '0',
      'NewName': name,
      'NewScheme': scheme,
      'NewPort': port.toString(),
      'NewURLPath': urlPath,
      'NewType': type,
      'NewIPv4Address': ipv4Address,
      'NewIPv6Address': ipv6Address,
      'NewIPv6InterfaceID': ipv6InterfaceID,
      'NewMACAddress': macAddress,
      'NewHostName': hostName,
    });
  }

  /// Delete a MyFRITZ service entry by index.
  Future<void> deleteServiceByIndex(int index) async {
    await call('DeleteServiceByIndex', {
      'NewIndex': index.toString(),
    });
  }
}

/// Extension on [Tr64Client] to access the X_AVM-DE_MyFritz service.
extension MyFritzClientExtension on Tr64Client {
  /// Create a [MyFritzService] for MyFRITZ configuration.
  ///
  /// Requires [Tr64Client.connect] to have been called first.
  MyFritzService? myFritz() {
    if (description == null) return null;
    final desc = description!.findByType(
      'urn:dslforum-org:service:X_AVM-DE_MyFritz:1',
    );
    if (desc == null) return null;
    return MyFritzService(
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
