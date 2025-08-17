import 'dart:io';
import 'dart:math';

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
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).round()} MB';
  return '${(bytes / (1024 * 1024 * 1024)).round()} GB';
}

String formatContent(String content, int targetWidth) {
  content = content.replaceAll('\n', '  ').replaceAll('\t', '  ');
  if (content.length <= targetWidth) return content.padRight(targetWidth);
  return content.substring(0, targetWidth - 3) + '...';
}

void prettyPrint(List<Map> items) {
  if (items.isEmpty) return;

  int cols;
  if (stdout.hasTerminal)
    cols = stdout.terminalColumns;
  else
    cols = 150;
  bool shortFormat = cols <= 100;

  int longestNameLen =
      items.fold(0, (maxLen, item) => max(maxLen, item['name'].toString().length));

  int idLenLimit = shortFormat ? 14 : 20;
  int nameLenLimit = shortFormat ? min(longestNameLen, 16) : min(longestNameLen, 32);
  int separatorsLen = shortFormat ? 6 : 10; //' │  │ 'or '│  │  │  │'
  int contentLenLimit = cols - idLenLimit - nameLenLimit - separatorsLen;

  // Ignore very slim terminals
  if (contentLenLimit < 10) contentLenLimit = 20;

  for (var item in items) {
    String id = formatId(item['id'], idLenLimit);
    String name = formatName(item['name'], nameLenLimit);
    String content = formatContent(item['content'], contentLenLimit);

    if (shortFormat) {
      print('${id} │ ${name} │ $content');
    } else {
      print('│ ${id} │ ${name} │ $content │');
    }
  }
}
