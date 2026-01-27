import '../client.dart';
import '../service.dart';

/// Whether a smart home device feature is supported.
enum EnabledEnum {
  /// Feature not supported.
  disabled('DISABLED'),

  /// Feature supported.
  enabled('ENABLED'),

  /// Feature undefined.
  undefined('UNDEFINED');

  final String _value;
  const EnabledEnum(this._value);

  /// Parse an enabled string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static EnabledEnum? tryParse(String value) {
    for (final e in values) {
      if (e._value == value) return e;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// Connection status of a smart home device.
enum PresentEnum {
  /// Device is disconnected.
  disconnected('DISCONNECTED'),

  /// Device is registered.
  registered('REGISTERED'),

  /// Device is connected.
  connected('CONNECTED'),

  /// Unknown status.
  unknown('UNKNOWN');

  final String _value;
  const PresentEnum(this._value);

  /// Parse a present string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static PresentEnum? tryParse(String value) {
    for (final p in values) {
      if (p._value == value) return p;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// Switch timer control mode.
enum SwModeEnum {
  /// Automatic timer.
  auto('AUTO'),

  /// Manual timer.
  manual('MANUAL'),

  /// Undefined timer.
  undefined('UNDEFINED');

  final String _value;
  const SwModeEnum(this._value);

  /// Parse a switch mode string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static SwModeEnum? tryParse(String value) {
    for (final m in values) {
      if (m._value == value) return m;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// Switch state.
enum SwStateEnum {
  /// Switch off.
  off('OFF'),

  /// Switch on.
  on_('ON'),

  /// Toggle switch state.
  toggle('TOGGLE'),

  /// Undefined.
  undefined('UNDEFINED');

  final String _value;
  const SwStateEnum(this._value);

  /// Parse a switch state string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static SwStateEnum? tryParse(String value) {
    for (final s in values) {
      if (s._value == value) return s;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// Whether a smart home value is valid.
enum ValidEnum {
  /// Invalid value.
  invalid('INVALID'),

  /// Valid value.
  valid('VALID'),

  /// Undefined value.
  undefined('UNDEFINED');

  final String _value;
  const ValidEnum(this._value);

  /// Parse a valid string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static ValidEnum? tryParse(String value) {
    for (final v in values) {
      if (v._value == value) return v;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// Radiator valve status.
enum VentilEnum {
  /// Valve closed.
  closed('CLOSED'),

  /// Valve opened.
  open('OPEN'),

  /// Valve temperature controlled.
  temp('TEMP');

  final String _value;
  const VentilEnum(this._value);

  /// Parse a valve status string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static VentilEnum? tryParse(String value) {
    for (final v in values) {
      if (v._value == value) return v;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// Result of X_AVM-DE_Homeauto:GetInfo action.
///
/// Contains allowed characters and length constraints for AIN and
/// DeviceName parameters.
class HomeautoInfo {
  /// Allowed characters for the AIN parameter.
  final String allowedCharsAIN;

  /// Maximum number of characters for AIN.
  final int maxCharsAIN;

  /// Minimum number of characters for AIN.
  final int minCharsAIN;

  /// Maximum number of characters for DeviceName.
  final int maxCharsDeviceName;

  /// Minimum number of characters for DeviceName.
  final int minCharsDeviceName;

  HomeautoInfo({
    required this.allowedCharsAIN,
    required this.maxCharsAIN,
    required this.minCharsAIN,
    required this.maxCharsDeviceName,
    required this.minCharsDeviceName,
  });

  factory HomeautoInfo.fromArguments(Map<String, String> args) {
    return HomeautoInfo(
      allowedCharsAIN: args['NewAllowedCharsAIN'] ?? '',
      maxCharsAIN: int.tryParse(args['NewMaxCharsAIN'] ?? '') ?? 0,
      minCharsAIN: int.tryParse(args['NewMinCharsAIN'] ?? '') ?? 0,
      maxCharsDeviceName:
          int.tryParse(args['NewMaxCharsDeviceName'] ?? '') ?? 0,
      minCharsDeviceName:
          int.tryParse(args['NewMinCharsDeviceName'] ?? '') ?? 0,
    );
  }

  @override
  String toString() =>
      'HomeautoInfo(ain=$minCharsAIN-$maxCharsAIN, '
      'name=$minCharsDeviceName-$maxCharsDeviceName)';
}

/// Result of GetGenericDeviceInfos / GetSpecificDeviceInfos actions.
///
/// Contains device identification, sensor readings, switch state, and
/// radiator valve (HKR) information for a smart home device.
class HomeautoDeviceInfo {
  /// Device identifier (AIN).
  final String ain;

  /// Device ID.
  final int deviceId;

  /// Device function bitmask.
  final int functionBitMask;

  /// Firmware version.
  final String firmwareVersion;

  /// Manufacturer information.
  final String manufacturer;

  /// Product name (e.g. "FRITZ!DECT 200", "Group", "Template").
  final String productName;

  /// Device name.
  final String deviceName;

  /// Connection status.
  final PresentEnum? present;

  /// Whether the multimeter feature is supported.
  final EnabledEnum? multimeterIsEnabled;

  /// Whether the multimeter value is valid.
  final ValidEnum? multimeterIsValid;

  /// Power value in 1/100 W.
  final int multimeterPower;

  /// Energy value in Wh.
  final int multimeterEnergy;

  /// Whether the temperature feature is supported.
  final EnabledEnum? temperatureIsEnabled;

  /// Whether the temperature value is valid.
  final ValidEnum? temperatureIsValid;

  /// Temperature in 1/10 °C.
  final int temperatureCelsius;

  /// Temperature offset in 1/10 °C.
  final int temperatureOffset;

  /// Whether the switch feature is supported.
  final EnabledEnum? switchIsEnabled;

  /// Whether the switch value is valid.
  final ValidEnum? switchIsValid;

  /// Switch status.
  final SwStateEnum? switchState;

  /// Switch timer control mode.
  final SwModeEnum? switchMode;

  /// Whether the switch keylock is active.
  final bool switchLock;

  /// Whether the HKR (radiator) feature is supported.
  final EnabledEnum? hkrIsEnabled;

  /// Whether HKR values are valid.
  final ValidEnum? hkrIsValid;

  /// HKR current temperature in 1/10 °C.
  final int hkrIsTemperature;

  /// HKR set valve status.
  final VentilEnum? hkrSetVentilStatus;

  /// HKR set temperature in 1/10 °C.
  final int hkrSetTemperature;

  /// HKR reduce valve status.
  final VentilEnum? hkrReduceVentilStatus;

  /// HKR reduce temperature in 1/10 °C.
  final int hkrReduceTemperature;

  /// HKR comfort valve status.
  final VentilEnum? hkrComfortVentilStatus;

  /// HKR comfort temperature in 1/10 °C.
  final int hkrComfortTemperature;

  HomeautoDeviceInfo({
    required this.ain,
    required this.deviceId,
    required this.functionBitMask,
    required this.firmwareVersion,
    required this.manufacturer,
    required this.productName,
    required this.deviceName,
    required this.present,
    required this.multimeterIsEnabled,
    required this.multimeterIsValid,
    required this.multimeterPower,
    required this.multimeterEnergy,
    required this.temperatureIsEnabled,
    required this.temperatureIsValid,
    required this.temperatureCelsius,
    required this.temperatureOffset,
    required this.switchIsEnabled,
    required this.switchIsValid,
    required this.switchState,
    required this.switchMode,
    required this.switchLock,
    required this.hkrIsEnabled,
    required this.hkrIsValid,
    required this.hkrIsTemperature,
    required this.hkrSetVentilStatus,
    required this.hkrSetTemperature,
    required this.hkrReduceVentilStatus,
    required this.hkrReduceTemperature,
    required this.hkrComfortVentilStatus,
    required this.hkrComfortTemperature,
  });

  factory HomeautoDeviceInfo.fromArguments(Map<String, String> args) {
    return HomeautoDeviceInfo(
      ain: args['NewAIN'] ?? '',
      deviceId: int.tryParse(args['NewDeviceId'] ?? '') ?? 0,
      functionBitMask:
          int.tryParse(args['NewFunctionBitMask'] ?? '') ?? 0,
      firmwareVersion: args['NewFirmwareVersion'] ?? '',
      manufacturer: args['NewManufacturer'] ?? '',
      productName: args['NewProductName'] ?? '',
      deviceName: args['NewDeviceName'] ?? '',
      present: PresentEnum.tryParse(args['NewPresent'] ?? ''),
      multimeterIsEnabled:
          EnabledEnum.tryParse(args['NewMultimeterIsEnabled'] ?? ''),
      multimeterIsValid:
          ValidEnum.tryParse(args['NewMultimeterIsValid'] ?? ''),
      multimeterPower:
          int.tryParse(args['NewMultimeterPower'] ?? '') ?? 0,
      multimeterEnergy:
          int.tryParse(args['NewMultimeterEnergy'] ?? '') ?? 0,
      temperatureIsEnabled:
          EnabledEnum.tryParse(args['NewTemperatureIsEnabled'] ?? ''),
      temperatureIsValid:
          ValidEnum.tryParse(args['NewTemperatureIsValid'] ?? ''),
      temperatureCelsius:
          int.tryParse(args['NewTemperatureCelsius'] ?? '') ?? 0,
      temperatureOffset:
          int.tryParse(args['NewTemperatureOffset'] ?? '') ?? 0,
      switchIsEnabled:
          EnabledEnum.tryParse(args['NewSwitchIsEnabled'] ?? ''),
      switchIsValid:
          ValidEnum.tryParse(args['NewSwitchIsValid'] ?? ''),
      switchState:
          SwStateEnum.tryParse(args['NewSwitchState'] ?? ''),
      switchMode:
          SwModeEnum.tryParse(args['NewSwitchMode'] ?? ''),
      switchLock: args['NewSwitchLock'] == '1',
      hkrIsEnabled:
          EnabledEnum.tryParse(args['NewHkrIsEnabled'] ?? ''),
      hkrIsValid:
          ValidEnum.tryParse(args['NewHkrIsValid'] ?? ''),
      hkrIsTemperature:
          int.tryParse(args['NewHkrIsTemperature'] ?? '') ?? 0,
      hkrSetVentilStatus:
          VentilEnum.tryParse(args['NewHkrSetVentilStatus'] ?? ''),
      hkrSetTemperature:
          int.tryParse(args['NewHkrSetTemperature'] ?? '') ?? 0,
      hkrReduceVentilStatus:
          VentilEnum.tryParse(args['NewHkrReduceVentilStatus'] ?? ''),
      hkrReduceTemperature:
          int.tryParse(args['NewHkrReduceTemperature'] ?? '') ?? 0,
      hkrComfortVentilStatus:
          VentilEnum.tryParse(args['NewHkrComfortVentilStatus'] ?? ''),
      hkrComfortTemperature:
          int.tryParse(args['NewHkrComfortTemperature'] ?? '') ?? 0,
    );
  }

  @override
  String toString() =>
      'HomeautoDeviceInfo(ain=$ain, name=$deviceName, '
      'product=$productName)';
}

/// TR-064 X_AVM-DE_Homeauto service.
///
/// Service type: urn:dslforum-org:service:X_AVM-DE_Homeauto:1
class HomeautoService extends Tr64Service {
  HomeautoService({
    required super.description,
    required super.callAction,
    required super.fetchUrl,
  });

  /// Get parameter constraints for AIN and DeviceName.
  Future<HomeautoInfo> getInfo() async {
    final result = await call('GetInfo');
    return HomeautoInfo.fromArguments(result);
  }

  /// Get device information by index.
  Future<HomeautoDeviceInfo> getGenericDeviceInfos(int index) async {
    final result = await call('GetGenericDeviceInfos', {
      'NewIndex': index.toString(),
    });
    return HomeautoDeviceInfo.fromArguments(result);
  }

  /// Get device information by AIN (device identifier).
  Future<HomeautoDeviceInfo> getSpecificDeviceInfos(String ain) async {
    final result = await call('GetSpecificDeviceInfos', {
      'NewAIN': ain,
    });
    return HomeautoDeviceInfo.fromArguments(result);
  }

  /// Set the name of a smart home device.
  Future<void> setDeviceName({
    required String ain,
    required String deviceName,
  }) async {
    await call('SetDeviceName', {
      'NewAIN': ain,
      'NewDeviceName': deviceName,
    });
  }

  /// Set the switch state of a smart home socket.
  Future<void> setSwitch({
    required String ain,
    required SwStateEnum switchState,
  }) async {
    await call('SetSwitch', {
      'NewAIN': ain,
      'NewSwitchState': switchState.toString(),
    });
  }
}

/// Extension on [Tr64Client] to access the X_AVM-DE_Homeauto service.
extension HomeautoClientExtension on Tr64Client {
  /// Create a [HomeautoService] for smart home device control.
  ///
  /// Requires [Tr64Client.connect] to have been called first.
  HomeautoService? homeauto() {
    if (description == null) return null;
    final desc = description!.findByType(
      'urn:dslforum-org:service:X_AVM-DE_Homeauto:1',
    );
    if (desc == null) return null;
    return HomeautoService(
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
