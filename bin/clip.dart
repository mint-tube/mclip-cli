import 'dart:async';
import 'dart:io';

import '../lib/commands.dart';

Future<void> main(List<String> appArgs) async {
  if (appArgs.isEmpty) {
    print('Usage: clip <command> [args...]');
    print('');
    print('Available commands (to be implemented):');
    print('  settings <key> <value>   Change setting <key> to <value>');
    print('  settings list            Print current settings');
    print('  ls                       List all stored items');
    print('  search <prefix>          Search items by id/name prefix');
    print('  text [content]           Create text with content from arg or stdin');
    print('  file <path>              Upload file at path');
    print('  paste <prefix> [dir]     Fetch an item by id/name prefix');
    print('  delete <id_prefix>...    Delete item(s) by id prefix');
    print('  raw "<query>"            Send SQL, print JSON');
    print('');
    exit(0);
  }

  final command = appArgs[0];
  final args = appArgs.sublist(1);

  switch (command) {
    case 'settings':
      await settings(args);
      exit(0);

    case 'ls':
      ls(args);
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
      exit(0);

    default:
      stderr.writeln("Unknown command.");
      stderr.writeln('  settings <key> <value>   Change setting <key> to <value>');
      stderr.writeln('  settings list            Print current settings');
      stderr.writeln('  ls                       List all stored items');
      stderr.writeln('  search <prefix>          Search items by id/name prefix');
      stderr.writeln(
          '  text [content]           Create text with content from arg or stdin');
      stderr.writeln('  file <path>              Upload file at path');
      stderr.writeln('  paste <prefix> [dir]     Fetch an item by id/name prefix');
      stderr.writeln('  delete <id_prefix>...    Delete item(s) by id prefix');
      stderr.writeln('  raw "<query>"            Send SQL, print JSON');
      stderr.writeln('');
      exit(1);
  }
}
