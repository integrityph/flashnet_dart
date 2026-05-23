import 'dart:typed_data';

/// Converts a Uint8List to a hex string
String getHexFromUint8Array(Uint8List bytes) {
  return bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join("");
}

/// Converts a hex string to a Uint8List
Uint8List getUint8ArrayFromHex(String hex) {
  // Remove 0x prefix if present
  String cleanHex = hex.startsWith('0x') ? hex.substring(2) : hex;

  if (cleanHex.length % 2 != 0) {
    throw ArgumentError("Invalid hex string length");
  }

  final bytes = Uint8List(cleanHex.length ~/ 2);
  for (var i = 0; i < cleanHex.length; i += 2) {
    bytes[i ~/ 2] = int.parse(cleanHex.substring(i, i + 2), radix: 16);
  }
  return bytes;
}