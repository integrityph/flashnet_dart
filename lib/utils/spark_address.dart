import 'dart:typed_data';
import 'package:bech32/bech32.dart';
import 'package:spark_dart/utils/address.dart';
import '../types/index.dart';
import 'hex.dart';

/// Internal container for public key bytes
class _SparkAddressBytes {
  final Uint8List identityPublicKey;
  _SparkAddressBytes(this.identityPublicKey);
}

const Map<SparkNetworkType, String> sparkAddressNetworkPrefix = {
  SparkNetworkTypes.mainnet: "spark",
  SparkNetworkTypes.testnet: "sparkt",
  SparkNetworkTypes.regtest: "sparkrt",
  SparkNetworkTypes.signet: "sparks",
  SparkNetworkTypes.local: "sparkl",
};

final Map<String, SparkNetworkType> sparkPrefixToNetwork = 
    sparkAddressNetworkPrefix.map((key, value) => MapEntry(value, key));

/// Backward Compatibility Constants
@Deprecated('Use sparkAddressNetworkPrefix')
const Map<NetworkType, String> addressNetworkPrefix = {
  NetworkTypes.mainnet: "sp",
  NetworkTypes.testnet: "spt",
  NetworkTypes.regtest: "sprt",
  NetworkTypes.signet: "sps",
  NetworkTypes.local: "spl",
};

final Map<String, SparkNetworkType> allSparkPrefixToNetwork = {
  ...sparkPrefixToNetwork,
  ...addressNetworkPrefix.map((key, value) => MapEntry(value, key)),
};

// --- Protobuf-style Helpers ---

/// Field 1: identityPublicKey (bytes type)
Uint8List _encodeProto(Uint8List publicKeyBytes) {
  final result = Uint8List(2 + publicKeyBytes.length);
  // Field 1, wire type 2 = tag 10
  result[0] = 10;
  result[1] = publicKeyBytes.length;
  result.setRange(2, result.length, publicKeyBytes);
  return result;
}

_SparkAddressBytes _decodeProto(Uint8List data) {
  int pos = 0;
  Uint8List? key;

  while (pos < data.length) {
    final tag = data[pos++];
    if (tag == 10) {
      final length = data[pos++];
      key = data.sublist(pos, pos + length);
      pos += length;
    } else {
      break;
    }
  }

  if (key == null || key.isEmpty) {
    throw Exception("Failed to decode public key from proto bytes");
  }
  return _SparkAddressBytes(key);
}

// --- Primary Logic ---

/// Encodes a public key and Spark network into a Spark address
String encodeSparkAddressNew(SparkAddressDataNew payload) {
  isValidPublicKey(payload.identityPublicKey);

  final publicKeyBytes = getUint8ArrayFromHex(payload.identityPublicKey);
  final protoEncoded = _encodeProto(publicKeyBytes);

  // Bech32m encoding
  final bech32Codec = Bech32Codec();
  final prefix = sparkAddressNetworkPrefix[payload.network]!;
  
  // Convert 8-bit bytes to 5-bit words
  final words = _convertBits(protoEncoded, 8, 5, true);
  
  // Note: Ensure your bech32 library supports Bech32m (variant 0x02)
  return bech32Codec.encode(Bech32(prefix, words), 200); 
}

/// Decodes a Spark address to extract the hex public key
String decodeSparkAddressNew(String address, SparkNetworkType network) {
  final modernPrefix = sparkAddressNetworkPrefix[network]!;
  final legacyPrefix = addressNetworkPrefix[network]!;
  
  if (!address.startsWith(modernPrefix) && !address.startsWith(legacyPrefix)) {
    throw Exception("Invalid Spark address: expected prefix $modernPrefix or $legacyPrefix");
  }

  final decoded = Bech32Codec().decode(address, 200);
  final protoBytes = _convertBits(Uint8List.fromList(decoded.data), 5, 8, false);
  
  final sparkAddressData = _decodeProto(protoBytes);
  final publicKey = getHexFromUint8Array(sparkAddressData.identityPublicKey);

  isValidPublicKey(publicKey);
  return publicKey;
}

/// Determines the Spark network type from a Spark address prefix
SparkNetworkType? getSparkNetworkFromAddress(String address) {
  if (address.isEmpty) return null;
  final parts = address.split("1");
  if (parts.length < 2) return null;
  
  final prefix = parts[0];
  return allSparkPrefixToNetwork[prefix];
}

/// Validates a Spark address
bool isValidSparkAddressNew(String address, [SparkNetworkType? network]) {
  try {
    if (!address.contains("1")) return false;

    final decoded = Bech32Codec().decode(address, 200);
    final prefix = decoded.hrp;

    final networkFromPrefix = allSparkPrefixToNetwork[prefix];
    if (networkFromPrefix == null) return false;

    if (network != null && network != networkFromPrefix) return false;

    final protoBytes = _convertBits(Uint8List.fromList(decoded.data), 5, 8, false);
    final sparkAddressData = _decodeProto(protoBytes);
    final publicKey = getHexFromUint8Array(sparkAddressData.identityPublicKey);
    
    isValidPublicKey(publicKey);
    return true;
  } catch (_) {
    return false;
  }
}

/// Bit conversion utility (8-bit to 5-bit for Bech32)
Uint8List _convertBits(Uint8List data, int from, int to, bool pad) {
  int acc = 0;
  int bits = 0;
  final List<int> result = [];
  final maxv = (1 << to) - 1;

  for (final value in data) {
    acc = (acc << from) | value;
    bits += from;
    while (bits >= to) {
      bits -= to;
      result.add((acc >> bits) & maxv);
    }
  }

  if (pad) {
    if (bits > 0) {
      result.add((acc << (to - bits)) & maxv);
    }
  } else if (bits >= from || ((acc << (to - bits)) & maxv) != 0) {
    throw Exception("Invalid padding");
  }

  return Uint8List.fromList(result);
}