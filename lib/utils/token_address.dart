import 'dart:convert';
import 'dart:typed_data';
import 'package:bech32/bech32.dart';
import 'package:crypto/crypto.dart';
import 'package:spark_dart/utils/address.dart';
import '../types/index.dart';
import 'hex.dart';

const Map<SparkNetworkType, String> sparkHumanReadableTokenIdentifierNetworkPrefix = {
  SparkNetworkTypes.mainnet: "btkn",
  SparkNetworkTypes.regtest: "btknrt",
  SparkNetworkTypes.testnet: "btknt",
  SparkNetworkTypes.signet: "btkns",
  SparkNetworkTypes.local: "btknl",
};

class TokenIdentifierHashes {
  final Uint8List versionHash;
  final Uint8List issuerPublicKeyHash;
  final Uint8List nameHash;
  final Uint8List tickerHash;
  final Uint8List decimalsHash;
  final Uint8List maxSupplyHash;
  final Uint8List isFreezableHash;
  final Uint8List networkHash;
  final Uint8List creationEntityPublicKeyHash;

  TokenIdentifierHashes({
    required this.versionHash,
    required this.issuerPublicKeyHash,
    required this.nameHash,
    required this.tickerHash,
    required this.decimalsHash,
    required this.maxSupplyHash,
    required this.isFreezableHash,
    required this.networkHash,
    required this.creationEntityPublicKeyHash,
  });
}

const Map<String, int> networkMagic = {
  'MAINNET': 3652501241,
  'TESTNET': 118034699,
  'REGTEST': 3669344250,
  'SIGNET': 1294402529,
};

const String sparkTokenCreationEntityPublicKey =
    "0205fe807e8fe1f368df955cc291f16d840b7f28374b0ed80b80c3e2e0921a0674";

/// Encode token identifier using Spark network type
String encodeSparkHumanReadableTokenIdentifier(
  dynamic tokenIdentifier, // String (hex) or Uint8List
  SparkNetworkType network,
) {
  try {
    final Uint8List tokenIdentifierBytes = tokenIdentifier is String
        ? getUint8ArrayFromHex(tokenIdentifier)
        : tokenIdentifier as Uint8List;

    final String prefix = sparkHumanReadableTokenIdentifierNetworkPrefix[network]!;
    
    // Bech32m uses variant 0x02. 
    // Logic for converting bits (8 to 5) as implemented in spark_address.dart
    final words = convertBits(tokenIdentifierBytes, 8, 5, true);
    
    return bech32mEncode(prefix, words);
  } catch (e) {
    throw Exception("Failed to encode Spark human readable token identifier: $e");
  }
}

/// Decode human-readable token identifier using Spark network type
SparkHumanReadableTokenIdentifier decodeSparkHumanReadableTokenIdentifier(
  String humanReadableTokenIdentifier,
  SparkNetworkType network,
) {
  try {
    final decoded = Bech32Codec().decode(humanReadableTokenIdentifier, 500);
    final String expectedPrefix = sparkHumanReadableTokenIdentifierNetworkPrefix[network]!;

    if (decoded.hrp != expectedPrefix) {
      throw Exception(
          "Invalid Spark human readable token identifier prefix, expected '$expectedPrefix' but got '${decoded.hrp}'");
    }

    final bytes = convertBits(Uint8List.fromList(decoded.data), 5, 8, false);

    return SparkHumanReadableTokenIdentifier(
      tokenIdentifier: getHexFromUint8Array(bytes),
      network: network,
    );
  } catch (e) {
    throw Exception("Failed to decode Spark human readable token identifier: $e");
  }
}

TokenIdentifierHashes getTokenIdentifierHashes({
  required dynamic issuerPublicKey,
  required String name,
  required String ticker,
  required int decimals,
  required BigInt maxSupply,
  required bool isFreezable,
  required String network,
  required dynamic creationEntityPublicKey,
}) {
  Uint8List sha256Hash(List<int> bytes) =>
      Uint8List.fromList(sha256.convert(bytes).bytes);

  final oneHash = sha256Hash([1]);
  final versionHash = oneHash;
  final nameHash = sha256Hash(utf8.encode(name));
  final tickerHash = sha256Hash(utf8.encode(ticker));
  final decimalsHash = sha256Hash([decimals]);

  final isFreezableHash = sha256Hash([isFreezable ? 1 : 0]);

  final magic = networkMagic[network]!;
  final networkBytes = ByteData(4)..setUint32(0, magic, Endian.big);
  final networkHash = sha256Hash(networkBytes.buffer.asUint8List());

  final creationEntityBytes = creationEntityPublicKey is String
      ? getUint8ArrayFromHex(creationEntityPublicKey)
      : creationEntityPublicKey as Uint8List;

  final bool isL1 = creationEntityBytes.isEmpty ||
      (creationEntityBytes.length == 33 &&
          creationEntityBytes.every((byte) => byte == 0));

  final creationEntityPublicKeyHash = isL1
      ? oneHash
      : (() {
          final layerData = Uint8List(34);
          layerData[0] = 2;
          layerData.setRange(1, 34, creationEntityBytes);
          return sha256Hash(layerData);
        })();

  final issuerBytes = issuerPublicKey is String
      ? getUint8ArrayFromHex(issuerPublicKey)
      : issuerPublicKey as Uint8List;
  final issuerPublicKeyHash = sha256Hash(issuerBytes);

  final maxSupplyBytes = _bigintTo16ByteArray(maxSupply);
  final maxSupplyHash = sha256Hash(maxSupplyBytes);

  return TokenIdentifierHashes(
    versionHash: versionHash,
    issuerPublicKeyHash: issuerPublicKeyHash,
    nameHash: nameHash,
    tickerHash: tickerHash,
    decimalsHash: decimalsHash,
    maxSupplyHash: maxSupplyHash,
    isFreezableHash: isFreezableHash,
    networkHash: networkHash,
    creationEntityPublicKeyHash: creationEntityPublicKeyHash,
  );
}

Uint8List _bigintTo16ByteArray(BigInt value) {
  BigInt valueToTrack = value;
  final Uint8List buffer = Uint8List(16);
  for (int i = 15; i >= 0 && valueToTrack > BigInt.zero; i--) {
    buffer[i] = (valueToTrack & BigInt.from(255)).toInt();
    valueToTrack >>= 8;
  }
  return buffer;
}

Uint8List getTokenIdentifierWithHashes(TokenIdentifierHashes hashes) {
  final List<Uint8List> allHashes = [
    hashes.versionHash,
    hashes.issuerPublicKeyHash,
    hashes.nameHash,
    hashes.tickerHash,
    hashes.decimalsHash,
    hashes.maxSupplyHash,
    hashes.isFreezableHash,
    hashes.networkHash,
    hashes.creationEntityPublicKeyHash,
  ];

  final int totalLength = allHashes.fold(0, (acc, h) => acc + h.length);
  final Uint8List concatenated = Uint8List(totalLength);
  int offset = 0;
  for (final h in allHashes) {
    concatenated.setRange(offset, offset + h.length, h);
    offset += h.length;
  }

  return Uint8List.fromList(sha256.convert(concatenated).bytes);
}

// Bit conversion helper (assuming it is shared with spark_address.dart)
Uint8List convertBits(Uint8List data, int from, int to, bool pad) {
  int acc = 0;
  int bits = 0;
  final List<int> result = [];
  final int maxv = (1 << to) - 1;

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

class SparkHumanReadableTokenIdentifier {
  final String tokenIdentifier;
  final SparkNetworkType network;

  SparkHumanReadableTokenIdentifier({required this.tokenIdentifier, required this.network});
}