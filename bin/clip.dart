import 'dart:async';
import 'dart:io';

import '../lib/commands.dart';

Future<void> main(List<String> appArgs) async {
  if (appArgs.isEmpty) {
    print('Usage: clip <command> [options]...');
    print('');
    print('Available commands (to be implemented):');
    print('  settings <key> <value>     Change setting <key> to <value>');
    print('  settings list              Print current settings');
    print('  ls                         List all stored items');
    print('  search {id|name} <prefix>  Search items by id or name prefix');
    print('  text [content]             Create text item with content');
    print('  file <path>                Create file item with path');
    print('  paste <id_prefix> [dir]    Fetch item by id prefix');
    print('  delete <id_prefix>...      Delete item(s) by id prefix');
    print('  raw "<query>"              Send SQL, print JSON');
    print('');
    exit(1);
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
      print('Available:');
      print('  settings <key> <value>     Change setting <key> to <value>');
      print('  settings list               Print current settings');
      print('  ls                         List all stored items');
      print('  search {id|name} <prefix>  Search items by id or name prefix');
      print('  text [content]             Create text item with content');
      print('  file <path>                Create file item with path');
      print('  paste <id_prefix> [dir]    Fetch item by id prefix');
      print('  delete <id_prefix>...      Delete item(s) by id prefix');
      print('  raw <query>                Send raw SQL query to server');
      print('');
      exit(1);
  }
}
