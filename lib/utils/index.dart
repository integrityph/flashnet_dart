import 'dart:math';
import 'dart:typed_data';

/// Helper function to generate random nonce
/// Uses [Random.secure()] for cryptographic strength
String generateNonce() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  return values.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
}

/// Helper function to convert decimal amounts to smallest units
/// Note: For high precision, using [BigInt] or a decimal library is safer than double multiplication.
BigInt toSmallestUnit(double amount, int decimals) {
  return BigInt.from((amount * pow(10, decimals)).floor());
}

/// Helper function to convert from smallest units to decimal
double fromSmallestUnit(dynamic amount, int decimals) {
  final BigInt bigintAmount;
  if (amount is BigInt) {
    bigintAmount = amount;
  } else if (amount is String) {
    bigintAmount = BigInt.parse(amount);
  } else if (amount is int) {
    bigintAmount = BigInt.from(amount);
  } else {
    throw ArgumentError("Invalid amount type: ${amount.runtimeType}");
  }
  
  return bigintAmount.toDouble() / pow(10, decimals);
}

/// Helper function to compare two non-negative decimal strings.
/// Returns -1 if a < b, 0 if equal, and 1 if a > b.
int compareDecimalStrings(String a, String b) {
  List<String> normalize(String s) {
    final parts = s.split('.');
    final whole = (parts[0].replaceFirst(RegExp(r'^0+'), '').isEmpty) 
        ? "0" 
        : parts[0].replaceFirst(RegExp(r'^0+'), '');
    
    final fraction = (parts.length > 1) 
        ? parts[1].replaceFirst(RegExp(r'0+$'), '') 
        : "";
    return [whole, fraction];
  }

  final normA = normalize(a);
  final normB = normalize(b);

  final wholeA = normA[0];
  final fracA = normA[1];
  final wholeB = normB[0];
  final fracB = normB[1];

  // Compare integer part length
  if (wholeA.length != wholeB.length) {
    return wholeA.length < wholeB.length ? -1 : 1;
  }

  // Compare integer parts lexicographically
  if (wholeA != wholeB) {
    return wholeA.compareTo(wholeB);
  }

  // Integers are equal – compare fractional parts
  final maxFracLen = max(fracA.length, fracB.length);
  final fracAPadded = fracA.padRight(maxFracLen, '0');
  final fracBPadded = fracB.padRight(maxFracLen, '0');

  return fracAPadded.compareTo(fracBPadded);
}

/// Safe BigInt conversion that handles potential floating point strings
BigInt safeBigInt(dynamic value) {
  if (value is BigInt) return value;
  if (value is int) return BigInt.from(value);
  if (value is String) {
    // Handle cases where scientific notation or dots might appear in string inputs
    if (value.contains('.') || value.contains('e')) {
      return BigInt.from(double.parse(value).floor());
    }
    return BigInt.parse(value);
  }
  throw ArgumentError("Cannot convert $value to BigInt");
}