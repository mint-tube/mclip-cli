class Consts {
  static const Duration timeoutDelay = Duration(seconds: 20);

  static const List<String> validSettings = ['endpoint', 'token'];

  static const int defaultOutputWidth = 150;
  static const int shortFormatThreshold = 100;

  static const int KB = 1024;
  static const int MB = 1024 * 1024;
  static const int GB = 1024 * 1024 * 1024;

  // one byte - two symbols (00101011 -> 2b)
  static const int bytesInId = 8;
}
