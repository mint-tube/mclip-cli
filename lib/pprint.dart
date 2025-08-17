import 'dart:io';

String truncateId(String id, int maxLength) {
  if (id.length <= maxLength) return id;
  return id.substring(0, maxLength - 3) + '...';
}

String truncateName(String name, int maxLength, {bool shortFormat = false}) {
  if (name.length <= maxLength) return name;
  if (shortFormat) {
    return name.substring(0, 6) + '...' + name.substring(name.length - 6);
  } else {
    return name.substring(0, 20) + '...' + name.substring(name.length - 9);
  }
}

String formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).round()} MB';
  return '${(bytes / (1024 * 1024 * 1024)).round()} GB';
}

String formatContent(String content, int availableWidth) {
  if (content.isEmpty) return '';
  content = content.replaceAll('\n', ' ').replaceAll('\t', ' ');
  if (content.length <= availableWidth) return content;
  return content.substring(0, availableWidth - 3) + '...';
}

void prettyPrint(List<dynamic> items) {
  if (items.isEmpty) return;

  int cols = stdout.terminalColumns;
  bool shortFormat = cols <= 100;

  int idMaxLen = shortFormat ? 14 : 25;
  int nameMaxLen = shortFormat ? 16 : 32;

  // Calculate available width for content
  int separatorsWidth = shortFormat ? 9 : 12; // │ │ │ │ or │ │ │ │ │
  int contentMaxLen = cols - idMaxLen - nameMaxLen - 12 - separatorsWidth;
  if (contentMaxLen < 20) contentMaxLen = 20;

  for (var item in items) {
    String id = truncateId(item['id']?.toString() ?? '', idMaxLen);
    String name = truncateName(item['name']?.toString() ?? '', nameMaxLen,
        shortFormat: shortFormat);
    String size = formatSize(item['size']?.toInt() ?? 0);
    String content = formatContent(item['content']?.toString() ?? '', contentMaxLen);

    if (shortFormat) {
      print(
          '${id.padRight(idMaxLen)} │ ${name.padRight(nameMaxLen)} │ ${size.padRight(8)} │ $content');
    } else {
      print(
          '│ ${id.padRight(idMaxLen)} │ ${name.padRight(nameMaxLen)} │ ${size.padRight(8)} │ $content │');
    }
  }
}
