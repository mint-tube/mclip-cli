import 'dart:io';
import 'dart:math';

import 'consts.dart';

String formatId(String id, int targetLength) {
  if (id.length <= targetLength) return id.padRight(targetLength);
  return id.substring(0, targetLength);
}

String formatName(String name, int targetLength) {
  if (name.length <= targetLength) return name.padRight(targetLength);
  if (targetLength < 9) return '...' + name.substring(name.length - targetLength);
  return name.substring(0, targetLength - 9) +
      '...' +
      name.substring(name.length - 6);
}

String formatSize(int bytes) {
  if (bytes < Consts.KB) return '$bytes B';
  if (bytes < Consts.MB) return '${(bytes / Consts.KB).round()} KB';
  if (bytes < Consts.GB)
    return '${(bytes / Consts.MB).round()} MB';
  else
    return '${(bytes / Consts.GB).round()} GB';
}

String formatFileContent(dynamic content, int sizeRaw, int targetWidth) {
  String size = formatSize(sizeRaw).padRight(7);
  String displayContent;

  if (content is List<int>) {
    displayContent = 'binary file';
  } else if (content is String) {
    displayContent = content
        .replaceAll('\r\n', '  ')
        .replaceAll('\r', '  ')
        .replaceAll('\n', '  ')
        .trim();

    int contentWidth = targetWidth - 10;
    if (displayContent.length > contentWidth) {
      displayContent = displayContent.substring(0, contentWidth - 3) + '...';
    }
  } else {
    size = formatSize(0);
    displayContent = 'unknown type';
  }

  return '${size} │ $displayContent';
}

String formatTextContent(String content, int targetWidth) {
  content = content.replaceAll('\n', '  ').replaceAll('\t', '  ');
  if (content.length <= targetWidth) return content.padRight(targetWidth);
  return content.substring(0, targetWidth - 3) + '...';
}

void prettyPrint(List<Map<String, dynamic>> items, StringSink out) {
  /*
  Expected fields in every item: 
  String name;
  String type;
  String name;
  String | List<Int> content;
  int size
  */
  int cols;
  if (out == stdout && stdout.hasTerminal)
    cols = stdout.terminalColumns;
  else if (out == stderr && stderr.hasTerminal)
    cols = stderr.terminalColumns;
  else
    cols = Consts.defaultOutputWidth;
  bool shortFormat = cols <= Consts.shortFormatThreshold;

  int longestNameLen = items.fold(
      0, (maxLen, item) => max(maxLen, (item['name'] as String).toString().length));

  int idLenLimit = shortFormat ? 6 : 12;
  int nameLenLimit = shortFormat ? min(longestNameLen, 16) : min(longestNameLen, 32);
  int separatorsLen = shortFormat ? 6 : 10; //' │  │ 'or '│  │  │  │'
  int contentLenLimit = cols - idLenLimit - nameLenLimit - separatorsLen;

  // Ignore very slim terminals
  if (contentLenLimit < 10) contentLenLimit = 25;

  for (final Map<String, dynamic> item in items) {
    String id = formatId(item['id'] as String, idLenLimit);
    String name = formatName(item['name'] as String, nameLenLimit);
    String content;
    if (item['type'] == 'text')
      content = formatTextContent(item['content'], contentLenLimit);
    else if (item['type'] == 'file')
      content = formatFileContent(item['content'], item['size'], contentLenLimit);
    else
      content = 'unknown type';

    if (shortFormat) {
      out.writeln('${id} │ ${name} │ $content');
    } else {
      out.writeln('│ ${id} │ ${name} │ $content │');
    }
  }
}
