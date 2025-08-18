import 'dart:async';
import 'dart:io';

import '../lib/commands.dart';
import '../lib/consts.dart';

Future<void> main(List<String> appArgs) async {
  if (appArgs.isEmpty) {
    print(_usageMessage);
    exit(Constants.Success);
  }

  final String command = appArgs[0];
  final List<String> args = appArgs.sublist(1);

  switch (command) {
    case 'settings':
      await settings(args);
      exit(Constants.Success);

    case 'ls':
      await ls(args);
      break;

    // case 'search':
    //   search(args);
    //   break;

    // case 'text':
    //   text(args);
    //   break;

    // case 'file':
    //   file(args);
    //   break;

    // case 'paste':
    //   paste(args);
    //   break;

    // case 'delete':
    //   delete(args);
    //   break;

    case 'raw':
      await raw(args);
      exit(Constants.Success);

    default:
      stderr.writeln("Unknown command.");
      stderr.writeln(_usageMessage);
      exit(Constants.UserError);
  }
}

String _usageMessage = '''
Usage: clip <command> [args...]
Available commands (not all are implemented):
  settings <key> <value>   Change setting <key> to <value>
  settings list            Print current settings
  ls                       List all stored items
  search <prefix>          Search items by id/name prefix
  text [content]          Create text with content from arg or stdin
  file <path>              Upload file at path
  paste <prefix> [dir]     Fetch an item by id/name prefix
  delete <id_prefix>...    Delete item(s) by id prefix
  raw "<query>"            Send SQL, print JSON
''';
