/// A Dart library for accessing Fritz!Box routers via the TR-064 protocol.
library;

export 'src/auth.dart' show Tr64Auth, AuthState;
export 'src/client.dart' show Tr64Client;
export 'src/device_description.dart'
    show DeviceDescription, ServiceDescription, DeviceNode;
export 'src/service.dart' show Tr64Service;
export 'src/services/device_info.dart' show DeviceInfoService;
export 'src/soap.dart' show SoapEnvelope, SoapResponse, SoapFaultException;
