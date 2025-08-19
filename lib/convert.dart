String hexEncode(List<int> bytes) {
  const List<String> alphabet = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f'
  ];

  StringBuffer hex = StringBuffer();

  for (int byte in bytes) {
    hex.write(alphabet[byte ~/ 16] + alphabet[byte % 16]);
  }

  return hex.toString();
}

List<int> hexDecode(String hex) {
  if (hex.length % 2 != 0) {
    throw FormatException('Invalid hex string in response');
  }

  final bytes = <int>[];

  for (int i = 0; i < hex.length; i += 2) {
    final hexPair = hex.substring(i, i + 2);
    final byte = int.parse(hexPair, radix: 16);
    bytes.add(byte);
  }

  return bytes;
}
