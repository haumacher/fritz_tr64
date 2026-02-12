import 'package:xml/xml.dart';

import '../client.dart';
import '../service.dart';

/// Voice coding mode.
enum VoiceCoding {
  /// Always use POTS quality (default).
  fixed('fixed'),

  /// Automatic audio codec selection.
  auto('auto'),

  /// Always use audio codec with compression.
  compressed('compressed'),

  /// Automatic use of compressed audio codec.
  autocompressed('autocompressed');

  final String _value;
  const VoiceCoding(this._value);

  /// Parse a voice coding string returned by the Fritz!Box.
  ///
  /// Returns `null` for unrecognised or empty values.
  static VoiceCoding? tryParse(String value) {
    for (final v in values) {
      if (v._value == value) return v;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// VoIP account registration status.
enum VoIPStatus {
  /// VoIP account is disabled.
  disabled('disabled'),

  /// VoIP account is not registered.
  notRegistered('not registered'),

  /// VoIP account is successfully registered.
  registered('registered'),

  /// A VoIP connection is active.
  connected('connected'),

  /// Unknown error.
  unknown('unknown');

  final String _value;
  const VoIPStatus(this._value);

  /// Parse a VoIP status string returned by the Fritz!Box.
  ///
  /// Returns `null` for unrecognised or empty values.
  static VoIPStatus? tryParse(String value) {
    for (final s in values) {
      if (s._value == value) return s;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// Result of X_VoIP:GetInfo action.
class VoIPInfo {
  final bool faxT38Enable;

  /// Voice coding mode.
  final VoiceCoding? voiceCoding;

  VoIPInfo({
    required this.faxT38Enable,
    required this.voiceCoding,
  });

  factory VoIPInfo.fromArguments(Map<String, String> args) {
    return VoIPInfo(
      faxT38Enable: args['NewFaxT38Enable'] == '1',
      voiceCoding: VoiceCoding.tryParse(args['NewVoiceCoding'] ?? ''),
    );
  }

  @override
  String toString() => 'VoIPInfo(faxT38=$faxT38Enable, coding=$voiceCoding)';
}

/// Result of X_VoIP:GetInfoEx action.
///
/// Contains min/max/allowed-chars constraints for VoIP configuration fields.
class VoIPInfoEx {
  final int voIPNumberMinChars;
  final int voIPNumberMaxChars;
  final String voIPNumberAllowedChars;
  final int voIPRegistrarMinChars;
  final int voIPRegistrarMaxChars;
  final String voIPRegistrarAllowedChars;
  final int voIPSTUNServerMinChars;
  final int voIPSTUNServerMaxChars;
  final String voIPSTUNServerAllowedChars;
  final int voIPUsernameMinChars;
  final int voIPUsernameMaxChars;
  final String voIPUsernameAllowedChars;
  final int voIPPasswordMinChars;
  final int voIPPasswordMaxChars;
  final String voIPPasswordAllowedChars;
  final int clientUsernameMinChars;
  final int clientUsernameMaxChars;
  final String clientUsernameAllowedChars;
  final int clientPasswordMinChars;
  final int clientPasswordMaxChars;
  final String clientPasswordAllowedChars;

  VoIPInfoEx({
    required this.voIPNumberMinChars,
    required this.voIPNumberMaxChars,
    required this.voIPNumberAllowedChars,
    required this.voIPRegistrarMinChars,
    required this.voIPRegistrarMaxChars,
    required this.voIPRegistrarAllowedChars,
    required this.voIPSTUNServerMinChars,
    required this.voIPSTUNServerMaxChars,
    required this.voIPSTUNServerAllowedChars,
    required this.voIPUsernameMinChars,
    required this.voIPUsernameMaxChars,
    required this.voIPUsernameAllowedChars,
    required this.voIPPasswordMinChars,
    required this.voIPPasswordMaxChars,
    required this.voIPPasswordAllowedChars,
    required this.clientUsernameMinChars,
    required this.clientUsernameMaxChars,
    required this.clientUsernameAllowedChars,
    required this.clientPasswordMinChars,
    required this.clientPasswordMaxChars,
    required this.clientPasswordAllowedChars,
  });

  factory VoIPInfoEx.fromArguments(Map<String, String> args) {
    return VoIPInfoEx(
      voIPNumberMinChars:
          int.tryParse(args['NewVoIPNumberMinChars'] ?? '') ?? 0,
      voIPNumberMaxChars:
          int.tryParse(args['NewVoIPNumberMaxChars'] ?? '') ?? 0,
      voIPNumberAllowedChars: args['NewVoIPNumberAllowedChars'] ?? '',
      voIPRegistrarMinChars:
          int.tryParse(args['NewVoIPRegistrarMinChars'] ?? '') ?? 0,
      voIPRegistrarMaxChars:
          int.tryParse(args['NewVoIPRegistrarMaxChars'] ?? '') ?? 0,
      voIPRegistrarAllowedChars:
          args['NewVoIPRegistrarAllowedChars'] ?? '',
      voIPSTUNServerMinChars:
          int.tryParse(args['NewVoIPSTUNServerMinChars'] ?? '') ?? 0,
      voIPSTUNServerMaxChars:
          int.tryParse(args['NewVoIPSTUNServerMaxChars'] ?? '') ?? 0,
      voIPSTUNServerAllowedChars:
          args['NewVoIPSTUNServerAllowedChars'] ?? '',
      voIPUsernameMinChars:
          int.tryParse(args['NewVoIPUsernameMinChars'] ?? '') ?? 0,
      voIPUsernameMaxChars:
          int.tryParse(args['NewVoIPUsernameMaxChars'] ?? '') ?? 0,
      voIPUsernameAllowedChars: args['NewVoIPUsernameAllowedChars'] ?? '',
      voIPPasswordMinChars:
          int.tryParse(args['NewVoIPPasswordMinChars'] ?? '') ?? 0,
      voIPPasswordMaxChars:
          int.tryParse(args['NewVoIPPasswordMaxChars'] ?? '') ?? 0,
      voIPPasswordAllowedChars: args['NewVoIPPasswordAllowedChars'] ?? '',
      clientUsernameMinChars:
          int.tryParse(args['NewX_AVM-DE_ClientUsernameMinChars'] ?? '') ?? 0,
      clientUsernameMaxChars:
          int.tryParse(args['NewX_AVM-DE_ClientUsernameMaxChars'] ?? '') ?? 0,
      clientUsernameAllowedChars:
          args['NewX_AVM-DE_ClientUsernameAllowedChars'] ?? '',
      clientPasswordMinChars:
          int.tryParse(args['NewX_AVM-DE_ClientPasswordMinChars'] ?? '') ?? 0,
      clientPasswordMaxChars:
          int.tryParse(args['NewX_AVM-DE_ClientPasswordMaxChars'] ?? '') ?? 0,
      clientPasswordAllowedChars:
          args['NewX_AVM-DE_ClientPasswordAllowedChars'] ?? '',
    );
  }

  @override
  String toString() => 'VoIPInfoEx(number=$voIPNumberMinChars-'
      '$voIPNumberMaxChars)';
}

/// Result of X_VoIP:GetVoIPAccount action.
class VoIPAccount {
  final String registrar;
  final String number;
  final String username;
  final String outboundProxy;
  final String stunServer;

  /// Registration status of this VoIP account.
  final VoIPStatus? status;

  VoIPAccount({
    required this.registrar,
    required this.number,
    required this.username,
    required this.outboundProxy,
    required this.stunServer,
    required this.status,
  });

  factory VoIPAccount.fromArguments(Map<String, String> args) {
    return VoIPAccount(
      registrar: args['NewVoIPRegistrar'] ?? '',
      number: args['NewVoIPNumber'] ?? '',
      username: args['NewVoIPUsername'] ?? '',
      outboundProxy: args['NewVoIPOutboundProxy'] ?? '',
      stunServer: args['NewVoIPSTUNServer'] ?? '',
      status: VoIPStatus.tryParse(args['NewVoIPStatus'] ?? ''),
    );
  }

  @override
  String toString() => 'VoIPAccount($number, $registrar)';
}

/// Result of X_VoIP:X_AVM-DE_GetClient3 action.
class VoIPClient {
  final int clientIndex;
  final String clientUsername;
  final String clientRegistrar;
  final int clientRegistrarPort;
  final String phoneName;
  final String clientId;
  final String outGoingNumber;
  final List<VoIPNumber> inComingNumbers;
  /// Whether external (internet) registration is enabled.
  ///
  /// **Warning:** This value is read from the TR-064 response but has been
  /// **ignored by Fritz!Box since 2015** per AVM spec. The Fritz!Box always
  /// returns `false` regardless of the actual web UI setting.
  /// Use [IpPhoneService] from the web API to read or set this reliably.
  final bool externalRegistration;

  final String internalNumber;
  final bool delayedCallNotification;

  VoIPClient({
    required this.clientIndex,
    required this.clientUsername,
    required this.clientRegistrar,
    required this.clientRegistrarPort,
    required this.phoneName,
    required this.clientId,
    required this.outGoingNumber,
    this.inComingNumbers = const [],
    required this.externalRegistration,
    required this.internalNumber,
    required this.delayedCallNotification,
  });

  factory VoIPClient.fromArguments(Map<String, String> args) {
    final incomingXml = args['NewX_AVM-DE_InComingNumbers'] ?? '';
    return VoIPClient(
      clientIndex:
          int.tryParse(args['NewX_AVM-DE_ClientIndex'] ?? '') ?? 0,
      clientUsername: args['NewX_AVM-DE_ClientUsername'] ?? '',
      clientRegistrar: args['NewX_AVM-DE_ClientRegistrar'] ?? '',
      clientRegistrarPort:
          int.tryParse(args['NewX_AVM-DE_ClientRegistrarPort'] ?? '') ?? 0,
      phoneName: args['NewX_AVM-DE_PhoneName'] ?? '',
      clientId: args['NewX_AVM-DE_ClientId'] ?? '',
      outGoingNumber: args['NewX_AVM-DE_OutGoingNumber'] ?? '',
      inComingNumbers:
          incomingXml.isEmpty ? const [] : _parseNumbersXml(incomingXml),
      externalRegistration:
          args['NewX_AVM-DE_ExternalRegistration'] == '1',
      internalNumber: args['NewX_AVM-DE_InternalNumber'] ?? '',
      delayedCallNotification:
          args['NewX_AVM-DE_DelayedCallNotification'] == '1',
    );
  }

  @override
  String toString() => 'VoIPClient($clientId, $phoneName)';
}

/// Type of a VoIP number entry.
enum VoIPNumberType {
  eAllCalls,
  eGSM,
  eISDN,
  eNone,
  ePOTS,
  eVoIP;

  static VoIPNumberType? tryParse(String value) {
    for (final t in values) {
      if (t.name == value) return t;
    }
    return null;
  }
}

/// A VoIP number entry from the GetNumbers XML list.
class VoIPNumber {
  final String number;
  final VoIPNumberType type;
  final int index;
  final String name;

  VoIPNumber({
    required this.number,
    required this.type,
    required this.index,
    required this.name,
  });

  @override
  String toString() => 'VoIPNumber($number, ${type.name})';
}

/// Result of X_VoIP:X_AVM-DE_GetAlarmClock action.
class AlarmClock {
  final bool enable;
  final String name;
  final String time;
  final String weekdays;
  final String phoneName;

  AlarmClock({
    required this.enable,
    required this.name,
    required this.time,
    required this.weekdays,
    required this.phoneName,
  });

  factory AlarmClock.fromArguments(Map<String, String> args) {
    return AlarmClock(
      enable: args['NewX_AVM-DE_AlarmClockEnable'] == '1',
      name: args['NewX_AVM-DE_AlarmClockName'] ?? '',
      time: args['NewX_AVM-DE_AlarmClockFormattedTime'] ?? '',
      weekdays: args['NewX_AVM-DE_AlarmClockWeekdays'] ?? '',
      phoneName: args['NewX_AVM-DE_AlarmClockPhoneName'] ?? '',
    );
  }

  @override
  String toString() => 'AlarmClock($name, $time)';
}

/// Country code result from X_AVM-DE_GetVoIPCommonCountryCode.
class CountryCode {
  final String lkz;
  final String lkzPrefix;

  CountryCode({
    required this.lkz,
    required this.lkzPrefix,
  });

  factory CountryCode.fromArguments(Map<String, String> args) {
    return CountryCode(
      lkz: args['NewX_AVM-DE_LKZ'] ?? '',
      lkzPrefix: args['NewX_AVM-DE_LKZPrefix'] ?? '',
    );
  }

  @override
  String toString() => 'CountryCode($lkzPrefix$lkz)';
}

/// Area code result from X_AVM-DE_GetVoIPCommonAreaCode.
class AreaCode {
  final String okz;
  final String okzPrefix;

  AreaCode({
    required this.okz,
    required this.okzPrefix,
  });

  factory AreaCode.fromArguments(Map<String, String> args) {
    return AreaCode(
      okz: args['NewX_AVM-DE_OKZ'] ?? '',
      okzPrefix: args['NewX_AVM-DE_OKZPrefix'] ?? '',
    );
  }

  @override
  String toString() => 'AreaCode($okzPrefix$okz)';
}

/// TR-064 X_VoIP service (VoIP telephony).
///
/// Service type: urn:dslforum-org:service:X_VoIP:1
class VoIPService extends Tr64Service {
  VoIPService({
    required super.description,
    required super.callAction,
    required super.fetchUrl,
  });

  // -- Basic info --

  /// Get basic VoIP configuration info.
  Future<VoIPInfo> getInfo() async {
    final result = await call('GetInfo');
    return VoIPInfo.fromArguments(result);
  }

  /// Get extended VoIP info with min/max/allowed-chars constraints.
  Future<VoIPInfoEx> getInfoEx() async {
    final result = await call('GetInfoEx');
    return VoIPInfoEx.fromArguments(result);
  }

  /// Get the number of existing VoIP numbers.
  Future<int> getExistingVoIPNumbers() async {
    final result = await call('GetExistingVoIPNumbers');
    return int.parse(result['NewExistingVoIPNumbers'] ?? '0');
  }

  /// Get the maximum number of VoIP numbers.
  Future<int> getMaxVoIPNumbers() async {
    final result = await call('GetMaxVoIPNumbers');
    return int.parse(result['NewMaxVoIPNumbers'] ?? '0');
  }

  // -- Area/country code settings --

  /// Get whether area code is enabled for a VoIP account.
  Future<bool> getVoIPEnableAreaCode(int accountIndex) async {
    final result = await call('GetVoIPEnableAreaCode', {
      'NewVoIPAccountIndex': accountIndex.toString(),
    });
    return result['NewVoIPEnableAreaCode'] == '1';
  }

  /// Enable or disable area code for a VoIP account.
  Future<void> setVoIPEnableAreaCode(int accountIndex, bool enable) async {
    await call('SetVoIPEnableAreaCode', {
      'NewVoIPAccountIndex': accountIndex.toString(),
      'NewVoIPEnableAreaCode': enable ? '1' : '0',
    });
  }

  /// Get whether country code is enabled for a VoIP account.
  Future<bool> getVoIPEnableCountryCode(int accountIndex) async {
    final result = await call('GetVoIPEnableCountryCode', {
      'NewVoIPAccountIndex': accountIndex.toString(),
    });
    return result['NewVoIPEnableCountryCode'] == '1';
  }

  /// Enable or disable country code for a VoIP account.
  Future<void> setVoIPEnableCountryCode(
      int accountIndex, bool enable) async {
    await call('SetVoIPEnableCountryCode', {
      'NewVoIPAccountIndex': accountIndex.toString(),
      'NewVoIPEnableCountryCode': enable ? '1' : '0',
    });
  }

  /// Set the VoIP configuration (fax T.38 and voice coding).
  Future<void> setConfig({
    required bool faxT38Enable,
    required VoiceCoding voiceCoding,
  }) async {
    await call('SetConfig', {
      'NewFaxT38Enable': faxT38Enable ? '1' : '0',
      'NewVoiceCoding': voiceCoding.toString(),
    });
  }

  /// Get the common country code (X_AVM-DE_ version).
  Future<CountryCode> getVoIPCommonCountryCode() async {
    final result = await call('X_AVM-DE_GetVoIPCommonCountryCode');
    return CountryCode.fromArguments(result);
  }

  /// Set the common country code (X_AVM-DE_ version).
  Future<void> setVoIPCommonCountryCode(
      String lkz, String lkzPrefix) async {
    await call('X_AVM-DE_SetVoIPCommonCountryCode', {
      'NewX_AVM-DE_LKZ': lkz,
      'NewX_AVM-DE_LKZPrefix': lkzPrefix,
    });
  }

  /// Get the common area code (X_AVM-DE_ version).
  Future<AreaCode> getVoIPCommonAreaCode() async {
    final result = await call('X_AVM-DE_GetVoIPCommonAreaCode');
    return AreaCode.fromArguments(result);
  }

  /// Set the common area code (X_AVM-DE_ version).
  Future<void> setVoIPCommonAreaCode(String okz, String okzPrefix) async {
    await call('X_AVM-DE_SetVoIPCommonAreaCode', {
      'NewX_AVM-DE_OKZ': okz,
      'NewX_AVM-DE_OKZPrefix': okzPrefix,
    });
  }

  // -- VoIP accounts --

  /// Add or update a VoIP account.
  Future<void> addVoIPAccount({
    required int accountIndex,
    required String registrar,
    required String number,
    required String username,
    required String password,
    required String outboundProxy,
    required String stunServer,
  }) async {
    await call('AddVoIPAccount', {
      'NewVoIPAccountIndex': accountIndex.toString(),
      'NewVoIPRegistrar': registrar,
      'NewVoIPNumber': number,
      'NewVoIPUsername': username,
      'NewVoIPPassword': password,
      'NewVoIPOutboundProxy': outboundProxy,
      'NewVoIPSTUNServer': stunServer,
    });
  }

  /// Delete a VoIP account by index.
  Future<void> deleteVoIPAccount(int accountIndex) async {
    await call('DeleteVoIPAccount', {
      'NewVoIPAccountIndex': accountIndex.toString(),
    });
  }

  /// Get a VoIP account by index.
  Future<VoIPAccount> getVoIPAccount(int accountIndex) async {
    final result = await call('GetVoIPAccount', {
      'NewVoIPAccountIndex': accountIndex.toString(),
    });
    return VoIPAccount.fromArguments(result);
  }

  /// Get all VoIP accounts as a list.
  ///
  /// Fetches the account list URL and parses each `<Item>` element.
  Future<List<VoIPAccount>> getVoIPAccounts() async {
    final result = await call('X_AVM-DE_GetVoIPAccounts');
    final xml = result['NewX_AVM-DE_VoIPAccountList'] ?? '';
    if (xml.isEmpty) return [];
    return _parseVoIPAccountsXml(xml);
  }

  /// Get the status of a VoIP account.
  Future<VoIPStatus?> getVoIPStatus(int accountIndex) async {
    final result = await call('GetVoIPStatus', {
      'NewVoIPAccountIndex': accountIndex.toString(),
    });
    return VoIPStatus.tryParse(result['NewVoIPStatus'] ?? '');
  }

  // -- Dialing --

  /// Get the phone name for dialing.
  Future<String> dialGetConfig() async {
    final result = await call('X_AVM-DE_DialGetConfig');
    return result['NewX_AVM-DE_PhoneName'] ?? '';
  }

  /// Hang up the current call.
  Future<void> dialHangup() async {
    await call('X_AVM-DE_DialHangup');
  }

  /// Dial a phone number.
  Future<void> dialNumber(String phoneNumber) async {
    await call('X_AVM-DE_DialNumber', {
      'NewX_AVM-DE_PhoneNumber': phoneNumber,
    });
  }

  /// Set the phone name for dialing.
  Future<void> dialSetConfig(String phoneName) async {
    await call('X_AVM-DE_DialSetConfig', {
      'NewX_AVM-DE_PhoneName': phoneName,
    });
  }

  // -- SIP clients --

  /// Get the number of SIP clients.
  Future<int> getNumberOfClients() async {
    final result = await call('X_AVM-DE_GetNumberOfClients');
    return int.parse(result['NewX_AVM-DE_NumberOfClients'] ?? '0');
  }

  /// Get a SIP client by index (GetClient2).
  Future<VoIPClient> getClient(int clientIndex) async {
    final result = await call('X_AVM-DE_GetClient2', {
      'NewX_AVM-DE_ClientIndex': clientIndex.toString(),
    });
    return VoIPClient.fromArguments(result);
  }

  /// Get a SIP client by index with full info (GetClient3).
  Future<VoIPClient> getClient3(int clientIndex) async {
    final result = await call('X_AVM-DE_GetClient3', {
      'NewX_AVM-DE_ClientIndex': clientIndex.toString(),
    });
    return VoIPClient.fromArguments(result);
  }

  /// Get a SIP client by its client ID.
  Future<VoIPClient> getClientByClientId(String clientId) async {
    final result = await call('X_AVM-DE_GetClientByClientId', {
      'NewX_AVM-DE_ClientId': clientId,
    });
    return VoIPClient.fromArguments(result);
  }

  /// Get the raw XML list of all SIP clients.
  Future<String> getClients() async {
    final result = await call('X_AVM-DE_GetClients');
    return result['NewX_AVM-DE_ClientList'] ?? '';
  }

  /// Delete a SIP client by index.
  Future<void> deleteClient(int clientIndex) async {
    await call('X_AVM-DE_DeleteClient', {
      'NewX_AVM-DE_ClientIndex': clientIndex.toString(),
    });
  }

  /// Configure a SIP client (SetClient2).
  Future<void> setClient({
    required int clientIndex,
    required String password,
    required String phoneName,
    required String clientId,
    required String outGoingNumber,
  }) async {
    await call('X_AVM-DE_SetClient2', {
      'NewX_AVM-DE_ClientIndex': clientIndex.toString(),
      'NewX_AVM-DE_ClientPassword': password,
      'NewX_AVM-DE_PhoneName': phoneName,
      'NewX_AVM-DE_ClientId': clientId,
      'NewX_AVM-DE_OutGoingNumber': outGoingNumber,
    });
  }

  /// Configure a SIP client with extended options (SetClient3).
  ///
  /// **Warning:** The [externalRegistration] parameter has been **ignored by
  /// Fritz!Box since 2015** per AVM spec. Setting it to `true` has no effect.
  /// To enable internet access for a SIP device, use [IpPhoneService] from
  /// the web API instead.
  Future<void> setClient3({
    required int clientIndex,
    required String password,
    required String phoneName,
    required String clientId,
    required String outGoingNumber,
    required String inComingNumbers,
    required bool externalRegistration,
  }) async {
    await call('X_AVM-DE_SetClient3', {
      'NewX_AVM-DE_ClientIndex': clientIndex.toString(),
      'NewX_AVM-DE_ClientPassword': password,
      'NewX_AVM-DE_PhoneName': phoneName,
      'NewX_AVM-DE_ClientId': clientId,
      'NewX_AVM-DE_OutGoingNumber': outGoingNumber,
      'NewX_AVM-DE_InComingNumbers': inComingNumbers,
      'NewX_AVM-DE_ExternalRegistration': externalRegistration ? '1' : '0',
    });
  }

  /// Configure a SIP client with username (SetClient4).
  ///
  /// Returns the internal number assigned to the client.
  ///
  /// Note: `SetClient4` does not support `ExternalRegistration`. To enable
  /// internet registration, call [setClient3] on the same index afterwards.
  Future<String> setClient4({
    required int clientIndex,
    required String password,
    required String clientUsername,
    required String phoneName,
    required String clientId,
    required String outGoingNumber,
    required String inComingNumbers,
  }) async {
    final result = await call('X_AVM-DE_SetClient4', {
      'NewX_AVM-DE_ClientIndex': clientIndex.toString(),
      'NewX_AVM-DE_ClientPassword': password,
      'NewX_AVM-DE_ClientUsername': clientUsername,
      'NewX_AVM-DE_PhoneName': phoneName,
      'NewX_AVM-DE_ClientId': clientId,
      'NewX_AVM-DE_OutGoingNumber': outGoingNumber,
      'NewX_AVM-DE_InComingNumbers': inComingNumbers,
    });
    return result['NewX_AVM-DE_InternalNumber'] ?? '';
  }

  /// Enable or disable delayed call notification for a client.
  Future<void> setDelayedCallNotification(
      int clientIndex, bool enable) async {
    await call('X_AVM-DE_SetDelayedCallNotification', {
      'NewX_AVM-DE_ClientIndex': clientIndex.toString(),
      'NewX_AVM-DE_DelayedCallNotification': enable ? '1' : '0',
    });
  }

  // -- Numbers --

  /// Get the number of VoIP phone numbers.
  Future<int> getNumberOfNumbers() async {
    final result = await call('X_AVM-DE_GetNumberOfNumbers');
    return int.parse(result['NewNumberOfNumbers'] ?? '0');
  }

  /// Get the list of VoIP phone numbers.
  ///
  /// Parses the XML list of `<Item>` elements.
  Future<List<VoIPNumber>> getNumbers() async {
    final result = await call('X_AVM-DE_GetNumbers');
    final xml = result['NewNumberList'] ?? '';
    if (xml.isEmpty) return [];
    return _parseNumbersXml(xml);
  }

  /// Get the phone name for a phone port by index.
  Future<String> getPhonePort(int index) async {
    final result = await call('X_AVM-DE_GetPhonePort', {
      'NewIndex': index.toString(),
    });
    return result['NewX_AVM-DE_PhoneName'] ?? '';
  }

  // -- Alarm clocks --

  /// Get an alarm clock by index.
  Future<AlarmClock> getAlarmClock(int index) async {
    final result = await call('X_AVM-DE_GetAlarmClock', {
      'NewIndex': index.toString(),
    });
    return AlarmClock.fromArguments(result);
  }

  /// Get the number of alarm clocks.
  Future<int> getNumberOfAlarmClocks() async {
    final result = await call('X_AVM-DE_GetNumberOfAlarmClocks');
    return int.parse(result['NewX_AVM-DE_NumberOfAlarmClocks'] ?? '0');
  }

  /// Enable or disable an alarm clock.
  Future<void> setAlarmClockEnable(int index, bool enable) async {
    await call('X_AVM-DE_SetAlarmClockEnable', {
      'NewIndex': index.toString(),
      'NewX_AVM-DE_AlarmClockEnable': enable ? '1' : '0',
    });
  }
}

/// Parse VoIP accounts XML list.
///
/// Expected structure: `List > Item > Number, Registrar, Username, ...`
List<VoIPAccount> _parseVoIPAccountsXml(String xml) {
  final document = XmlDocument.parse(xml);
  final accounts = <VoIPAccount>[];
  for (final item in document.findAllElements('Item')) {
    accounts.add(VoIPAccount(
      registrar: _childText(item, 'Registrar') ?? '',
      number: _childText(item, 'Number') ?? '',
      username: _childText(item, 'Username') ?? '',
      outboundProxy: _childText(item, 'OutboundProxy') ?? '',
      stunServer: _childText(item, 'STUNServer') ?? '',
      status: VoIPStatus.tryParse(_childText(item, 'Status') ?? ''),
    ));
  }
  return accounts;
}

/// Parse VoIP numbers XML list.
///
/// Expected structure: `List > Item > Number, Type, Index, Name`.
List<VoIPNumber> _parseNumbersXml(String xml) {
  final document = XmlDocument.parse(xml);
  final numbers = <VoIPNumber>[];
  for (final item in document.findAllElements('Item')) {
    final typeStr = _childText(item, 'Type') ?? '';
    final type = VoIPNumberType.tryParse(typeStr);
    if (type == null) continue;
    numbers.add(VoIPNumber(
      number: _childText(item, 'Number') ?? '',
      type: type,
      index: int.tryParse(_childText(item, 'Index') ?? '') ?? 0,
      name: _childText(item, 'Name') ?? '',
    ));
  }
  return numbers;
}

XmlElement? _findChild(XmlElement parent, String localName) {
  for (final child in parent.childElements) {
    if (child.localName == localName) return child;
  }
  return null;
}

String? _childText(XmlElement parent, String localName) {
  final el = _findChild(parent, localName);
  if (el == null) return null;
  final text = el.innerText;
  return text.isEmpty ? null : text;
}

/// Extension on [Tr64Client] to access the X_VoIP service.
extension VoIPClientExtension on Tr64Client {
  /// Create a [VoIPService] for managing VoIP telephony.
  ///
  /// Requires [Tr64Client.connect] to have been called first.
  VoIPService? voip() {
    if (description == null) return null;
    final desc = description!.findByType(
      'urn:dslforum-org:service:X_VoIP:1',
    );
    if (desc == null) return null;
    return VoIPService(
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
