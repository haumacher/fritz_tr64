import 'package:flutter_tr64/src/device_description.dart';
import 'package:flutter_tr64/src/services/homeauto.dart';
import 'package:test/test.dart';

ServiceDescription _fakeDescription() {
  return ServiceDescription(
    serviceType: 'urn:dslforum-org:service:X_AVM-DE_Homeauto:1',
    serviceId: 'urn:X_AVM-DE_Homeauto-com:serviceId:X_AVM-DE_Homeauto1',
    controlUrl: '/upnp/control/x_homeauto',
    scpdUrl: '/x_homeautoSCPD.xml',
  );
}

Future<String> _unusedFetchUrl(String url) async => '';

void main() {
  group('EnabledEnum', () {
    test('tryParse returns matching enum value', () {
      expect(EnabledEnum.tryParse('DISABLED'), EnabledEnum.disabled);
      expect(EnabledEnum.tryParse('ENABLED'), EnabledEnum.enabled);
      expect(EnabledEnum.tryParse('UNDEFINED'), EnabledEnum.undefined);
    });

    test('tryParse returns null for unknown or empty', () {
      expect(EnabledEnum.tryParse('unknown'), isNull);
      expect(EnabledEnum.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(EnabledEnum.disabled.toString(), 'DISABLED');
      expect(EnabledEnum.enabled.toString(), 'ENABLED');
      expect(EnabledEnum.undefined.toString(), 'UNDEFINED');
    });
  });

  group('PresentEnum', () {
    test('tryParse returns matching enum value', () {
      expect(PresentEnum.tryParse('DISCONNECTED'), PresentEnum.disconnected);
      expect(PresentEnum.tryParse('REGISTERED'), PresentEnum.registered);
      expect(PresentEnum.tryParse('CONNECTED'), PresentEnum.connected);
      expect(PresentEnum.tryParse('UNKNOWN'), PresentEnum.unknown);
    });

    test('tryParse returns null for unknown or empty', () {
      expect(PresentEnum.tryParse('other'), isNull);
      expect(PresentEnum.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(PresentEnum.disconnected.toString(), 'DISCONNECTED');
      expect(PresentEnum.registered.toString(), 'REGISTERED');
      expect(PresentEnum.connected.toString(), 'CONNECTED');
      expect(PresentEnum.unknown.toString(), 'UNKNOWN');
    });
  });

  group('SwModeEnum', () {
    test('tryParse returns matching enum value', () {
      expect(SwModeEnum.tryParse('AUTO'), SwModeEnum.auto);
      expect(SwModeEnum.tryParse('MANUAL'), SwModeEnum.manual);
      expect(SwModeEnum.tryParse('UNDEFINED'), SwModeEnum.undefined);
    });

    test('tryParse returns null for unknown or empty', () {
      expect(SwModeEnum.tryParse('other'), isNull);
      expect(SwModeEnum.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(SwModeEnum.auto.toString(), 'AUTO');
      expect(SwModeEnum.manual.toString(), 'MANUAL');
      expect(SwModeEnum.undefined.toString(), 'UNDEFINED');
    });
  });

  group('SwStateEnum', () {
    test('tryParse returns matching enum value', () {
      expect(SwStateEnum.tryParse('OFF'), SwStateEnum.off);
      expect(SwStateEnum.tryParse('ON'), SwStateEnum.on_);
      expect(SwStateEnum.tryParse('TOGGLE'), SwStateEnum.toggle);
      expect(SwStateEnum.tryParse('UNDEFINED'), SwStateEnum.undefined);
    });

    test('tryParse returns null for unknown or empty', () {
      expect(SwStateEnum.tryParse('other'), isNull);
      expect(SwStateEnum.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(SwStateEnum.off.toString(), 'OFF');
      expect(SwStateEnum.on_.toString(), 'ON');
      expect(SwStateEnum.toggle.toString(), 'TOGGLE');
      expect(SwStateEnum.undefined.toString(), 'UNDEFINED');
    });
  });

  group('ValidEnum', () {
    test('tryParse returns matching enum value', () {
      expect(ValidEnum.tryParse('INVALID'), ValidEnum.invalid);
      expect(ValidEnum.tryParse('VALID'), ValidEnum.valid);
      expect(ValidEnum.tryParse('UNDEFINED'), ValidEnum.undefined);
    });

    test('tryParse returns null for unknown or empty', () {
      expect(ValidEnum.tryParse('other'), isNull);
      expect(ValidEnum.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(ValidEnum.invalid.toString(), 'INVALID');
      expect(ValidEnum.valid.toString(), 'VALID');
      expect(ValidEnum.undefined.toString(), 'UNDEFINED');
    });
  });

  group('VentilEnum', () {
    test('tryParse returns matching enum value', () {
      expect(VentilEnum.tryParse('CLOSED'), VentilEnum.closed);
      expect(VentilEnum.tryParse('OPEN'), VentilEnum.open);
      expect(VentilEnum.tryParse('TEMP'), VentilEnum.temp);
    });

    test('tryParse returns null for unknown or empty', () {
      expect(VentilEnum.tryParse('other'), isNull);
      expect(VentilEnum.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(VentilEnum.closed.toString(), 'CLOSED');
      expect(VentilEnum.open.toString(), 'OPEN');
      expect(VentilEnum.temp.toString(), 'TEMP');
    });
  });

  group('HomeautoInfo', () {
    test('fromArguments parses all fields', () {
      final info = HomeautoInfo.fromArguments({
        'NewAllowedCharsAIN': '0123456789ABCDEFabcdef :-grptmp',
        'NewMaxCharsAIN': '19',
        'NewMinCharsAIN': '1',
        'NewMaxCharsDeviceName': '79',
        'NewMinCharsDeviceName': '1',
      });

      expect(info.allowedCharsAIN, '0123456789ABCDEFabcdef :-grptmp');
      expect(info.maxCharsAIN, 19);
      expect(info.minCharsAIN, 1);
      expect(info.maxCharsDeviceName, 79);
      expect(info.minCharsDeviceName, 1);
    });

    test('fromArguments defaults for missing keys', () {
      final info = HomeautoInfo.fromArguments({});

      expect(info.allowedCharsAIN, '');
      expect(info.maxCharsAIN, 0);
      expect(info.minCharsAIN, 0);
      expect(info.maxCharsDeviceName, 0);
      expect(info.minCharsDeviceName, 0);
    });

    test('toString includes key fields', () {
      final info = HomeautoInfo(
        allowedCharsAIN: 'abc',
        maxCharsAIN: 19,
        minCharsAIN: 1,
        maxCharsDeviceName: 79,
        minCharsDeviceName: 1,
      );
      expect(info.toString(), 'HomeautoInfo(ain=1-19, name=1-79)');
    });
  });

  group('HomeautoDeviceInfo', () {
    test('fromArguments parses all fields', () {
      final info = HomeautoDeviceInfo.fromArguments({
        'NewAIN': '087610000444',
        'NewDeviceId': '16',
        'NewFunctionBitMask': '2944',
        'NewFirmwareVersion': '04.92',
        'NewManufacturer': 'AVM',
        'NewProductName': 'FRITZ!DECT 200',
        'NewDeviceName': 'Living Room Socket',
        'NewPresent': 'CONNECTED',
        'NewMultimeterIsEnabled': 'ENABLED',
        'NewMultimeterIsValid': 'VALID',
        'NewMultimeterPower': '2350',
        'NewMultimeterEnergy': '12345',
        'NewTemperatureIsEnabled': 'ENABLED',
        'NewTemperatureIsValid': 'VALID',
        'NewTemperatureCelsius': '215',
        'NewTemperatureOffset': '-10',
        'NewSwitchIsEnabled': 'ENABLED',
        'NewSwitchIsValid': 'VALID',
        'NewSwitchState': 'ON',
        'NewSwitchMode': 'AUTO',
        'NewSwitchLock': '1',
        'NewHkrIsEnabled': 'DISABLED',
        'NewHkrIsValid': 'INVALID',
        'NewHkrIsTemperature': '0',
        'NewHkrSetVentilStatus': 'CLOSED',
        'NewHkrSetTemperature': '200',
        'NewHkrReduceVentilStatus': 'TEMP',
        'NewHkrReduceTemperature': '160',
        'NewHkrComfortVentilStatus': 'OPEN',
        'NewHkrComfortTemperature': '220',
      });

      expect(info.ain, '087610000444');
      expect(info.deviceId, 16);
      expect(info.functionBitMask, 2944);
      expect(info.firmwareVersion, '04.92');
      expect(info.manufacturer, 'AVM');
      expect(info.productName, 'FRITZ!DECT 200');
      expect(info.deviceName, 'Living Room Socket');
      expect(info.present, PresentEnum.connected);
      expect(info.multimeterIsEnabled, EnabledEnum.enabled);
      expect(info.multimeterIsValid, ValidEnum.valid);
      expect(info.multimeterPower, 2350);
      expect(info.multimeterEnergy, 12345);
      expect(info.temperatureIsEnabled, EnabledEnum.enabled);
      expect(info.temperatureIsValid, ValidEnum.valid);
      expect(info.temperatureCelsius, 215);
      expect(info.temperatureOffset, -10);
      expect(info.switchIsEnabled, EnabledEnum.enabled);
      expect(info.switchIsValid, ValidEnum.valid);
      expect(info.switchState, SwStateEnum.on_);
      expect(info.switchMode, SwModeEnum.auto);
      expect(info.switchLock, isTrue);
      expect(info.hkrIsEnabled, EnabledEnum.disabled);
      expect(info.hkrIsValid, ValidEnum.invalid);
      expect(info.hkrIsTemperature, 0);
      expect(info.hkrSetVentilStatus, VentilEnum.closed);
      expect(info.hkrSetTemperature, 200);
      expect(info.hkrReduceVentilStatus, VentilEnum.temp);
      expect(info.hkrReduceTemperature, 160);
      expect(info.hkrComfortVentilStatus, VentilEnum.open);
      expect(info.hkrComfortTemperature, 220);
    });

    test('fromArguments defaults for missing keys', () {
      final info = HomeautoDeviceInfo.fromArguments({});

      expect(info.ain, '');
      expect(info.deviceId, 0);
      expect(info.functionBitMask, 0);
      expect(info.firmwareVersion, '');
      expect(info.manufacturer, '');
      expect(info.productName, '');
      expect(info.deviceName, '');
      expect(info.present, isNull);
      expect(info.multimeterIsEnabled, isNull);
      expect(info.multimeterIsValid, isNull);
      expect(info.multimeterPower, 0);
      expect(info.multimeterEnergy, 0);
      expect(info.temperatureIsEnabled, isNull);
      expect(info.temperatureIsValid, isNull);
      expect(info.temperatureCelsius, 0);
      expect(info.temperatureOffset, 0);
      expect(info.switchIsEnabled, isNull);
      expect(info.switchIsValid, isNull);
      expect(info.switchState, isNull);
      expect(info.switchMode, isNull);
      expect(info.switchLock, isFalse);
      expect(info.hkrIsEnabled, isNull);
      expect(info.hkrIsValid, isNull);
      expect(info.hkrIsTemperature, 0);
      expect(info.hkrSetVentilStatus, isNull);
      expect(info.hkrSetTemperature, 0);
      expect(info.hkrReduceVentilStatus, isNull);
      expect(info.hkrReduceTemperature, 0);
      expect(info.hkrComfortVentilStatus, isNull);
      expect(info.hkrComfortTemperature, 0);
    });

    test('toString includes key fields', () {
      final info = HomeautoDeviceInfo.fromArguments({
        'NewAIN': '087610000444',
        'NewDeviceName': 'Living Room',
        'NewProductName': 'FRITZ!DECT 200',
      });
      expect(info.toString(),
          'HomeautoDeviceInfo(ain=087610000444, name=Living Room, '
          'product=FRITZ!DECT 200)');
    });
  });

  group('HomeautoService', () {
    test('getInfo returns parsed HomeautoInfo', () async {
      final service = HomeautoService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetInfo');
          expect(arguments, isEmpty);
          return {
            'NewAllowedCharsAIN': '0123456789ABCDEFabcdef :-grptmp',
            'NewMaxCharsAIN': '19',
            'NewMinCharsAIN': '1',
            'NewMaxCharsDeviceName': '79',
            'NewMinCharsDeviceName': '1',
          };
        },
      );

      final info = await service.getInfo();
      expect(info.allowedCharsAIN, '0123456789ABCDEFabcdef :-grptmp');
      expect(info.maxCharsAIN, 19);
      expect(info.minCharsAIN, 1);
      expect(info.maxCharsDeviceName, 79);
    });

    test('getGenericDeviceInfos sends index and returns parsed info',
        () async {
      final service = HomeautoService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetGenericDeviceInfos');
          expect(arguments['NewIndex'], '0');
          return {
            'NewAIN': '087610000444',
            'NewDeviceId': '16',
            'NewFunctionBitMask': '2944',
            'NewFirmwareVersion': '04.92',
            'NewManufacturer': 'AVM',
            'NewProductName': 'FRITZ!DECT 200',
            'NewDeviceName': 'Living Room Socket',
            'NewPresent': 'CONNECTED',
            'NewMultimeterIsEnabled': 'ENABLED',
            'NewMultimeterIsValid': 'VALID',
            'NewMultimeterPower': '2350',
            'NewMultimeterEnergy': '12345',
            'NewTemperatureIsEnabled': 'ENABLED',
            'NewTemperatureIsValid': 'VALID',
            'NewTemperatureCelsius': '215',
            'NewTemperatureOffset': '0',
            'NewSwitchIsEnabled': 'ENABLED',
            'NewSwitchIsValid': 'VALID',
            'NewSwitchState': 'ON',
            'NewSwitchMode': 'AUTO',
            'NewSwitchLock': '0',
            'NewHkrIsEnabled': 'DISABLED',
            'NewHkrIsValid': 'INVALID',
            'NewHkrIsTemperature': '0',
            'NewHkrSetVentilStatus': 'CLOSED',
            'NewHkrSetTemperature': '0',
            'NewHkrReduceVentilStatus': 'CLOSED',
            'NewHkrReduceTemperature': '0',
            'NewHkrComfortVentilStatus': 'CLOSED',
            'NewHkrComfortTemperature': '0',
          };
        },
      );

      final info = await service.getGenericDeviceInfos(0);
      expect(info.ain, '087610000444');
      expect(info.deviceName, 'Living Room Socket');
      expect(info.productName, 'FRITZ!DECT 200');
      expect(info.present, PresentEnum.connected);
      expect(info.multimeterPower, 2350);
      expect(info.switchState, SwStateEnum.on_);
    });

    test('getSpecificDeviceInfos sends AIN and returns parsed info',
        () async {
      final service = HomeautoService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetSpecificDeviceInfos');
          expect(arguments['NewAIN'], '087610000444');
          return {
            'NewDeviceId': '16',
            'NewFunctionBitMask': '2944',
            'NewFirmwareVersion': '04.92',
            'NewManufacturer': 'AVM',
            'NewProductName': 'FRITZ!DECT 200',
            'NewDeviceName': 'Living Room Socket',
            'NewPresent': 'CONNECTED',
            'NewMultimeterIsEnabled': 'ENABLED',
            'NewMultimeterIsValid': 'VALID',
            'NewMultimeterPower': '2350',
            'NewMultimeterEnergy': '12345',
            'NewTemperatureIsEnabled': 'ENABLED',
            'NewTemperatureIsValid': 'VALID',
            'NewTemperatureCelsius': '215',
            'NewTemperatureOffset': '0',
            'NewSwitchIsEnabled': 'ENABLED',
            'NewSwitchIsValid': 'VALID',
            'NewSwitchState': 'ON',
            'NewSwitchMode': 'MANUAL',
            'NewSwitchLock': '0',
            'NewHkrIsEnabled': 'DISABLED',
            'NewHkrIsValid': 'INVALID',
            'NewHkrIsTemperature': '0',
            'NewHkrSetVentilStatus': 'CLOSED',
            'NewHkrSetTemperature': '0',
            'NewHkrReduceVentilStatus': 'CLOSED',
            'NewHkrReduceTemperature': '0',
            'NewHkrComfortVentilStatus': 'CLOSED',
            'NewHkrComfortTemperature': '0',
          };
        },
      );

      final info = await service.getSpecificDeviceInfos('087610000444');
      expect(info.deviceName, 'Living Room Socket');
      expect(info.switchMode, SwModeEnum.manual);
      expect(info.temperatureCelsius, 215);
    });

    test('setDeviceName sends correct arguments', () async {
      final service = HomeautoService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetDeviceName');
          expect(arguments['NewAIN'], '087610000444');
          expect(arguments['NewDeviceName'], 'Kitchen Socket');
          return {};
        },
      );

      await service.setDeviceName(
        ain: '087610000444',
        deviceName: 'Kitchen Socket',
      );
    });

    test('setSwitch sends correct arguments', () async {
      final service = HomeautoService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetSwitch');
          expect(arguments['NewAIN'], '087610000444');
          expect(arguments['NewSwitchState'], 'ON');
          return {};
        },
      );

      await service.setSwitch(
        ain: '087610000444',
        switchState: SwStateEnum.on_,
      );
    });

    test('setSwitch sends TOGGLE state', () async {
      final service = HomeautoService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(arguments['NewSwitchState'], 'TOGGLE');
          return {};
        },
      );

      await service.setSwitch(
        ain: '087610000444',
        switchState: SwStateEnum.toggle,
      );
    });
  });
}
