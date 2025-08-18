import 'dart:io';
import 'dart:convert';

bool validateEndpoint(String endpoint) {
  final Uri uri = Uri.parse(endpoint);
  return (['http', 'https'].contains(uri.scheme) &&
      uri.authority.isNotEmpty &&
      uri.port > -2);
  // port -1 means no port specified
}

// Read json file and validate some fields
Future<Map<String, dynamic>> readSettings() async {
  try {
    final String? homeDir = Platform.environment['HOME'];
    final File file = File("$homeDir/.config/metaclip.json");
    Map<String, dynamic> jsonData = {};
    List<String> unsetSettings = [];

    if (await file.exists()) {
      final String content = await file.readAsString();
      jsonData = jsonDecode(content) as Map<String, dynamic>;
    }
    // endpoint
    if (!jsonData.containsKey('endpoint')) {
      unsetSettings.add('endpoint');
    } else if (!validateEndpoint(jsonData['endpoint'])) {
      stderr.writeln('Invalid API URL: ${jsonData['endpoint']}');
      unsetSettings.add('endpoint');
    }

    // token
    if (!jsonData.containsKey('token')) {
      unsetSettings.add('token');
    }

    if (unsetSettings.isNotEmpty) {
      stderr.writeln('Update the following settings:');
      for (final String setting in unsetSettings) {
        stderr.writeln(' - $setting');
      }
      stderr.writeln("Use 'clip settings <key> <value>'");
      exit(1);
    }

    // Convert json
    jsonData['endpoint'] = Uri.parse(jsonData['endpoint']);
    return jsonData;
  } catch (e) {
    stderr.writeln('Error reading settings: $e');
    exit(2);
  }
}
