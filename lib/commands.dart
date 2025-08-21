import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart';

import 'settings.dart';
import 'pprint.dart';
import 'consts.dart';
import 'convert.dart';

String newId() {
  final random = Random();
  final bytes = List<int>.generate(Consts.bytesInId, (i) => random.nextInt(256));
  return hexEncode(bytes);
}

Future<List<Map<String, dynamic>>> execute(String query) async {
  Response response;
  Map<String, dynamic> settings = await readSettings();
  Uri endpoint = settings['endpoint'] as Uri;
  String token = settings['token'] as String;
  Duration timeout = settings['timeout'] as Duration;

  try {
    response = await post(endpoint,
            headers: {"Authorization": token, "Content-Type": "text/plain"},
            body: query)
        .timeout(
      timeout,
      onTimeout: () => throw TimeoutException(null),
    );
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
    stderr.writeln("Timeout: No response in ${timeout.inSeconds} seconds");
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

      // decode hex to bytes or string, whatever applicable
      for (final item in mapped) {
        if (item['content'] == null) break; // assuming all items are typical
        try {
          item["content"] = utf8.decode(hexDecode(item["content"]));
        } on FormatException {
          item["content"] = hexDecode(item["content"]);
        }
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
    print('Usage: mclip settings <key> <value>');
    print("'mclip settings ls' will show current settings");
    exit(1);
  }

  final file = File(getConfigPath());
  Map<String, dynamic> jsonData = {};
  if (await file.exists()) {
    final content = await file.readAsString();
    jsonData = jsonDecode(content) as Map<String, dynamic>;
  }

  if (value == null) {
    if (key == 'ls') {
      jsonData.forEach((key, value) => print("$key: $value"));
      return;
    } else {
      print('Usage: mclip settings <key> <value>');
      print("'mclip settings ls' will show current settings");
      exit(1);
    }
  }

  if (!Consts.validSettings.contains(key)) {
    stderr.writeln("Error: There's no '$key' setting.");
    stderr.writeln('View all keys with "mclip settings ls"');
    exit(1);
  }

  if (key == 'endpoint' && !validateEndpoint(value)) {
    stderr.writeln('Error: Invalid endpoint URL');
    stderr.writeln('Example: https://metaclip.ru/api');
    exit(1);
  }

  if (key == 'timeout') {
    try {
      int timeout = int.parse(value);
      Duration(seconds: timeout);
      if (timeout < 3) {
        stderr.writeln('Timeout threshold is too low: ${timeout}');
        stderr.writeln('Must be at least 3');
        exit(1);
      }
    } catch (e) {
      stderr.writeln('Invalid timeout threshold: ${jsonData['timeout']}');
      stderr.writeln('Must be a whole number of seconds');
      exit(1);
    }
  }

  // Update the jsonData with the new value
  jsonData[key] = value;

  try {
    // Create parent directory if it doesn't exist
    await file.parent.create(recursive: true);
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(jsonData));
    print('"$key" updated successfully');
  } catch (e) {
    print('Error saving settings: $e');
    exit(2);
  }
}

Future<void> ls(List<String> args) async {
  if (args.isNotEmpty) {
    stderr.writeln("No arguments expected; ignoring.");
  }
  List<Map<String, dynamic>> items = await execute(
      "SELECT id, type, name, substr(content, 1, 400) as content, length(content) as size FROM items");
  prettyPrint(items, stdout);
}

Future<void> search(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln("Usage: mclip search <prefix>");
    exit(1);
  }
  if (args[0].trim() == '') {
    stderr.writeln("Error: Invalid prefix");
    exit(1);
  }

  String prefix = args[0].replaceAll("'", "''");
  List<Map<String, dynamic>> found = await execute(
      """SELECT id, type, name, substr(content, 1, 400) as content, length(content) as size FROM items
      WHERE id LIKE '$prefix%' OR name LIKE '$prefix%'""");
  prettyPrint(found, stdout);
}

Future<void> text(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln("Usage: mclip text <name>");
    exit(1);
  }

  StringBuffer buffer = StringBuffer();
  String? line;

  stdin.hasTerminal ? print("Ctrl+D to finish") : null;
  while (true) {
    line = stdin.readLineSync();
    if (line == null) break;
    buffer.writeln(line);
  }

  String id = newId();
  String content = hexEncode(utf8.encode(buffer.toString()));
  String name = args.join(' ').replaceAll("'", "''");

  await execute(
      "INSERT INTO items (id, type, name, content) values ('$id', 'text', '$name', X'$content')");
}

Future<void> file(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln("Usage: mclip file <path>");
    exit(1);
  }

  File file = File(args[0]);

  if (!file.existsSync()) {
    stderr.writeln("Error: file doesn't exist");
    exit(2);
  }

  int fileSize = await file.length();

  if (fileSize > 200 * Consts.MB) {
    stderr.writeln("Error: File is too large (> 200 MB)");
    exit(2);
  } else if (fileSize > 25 * Consts.MB) {
    stderr.writeln("Warning: Consider using other services for light file");
  }

  String id = newId();
  String name = file.path.split(Platform.pathSeparator).last;
  String content = hexEncode(await file.readAsBytes());

  await execute(
      "INSERT INTO items (id, type, name, content) values ('$id', 'file', '$name', X'$content')");
}

Future<void> paste(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Error: no prefix given');
    exit(1);
  }

  if (args.length > 2) {
    stderr.writeln('Usage: mclip paste <prefix> [dir]');
  }

  String prefix = args[0].replaceAll("'", "''");
  List<Map<String, dynamic>> found = await execute(
      """SELECT id, type, name, substr(content, 1, 400) as content, length(content) as size FROM items
      WHERE id LIKE '$prefix%' OR name LIKE '$prefix%'""");

  if (found.isEmpty) {
    stderr.writeln("No items with this prefix");
    exit(1);
  }
  if (found.length > 1) {
    stderr.writeln("More than one element with such prefix exists. Specify.");
    prettyPrint(found, stderr);
    exit(1);
  }

  Map<String, dynamic> item = found[0];

  if (item['type'] == "file") {
    String? dir = args.elementAtOrNull(1) ?? Directory.current.path;
    File file = File(dir + Platform.pathSeparator + item['name']);
    file.createSync(recursive: true);
    file.writeAsBytesSync(hexDecode(item['content']));
  } else {
    print(item["content"]);
  }
}

Future<void> delete(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln("Usage: mclip delete <prefix>");
    exit(1);
  }
  if (args[0].trim() == '') {
    stderr.writeln("Error: Invalid prefix");
    exit(1);
  }

  String prefix = args[0].replaceAll("'", "''");
  List<Map<String, dynamic>> found = await execute(
      """SELECT id, type, name, substr(content, 1, 400) as content, length(content) as size FROM items
      WHERE id LIKE '$prefix%' OR name LIKE '$prefix%'""");
  if (found.isEmpty) {
    stderr.writeln("No items with this prefix");
    exit(1);
  }
  if (found.length > 1) {
    stderr.writeln("More than 1 item with such prefix/id exists. Specify.");
    prettyPrint(found, stderr);
    exit(1);
  }
  await execute(
      "DELETE FROM items WHERE id LIKE '$prefix%' OR name LIKE '$prefix%'");
}

Future<void> purge(List<String> args) async {
  if (args.isNotEmpty) {
    stderr.writeln("No arguments expected; ignoring.");
  }
  // no confirmation because i hate them
  await execute("DELETE FROM items");
}

Future<void> raw(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: mclip raw "<query>');
  }
  List<Map<String, dynamic>> items = await execute(args.join(" "));
  print(JsonEncoder.withIndent('  ').convert(items));
}
