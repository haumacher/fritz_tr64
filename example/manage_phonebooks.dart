import 'dart:io';

import 'package:fritz_tr064/fritz_tr064.dart';

import 'config.dart';

void printUsage() {
  stderr.writeln('Usage: dart run example/manage_phonebooks.dart <action> [args...]');
  stderr.writeln();
  stderr.writeln('Actions:');
  stderr.writeln('  GetPhonebookList');
  stderr.writeln('  GetPhonebook NewPhonebookID=<id>');
  stderr.writeln('  AddPhonebook NewPhonebookName=<name> [NewPhonebookExtraID=<id>]');
  stderr.writeln('  DeletePhonebook NewPhonebookID=<id> [NewPhonebookExtraID=<id>]');
  stderr.writeln('  GetNumberOfEntries');
  stderr.writeln('  GetInfoByIndex NewIndex=<index>');
  stderr.writeln('  SetEnableByIndex NewIndex=<index> NewEnable=<true|false>');
  stderr.writeln('  SetConfigByIndex NewIndex=<index> NewEnable=<true|false> NewUrl=<url>');
  stderr.writeln('                   NewServiceId=<id> NewUsername=<user> NewPassword=<pass>');
  stderr.writeln('                   NewName=<name>');
  stderr.writeln('  DeleteByIndex NewIndex=<index>');
  stderr.writeln();
  stderr.writeln('Examples:');
  stderr.writeln('  dart run example/manage_phonebooks.dart GetPhonebookList');
  stderr.writeln('  dart run example/manage_phonebooks.dart GetPhonebook NewPhonebookID=0');
  stderr.writeln('  dart run example/manage_phonebooks.dart SetEnableByIndex NewIndex=1 NewEnable=true');
}

Map<String, String> parseArgs(List<String> args) {
  final result = <String, String>{};
  for (final arg in args) {
    final idx = arg.indexOf('=');
    if (idx < 0) {
      stderr.writeln('Invalid argument: $arg (expected Key=Value)');
      exit(1);
    }
    final key = arg.substring(0, idx);
    final value = arg.substring(idx + 1);
    result[key] = value;
  }
  return result;
}

String require(Map<String, String> args, String key) {
  final value = args[key];
  if (value == null) {
    stderr.writeln('Missing required argument: $key');
    exit(1);
  }
  return value;
}

bool parseBool(String value) {
  if (value == 'true' || value == '1') return true;
  if (value == 'false' || value == '0') return false;
  stderr.writeln('Invalid boolean: $value (expected true/false or 1/0)');
  exit(1);
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    printUsage();
    exit(1);
  }

  final action = arguments[0];
  final args = parseArgs(arguments.skip(1).toList());

  final client = await createClient();

  try {
    final onTel = client.onTel();
    if (onTel == null) {
      stderr.writeln('OnTel service not available on this device.');
      exit(1);
    }

    switch (action) {
      case 'GetPhonebookList':
        final ids = await onTel.getPhonebookList();
        print('Phonebook IDs: ${ids.join(', ')}');

      case 'GetPhonebook':
        final id = int.parse(require(args, 'NewPhonebookID'));
        final pb = await onTel.getPhonebook(id);
        print('Name: ${pb.name}');
        print('URL: ${pb.url}');
        print('ExtraID: ${pb.extraId}');

      case 'AddPhonebook':
        final name = require(args, 'NewPhonebookName');
        final extraId = args['NewPhonebookExtraID'] ?? '';
        await onTel.addPhonebook(name, extraId: extraId);
        print('Phonebook "$name" added.');

      case 'DeletePhonebook':
        final id = int.parse(require(args, 'NewPhonebookID'));
        final extraId = args['NewPhonebookExtraID'] ?? '';
        await onTel.deletePhonebook(id, extraId: extraId);
        print('Phonebook $id deleted.');

      case 'GetNumberOfEntries':
        final count = await onTel.getNumberOfEntries();
        print('Total entries: $count');

      case 'GetInfoByIndex':
        final index = int.parse(require(args, 'NewIndex'));
        final info = await onTel.getInfoByIndex(index);
        print('Enable: ${info.enable}');
        print('Status: ${info.status}');
        print('LastConnect: ${info.lastConnect}');
        print('URL: ${info.url}');
        print('ServiceId: ${info.serviceId}');
        print('Username: ${info.username}');
        print('Name: ${info.name}');

      case 'SetEnableByIndex':
        final index = int.parse(require(args, 'NewIndex'));
        final enable = parseBool(require(args, 'NewEnable'));
        await onTel.setEnableByIndex(index, enable);
        print('Enabled set to $enable for index $index.');

      case 'SetConfigByIndex':
        final index = int.parse(require(args, 'NewIndex'));
        final enable = parseBool(require(args, 'NewEnable'));
        final url = require(args, 'NewUrl');
        final serviceId = require(args, 'NewServiceId');
        final username = require(args, 'NewUsername');
        final password = require(args, 'NewPassword');
        final name = require(args, 'NewName');
        await onTel.setConfigByIndex(
          index: index,
          enable: enable,
          url: url,
          serviceId: serviceId,
          username: username,
          password: password,
          name: name,
        );
        print('Config set for index $index.');

      case 'DeleteByIndex':
        final index = int.parse(require(args, 'NewIndex'));
        await onTel.deleteByIndex(index);
        print('Index $index deleted.');

      default:
        stderr.writeln('Unknown action: $action');
        printUsage();
        exit(1);
    }
  } on SoapFaultException catch (e) {
    stderr.writeln('SOAP error ${e.faultCode}: ${e.faultString}');
    exit(1);
  } finally {
    client.close();
  }
}
