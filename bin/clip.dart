import 'dart:async';
import 'dart:io';

import '../lib/commands.dart';

Future<void> main(List<String> appArgs) async {
  if (appArgs.isEmpty) {
    print(_usageMessage);
    exit(0);
  }

  final handler = commands[appArgs[0]];

  if (handler == null) {
    stderr.writeln("Unknown command.");
    stderr.writeln(_usageMessage);
    exit(1);
  }

  // clip delete 52e -> delete([52e])
  await handler(appArgs.sublist(1));
}

const Map<String, Future<void> Function(List<String>)> commands = {
  'settings': settings,
  'ls': ls,
  'search': search,
  'text': text,
  'file': file,
  'paste': paste,
  'delete': delete,
  'purge': purge,
  'raw': raw
};

const String _usageMessage = '''
Usage: clip <command> [args...]
Available commands (not all are implemented):
  settings <key> <value>   Change setting <key> to <value>
  settings ls              Print current settings
  ls                       List all stored items
  search <prefix>          Search items by id/name beginning
  text <name>              Create text with content from stdin
  file <path>              Upload file at relative path
  paste <prefix> [dir]     Paste an item; text to stdout, file to dir
  delete <prefix>          Delete item by id/name beginning
  purge                     Delete all items
  raw "<query>"            Send SQL, print JSON
''';
