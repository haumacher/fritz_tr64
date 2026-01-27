import '../client.dart';
import '../service.dart';

/// Firmware update result for a HomePlug device.
enum UpdateSuccessful {
  /// Update result unknown.
  unknown('unknown'),

  /// Update failed.
  failed('failed'),

  /// Update succeeded.
  succeeded('succeeded');

  final String _value;
  const UpdateSuccessful(this._value);

  /// Parse an update-successful string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static UpdateSuccessful? tryParse(String value) {
    for (final u in values) {
      if (u._value == value) return u;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// Result of GetGenericDeviceEntry / GetSpecificDeviceEntry actions.
///
/// Contains identification, status, and firmware update information
/// for a HomePlug (powerline) device.
class HomePlugDeviceEntry {
  /// MAC address of the device.
  final String macAddress;

  /// Whether the device is currently active.
  final bool active;

  /// Device name.
  final String name;

  /// Device model.
  final String model;

  /// Whether a firmware update is available.
  final bool updateAvailable;

  /// Result of the last firmware update.
  final UpdateSuccessful? updateSuccessful;

  HomePlugDeviceEntry({
    required this.macAddress,
    required this.active,
    required this.name,
    required this.model,
    required this.updateAvailable,
    required this.updateSuccessful,
  });

  factory HomePlugDeviceEntry.fromArguments(Map<String, String> args) {
    return HomePlugDeviceEntry(
      macAddress: args['NewMACAddress'] ?? '',
      active: args['NewActive'] == '1',
      name: args['NewName'] ?? '',
      model: args['NewModel'] ?? '',
      updateAvailable: args['NewUpdateAvailable'] == '1',
      updateSuccessful:
          UpdateSuccessful.tryParse(args['NewUpdateSuccessful'] ?? ''),
    );
  }

  @override
  String toString() =>
      'HomePlugDeviceEntry(mac=$macAddress, name=$name, model=$model)';
}

/// TR-064 X_AVM-DE_Homeplug service.
///
/// Service type: urn:dslforum-org:service:X_AVM-DE_Homeplug:1
class HomePlugService extends Tr64Service {
  HomePlugService({
    required super.description,
    required super.callAction,
    required super.fetchUrl,
  });

  /// Get the number of HomePlug device entries.
  Future<int> getNumberOfDeviceEntries() async {
    final result = await call('GetNumberOfDeviceEntries');
    return int.tryParse(result['NewNumberOfEntries'] ?? '') ?? 0;
  }

  /// Get device entry by index.
  Future<HomePlugDeviceEntry> getGenericDeviceEntry(int index) async {
    final result = await call('GetGenericDeviceEntry', {
      'NewIndex': index.toString(),
    });
    return HomePlugDeviceEntry.fromArguments(result);
  }

  /// Get device entry by MAC address.
  Future<HomePlugDeviceEntry> getSpecificDeviceEntry(
      String macAddress) async {
    final result = await call('GetSpecificDeviceEntry', {
      'NewMACAddress': macAddress,
    });
    return HomePlugDeviceEntry.fromArguments({
      ...result,
      'NewMACAddress': macAddress,
    });
  }

  /// Trigger a firmware update for a device.
  Future<void> deviceDoUpdate(String macAddress) async {
    await call('DeviceDoUpdate', {
      'NewMACAddress': macAddress,
    });
  }
}

/// Extension on [Tr64Client] to access the X_AVM-DE_Homeplug service.
extension HomePlugClientExtension on Tr64Client {
  /// Create a [HomePlugService] for powerline device management.
  ///
  /// Requires [Tr64Client.connect] to have been called first.
  HomePlugService? homePlug() {
    if (description == null) return null;
    final desc = description!.findByType(
      'urn:dslforum-org:service:X_AVM-DE_Homeplug:1',
    );
    if (desc == null) return null;
    return HomePlugService(
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
