import 'dart:io';
import 'dart:math';

import 'consts.dart';

String formatId(String id, int targetLength) {
  if (id.length <= targetLength) return id.padRight(targetLength);
  return id.substring(0, targetLength - 3) + '...';
}

String formatName(String name, int targetLength) {
  if (name.length <= targetLength) return name.padRight(targetLength);
  if (targetLength < 9) return '...' + name.substring(name.length - targetLength);
  return name.substring(0, targetLength - 9) +
      '...' +
      name.substring(name.length - 6);
}

String formatSize(int bytes) {
  if (bytes < Constants.KB) return '$bytes B';
  if (bytes < Constants.MB) return '${(bytes / Constants.KB).round()} KB';
  if (bytes < Constants.GB) return '${(bytes / Constants.MB).round()} MB';
  return '${(bytes / Constants.GB).round()} GB';
}

String formatContent(String content, int targetWidth) {
  content = content.replaceAll('\n', '  ').replaceAll('\t', '  ');
  if (content.length <= targetWidth) return content.padRight(targetWidth);
  return content.substring(0, targetWidth - 3) + '...';
}

void prettyPrint(List<Map<String, dynamic>> items) {
  if (items.isEmpty) return;

  int cols;
  if (stdout.hasTerminal)
    cols = stdout.terminalColumns;
  else
    cols = Constants.defaultOutputWidth;
  bool shortFormat = cols <= Constants.shortFormatThreshold;

  int longestNameLen = items.fold(
      0, (maxLen, item) => max(maxLen, (item['name'] as String).toString().length));

  int idLenLimit = shortFormat ? 14 : 20;
  int nameLenLimit = shortFormat ? min(longestNameLen, 16) : min(longestNameLen, 32);
  int separatorsLen = shortFormat ? 6 : 10; //' │  │ 'or '│  │  │  │'
  int contentLenLimit = cols - idLenLimit - nameLenLimit - separatorsLen;

  // Ignore very slim terminals
  if (contentLenLimit < 10) contentLenLimit = 20;

  for (final Map<String, dynamic> item in items) {
    String id = formatId(item['id'] as String, idLenLimit);
    String name = formatName(item['name'] as String, nameLenLimit);
    String content = formatContent(item['content'] as String, contentLenLimit);

    if (shortFormat) {
      print('${id} │ ${name} │ $content');
    } else {
      print('│ ${id} │ ${name} │ $content │');
    }
  }
}
