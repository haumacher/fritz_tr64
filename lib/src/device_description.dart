import 'package:xml/xml.dart';

/// A TR-064 service descriptor from the device description XML.
class ServiceDescription {
  final String serviceType;
  final String serviceId;
  final String controlUrl;
  final String scpdUrl;

  ServiceDescription({
    required this.serviceType,
    required this.serviceId,
    required this.controlUrl,
    required this.scpdUrl,
  });

  @override
  String toString() => 'ServiceDescription($serviceType, $controlUrl)';
}

/// A device node in the TR-064 device tree.
class DeviceNode {
  final String deviceType;
  final String friendlyName;
  final List<ServiceDescription> services;
  final List<DeviceNode> subDevices;

  DeviceNode({
    required this.deviceType,
    required this.friendlyName,
    required this.services,
    required this.subDevices,
  });

  @override
  String toString() => 'DeviceNode($friendlyName, '
      '${services.length} services, '
      '${subDevices.length} sub-devices)';
}

/// Parsed device description from tr64desc.xml.
class DeviceDescription {
  final DeviceNode rootDevice;

  /// Flat map of all services keyed by serviceType.
  final Map<String, ServiceDescription> servicesByType;

  /// Flat map of all services keyed by serviceId.
  final Map<String, ServiceDescription> servicesById;

  DeviceDescription._({
    required this.rootDevice,
    required this.servicesByType,
    required this.servicesById,
  });

  /// Parse a tr64desc.xml document.
  factory DeviceDescription.parse(String xml) {
    final document = XmlDocument.parse(xml);
    final root = document.rootElement;

    // The root element is <root>, containing a <device> element
    final deviceElement = _findElement(root, 'device');
    if (deviceElement == null) {
      throw FormatException('No <device> element found in description XML');
    }

    final servicesByType = <String, ServiceDescription>{};
    final servicesById = <String, ServiceDescription>{};

    final rootDevice =
        _parseDevice(deviceElement, servicesByType, servicesById);

    return DeviceDescription._(
      rootDevice: rootDevice,
      servicesByType: servicesByType,
      servicesById: servicesById,
    );
  }

  /// Look up a service by its type URI.
  ServiceDescription? findByType(String serviceType) =>
      servicesByType[serviceType];

  /// Look up a service by its ID.
  ServiceDescription? findById(String serviceId) =>
      servicesById[serviceId];

  /// Get all discovered services.
  Iterable<ServiceDescription> get allServices => servicesByType.values;
}

DeviceNode _parseDevice(
  XmlElement element,
  Map<String, ServiceDescription> servicesByType,
  Map<String, ServiceDescription> servicesById,
) {
  final deviceType = _getElementText(element, 'deviceType') ?? '';
  final friendlyName = _getElementText(element, 'friendlyName') ?? '';

  // Parse services
  final services = <ServiceDescription>[];
  final serviceListElement = _findElement(element, 'serviceList');
  if (serviceListElement != null) {
    for (final serviceElement
        in serviceListElement.childElements.where((e) => e.localName == 'service')) {
      final service = _parseService(serviceElement);
      services.add(service);
      servicesByType[service.serviceType] = service;
      servicesById[service.serviceId] = service;
    }
  }

  // Parse sub-devices
  final subDevices = <DeviceNode>[];
  final deviceListElement = _findElement(element, 'deviceList');
  if (deviceListElement != null) {
    for (final subDeviceElement
        in deviceListElement.childElements.where((e) => e.localName == 'device')) {
      subDevices.add(
          _parseDevice(subDeviceElement, servicesByType, servicesById));
    }
  }

  return DeviceNode(
    deviceType: deviceType,
    friendlyName: friendlyName,
    services: services,
    subDevices: subDevices,
  );
}

ServiceDescription _parseService(XmlElement element) {
  return ServiceDescription(
    serviceType: _getElementText(element, 'serviceType') ?? '',
    serviceId: _getElementText(element, 'serviceId') ?? '',
    controlUrl: _getElementText(element, 'controlURL') ?? '',
    scpdUrl: _getElementText(element, 'SCPDURL') ?? '',
  );
}

/// Find a direct child element by local name (namespace-agnostic).
XmlElement? _findElement(XmlElement parent, String localName) {
  for (final child in parent.childElements) {
    if (child.localName == localName) return child;
  }
  return null;
}

/// Get the text content of a direct child element.
String? _getElementText(XmlElement parent, String localName) {
  final element = _findElement(parent, localName);
  if (element == null) return null;
  final text = element.innerText;
  return text.isEmpty ? null : text;
}
