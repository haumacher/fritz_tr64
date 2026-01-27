import 'package:fritz_tr064/fritz_tr064.dart';

import 'config.dart';

void main() async {
  final client = await createClient();

  try {
    final homeauto = client.homeauto();
    if (homeauto == null) {
      print('X_AVM-DE_Homeauto service not available on this device.');
      return;
    }

    // Parameter constraints
    print('Parameter constraints:');
    final info = await homeauto.getInfo();
    print('  AIN:        ${info.minCharsAIN}-${info.maxCharsAIN} chars '
        '(allowed: ${info.allowedCharsAIN})');
    print('  DeviceName: ${info.minCharsDeviceName}-'
        '${info.maxCharsDeviceName} chars');

    // Enumerate devices by index
    print('\nSmart home devices:');
    for (var i = 0;; i++) {
      final HomeautoDeviceInfo device;
      try {
        device = await homeauto.getGenericDeviceInfos(i);
      } on SoapFaultException {
        break; // no more devices
      }

      print('  [$i] ${device.deviceName} (${device.productName})');
      print('      AIN:           ${device.ain}');
      print('      Device ID:     ${device.deviceId}');
      print('      Firmware:      ${device.firmwareVersion}');
      print('      Manufacturer:  ${device.manufacturer}');
      print('      Present:       ${device.present ?? '(none)'}');

      // Temperature sensor
      if (device.temperatureIsEnabled == EnabledEnum.enabled) {
        print('      Temperature:   '
            '${device.temperatureCelsius / 10} °C '
            '(offset ${device.temperatureOffset / 10} °C, '
            '${device.temperatureIsValid ?? '?'})');
      }

      // Multimeter (power/energy)
      if (device.multimeterIsEnabled == EnabledEnum.enabled) {
        print('      Power:         '
            '${device.multimeterPower / 100} W '
            '(${device.multimeterIsValid ?? '?'})');
        print('      Energy:        ${device.multimeterEnergy} Wh');
      }

      // Switch
      if (device.switchIsEnabled == EnabledEnum.enabled) {
        print('      Switch:        '
            '${device.switchState ?? '?'} '
            '(mode ${device.switchMode ?? '?'}, '
            'lock ${device.switchLock}, '
            '${device.switchIsValid ?? '?'})');
      }

      // HKR (radiator valve)
      if (device.hkrIsEnabled == EnabledEnum.enabled) {
        print('      HKR temp:      '
            '${device.hkrIsTemperature / 10} °C '
            '(${device.hkrIsValid ?? '?'})');
        print('      HKR set:       '
            '${device.hkrSetTemperature / 10} °C '
            '(${device.hkrSetVentilStatus ?? '?'})');
        print('      HKR comfort:   '
            '${device.hkrComfortTemperature / 10} °C '
            '(${device.hkrComfortVentilStatus ?? '?'})');
        print('      HKR reduce:    '
            '${device.hkrReduceTemperature / 10} °C '
            '(${device.hkrReduceVentilStatus ?? '?'})');
      }
    }
  } finally {
    client.close();
  }
}
