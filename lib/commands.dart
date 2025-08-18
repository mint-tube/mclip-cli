import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart';

import 'settings.dart';
import 'pprint.dart';
import 'consts.dart';

Future<List<Map<String, dynamic>>> execute(String query) async {
  Response response;
  Map<String, dynamic> settings = await readSettings();
  Uri endpoint = settings['endpoint'] as Uri;
  String token = settings['token'] as String;

  try {
    response = await post(endpoint,
            headers: {"Authorization": token, "Content-Type": "text/plain"},
            body: query)
        .timeout(Constants.timeoutDelay,
            onTimeout: () => throw TimeoutException(''));
  } on SocketException catch (e) {
    if (e.message.contains('Connection refused')) {
      stderr.writeln(
        'Connection Error: Unable to connect to the API.\n'
        '${endpoint.authority} appears to be offline or not accepting connections.',
      );
    } else {
      stderr.writeln(
        'Network Error: Unable to connect to the metaclip server.\n'
        'Error details: ${e.message}',
      );
    }
    exit(2);
  } on TimeoutException {
    stderr.writeln(
        "Timeout: No response in ${Constants.timeoutDelay.inSeconds} seconds");
    exit(2);
  } catch (e) {
    stderr.writeln(
        'Unexpected Error: An error occurred while communicating with the server.');
    exit(2);
  }

  switch (response.statusCode) {
    case 200:
      // decode json response
      final List<dynamic> decoded = jsonDecode(response.body);
      final List<Map<String, dynamic>> mapped =
          decoded.map((item) => item as Map<String, dynamic>).toList();

      // decode base64 content
      for (final item in mapped) {
        item["content"] = utf8.decode(base64.decode(item["content"]));
      }
      return mapped;
    case 401:
      stderr.writeln("Error: token was rejected");
      exit(1);
    default:
      stderr.writeln(
          "Request to ${endpoint} failed: ${response.statusCode} - ${response.reasonPhrase}");
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

  final homeDir = Platform.environment['HOME'];
  final file = File("$homeDir/.config/metaclip.json");
  Map<String, dynamic> jsonData = {};
  if (await file.exists()) {
    final content = await file.readAsString();
    jsonData = jsonDecode(content) as Map<String, dynamic>;
  }

  if (value == null) {
    if (key == 'list' || key == 'ls') {
      jsonData.forEach((key, value) => print("$key: $value"));
      exit(0);
    } else {
      print('Usage: clip settings <key> <value>');
      print('"clip settings list" will show current settings');
      exit(1);
    }
  }

  if (!Constants.validSettings.contains(key)) {
    stderr.writeln("Error: There's no '$key' setting.");
    stderr.writeln('View all keys with "clip settings list"');
    exit(1);
  }

  if (key == 'endpoint' && !validateEndpoint(value)) {
    stderr.writeln('Error: Invalid endpoint URL');
    exit(1);
  }

  jsonData[key] = value;

  try {
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(jsonData));
    print('"$key" updated successfully');
  } catch (e) {
    print('Error saving settings: $e');
    exit(2);
  }
}

Future<void> ls(List<String> args) async {
  if (args.isNotEmpty) stderr.writeln("No arguments expected; ignoring.");
  List<Map<String, dynamic>> items = await execute("SELECT * FROM items");
  if (items.isNotEmpty) prettyPrint(items);
  exit(0);
}

// Future<void> search(List<String> args) async {

// }

Future<void> delete(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln("Usage: clip delete [prefix..]");
    exit(1);
  }
  List<Map<String, dynamic>> deleted = await execute(
      "SELECT name FROM items WHERE id LIKE '${args[0]}%' OR name LIKE '${args[0]}%';" +
          "DELETE FROM items WHERE id LIKE '${args[0]}%' OR name LIKE '${args[0]}%'");
  if (deleted.isEmpty)
    print("No items were deleted");
  else
    print("Deleted ${deleted.length} items");
}

Future<void> raw(List<String> args) async {
  try {
    final List<Map<String, dynamic>> items = await execute(args.join(" "));
    print(JsonEncoder.withIndent('  ').convert(items));
  } catch (error) {
    stderr.writeln("Error executing command: $error");
    exit(1);
  }
}
