import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:path/path.dart' as path;

class Item {
  String uuid, type, name, content;
  Item(this.uuid, this.type, this.name, this.content);
  // Item.fromJson();
}

class Settings {
  static Uri? endpoint;
  static String? token;

  static Future<void> read(String filePath) async {
    try {
      final file = File(filePath);
      Map<String, dynamic> jsonData = {};
      bool overwrite = false;

      // Try to read existing file
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          jsonData = jsonDecode(content) as Map<String, dynamic>;
        } catch (e) {
          print('Error parsing settings file: $e');
          jsonData = {};
        }
      }

      // Check for endpoint
      if (!jsonData.containsKey('endpoint') || jsonData['endpoint'] == null) {
        stdout.write('Enter endpoint URL (e.g., https://example.com/api): ');
        final endpointInput = stdin.readLineSync()?.trim();
        if (endpointInput == null || endpointInput.isEmpty) {
          print('Endpoint is required');
          exit(1);
        }
        try {
          endpoint = Uri.parse(endpointInput);
          jsonData['endpoint'] = endpointInput;
          overwrite = true;
        } catch (e) {
          print('Invalid endpoint URL: $e');
          exit(1);
        }
      } else {
        // Endpoint provided
        try {
          endpoint = Uri.parse(jsonData['endpoint'] as String);
        } catch (e) {
          print('Invalid endpoint URL in config: $e');
          stdout.write('Enter endpoint URL (e.g., https://api.example.com): ');
          final endpointInput = stdin.readLineSync()?.trim();
          if (endpointInput == null || endpointInput.isEmpty) {
            print('Endpoint is required');
            exit(1);
          }
          try {
            endpoint = Uri.parse(endpointInput);
            jsonData['endpoint'] = endpointInput;
            overwrite = true;
          } catch (e) {
            print('Invalid endpoint URL: $e');
            exit(1);
          }
        }
      }

      // Check for token
      if (!jsonData.containsKey('token') || jsonData['token'] == null) {
        stdout.write('Enter authentication token: ');
        final tokenInput = stdin.readLineSync()?.trim();
        if (tokenInput == null || tokenInput.isEmpty) {
          print('Token is required');
          exit(1);
        }
        token = tokenInput;
        jsonData['token'] = tokenInput;
        overwrite = true;
      } else {
        // Token provided
        token = jsonData['token'] as String;
      }

      // Save the configuration if it was modified
      if (overwrite) {
        try {
          final parentDir = file.parent;
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }

          final jsonString = JsonEncoder.withIndent('  ').convert(jsonData);
          await file.writeAsString(jsonString);
          print('Settings saved to $filePath');
        } catch (e) {
          print('Error saving settings: $e');
          exit(2);
        }
      }
    } catch (e) {
      print('Error reading settings file: $e');
      exit(2);
    }
  }
}

Future<List> execute(String query) async {
  Response response = Response('', 500);
  try {
    response = await post(Settings.endpoint!,
        headers: {"Authorization": Settings.token!, "Content-Type": "text/plain"},
        body: query);
  } catch (e) {
    stderr.writeln("Connection refused: $e");
    exit(2);
  }

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as List;
  } else {
    print("Request to ${Settings.endpoint} failed: ${response.statusCode}");
    exit(2);
  }
}

void settings(List<String> args) {
  String? key = args.elementAtOrNull(0);
  String? value = args.elementAtOrNull(1);
  if (key == null) {
    print('Usage: clip settings <key> <value>');
    print('"clip settings list" will show current settings');
    exit(1);
  }
  if (value == null) {
    if (key == 'list') {
      // TODO: list of settings
      exit(0);
    } else {
      print('Usage: clip settings <key> <value>');
      print('"clip settings list" will show current settings');
      exit(1);
    }
  }
  // TODO: setting settings in ~/.config/metaclip.json
}

Future<void> raw(List<String> args) async {
  try {
    final items = await execute(args.join(" "));
    items.forEach(print);
  } catch (error) {
    stderr.writeln("Error executing raw command: $error");
    exit(1);
  }
}

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
    print('  raw \'<query>\'            Send raw SQL query to server');
    print('');
    print('Use clip <command> --help for more information on a specific command.');
    exit(1);
  }

  final command = appArgs[0];
  final args = appArgs.sublist(1);

  final homeDir = Platform.environment['HOME'];
  if (homeDir == null) {
    stderr.writeln('HOME environment variable not found');
    exit(1);
  }

  try {
    await Settings.read(path.join(homeDir, '.config', 'metaclip.json'));
  } catch (e) {
    stderr.writeln('Failed to read settings: $e');
    exit(1);
  }

  switch (command) {
    case 'settings':
      settings(args);
      exit(0);

    // case 'ls':
    //   ls(args);
    //   break;

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
