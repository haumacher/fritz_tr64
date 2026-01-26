import 'package:flutter_tr64/flutter_tr64.dart';

void main() async {
  // Create a client for your Fritz!Box
  final client = Tr64Client(
    host: '192.168.178.1',
    username: 'admin',
    password: 'your-password',
  );

  try {
    // Connect: fetches and parses the device description
    await client.connect();

    print('Connected! Found ${client.description!.allServices.length} services.');

    // Use the DeviceInfo service
    final deviceInfo = client.deviceInfo();
    if (deviceInfo != null) {
      final info = await deviceInfo.getInfo();
      print('Model: ${info.modelName}');
      print('Software: ${info.softwareVersion}');
      print('Serial: ${info.serialNumber}');
      print('Uptime: ${info.upTime} seconds');
    }

    // Or call any service action generically
    final result = await client.call(
      serviceType: 'urn:dslforum-org:service:DeviceInfo:1',
      controlUrl: '/upnp/control/deviceinfo',
      actionName: 'GetSecurityPort',
    );
    print('Security port: ${result['NewSecurityPort']}');
  } finally {
    client.close();
  }
}
