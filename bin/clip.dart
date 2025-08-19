import 'dart:async';
import 'dart:io';

import '../lib/commands.dart';

Future<Never> main(List<String> appArgs) async {
  if (appArgs.isEmpty) {
    print(_usageMessage);
    exit(0);
  }

  final String command = appArgs[0];
  final List<String> args = appArgs.sublist(1);

  switch (command) {
    case 'settings':
      await settings(args);
      exit(0);

    case 'ls':
      await ls(args);
      exit(0);

    case 'search':
      await search(args);
      exit(0);

    case 'text':
      await text(args);
      exit(0);

    // case 'file':
    //   file(args);
    //   exit(0);

    // case 'paste':
    //   paste(args);
    //   exit(0);

    case 'delete':
      await delete(args);
      exit(0);

    case 'raw':
      await raw(args);
      exit(0);

    default:
      stderr.writeln("Unknown command.");
      stderr.writeln(_usageMessage);
      exit(1);
  }
}

String _usageMessage = '''
Usage: clip <command> [args...]
Available commands (not all are implemented):
  settings <key> <value>   Change setting <key> to <value>
  settings list            Print current settings
  ls                       List all stored items
  search <prefix>          Search items by id/name prefix
  text [content]           Create text with content from arg or stdin
  file <path>              Upload file at path
  paste <prefix> [dir]     Fetch an item by id/name prefix
  delete <prefix>          Delete item(s) with id/name starting with prefix
  raw "<query>"            Send SQL, print JSON
''';
