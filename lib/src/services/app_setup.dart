import '../client.dart';
import '../service.dart';

/// Access right level for an app instance.
enum AppRight {
  /// Read and write access.
  rw('RW'),

  /// Read only access.
  ro('RO'),

  /// No access allowed.
  no('NO'),

  /// No specific right defined.
  undefined('UNDEFINED');

  final String _value;
  const AppRight(this._value);

  /// Parse a right string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static AppRight? tryParse(String value) {
    for (final r in values) {
      if (r._value == value) return r;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// Known event IDs for the ResetEvent action.
enum AppEventId {
  /// JASON message.
  jasonMessage(300),

  /// SIP register failed.
  sipRegisterFailed(500),

  /// SIP failure.
  sipFailure(501),

  /// Possible fraud.
  possibleFraud(502);

  final int value;
  const AppEventId(this.value);

  /// Parse an event ID integer returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static AppEventId? tryParse(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  @override
  String toString() => value.toString();
}

/// Result of X_AVM-DE_AppSetup:GetInfo action.
///
/// Contains parameter constraints (min/max length, allowed characters)
/// for the various action arguments.
class AppSetupInfo {
  /// Minimum number of characters for AppId.
  final int minCharsAppId;

  /// Maximum number of characters for AppId.
  final int maxCharsAppId;

  /// Allowed characters for AppId.
  final String allowedCharsAppId;

  /// Minimum number of characters for AppDisplayName.
  final int minCharsAppDisplayName;

  /// Maximum number of characters for AppDisplayName.
  final int maxCharsAppDisplayName;

  /// Minimum number of characters for AppUsername.
  final int minCharsAppUsername;

  /// Maximum number of characters for AppUsername.
  final int maxCharsAppUsername;

  /// Allowed characters for AppUsername.
  final String allowedCharsAppUsername;

  /// Minimum number of characters for AppPassword.
  final int minCharsAppPassword;

  /// Maximum number of characters for AppPassword.
  final int maxCharsAppPassword;

  /// Allowed characters for AppPassword.
  final String allowedCharsAppPassword;

  /// Minimum number of characters for IPSecIdentifier.
  final int minCharsIPSecIdentifier;

  /// Maximum number of characters for IPSecIdentifier.
  final int maxCharsIPSecIdentifier;

  /// Allowed characters for IPSecIdentifier.
  final String allowedCharsIPSecIdentifier;

  /// Minimum number of characters for IPSecPreSharedKey.
  final int minCharsIPSecPreSharedKey;

  /// Maximum number of characters for IPSecPreSharedKey.
  final int maxCharsIPSecPreSharedKey;

  /// Allowed characters for IPSecPreSharedKey.
  final String allowedCharsIPSecPreSharedKey;

  /// Minimum number of characters for IPSecXauthUsername.
  final int minCharsIPSecXauthUsername;

  /// Maximum number of characters for IPSecXauthUsername.
  final int maxCharsIPSecXauthUsername;

  /// Allowed characters for IPSecXauthUsername.
  final String allowedCharsIPSecXauthUsername;

  /// Minimum number of characters for IPSecXauthPassword.
  final int minCharsIPSecXauthPassword;

  /// Maximum number of characters for IPSecXauthPassword.
  final int maxCharsIPSecXauthPassword;

  /// Allowed characters for IPSecXauthPassword.
  final String allowedCharsIPSecXauthPassword;

  /// Allowed characters for CryptAlgos.
  final String allowedCharsCryptAlgos;

  /// Allowed characters for AppAVMAddress.
  final String allowedCharsAppAVMAddress;

  /// Minimum number of characters for Filter.
  final int minCharsFilter;

  /// Maximum number of characters for Filter.
  final int maxCharsFilter;

  /// Allowed characters for Filter.
  final String allowedCharsFilter;

  AppSetupInfo({
    required this.minCharsAppId,
    required this.maxCharsAppId,
    required this.allowedCharsAppId,
    required this.minCharsAppDisplayName,
    required this.maxCharsAppDisplayName,
    required this.minCharsAppUsername,
    required this.maxCharsAppUsername,
    required this.allowedCharsAppUsername,
    required this.minCharsAppPassword,
    required this.maxCharsAppPassword,
    required this.allowedCharsAppPassword,
    required this.minCharsIPSecIdentifier,
    required this.maxCharsIPSecIdentifier,
    required this.allowedCharsIPSecIdentifier,
    required this.minCharsIPSecPreSharedKey,
    required this.maxCharsIPSecPreSharedKey,
    required this.allowedCharsIPSecPreSharedKey,
    required this.minCharsIPSecXauthUsername,
    required this.maxCharsIPSecXauthUsername,
    required this.allowedCharsIPSecXauthUsername,
    required this.minCharsIPSecXauthPassword,
    required this.maxCharsIPSecXauthPassword,
    required this.allowedCharsIPSecXauthPassword,
    required this.allowedCharsCryptAlgos,
    required this.allowedCharsAppAVMAddress,
    required this.minCharsFilter,
    required this.maxCharsFilter,
    required this.allowedCharsFilter,
  });

  factory AppSetupInfo.fromArguments(Map<String, String> args) {
    return AppSetupInfo(
      minCharsAppId:
          int.tryParse(args['NewMinCharsAppId'] ?? '') ?? 0,
      maxCharsAppId:
          int.tryParse(args['NewMaxCharsAppId'] ?? '') ?? 0,
      allowedCharsAppId: args['NewAllowedCharsAppId'] ?? '',
      minCharsAppDisplayName:
          int.tryParse(args['NewMinCharsAppDisplayName'] ?? '') ?? 0,
      maxCharsAppDisplayName:
          int.tryParse(args['NewMaxCharsAppDisplayName'] ?? '') ?? 0,
      minCharsAppUsername:
          int.tryParse(args['NewMinCharsAppUsername'] ?? '') ?? 0,
      maxCharsAppUsername:
          int.tryParse(args['NewMaxCharsAppUsername'] ?? '') ?? 0,
      allowedCharsAppUsername: args['NewAllowedCharsAppUsername'] ?? '',
      minCharsAppPassword:
          int.tryParse(args['NewMinCharsAppPassword'] ?? '') ?? 0,
      maxCharsAppPassword:
          int.tryParse(args['NewMaxCharsAppPassword'] ?? '') ?? 0,
      allowedCharsAppPassword: args['NewAllowedCharsAppPassword'] ?? '',
      minCharsIPSecIdentifier:
          int.tryParse(args['NewMinCharsIPSecIdentifier'] ?? '') ?? 0,
      maxCharsIPSecIdentifier:
          int.tryParse(args['NewMaxCharsIPSecIdentifier'] ?? '') ?? 0,
      allowedCharsIPSecIdentifier:
          args['NewAllowedCharsIPSecIdentifier'] ?? '',
      minCharsIPSecPreSharedKey:
          int.tryParse(args['NewMinCharsIPSecPreSharedKey'] ?? '') ?? 0,
      maxCharsIPSecPreSharedKey:
          int.tryParse(args['NewMaxCharsIPSecPreSharedKey'] ?? '') ?? 0,
      allowedCharsIPSecPreSharedKey:
          args['NewAllowedCharsIPSecPreSharedKey'] ?? '',
      minCharsIPSecXauthUsername:
          int.tryParse(args['NewMinCharsIPSecXauthUsername'] ?? '') ?? 0,
      maxCharsIPSecXauthUsername:
          int.tryParse(args['NewMaxCharsIPSecXauthUsername'] ?? '') ?? 0,
      allowedCharsIPSecXauthUsername:
          args['NewAllowedCharsIPSecXauthUsername'] ?? '',
      minCharsIPSecXauthPassword:
          int.tryParse(args['NewMinCharsIPSecXauthPassword'] ?? '') ?? 0,
      maxCharsIPSecXauthPassword:
          int.tryParse(args['NewMaxCharsIPSecXauthPassword'] ?? '') ?? 0,
      allowedCharsIPSecXauthPassword:
          args['NewAllowedCharsIPSecXauthPassword'] ?? '',
      allowedCharsCryptAlgos: args['NewAllowedCharsCryptAlgos'] ?? '',
      allowedCharsAppAVMAddress: args['NewAllowedCharsAppAVMAddress'] ?? '',
      minCharsFilter:
          int.tryParse(args['NewMinCharsFilter'] ?? '') ?? 0,
      maxCharsFilter:
          int.tryParse(args['NewMaxCharsFilter'] ?? '') ?? 0,
      allowedCharsFilter: args['NewAllowedCharsFilter'] ?? '',
    );
  }

  @override
  String toString() =>
      'AppSetupInfo(appId=$minCharsAppId-$maxCharsAppId, '
      'password=$minCharsAppPassword-$maxCharsAppPassword)';
}

/// Result of X_AVM-DE_AppSetup:GetConfig action.
///
/// Contains the access rights of the current TR-064 security context.
class AppSetupConfig {
  /// FRITZ!OS configuration right.
  final AppRight? configRight;

  /// FRITZ!OS app specific configuration right.
  final AppRight? appRight;

  /// FRITZ!OS NAS specific right.
  final AppRight? nasRight;

  /// FRITZ!OS phone specific right.
  final AppRight? phoneRight;

  /// FRITZ!OS dial specific right.
  final AppRight? dialRight;

  /// FRITZ!OS home automation specific right.
  final AppRight? homeautoRight;

  /// Whether access rights from the internet are configured.
  final bool internetRights;

  /// Whether the current access is coming from the internet.
  final bool accessFromInternet;

  AppSetupConfig({
    required this.configRight,
    required this.appRight,
    required this.nasRight,
    required this.phoneRight,
    required this.dialRight,
    required this.homeautoRight,
    required this.internetRights,
    required this.accessFromInternet,
  });

  factory AppSetupConfig.fromArguments(Map<String, String> args) {
    return AppSetupConfig(
      configRight: AppRight.tryParse(args['NewConfigRight'] ?? ''),
      appRight: AppRight.tryParse(args['NewAppRight'] ?? ''),
      nasRight: AppRight.tryParse(args['NewNasRight'] ?? ''),
      phoneRight: AppRight.tryParse(args['NewPhoneRight'] ?? ''),
      dialRight: AppRight.tryParse(args['NewDialRight'] ?? ''),
      homeautoRight: AppRight.tryParse(args['NewHomeautoRight'] ?? ''),
      internetRights: args['NewInternetRights'] == '1',
      accessFromInternet: args['NewAccessFromInternet'] == '1',
    );
  }

  @override
  String toString() =>
      'AppSetupConfig(config=$configRight, app=$appRight, nas=$nasRight)';
}

/// Result of X_AVM-DE_AppSetup:GetAppRemoteInfo action.
///
/// Contains network information needed for apps to access the Fritz!Box
/// via WAN.
class AppRemoteInfo {
  /// Subnet mask of the local CPE network.
  final String subnetMask;

  /// Local IP address of the CPE device.
  final String ipAddress;

  /// IP address of the WAN interface.
  final String externalIPAddress;

  /// IPv6 address of the WAN interface.
  final String externalIPv6Address;

  /// Whether a specific DynDNS is activated.
  final bool remoteAccessDDNSEnabled;

  /// Domain of the DynDNS.
  final String remoteAccessDDNSDomain;

  /// Whether MyFRITZ DynDNS is activated.
  final bool myFritzDynDNSEnabled;

  /// MyFRITZ URL.
  final String myFritzDynDNSName;

  AppRemoteInfo({
    required this.subnetMask,
    required this.ipAddress,
    required this.externalIPAddress,
    required this.externalIPv6Address,
    required this.remoteAccessDDNSEnabled,
    required this.remoteAccessDDNSDomain,
    required this.myFritzDynDNSEnabled,
    required this.myFritzDynDNSName,
  });

  factory AppRemoteInfo.fromArguments(Map<String, String> args) {
    return AppRemoteInfo(
      subnetMask: args['NewSubnetMask'] ?? '',
      ipAddress: args['NewIPAddress'] ?? '',
      externalIPAddress: args['NewExternalIPAddress'] ?? '',
      externalIPv6Address: args['NewExternalIPv6Address'] ?? '',
      remoteAccessDDNSEnabled:
          args['NewRemoteAccessDDNSEnabled'] == '1',
      remoteAccessDDNSDomain:
          args['NewRemoteAccessDDNSDomain'] ?? '',
      myFritzDynDNSEnabled: args['NewMyFritzDynDNSEnabled'] == '1',
      myFritzDynDNSName: args['NewMyFritzDynDNSName'] ?? '',
    );
  }

  @override
  String toString() =>
      'AppRemoteInfo(ip=$ipAddress, external=$externalIPAddress)';
}

/// Result of X_AVM-DE_AppSetup:SetAppMessageReceiver action.
class AppMessageReceiverResult {
  /// Shared secret used for encryption and authentication.
  final String encryptionSecret;

  /// Sender ID used in messages from this box to the app.
  final String boxSenderId;

  AppMessageReceiverResult({
    required this.encryptionSecret,
    required this.boxSenderId,
  });

  factory AppMessageReceiverResult.fromArguments(Map<String, String> args) {
    return AppMessageReceiverResult(
      encryptionSecret: args['NewEncryptionSecret'] ?? '',
      boxSenderId: args['NewBoxSenderId'] ?? '',
    );
  }

  @override
  String toString() =>
      'AppMessageReceiverResult(boxSenderId=$boxSenderId)';
}

/// TR-064 X_AVM-DE_AppSetup service.
///
/// Service type: urn:dslforum-org:service:X_AVM-DE_AppSetup:1
class AppSetupService extends Tr64Service {
  AppSetupService({
    required super.description,
    required super.callAction,
    required super.fetchUrl,
  });

  /// Get the message filter list for an app instance.
  ///
  /// Returns the filter list as an XML string.
  Future<String> getAppMessageFilter(String appId) async {
    final result = await call('GetAppMessageFilter', {
      'NewAppId': appId,
    });
    return result['NewFilterList'] ?? '';
  }

  /// Get remote access information for apps.
  Future<AppRemoteInfo> getAppRemoteInfo() async {
    final result = await call('GetAppRemoteInfo');
    return AppRemoteInfo.fromArguments(result);
  }

  /// Get the current access rights of the TR-064 security context.
  Future<AppSetupConfig> getConfig() async {
    final result = await call('GetConfig');
    return AppSetupConfig.fromArguments(result);
  }

  /// Get parameter constraints for action arguments.
  Future<AppSetupInfo> getInfo() async {
    final result = await call('GetInfo');
    return AppSetupInfo.fromArguments(result);
  }

  /// Register a new app instance.
  ///
  /// Creates a new app instance if [appId] does not already exist.
  /// Otherwise the existing app instance is overwritten.
  /// Must be called from within the home network.
  Future<void> registerApp({
    required String appId,
    required String appDisplayName,
    required String appDeviceMAC,
    required String appUsername,
    required String appPassword,
    required AppRight appRight,
    required AppRight nasRight,
    required AppRight phoneRight,
    required AppRight homeautoRight,
    required bool appInternetRights,
  }) async {
    await call('RegisterApp', {
      'NewAppId': appId,
      'NewAppDisplayName': appDisplayName,
      'NewAppDeviceMAC': appDeviceMAC,
      'NewAppUsername': appUsername,
      'NewAppPassword': appPassword,
      'NewAppRight': appRight.toString(),
      'NewNasRight': nasRight.toString(),
      'NewPhoneRight': phoneRight.toString(),
      'NewHomeautoRight': homeautoRight.toString(),
      'NewAppInternetRights': appInternetRights ? '1' : '0',
    });
  }

  /// Reset an event specified by an event ID.
  ///
  /// Must be called from within the home network.
  Future<void> resetEvent(int eventId) async {
    await call('ResetEvent', {
      'NewEventId': eventId.toString(),
    });
  }

  /// Set a message filter for an app instance.
  ///
  /// Pass an empty [filter] to remove the filter of the given [type].
  Future<void> setAppMessageFilter({
    required String appId,
    required String type,
    required String filter,
  }) async {
    await call('SetAppMessageFilter', {
      'NewAppId': appId,
      'NewType': type,
      'NewFilter': filter,
    });
  }

  /// Configure a message receiver for an app instance.
  ///
  /// Pass an empty [appAVMAddress] to stop receiving messages.
  /// Must be called from within the home network.
  Future<AppMessageReceiverResult> setAppMessageReceiver({
    required String appId,
    required String cryptAlgos,
    required String appAVMAddress,
    required String appAVMPasswordHash,
  }) async {
    final result = await call('SetAppMessageReceiver', {
      'NewAppId': appId,
      'NewCryptAlgos': cryptAlgos,
      'NewAppAVMAddress': appAVMAddress,
      'NewAppAVMPasswordHash': appAVMPasswordHash,
    });
    return AppMessageReceiverResult.fromArguments(result);
  }

  /// Configure VPN (IPsec) access for an app instance.
  ///
  /// Pass all IPSec parameters as empty strings to delete the VPN
  /// configuration.
  Future<void> setAppVPN({
    required String appId,
    required String ipSecIdentifier,
    required String ipSecPreSharedKey,
    required String ipSecXauthUsername,
    required String ipSecXauthPassword,
  }) async {
    await call('SetAppVPN', {
      'NewAppId': appId,
      'NewIPSecIdentifier': ipSecIdentifier,
      'NewIPSecPreSharedKey': ipSecPreSharedKey,
      'NewIPSecXauthUsername': ipSecXauthUsername,
      'NewIPSecXauthPassword': ipSecXauthPassword,
    });
  }

  /// Configure VPN (IPsec) access with PFS for an app instance.
  ///
  /// Pass all IPSec parameters as empty strings to delete the VPN
  /// configuration.
  Future<void> setAppVPNWithPFS({
    required String appId,
    required String ipSecIdentifier,
    required String ipSecPreSharedKey,
    required String ipSecXauthUsername,
    required String ipSecXauthPassword,
  }) async {
    await call('SetAppVPNwithPFS', {
      'NewAppId': appId,
      'NewIPSecIdentifier': ipSecIdentifier,
      'NewIPSecPreSharedKey': ipSecPreSharedKey,
      'NewIPSecXauthUsername': ipSecXauthUsername,
      'NewIPSecXauthPassword': ipSecXauthPassword,
    });
  }

  /// Get the box sender ID for an app instance.
  Future<String> getBoxSenderId(String appId) async {
    final result = await call('GetBoxSenderId', {
      'NewAppId': appId,
    });
    return result['NewBoxSenderId'] ?? '';
  }
}

/// Extension on [Tr64Client] to access the X_AVM-DE_AppSetup service.
extension AppSetupClientExtension on Tr64Client {
  /// Create an [AppSetupService] for app registration and configuration.
  ///
  /// Requires [Tr64Client.connect] to have been called first.
  AppSetupService? appSetup() {
    if (description == null) return null;
    final desc = description!.findByType(
      'urn:dslforum-org:service:X_AVM-DE_AppSetup:1',
    );
    if (desc == null) return null;
    return AppSetupService(
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
