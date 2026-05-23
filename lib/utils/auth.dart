import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:spark_dart/spark_wallet/spark_wallet.dart';
import '../api/client.dart';
import '../types/index.dart';
import 'hex.dart';

/// Abstract definition for a Spark Wallet to avoid direct SDK dependencies if needed
abstract class BaseSparkWallet {
  Future<String> signMessageWithIdentityKey(String message, bool isUtf8);
}

/// AuthManager handles the challenge-response authentication flow
class AuthManager {
  final ApiClient apiClient;
  final String pubkey;
  
  SparkWallet? _wallet;
  Signer? _signer;

  /// Create an AuthManager with either a wallet or a custom signer
  AuthManager(
    this.apiClient,
    this.pubkey,
    dynamic signerOrWallet,
  ) {
    if (signerOrWallet is SparkWallet) {
      _wallet = signerOrWallet;
    } else if (signerOrWallet is Signer) {
      _signer = signerOrWallet;
    } else {
      throw ArgumentError(
          "signerOrWallet must be an instance of BaseSparkWallet or Signer");
    }
  }

  /// Sign a message with either the wallet's identity key or the custom signer
  Future<String> _signMessage(String message) async {
    try {
      if (_wallet != null) {
        // Use wallet's public signMessageWithIdentityKey method
        return await _wallet!.signMessageWithIdentityKey(message, true);
      } else if (_signer != null) {
        // Use custom signer - signs raw bytes of the hash
        final List<int> messageBytes = message.startsWith("0x")
            ? getUint8ArrayFromHex(message.substring(2))
            : utf8.encode(message); // If not hex, treat as UTF8

        // Generate SHA-256 hash
        final messageHash = sha256.convert(messageBytes).bytes;

        final signature = await _signer!.signMessage(Uint8List.fromList(messageHash));
        return getHexFromUint8Array(signature);
      } else {
        throw Exception("No wallet or signer available");
      }
    } catch (e) {
      throw Exception("Failed to sign message: $e");
    }
  }

  /// Authenticate with the AMM API and get an access token
  Future<String> authenticate() async {
    try {
      // Step 1: Get challenge
      final challengeRequest = ChallengeRequest(
        publicKey: pubkey,
      );

      final challengeResponseMap = await apiClient.ammPost<Map<String, dynamic>>(
        "/v1/auth/challenge",
        challengeRequest.toJson(),
      );
      
      ChallengeResponse? challengeResponse;
      try {
        challengeResponse = ChallengeResponse.fromJson(challengeResponseMap);
      } catch (_) {}
      

      if (challengeResponse == null || challengeResponse.challenge.isEmpty) {
        throw Exception("No challenge received from server");
      }

      // Step 2: Sign the challenge
      // Use challengeString if available (UTF-8 friendly for wallets)
      final messageToSign = challengeResponse.challengeString.isNotEmpty
        ? challengeResponse.challengeString
        : challengeResponse.challenge;
      final signature = await _signMessage(messageToSign);

      // Step 3: Verify signature and get access token
      final verifyRequest = VerifyRequest(
        publicKey: pubkey,
        signature: signature,
      );

      final verifyResponseMap = await apiClient.ammPost<Map<String, dynamic>>(
        "/v1/auth/verify",
        verifyRequest.toJson(),
      );
      
      VerifyResponse? verifyResponse;
      try {
        verifyResponse = VerifyResponse.fromJson(verifyResponseMap);
      } catch (_) {}

      if (verifyResponse == null || verifyResponse.accessToken.isEmpty) {
        throw Exception("No access token received from server");
      }

      // Set the token in the API client
      apiClient.setAuthToken(verifyResponse.accessToken);

      return verifyResponse.accessToken;
    } catch (e) {
      throw Exception("Authentication failed: $e");
    }
  }
}