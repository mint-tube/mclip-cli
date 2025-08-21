import 'dart:io';
import 'dart:convert';

String getConfigPath() {
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null) {
      return "$appData\\metaclip\\config.json";
    }
    // Fallback to user profile
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null) {
      return "$userProfile\\metaclip\\config.json";
    }
  }

  // Linux and macOS
  final homeDir = Platform.environment['HOME'];
  if (homeDir != null) {
    return "$homeDir/.config/metaclip.json";
  }

  throw Exception('Could not determine config directory');
}

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
    final File file = File(getConfigPath());
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
      stderr.writeln('Example: https://metaclip.ru/api');
      unsetSettings.add('endpoint');
    }

    // token
    if (!jsonData.containsKey('token')) {
      unsetSettings.add('token');
    }

    if (!jsonData.containsKey('timeout')) {
      unsetSettings.add('timeout');
    } else {
      try {
        int timeout = int.parse(jsonData['timeout']);
        Duration(seconds: timeout);
        if (timeout < 3) {
          stderr.writeln('Timeout threshold is too low: ${jsonData['timeout']}');
          stderr.writeln('Must be at least 3');
          unsetSettings.add('timeout');
        }
      } catch (e) {
        stderr.writeln('Invalid timeout threshold: ${jsonData['timeout']}');
        stderr.writeln('Must be a whole number of seconds');
        unsetSettings.add('timeout');
      }
    }

    if (unsetSettings.isNotEmpty) {
      stderr.writeln('Update the following settings:');
      for (final String setting in unsetSettings) {
        stderr.writeln(' - $setting');
      }
      stderr.writeln("Use 'mclip settings <key> <value>'");
      exit(1);
    }

    // Convert json strings to respective types
    jsonData['endpoint'] = Uri.parse(jsonData['endpoint']);
    jsonData['token'] = jsonData['token'] as String;
    jsonData['timeout'] = Duration(seconds: int.parse(jsonData['timeout']));
    return jsonData;
  } catch (e) {
    stderr.writeln('Error reading settings: $e');
    exit(2);
  }
}
