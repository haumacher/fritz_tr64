import '../client.dart';
import '../service.dart';

/// Result of DeviceInfo:GetInfo action.
class DeviceInfo {
  final String manufacturer;
  final String manufacturerOui;
  final String modelName;
  final String description;
  final String productClass;
  final String serialNumber;
  final String softwareVersion;
  final String hardwareVersion;
  final String specVersion;
  final String provisioningCode;
  final int upTime;
  final String deviceLog;

  DeviceInfo({
    required this.manufacturer,
    required this.manufacturerOui,
    required this.modelName,
    required this.description,
    required this.productClass,
    required this.serialNumber,
    required this.softwareVersion,
    required this.hardwareVersion,
    required this.specVersion,
    required this.provisioningCode,
    required this.upTime,
    required this.deviceLog,
  });

  factory DeviceInfo.fromArguments(Map<String, String> args) {
    return DeviceInfo(
      manufacturer: args['NewManufacturerName'] ?? '',
      manufacturerOui: args['NewManufacturerOUI'] ?? '',
      modelName: args['NewModelName'] ?? '',
      description: args['NewDescription'] ?? '',
      productClass: args['NewProductClass'] ?? '',
      serialNumber: args['NewSerialNumber'] ?? '',
      softwareVersion: args['NewSoftwareVersion'] ?? '',
      hardwareVersion: args['NewHardwareVersion'] ?? '',
      specVersion: args['NewSpecVersion'] ?? '',
      provisioningCode: args['NewProvisioningCode'] ?? '',
      upTime: int.tryParse(args['NewUpTime'] ?? '') ?? 0,
      deviceLog: args['NewDeviceLog'] ?? '',
    );
  }

  @override
  String toString() => 'DeviceInfo($modelName, $softwareVersion)';
}

/// TR-064 DeviceInfo service.
///
/// Service type: urn:dslforum-org:service:DeviceInfo:1
class DeviceInfoService extends Tr64Service {
  DeviceInfoService({
    required super.description,
    required super.callAction,
    required super.fetchUrl,
  });

  /// Get device information.
  Future<DeviceInfo> getInfo() async {
    final result = await call('GetInfo');
    return DeviceInfo.fromArguments(result);
  }

  /// Get the HTTPS security port.
  Future<int> getSecurityPort() async {
    final result = await call('GetSecurityPort');
    return int.parse(result['NewSecurityPort'] ?? '0');
  }

  /// Get the device log.
  Future<String> getDeviceLog() async {
    final result = await call('GetDeviceLog');
    return result['NewDeviceLog'] ?? '';
  }
}

/// Extension on [Tr64Client] to access the DeviceInfo service.
extension DeviceInfoClientExtension on Tr64Client {
  /// Create a [DeviceInfoService] for querying device information.
  ///
  /// Requires [Tr64Client.connect] to have been called first.
  DeviceInfoService? deviceInfo() {
    if (description == null) return null;
    final desc = description!.findByType(
      'urn:dslforum-org:service:DeviceInfo:1',
    );
    if (desc == null) return null;
    return DeviceInfoService(
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
