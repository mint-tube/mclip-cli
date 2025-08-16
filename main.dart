import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart';

String valueOrUnset(Map<String, dynamic> map, key) {
  return map.containsKey(key) ? map[key] : "unset";
}

class Settings {
  static Uri? endpoint;
  static String? token;

  static void _validateEndpoint(Uri uri) {
    if (!(['http', 'https'].contains(uri.scheme) &&
        uri.authority.isNotEmpty &&
        uri.port > -2)) {
      // port -1 means no port given
      throw HttpException('');
    }
  }

  static Future<void> read(String filePath) async {
    try {
      final file = File(filePath);
      Map<String, dynamic> jsonData = {};
      List<String> unsetSettings = [];

      // Try to read existing file
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          jsonData = jsonDecode(content) as Map<String, dynamic>;
        } catch (e) {
          stderr.writeln('Error parsing settings file: $e');
          jsonData = {};
        }
      }

      if (!jsonData.containsKey('endpoint')) {
        unsetSettings.add('endpoint');
      } else {
        try {
          endpoint = Uri.parse(jsonData['endpoint'] as String);
          _validateEndpoint(endpoint!);
        } catch (e) {
          stderr.writeln('Invalid API URL: ${jsonData['endpoint']}');
          unsetSettings.add('endpoint');
        }
      }

      if (!jsonData.containsKey('token')) {
        unsetSettings.add('token');
      } else {
        token = jsonData['token'] as String;
      }

      if (unsetSettings.isNotEmpty) {
        stderr.writeln('Update the following settings:');
        for (String setting in unsetSettings) {
          stderr.writeln(' - $setting');
        }
        stderr.writeln("Use 'clip settings <key> <value>'");

        exit(1);
      }
    } catch (e) {
      stderr.writeln('Error reading settings: $e');
      exit(2);
    }
  }
}

Future<List> execute(String query) async {
  Response response = Response('', 500);
  try {
    response = await post(Settings.endpoint!,
            headers: {
              "Authorization": Settings.token!,
              "Content-Type": "text/plain"
            },
            body: query)
        .timeout(const Duration(seconds: 30));
  } on TimeoutException {
    stderr.writeln(
      'Request Timeout: The server took too long to respond.\n'
      'Please try again later.',
    );
    exit(2);
  } on SocketException catch (e) {
    if (e.message.contains('Connection refused')) {
      stderr.writeln(
        'Connection Error: Unable to connect to the API.\n'
        '${Settings.endpoint} appears to be offline or not accepting connections.',
      );
    } else {
      stderr.writeln(
        'Network Error: Unable to connect to the metaclip server.\n'
        'Error details: ${e.message}',
      );
    }
    exit(2);
  } catch (e) {
    stderr.writeln('''
Unexpected Error: An error occurred while communicating with the server.
$e
    ''');
    exit(2);
  }

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as List;
  } else {
    stderr.writeln("Request to ${Settings.endpoint} failed: ${response.statusCode}");
    exit(2);
  }
}

Future<void> settings(List<String> args) async {
  String? key = args.elementAtOrNull(0);
  String? value = args.elementAtOrNull(1);

  if (key == null) {
    print('Usage: clip settings <key> <value>');
    print("'clip settings list' will show current settings");
    exit(1);
  }

  final homeDir = Platform.environment['HOME']!;
  final file = File('${homeDir}/.config/metaclip.json');
  Map<String, dynamic> jsonData = {};

  if (await file.exists()) {
    final content = await file.readAsString();
    jsonData = jsonDecode(content) as Map<String, dynamic>;
  }

  if (value == null) {
    if (key == 'list' || key == 'ls') {
      print('  endpoint: ${valueOrUnset(jsonData, 'endpoint')}');
      print('  token:    ${valueOrUnset(jsonData, 'token')}');
      exit(0);
    } else {
      print('Usage: clip settings <key> <value>');
      print('"clip settings list" will show current settings');
      exit(1);
    }
  }
  if (!['endpoint', 'token'].contains(key)) {
    stderr.writeln("Error: There's no '$key' setting.");
    stderr.writeln('View all keys with "clip settings list"');
    exit(1);
  }

  if (key == 'endpoint') {
    try {
      final uri = Uri.parse(value);
      Settings._validateEndpoint(uri);
    } catch (e) {
      stderr.writeln('Error: Invalid endpoint URL');
      exit(1);
    }
  }

  jsonData[key] = value;

  try {
    final jsonString = JsonEncoder.withIndent('  ').convert(jsonData);
    await file.writeAsString(jsonString);
    print('"$key" updated successfully');
  } catch (e) {
    print('Error saving settings: $e');
    exit(2);
  }
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
    print('  raw "<query>"              Send raw SQL query to server');
    print('');
    exit(1);
  }

  final command = appArgs[0];
  final args = appArgs.sublist(1);

  if (command == 'settings') {
    await settings(args);
    exit(0);
  }

  try {
    final homeDir = Platform.environment['HOME'];
    await Settings.read("${homeDir}/.config/metaclip.json");
  } catch (e) {
    stderr.writeln('Failed to read settings: $e');
    exit(2);
  }

  switch (command) {
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
