import 'device_description.dart';

/// Base class for TR-064 service wrappers.
///
/// Subclasses represent specific TR-064 services (e.g. DeviceInfo)
/// and provide typed action methods.
class Tr64Service {
  final ServiceDescription description;

  /// Callback to invoke a SOAP action through the client.
  /// This is set by the client when creating service instances.
  final Future<Map<String, String>> Function(
    String serviceType,
    String controlUrl,
    String actionName,
    Map<String, String> arguments,
  ) _callAction;

  Tr64Service({
    required this.description,
    required Future<Map<String, String>> Function(
      String serviceType,
      String controlUrl,
      String actionName,
      Map<String, String> arguments,
    ) callAction,
  }) : _callAction = callAction;

  String get serviceType => description.serviceType;
  String get controlUrl => description.controlUrl;

  /// Call a SOAP action on this service and return the response arguments.
  Future<Map<String, String>> call(
    String actionName, [
    Map<String, String> arguments = const {},
  ]) {
    return _callAction(serviceType, controlUrl, actionName, arguments);
  }
}
