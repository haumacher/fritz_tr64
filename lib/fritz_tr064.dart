/// A Dart library for accessing Fritz!Box routers via the TR-064 protocol.
library;

export 'src/auth.dart' show Tr64Auth, AuthState;
export 'src/client.dart' show Tr64Client;
export 'src/device_description.dart'
    show DeviceDescription, ServiceDescription, DeviceNode;
export 'src/service.dart' show Tr64Service;
export 'src/services/app_setup.dart';
export 'src/services/device_info.dart';
export 'src/services/homeauto.dart';
export 'src/services/homeplug.dart';
export 'src/services/my_fritz.dart';
export 'src/services/on_tel.dart';
export 'src/services/remote_access.dart';
export 'src/services/tam.dart';
export 'src/services/voip.dart';
export 'src/services/x_auth.dart';
export 'src/soap.dart' show SoapEnvelope, SoapResponse, SoapFaultException;
