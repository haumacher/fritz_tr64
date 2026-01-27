import 'package:fritz_tr064/fritz_tr064.dart';

import 'config.dart';

void main() async {
  final client = await createClient();

  try {
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
