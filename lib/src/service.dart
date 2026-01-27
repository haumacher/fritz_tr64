import 'device_description.dart';

/// Callback type for invoking a SOAP action.
typedef SoapActionCallback = Future<Map<String, String>> Function(
  String serviceType,
  String controlUrl,
  String actionName,
  Map<String, String> arguments,
);

/// Callback type for fetching a URL and returning its body.
typedef FetchUrlCallback = Future<String> Function(String url);

/// Base class for TR-064 service wrappers.
///
/// Subclasses represent specific TR-064 services (e.g. DeviceInfo)
/// and provide typed action methods.
class Tr64Service {
  final ServiceDescription description;

  /// Callback to invoke a SOAP action through the client.
  final SoapActionCallback _callAction;

  /// Callback to fetch a URL through the client's HTTP connection.
  final FetchUrlCallback _fetchUrl;

  Tr64Service({
    required this.description,
    required SoapActionCallback callAction,
    required FetchUrlCallback fetchUrl,
  })  : _callAction = callAction,
        _fetchUrl = fetchUrl;

  String get serviceType => description.serviceType;
  String get controlUrl => description.controlUrl;

  /// Call a SOAP action on this service and return the response arguments.
  Future<Map<String, String>> call(
    String actionName, [
    Map<String, String> arguments = const {},
  ]) {
    return _callAction(serviceType, controlUrl, actionName, arguments);
  }

  /// Fetch a URL and return the response body.
  Future<String> fetchUrl(String url) => _fetchUrl(url);
}
