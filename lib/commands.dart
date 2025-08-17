import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart';

import 'settings.dart';
import 'pprint.dart';

Future<List<Map>> execute(String query) async {
  Response response;
  Map<String, dynamic> settings = await readSettings();
  Uri endpoint = settings['endpoint'];
  String token = settings['token'];

  try {
    response = await post(endpoint,
            headers: {"Authorization": token, "Content-Type": "text/plain"},
            body: query)
        .timeout(Duration(seconds: 20), onTimeout: () => throw TimeoutException(''));
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
    stderr.writeln("Timeout: No response in 20 seconds");
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
      final List<Map> mapped = decoded.map((item) => item as Map).toList();

      // decode base64 content
      mapped.forEach((item) {
        item["content"] = utf8.decode(base64.decode(item["content"]));
      });
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

  final file = File("${Platform.environment['HOME']}/.config/metaclip.json");
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

  if (!['endpoint', 'token'].contains(key)) {
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
  List<Map> items = await execute("SELECT * FROM items");
  if (items.isNotEmpty) prettyPrint(items);
  exit(0);
}

Future<void> raw(List<String> args) async {
  try {
    final items = await execute(args.join(" "));
    print(JsonEncoder.withIndent('  ').convert(items));
  } catch (error) {
    stderr.writeln("Error executing command: $error");
    exit(1);
  }
}
