import 'dart:typed_data';

/// Spark network types - represents the actual Spark blockchain network
/// Used for address encoding, token identifiers, and wallet operations
typedef SparkNetworkType = String;

class SparkNetworkTypes {
  static const SparkNetworkType mainnet = "MAINNET";
  static const SparkNetworkType regtest = "REGTEST";
  static const SparkNetworkType testnet = "TESTNET";
  static const SparkNetworkType signet = "SIGNET";
  static const SparkNetworkType local = "LOCAL";
}

/// Client environment types - represents the client configuration environment
/// Used for API endpoints, settlement services, and client behavior
typedef ClientEnvironment = String;

class ClientEnvironments {
  static const ClientEnvironment mainnet = "mainnet";
  static const ClientEnvironment regtest = "regtest";
  static const ClientEnvironment testnet = "testnet";
  static const ClientEnvironment signet = "signet";
  static const ClientEnvironment local = "local";
}

/// Client network configuration class
class ClientNetworkConfig {
  final String ammGatewayUrl;
  final String mempoolApiUrl;
  final String explorerUrl;
  final String? sparkScanUrl;

  ClientNetworkConfig({
    required this.ammGatewayUrl,
    required this.mempoolApiUrl,
    required this.explorerUrl,
    this.sparkScanUrl,
  });
}

/// Configuration for FlashnetClient constructor
class FlashnetClientConfig {
  final SparkNetworkType sparkNetworkType;
  
  /// Client configuration - can be either a String (Environment) or ClientNetworkConfig
  final Object clientConfig;
  final bool? autoAuthenticate;

  FlashnetClientConfig({
    required this.sparkNetworkType,
    required this.clientConfig,
    this.autoAuthenticate,
  });
}

class FlashnetClientCustomConfig {
  final SparkNetworkType sparkNetworkType;
  final ClientNetworkConfig clientNetworkConfig;
  final bool? autoAuthenticate;

  FlashnetClientCustomConfig({
    required this.sparkNetworkType,
    required this.clientNetworkConfig,
    this.autoAuthenticate,
  });
}

class FlashnetClientEnvironmentConfig {
  final SparkNetworkType sparkNetworkType;
  final ClientEnvironment clientEnvironment;
  final bool? autoAuthenticate;

  FlashnetClientEnvironmentConfig({
    required this.sparkNetworkType,
    required this.clientEnvironment,
    this.autoAuthenticate,
  });
}

/// Legacy configuration for backward compatibility
@Deprecated('Use FlashnetClientConfig instead')
class FlashnetClientLegacyConfig {
  final NetworkType? network;
  final bool? autoAuthenticate;

  FlashnetClientLegacyConfig({this.network, this.autoAuthenticate});
}

// BACKWARD COMPATIBILITY TYPES

@Deprecated('Use SparkNetworkType instead')
typedef NetworkType = String;

class NetworkTypes {
  static const NetworkType mainnet = "MAINNET";
  static const NetworkType regtest = "REGTEST";
  static const NetworkType testnet = "TESTNET";
  static const NetworkType signet = "SIGNET";
  static const NetworkType local = "LOCAL";
}

// TYPE CONVERSION UTILITIES

@Deprecated('For migration purposes only')
SparkNetworkType getSparkNetworkFromLegacy(NetworkType networkType) {
  return networkType == "LOCAL" ? SparkNetworkTypes.regtest : networkType;
}

@Deprecated('For migration purposes only')
ClientEnvironment getClientEnvironmentFromLegacy(NetworkType networkType) {
  return networkType.toLowerCase();
}

bool isSparkNetworkType(dynamic value) {
  return value is String && 
    ["MAINNET", "REGTEST", "TESTNET", "SIGNET", "LOCAL"].contains(value);
}

bool isClientEnvironment(dynamic value) {
  return value is String && 
    ["mainnet", "regtest", "testnet", "signet", "local"].contains(value);
}

class WalletConfig {
  final String mnemonic;
  @Deprecated('Use SparkNetworkType instead')
  final NetworkType network;

  WalletConfig({required this.mnemonic, required this.network});
}

class SparkAddressData {
  final String identityPublicKey;
  @Deprecated('Use SparkNetworkType instead')
  final NetworkType network;

  SparkAddressData({required this.identityPublicKey, required this.network});
}

class SparkAddressDataNew {
  final String identityPublicKey;
  final SparkNetworkType network;

  SparkAddressDataNew({required this.identityPublicKey, required this.network});
}

abstract class Signer {
  Future<Uint8List> signMessage(Uint8List message);
}

// Authentication types

class ChallengeRequest {
  final String publicKey;
  ChallengeRequest({required this.publicKey});
  Map<String, dynamic> toJson() => {'publicKey': publicKey};
}

class ChallengeResponse {
  final String challenge;
  final String challengeString;
  final String requestId;

  ChallengeResponse({
    required this.challenge,
    required this.challengeString,
    required this.requestId,
  });

  factory ChallengeResponse.fromJson(Map<String, dynamic> json) => ChallengeResponse(
    challenge: json['challenge'],
    challengeString: json['challengeString'],
    requestId: json['requestId'],
  );
}

class VerifyRequest {
  final String publicKey;
  final String signature;
  VerifyRequest({required this.publicKey, required this.signature});
  Map<String, dynamic> toJson() => {'publicKey': publicKey, 'signature': signature};
}

class VerifyResponse {
  final String accessToken;
  VerifyResponse({required this.accessToken});
  factory VerifyResponse.fromJson(Map<String, dynamic> json) => 
    VerifyResponse(accessToken: json['accessToken']);
}

// Error types
typedef ErrorSeverity = String;

class FlashnetGatewayErrorSchema {
  final String errorCode;
  final String errorCategory;
  final String message;
  final dynamic details;
  final String requestId;
  final String timestamp;
  final String service;
  final String severity;
  final String? remediation;

  FlashnetGatewayErrorSchema({
    required this.errorCode,
    required this.errorCategory,
    required this.message,
    this.details,
    required this.requestId,
    required this.timestamp,
    required this.service,
    required this.severity,
    this.remediation,
  });

  factory FlashnetGatewayErrorSchema.fromJson(Map<String, dynamic> json) => FlashnetGatewayErrorSchema(
    errorCode: json['errorCode'],
    errorCategory: json['errorCategory'],
    message: json['message'],
    details: json['details'],
    requestId: json['requestId'],
    timestamp: json['timestamp'],
    service: json['service'],
    severity: json['severity'],
    remediation: json['remediation'],
  );
}

// Host types

class RegisterHostRequest {
  final String namespace;
  final int minFeeBps;
  final String feeRecipientPublicKey;
  final String nonce;
  final String signature;

  RegisterHostRequest({
    required this.namespace,
    required this.minFeeBps,
    required this.feeRecipientPublicKey,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'namespace': namespace,
    'minFeeBps': minFeeBps,
    'feeRecipientPublicKey': feeRecipientPublicKey,
    'nonce': nonce,
    'signature': signature,
  };
}

class RegisterHostResponse {
  final String namespace;
  final String message;

  RegisterHostResponse({required this.namespace, required this.message});

  factory RegisterHostResponse.fromJson(Map<String, dynamic> json) => 
    RegisterHostResponse(namespace: json['namespace'], message: json['message']);
}

class GetHostResponse {
  final String namespace;
  final String feeRecipientPublicKey;
  final int minFeeBps;
  final double flashnetSplitPercentage;
  final String createdAt;

  GetHostResponse({
    required this.namespace,
    required this.feeRecipientPublicKey,
    required this.minFeeBps,
    required this.flashnetSplitPercentage,
    required this.createdAt,
  });

  factory GetHostResponse.fromJson(Map<String, dynamic> json) => GetHostResponse(
    namespace: json['namespace'],
    feeRecipientPublicKey: json['feeRecipientPublicKey'],
    minFeeBps: json['minFeeBps'],
    flashnetSplitPercentage: (json['flashnetSplitPercentage'] as num).toDouble(),
    createdAt: json['createdAt'],
  );
}

class WithdrawHostFeesRequest {
  final String lpIdentityPublicKey;
  final String? assetBAmount;
  final String nonce;
  final String signature;

  WithdrawHostFeesRequest({
    required this.lpIdentityPublicKey,
    this.assetBAmount,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'assetBAmount': assetBAmount,
    'nonce': nonce,
    'signature': signature,
  };
}

class WithdrawHostFeesResponse {
  final String requestId;
  final bool accepted;
  final String? assetAWithdrawn;
  final String? assetBWithdrawn;
  final String? transferId;
  final String? error;

  WithdrawHostFeesResponse({
    required this.requestId,
    required this.accepted,
    this.assetAWithdrawn,
    this.assetBWithdrawn,
    this.transferId,
    this.error,
  });

  factory WithdrawHostFeesResponse.fromJson(Map<String, dynamic> json) => WithdrawHostFeesResponse(
    requestId: json['requestId'],
    accepted: json['accepted'],
    assetAWithdrawn: json['assetAWithdrawn'],
    assetBWithdrawn: json['assetBWithdrawn'],
    transferId: json['transferId'],
    error: json['error'],
  );
}

class GetPoolHostFeesRequest {
  final String hostNamespace;
  final String poolId;

  GetPoolHostFeesRequest({required this.hostNamespace, required this.poolId});

  Map<String, dynamic> toJson() => {'hostNamespace': hostNamespace, 'poolId': poolId};
}

class GetPoolHostFeesResponse {
  final String poolId;
  final String hostNamespace;
  final String feeRecipientType;
  final String assetAFees;
  final String assetBFees;

  GetPoolHostFeesResponse({
    required this.poolId,
    required this.hostNamespace,
    required this.feeRecipientType,
    required this.assetAFees,
    required this.assetBFees,
  });

  factory GetPoolHostFeesResponse.fromJson(Map<String, dynamic> json) => GetPoolHostFeesResponse(
    poolId: json['poolId'],
    hostNamespace: json['hostNamespace'],
    feeRecipientType: json['feeRecipientType'],
    assetAFees: json['assetAFees'],
    assetBFees: json['assetBFees'],
  );
}

class WithdrawIntegratorFeesRequest {
  final String integratorPublicKey;
  final String lpIdentityPublicKey;
  final String? assetAAmount;
  final String? assetBAmount;
  final String nonce;
  final String signature;

  WithdrawIntegratorFeesRequest({
    required this.integratorPublicKey,
    required this.lpIdentityPublicKey,
    this.assetAAmount,
    this.assetBAmount,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'integratorPublicKey': integratorPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'assetAAmount': assetAAmount,
    'assetBAmount': assetBAmount,
    'nonce': nonce,
    'signature': signature,
  };
}

class WithdrawIntegratorFeesResponse {
  final String requestId;
  final bool accepted;
  final String? assetAWithdrawn;
  final String? assetBWithdrawn;
  final String? transferId;
  final String? error;

  WithdrawIntegratorFeesResponse({
    required this.requestId,
    required this.accepted,
    this.assetAWithdrawn,
    this.assetBWithdrawn,
    this.transferId,
    this.error,
  });

  factory WithdrawIntegratorFeesResponse.fromJson(Map<String, dynamic> json) => WithdrawIntegratorFeesResponse(
    requestId: json['requestId'],
    accepted: json['accepted'],
    assetAWithdrawn: json['assetAWithdrawn'],
    assetBWithdrawn: json['assetBWithdrawn'],
    transferId: json['transferId'],
    error: json['error'],
  );
}

class CreateConstantProductPoolRequest {
  final String poolOwnerPublicKey;
  final String assetAAddress;
  final String assetBAddress;
  final String lpFeeRateBps;
  final String totalHostFeeRateBps;
  final String? hostNamespace;
  final String nonce;
  final String signature;

  CreateConstantProductPoolRequest({
    required this.poolOwnerPublicKey,
    required this.assetAAddress,
    required this.assetBAddress,
    required this.lpFeeRateBps,
    required this.totalHostFeeRateBps,
    this.hostNamespace,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'poolOwnerPublicKey': poolOwnerPublicKey,
    'assetAAddress': assetAAddress,
    'assetBAddress': assetBAddress,
    'lpFeeRateBps': lpFeeRateBps,
    'totalHostFeeRateBps': totalHostFeeRateBps,
    'hostNamespace': hostNamespace,
    'nonce': nonce,
    'signature': signature,
  };
}

// Pool Creation Types

class CreateSingleSidedPoolRequest {
  final String poolOwnerPublicKey;
  final String assetAAddress;
  final String assetBAddress;
  final String assetAInitialReserve;
  final String virtualReserveA;
  final String virtualReserveB;
  final String threshold;
  final String lpFeeRateBps;
  final String totalHostFeeRateBps;
  final String? hostNamespace;
  final String nonce;
  final String signature;

  CreateSingleSidedPoolRequest({
    required this.poolOwnerPublicKey,
    required this.assetAAddress,
    required this.assetBAddress,
    required this.assetAInitialReserve,
    required this.virtualReserveA,
    required this.virtualReserveB,
    required this.threshold,
    required this.lpFeeRateBps,
    required this.totalHostFeeRateBps,
    this.hostNamespace,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'poolOwnerPublicKey': poolOwnerPublicKey,
    'assetAAddress': assetAAddress,
    'assetBAddress': assetBAddress,
    'assetAInitialReserve': assetAInitialReserve,
    'virtualReserveA': virtualReserveA,
    'virtualReserveB': virtualReserveB,
    'threshold': threshold,
    'lpFeeRateBps': lpFeeRateBps,
    'totalHostFeeRateBps': totalHostFeeRateBps,
    'hostNamespace': hostNamespace,
    'nonce': nonce,
    'signature': signature,
  };
}

class CreatePoolResponse {
  final String poolId;
  final String message;

  CreatePoolResponse({required this.poolId, required this.message});

  factory CreatePoolResponse.fromJson(Map<String, dynamic> json) =>
      CreatePoolResponse(poolId: json['poolId'], message: json['message']);
}

class ConfirmInitialDepositRequest {
  final String poolId;
  final String assetASparkTransferId;
  final String nonce;
  final String signature;
  final String? poolOwnerPublicKey;

  ConfirmInitialDepositRequest({
    required this.poolId,
    required this.assetASparkTransferId,
    required this.nonce,
    required this.signature,
    this.poolOwnerPublicKey,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'assetASparkTransferId': assetASparkTransferId,
    'nonce': nonce,
    'signature': signature,
    'poolOwnerPublicKey': poolOwnerPublicKey,
  };
}

class ConfirmDepositResponse {
  final String poolId;
  final bool confirmed;
  final String message;

  ConfirmDepositResponse({
    required this.poolId,
    required this.confirmed,
    required this.message,
  });

  factory ConfirmDepositResponse.fromJson(Map<String, dynamic> json) =>
      ConfirmDepositResponse(
        poolId: json['poolId'],
        confirmed: json['confirmed'],
        message: json['message'],
      );
}

// Liquidity Types

class AddLiquidityRequest {
  final String userPublicKey;
  final String poolId;
  final String assetASparkTransferId;
  final String assetBSparkTransferId;
  final String assetAAmountToAdd;
  final String assetBAmountToAdd;
  final String assetAMinAmountIn;
  final String assetBMinAmountIn;
  final String nonce;
  final String signature;

  AddLiquidityRequest({
    required this.userPublicKey,
    required this.poolId,
    required this.assetASparkTransferId,
    required this.assetBSparkTransferId,
    required this.assetAAmountToAdd,
    required this.assetBAmountToAdd,
    required this.assetAMinAmountIn,
    required this.assetBMinAmountIn,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'poolId': poolId,
    'assetASparkTransferId': assetASparkTransferId,
    'assetBSparkTransferId': assetBSparkTransferId,
    'assetAAmountToAdd': assetAAmountToAdd,
    'assetBAmountToAdd': assetBAmountToAdd,
    'assetAMinAmountIn': assetAMinAmountIn,
    'assetBMinAmountIn': assetBMinAmountIn,
    'nonce': nonce,
    'signature': signature,
  };
}

class RefundDetails {
  final String? assetAAmount;
  final String? assetBAmount;
  final String? assetATransferId;
  final String? assetBTransferId;

  RefundDetails({
    this.assetAAmount,
    this.assetBAmount,
    this.assetATransferId,
    this.assetBTransferId,
  });

  factory RefundDetails.fromJson(Map<String, dynamic> json) => RefundDetails(
    assetAAmount: json['assetAAmount'],
    assetBAmount: json['assetBAmount'],
    assetATransferId: json['assetATransferId'],
    assetBTransferId: json['assetBTransferId'],
  );
}

class AddLiquidityResponse {
  final String requestId;
  final bool accepted;
  final String? lpTokensMinted;
  final String? assetAAmountUsed;
  final String? assetBAmountUsed;
  final String? error;
  final RefundDetails? refund;

  AddLiquidityResponse({
    required this.requestId,
    required this.accepted,
    this.lpTokensMinted,
    this.assetAAmountUsed,
    this.assetBAmountUsed,
    this.error,
    this.refund,
  });

  factory AddLiquidityResponse.fromJson(Map<String, dynamic> json) =>
      AddLiquidityResponse(
        requestId: json['requestId'],
        accepted: json['accepted'],
        lpTokensMinted: json['lpTokensMinted'],
        assetAAmountUsed: json['assetAAmountUsed'],
        assetBAmountUsed: json['assetBAmountUsed'],
        error: json['error'],
        refund: json['refund'] != null
            ? RefundDetails.fromJson(json['refund'])
            : null,
      );
}

class RemoveLiquidityRequest {
  final String userPublicKey;
  final String poolId;
  final String lpTokensToRemove;
  final String nonce;
  final String signature;

  RemoveLiquidityRequest({
    required this.userPublicKey,
    required this.poolId,
    required this.lpTokensToRemove,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'poolId': poolId,
    'lpTokensToRemove': lpTokensToRemove,
    'nonce': nonce,
    'signature': signature,
  };
}

class RemoveLiquidityResponse {
  final String requestId;
  final bool accepted;
  final String? assetAWithdrawn;
  final String? assetBWithdrawn;
  final String? assetATransferId;
  final String? assetBTransferId;
  final String? error;

  RemoveLiquidityResponse({
    required this.requestId,
    required this.accepted,
    this.assetAWithdrawn,
    this.assetBWithdrawn,
    this.assetATransferId,
    this.assetBTransferId,
    this.error,
  });

  factory RemoveLiquidityResponse.fromJson(Map<String, dynamic> json) =>
      RemoveLiquidityResponse(
        requestId: json['requestId'],
        accepted: json['accepted'],
        assetAWithdrawn: json['assetAWithdrawn'],
        assetBWithdrawn: json['assetBWithdrawn'],
        assetATransferId: json['assetATransferId'],
        assetBTransferId: json['assetBTransferId'],
        error: json['error'],
      );
}

class SimulateAddLiquidityRequest {
  final String poolId;
  final String assetAAmount;
  final String assetBAmount;

  SimulateAddLiquidityRequest({
    required this.poolId,
    required this.assetAAmount,
    required this.assetBAmount,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'assetAAmount': assetAAmount,
    'assetBAmount': assetBAmount,
  };
}

class SimulateAddLiquidityResponse {
  final String lpTokensToMint;
  final String assetAAmountToAdd;
  final String assetBAmountToAdd;
  final String assetARefundAmount;
  final String assetBRefundAmount;
  final String poolSharePercentage;
  final String? warningMessage;

  SimulateAddLiquidityResponse({
    required this.lpTokensToMint,
    required this.assetAAmountToAdd,
    required this.assetBAmountToAdd,
    required this.assetARefundAmount,
    required this.assetBRefundAmount,
    required this.poolSharePercentage,
    this.warningMessage,
  });

  factory SimulateAddLiquidityResponse.fromJson(Map<String, dynamic> json) =>
      SimulateAddLiquidityResponse(
        lpTokensToMint: json['lpTokensToMint'],
        assetAAmountToAdd: json['assetAAmountToAdd'],
        assetBAmountToAdd: json['assetBAmountToAdd'],
        assetARefundAmount: json['assetARefundAmount'],
        assetBRefundAmount: json['assetBRefundAmount'],
        poolSharePercentage: json['poolSharePercentage'],
        warningMessage: json['warningMessage'],
      );
}

class SimulateRemoveLiquidityRequest {
  final String poolId;
  final String providerPublicKey;
  final String lpTokensToRemove;

  SimulateRemoveLiquidityRequest({
    required this.poolId,
    required this.providerPublicKey,
    required this.lpTokensToRemove,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'providerPublicKey': providerPublicKey,
    'lpTokensToRemove': lpTokensToRemove,
  };
}

class SimulateRemoveLiquidityResponse {
  final String assetAAmount;
  final String assetBAmount;
  final String currentLpBalance;
  final String poolShareRemovedPercentage;
  final String? warningMessage;

  SimulateRemoveLiquidityResponse({
    required this.assetAAmount,
    required this.assetBAmount,
    required this.currentLpBalance,
    required this.poolShareRemovedPercentage,
    this.warningMessage,
  });

  factory SimulateRemoveLiquidityResponse.fromJson(Map<String, dynamic> json) =>
      SimulateRemoveLiquidityResponse(
        assetAAmount: json['assetAAmount'],
        assetBAmount: json['assetBAmount'],
        currentLpBalance: json['currentLpBalance'],
        poolShareRemovedPercentage: json['poolShareRemovedPercentage'],
        warningMessage: json['warningMessage'],
      );
}

// Swap Types

class ExecuteSwapRequest {
  final String userPublicKey;
  final String poolId;
  final String assetInAddress;
  final String assetOutAddress;
  final String amountIn;
  final String? maxSlippageBps;
  final String minAmountOut;
  final String? assetInSparkTransferId;
  final String nonce;
  final String totalIntegratorFeeRateBps;
  final String integratorPublicKey;
  final String signature;

  ExecuteSwapRequest({
    required this.userPublicKey,
    required this.poolId,
    required this.assetInAddress,
    required this.assetOutAddress,
    required this.amountIn,
    this.maxSlippageBps,
    required this.minAmountOut,
    this.assetInSparkTransferId,
    required this.nonce,
    required this.totalIntegratorFeeRateBps,
    required this.integratorPublicKey,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'poolId': poolId,
    'assetInAddress': assetInAddress,
    'assetOutAddress': assetOutAddress,
    'amountIn': amountIn,
    'maxSlippageBps': maxSlippageBps,
    'minAmountOut': minAmountOut,
    'assetInSparkTransferId': assetInSparkTransferId,
    'nonce': nonce,
    'totalIntegratorFeeRateBps': totalIntegratorFeeRateBps,
    'integratorPublicKey': integratorPublicKey,
    'signature': signature,
  };
}

class SwapResponse {
  final String requestId;
  final bool accepted;
  final String? amountOut;
  final String? feeAmount;
  final String? executionPrice;
  final String? assetOutAddress;
  final String? assetInAddress;
  final String? outboundTransferId;
  final String? error;
  final String? refundedAssetAddress;
  final String? refundedAmount;
  final String? refundTransferId;

  SwapResponse({
    required this.requestId,
    required this.accepted,
    this.amountOut,
    this.feeAmount,
    this.executionPrice,
    this.assetOutAddress,
    this.assetInAddress,
    this.outboundTransferId,
    this.error,
    this.refundedAssetAddress,
    this.refundedAmount,
    this.refundTransferId,
  });

  factory SwapResponse.fromJson(Map<String, dynamic> json) => SwapResponse(
    requestId: json['requestId'],
    accepted: json['accepted'],
    amountOut: json['amountOut'],
    feeAmount: json['feeAmount'],
    executionPrice: json['executionPrice'],
    assetOutAddress: json['assetOutAddress'],
    assetInAddress: json['assetInAddress'],
    outboundTransferId: json['outboundTransferId'],
    error: json['error'],
    refundedAssetAddress: json['refundedAssetAddress'],
    refundedAmount: json['refundedAmount'],
    refundTransferId: json['refundTransferId'],
  );
}

class SimulateSwapRequest {
  final String poolId;
  final String assetInAddress;
  final String assetOutAddress;
  final String amountIn;
  final int? integratorBps;

  SimulateSwapRequest({
    required this.poolId,
    required this.assetInAddress,
    required this.assetOutAddress,
    required this.amountIn,
    this.integratorBps,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'assetInAddress': assetInAddress,
    'assetOutAddress': assetOutAddress,
    'amountIn': amountIn,
    'integratorBps': integratorBps,
  };
}

class SimulateSwapResponse {
  final String amountOut;
  final String? executionPrice;
  final String? feePaidAssetIn;
  final String? priceImpactPct;
  final String? warningMessage;

  SimulateSwapResponse({
    required this.amountOut,
    this.executionPrice,
    this.feePaidAssetIn,
    this.priceImpactPct,
    this.warningMessage,
  });

  factory SimulateSwapResponse.fromJson(Map<String, dynamic> json) =>
      SimulateSwapResponse(
        amountOut: json['amountOut'],
        executionPrice: json['executionPrice'],
        feePaidAssetIn: json['feePaidAssetIn'],
        priceImpactPct: json['priceImpactPct'],
        warningMessage: json['warningMessage'],
      );
}

// Route Swap Types

class RouteHopRequest {
  final String poolId;
  final String assetInAddress;
  final String assetOutAddress;
  final String? hopIntegratorFeeRateBps;

  RouteHopRequest({
    required this.poolId,
    required this.assetInAddress,
    required this.assetOutAddress,
    this.hopIntegratorFeeRateBps,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'assetInAddress': assetInAddress,
    'assetOutAddress': assetOutAddress,
    'hopIntegratorFeeRateBps': hopIntegratorFeeRateBps,
  };
}

class RouteHop {
  final String poolId;
  final String assetInAddress;
  final String assetOutAddress;

  RouteHop({
    required this.poolId,
    required this.assetInAddress,
    required this.assetOutAddress,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'assetInAddress': assetInAddress,
    'assetOutAddress': assetOutAddress,
  };
}

class ExecuteRouteSwapRequest {
  final String userPublicKey;
  final List<RouteHopRequest> hops;
  final String initialSparkTransferId;
  final String inputAmount;
  final String maxRouteSlippageBps;
  final String minAmountOut;
  final String nonce;
  final String signature;
  final String? integratorFeeRateBps;
  final String? integratorPublicKey;

  ExecuteRouteSwapRequest({
    required this.userPublicKey,
    required this.hops,
    required this.initialSparkTransferId,
    required this.inputAmount,
    required this.maxRouteSlippageBps,
    required this.minAmountOut,
    required this.nonce,
    required this.signature,
    this.integratorFeeRateBps,
    this.integratorPublicKey,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'hops': hops.map((h) => h.toJson()).toList(),
    'initialSparkTransferId': initialSparkTransferId,
    'inputAmount': inputAmount,
    'maxRouteSlippageBps': maxRouteSlippageBps,
    'minAmountOut': minAmountOut,
    'nonce': nonce,
    'signature': signature,
    'integratorFeeRateBps': integratorFeeRateBps,
    'integratorPublicKey': integratorPublicKey,
  };
}

class ExecuteRouteSwapResponse {
  final String requestId;
  final bool accepted;
  final String outputAmount;
  final String executionPrice;
  final String finalOutboundTransferId;
  final String? error;
  final String? refundedAssetPublicKey;
  final String? refundedAmount;
  final String? refundTransferId;

  ExecuteRouteSwapResponse({
    required this.requestId,
    required this.accepted,
    required this.outputAmount,
    required this.executionPrice,
    required this.finalOutboundTransferId,
    this.error,
    this.refundedAssetPublicKey,
    this.refundedAmount,
    this.refundTransferId,
  });

  factory ExecuteRouteSwapResponse.fromJson(Map<String, dynamic> json) =>
      ExecuteRouteSwapResponse(
        requestId: json['requestId'],
        accepted: json['accepted'],
        outputAmount: json['outputAmount'],
        executionPrice: json['executionPrice'],
        finalOutboundTransferId: json['finalOutboundTransferId'],
        error: json['error'],
        refundedAssetPublicKey: json['refundedAssetPublicKey'],
        refundedAmount: json['refundedAmount'],
        refundTransferId: json['refundTransferId'],
      );
}

class SimulateRouteSwapRequest {
  final List<RouteHop> hops;
  final String amountIn;
  final String maxRouteSlippageBps;

  SimulateRouteSwapRequest({
    required this.hops,
    required this.amountIn,
    required this.maxRouteSlippageBps,
  });

  Map<String, dynamic> toJson() => {
    'hops': hops.map((h) => h.toJson()).toList(),
    'amountIn': amountIn,
    'maxRouteSlippageBps': maxRouteSlippageBps,
  };
}

class HopResult {
  final String poolId;
  final String amountIn;
  final String amountOut;
  final String priceImpactPct;

  HopResult({
    required this.poolId,
    required this.amountIn,
    required this.amountOut,
    required this.priceImpactPct,
  });

  factory HopResult.fromJson(Map<String, dynamic> json) => HopResult(
    poolId: json['poolId'],
    amountIn: json['amountIn'],
    amountOut: json['amountOut'],
    priceImpactPct: json['priceImpactPct'],
  );
}

class SimulateRouteSwapResponse {
  final String outputAmount;
  final String executionPrice;
  final String totalLpFees;
  final String totalHostFees;
  final String totalPriceImpactPct;
  final List<HopResult> hopBreakdown;
  final String? warningMessage;

  SimulateRouteSwapResponse({
    required this.outputAmount,
    required this.executionPrice,
    required this.totalLpFees,
    required this.totalHostFees,
    required this.totalPriceImpactPct,
    required this.hopBreakdown,
    this.warningMessage,
  });

  factory SimulateRouteSwapResponse.fromJson(Map<String, dynamic> json) =>
      SimulateRouteSwapResponse(
        outputAmount: json['outputAmount'],
        executionPrice: json['executionPrice'],
        totalLpFees: json['totalLpFees'],
        totalHostFees: json['totalHostFees'],
        totalPriceImpactPct: json['totalPriceImpactPct'],
        hopBreakdown: (json['hopBreakdown'] as List)
            .map((h) => HopResult.fromJson(h))
            .toList(),
        warningMessage: json['warningMessage'],
      );
}

// Legacy alias
typedef RouteSwapSimulationResponse = SimulateRouteSwapResponse;

// Discovery Types

class AmmPool {
  final String lpPublicKey;
  final String? hostName;
  final int hostFeeBps;
  final int lpFeeBps;
  final String assetAAddress;
  final String assetBAddress;
  final String? assetAReserve;
  final String? assetBReserve;
  final String? virtualReserveA;
  final String? virtualReserveB;
  final double? thresholdPct;
  final String? currentPriceAInB;
  final String? tvlAssetB;
  final String? volume24hAssetB;
  final String? priceChangePercent24h;
  final String? curveType;
  final String? initialReserveA;
  final String? bondingProgressPercent;
  final String? graduationThresholdAmount;
  final String createdAt;
  final String updatedAt;
  final int? currentTick;
  final int? tickSpacing;
  final String? totalLiquidity;

  AmmPool({
    required this.lpPublicKey,
    this.hostName,
    required this.hostFeeBps,
    required this.lpFeeBps,
    required this.assetAAddress,
    required this.assetBAddress,
    this.assetAReserve,
    this.assetBReserve,
    this.virtualReserveA,
    this.virtualReserveB,
    this.thresholdPct,
    this.currentPriceAInB,
    this.tvlAssetB,
    this.volume24hAssetB,
    this.priceChangePercent24h,
    this.curveType,
    this.initialReserveA,
    this.bondingProgressPercent,
    this.graduationThresholdAmount,
    required this.createdAt,
    required this.updatedAt,
    this.currentTick,
    this.tickSpacing,
    this.totalLiquidity,
  });

  factory AmmPool.fromJson(Map<String, dynamic> json) => AmmPool(
    lpPublicKey: json['lpPublicKey'],
    hostName: json['hostName'],
    hostFeeBps: json['hostFeeBps'],
    lpFeeBps: json['lpFeeBps'],
    assetAAddress: json['assetAAddress'],
    assetBAddress: json['assetBAddress'],
    assetAReserve: json['assetAReserve'],
    assetBReserve: json['assetBReserve'],
    virtualReserveA: json['virtualReserveA'],
    virtualReserveB: json['virtualReserveB'],
    thresholdPct: (json['thresholdPct'] as num?)?.toDouble(),
    currentPriceAInB: json['currentPriceAInB'],
    tvlAssetB: json['tvlAssetB'],
    volume24hAssetB: json['volume24hAssetB'],
    priceChangePercent24h: json['priceChangePercent24h'],
    curveType: json['curveType'],
    initialReserveA: json['initialReserveA'],
    bondingProgressPercent: json['bondingProgressPercent'],
    graduationThresholdAmount: json['graduationThresholdAmount'],
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
    currentTick: json['currentTick'],
    tickSpacing: json['tickSpacing'],
    totalLiquidity: json['totalLiquidity'],
  );

  Map<String, dynamic> toJson() => {
    'lpPublicKey': lpPublicKey,
    'hostName': hostName,
    'hostFeeBps': hostFeeBps,
    'lpFeeBps': lpFeeBps,
    'assetAAddress': assetAAddress,
    'assetBAddress': assetBAddress,
    'assetAReserve': assetAReserve,
    'assetBReserve': assetBReserve,
    'virtualReserveA': virtualReserveA,
    'virtualReserveB': virtualReserveB,
    'thresholdPct': thresholdPct,
    'currentPriceAInB': currentPriceAInB,
    'tvlAssetB': tvlAssetB,
    'volume24hAssetB': volume24hAssetB,
    'priceChangePercent24h': priceChangePercent24h,
    'curveType': curveType,
    'initialReserveA': initialReserveA,
    'bondingProgressPercent': bondingProgressPercent,
    'graduationThresholdAmount': graduationThresholdAmount,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'currentTick': currentTick,
    'tickSpacing': tickSpacing,
    'totalLiquidity': totalLiquidity,
  };
}

typedef PoolSortOrder = String;

class PoolSortOrders {
  static const PoolSortOrder createdAtDesc = "CREATED_AT_DESC";
  static const PoolSortOrder createdAtAsc = "CREATED_AT_ASC";
  static const PoolSortOrder volume24hDesc = "VOLUME24H_DESC";
  static const PoolSortOrder volume24hAsc = "VOLUME24H_ASC";
  static const PoolSortOrder tvlDesc = "TVL_DESC";
  static const PoolSortOrder tvlAsc = "TVL_ASC";
}

class ListPoolsQuery {
  final String? assetAAddress;
  final String? assetBAddress;
  final List<String>? hostNames;
  final double? minVolume24h;
  final double? minTvl;
  final List<String>? curveTypes;
  final PoolSortOrder? sort;
  final int? limit;
  final int? offset;
  final String? afterUpdatedAt;

  ListPoolsQuery({
    this.assetAAddress,
    this.assetBAddress,
    this.hostNames,
    this.minVolume24h,
    this.minTvl,
    this.curveTypes,
    this.sort,
    this.limit,
    this.offset,
    this.afterUpdatedAt,
  });

  Map<String, dynamic> toJson() => {
    'assetAAddress': assetAAddress,
    'assetBAddress': assetBAddress,
    'hostNames': hostNames,
    'minVolume24h': minVolume24h,
    'minTvl': minTvl,
    'curveTypes': curveTypes,
    'sort': sort,
    'limit': limit,
    'offset': offset,
    'afterUpdatedAt': afterUpdatedAt,
  };
}

class ListPoolsResponse {
  final List<AmmPool> pools;
  final int totalCount;

  ListPoolsResponse({required this.pools, required this.totalCount});

  factory ListPoolsResponse.fromJson(Map<String, dynamic> json) =>
      ListPoolsResponse(
        pools: (json['pools'] as List).map((p) => AmmPool.fromJson(p)).toList(),
        totalCount: json['totalCount'],
      );
}

class PoolDetailsResponse {
  final String lpPublicKey;
  final String? hostName;
  final int hostFeeBps;
  final int lpFeeBps;
  final String assetAAddress;
  final String assetBAddress;
  final String assetAReserve;
  final String assetBReserve;
  final String? virtualReserveA;
  final String? virtualReserveB;
  final double? thresholdPct;
  final String? currentPriceAInB;
  final String tvlAssetB;
  final String volume24hAssetB;
  final String? priceChangePercent24h;
  final String curveType;
  final String? initialReserveA;
  final String? bondingProgressPercent;
  final String? graduationThresholdAmount;
  final String createdAt;
  final String updatedAt;
  final String status;
  final int? currentTick;
  final int? tickSpacing;
  final String? sqrtPrice;
  final String? totalLiquidity;
  final int? positionCount;

  PoolDetailsResponse({
    required this.lpPublicKey,
    this.hostName,
    required this.hostFeeBps,
    required this.lpFeeBps,
    required this.assetAAddress,
    required this.assetBAddress,
    required this.assetAReserve,
    required this.assetBReserve,
    this.virtualReserveA,
    this.virtualReserveB,
    this.thresholdPct,
    this.currentPriceAInB,
    required this.tvlAssetB,
    required this.volume24hAssetB,
    this.priceChangePercent24h,
    required this.curveType,
    this.initialReserveA,
    this.bondingProgressPercent,
    this.graduationThresholdAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.currentTick,
    this.tickSpacing,
    this.sqrtPrice,
    this.totalLiquidity,
    this.positionCount,
  });

  factory PoolDetailsResponse.fromJson(Map<String, dynamic> json) =>
      PoolDetailsResponse(
        lpPublicKey: json['lpPublicKey'],
        hostName: json['hostName'],
        hostFeeBps: json['hostFeeBps'],
        lpFeeBps: json['lpFeeBps'],
        assetAAddress: json['assetAAddress'],
        assetBAddress: json['assetBAddress'],
        assetAReserve: json['assetAReserve'],
        assetBReserve: json['assetBReserve'],
        virtualReserveA: json['virtualReserveA'],
        virtualReserveB: json['virtualReserveB'],
        thresholdPct: (json['thresholdPct'] as num?)?.toDouble(),
        currentPriceAInB: json['currentPriceAInB'],
        tvlAssetB: json['tvlAssetB'],
        volume24hAssetB: json['volume24hAssetB'],
        priceChangePercent24h: json['priceChangePercent24h'],
        curveType: json['curveType'],
        initialReserveA: json['initialReserveA'],
        bondingProgressPercent: json['bondingProgressPercent'],
        graduationThresholdAmount: json['graduationThresholdAmount'],
        createdAt: json['createdAt'],
        updatedAt: json['updatedAt'],
        status: json['status'],
        currentTick: json['currentTick'],
        tickSpacing: json['tickSpacing'],
        sqrtPrice: json['sqrtPrice'],
        totalLiquidity: json['totalLiquidity'],
        positionCount: json['positionCount'],
      );
}

// LP Position Types

class LpPositionDetailsResponse {
  final String providerPublicKey;
  final String poolId;
  final String lpTokensOwned;
  final String sharePercentage;
  final String valueAssetA;
  final String valueAssetB;
  final String? principalAssetA;
  final String? principalAssetB;
  final String? unrealizedProfitLossAssetA;
  final String? unrealizedProfitLossAssetB;

  LpPositionDetailsResponse({
    required this.providerPublicKey,
    required this.poolId,
    required this.lpTokensOwned,
    required this.sharePercentage,
    required this.valueAssetA,
    required this.valueAssetB,
    this.principalAssetA,
    this.principalAssetB,
    this.unrealizedProfitLossAssetA,
    this.unrealizedProfitLossAssetB,
  });

  factory LpPositionDetailsResponse.fromJson(Map<String, dynamic> json) =>
      LpPositionDetailsResponse(
        providerPublicKey: json['providerPublicKey'],
        poolId: json['poolId'],
        lpTokensOwned: json['lpTokensOwned'],
        sharePercentage: json['sharePercentage'],
        valueAssetA: json['valueAssetA'],
        valueAssetB: json['valueAssetB'],
        principalAssetA: json['principalAssetA'],
        principalAssetB: json['principalAssetB'],
        unrealizedProfitLossAssetA: json['unrealizedProfitLossAssetA'],
        unrealizedProfitLossAssetB: json['unrealizedProfitLossAssetB'],
      );
}

class LpPositionInfo {
  final String poolId;
  final int lpFeeRateBps;
  final String assetAAddress;
  final String assetBAddress;
  final String lpTokenSupply;
  final String userLpTokens;
  final String userShareOfPoolPercent;
  final String assetAAmount;
  final String assetBAmount;

  LpPositionInfo({
    required this.poolId,
    required this.lpFeeRateBps,
    required this.assetAAddress,
    required this.assetBAddress,
    required this.lpTokenSupply,
    required this.userLpTokens,
    required this.userShareOfPoolPercent,
    required this.assetAAmount,
    required this.assetBAmount,
  });

  factory LpPositionInfo.fromJson(Map<String, dynamic> json) => LpPositionInfo(
        poolId: json['poolId'],
        lpFeeRateBps: json['lpFeeRateBps'],
        assetAAddress: json['assetAAddress'],
        assetBAddress: json['assetBAddress'],
        lpTokenSupply: json['lpTokenSupply'],
        userLpTokens: json['userLpTokens'],
        userShareOfPoolPercent: json['userShareOfPoolPercent'],
        assetAAmount: json['assetAAmount'],
        assetBAmount: json['assetBAmount'],
      );
}

class AllLpPositionsResponse {
  final String lpPublicKey;
  final List<LpPositionInfo> positions;

  AllLpPositionsResponse({required this.lpPublicKey, required this.positions});

  factory AllLpPositionsResponse.fromJson(Map<String, dynamic> json) =>
      AllLpPositionsResponse(
        lpPublicKey: json['lpPublicKey'],
        positions: (json['positions'] as List)
            .map((p) => LpPositionInfo.fromJson(p))
            .toList(),
      );
}

// Swap Event Types

class PoolSwapEvent {
  final String id;
  final String swapperPublicKey;
  final String amountIn;
  final String amountOut;
  final String assetInAddress;
  final String assetOutAddress;
  final String? price;
  final String createdAt;
  final String feePaid;
  final String inboundTransferId;
  final String outboundTransferId;

  PoolSwapEvent({
    required this.id,
    required this.swapperPublicKey,
    required this.amountIn,
    required this.amountOut,
    required this.assetInAddress,
    required this.assetOutAddress,
    this.price,
    required this.createdAt,
    required this.feePaid,
    required this.inboundTransferId,
    required this.outboundTransferId,
  });

  factory PoolSwapEvent.fromJson(Map<String, dynamic> json) => PoolSwapEvent(
        id: json['id'],
        swapperPublicKey: json['swapperPublicKey'],
        amountIn: json['amountIn'],
        amountOut: json['amountOut'],
        assetInAddress: json['assetInAddress'],
        assetOutAddress: json['assetOutAddress'],
        price: json['price'],
        createdAt: json['createdAt'],
        feePaid: json['feePaid'],
        inboundTransferId: json['inboundTransferId'],
        outboundTransferId: json['outboundTransferId'],
      );
}

class GlobalSwapEvent extends PoolSwapEvent {
  final String poolLpPublicKey;
  final String poolType;
  final String? poolAssetAAddress;
  final String? poolAssetBAddress;

  GlobalSwapEvent({
    required super.id,
    required super.swapperPublicKey,
    required super.amountIn,
    required super.amountOut,
    required super.assetInAddress,
    required super.assetOutAddress,
    super.price,
    required super.createdAt,
    required super.feePaid,
    required super.inboundTransferId,
    required super.outboundTransferId,
    required this.poolLpPublicKey,
    required this.poolType,
    this.poolAssetAAddress,
    this.poolAssetBAddress,
  });

  factory GlobalSwapEvent.fromJson(Map<String, dynamic> json) {
    final base = PoolSwapEvent.fromJson(json);
    return GlobalSwapEvent(
      id: base.id,
      swapperPublicKey: base.swapperPublicKey,
      amountIn: base.amountIn,
      amountOut: base.amountOut,
      assetInAddress: base.assetInAddress,
      assetOutAddress: base.assetOutAddress,
      price: base.price,
      createdAt: base.createdAt,
      feePaid: base.feePaid,
      inboundTransferId: base.inboundTransferId,
      outboundTransferId: base.outboundTransferId,
      poolLpPublicKey: json['poolLpPublicKey'],
      poolType: json['poolType'],
      poolAssetAAddress: json['poolAssetAAddress'],
      poolAssetBAddress: json['poolAssetBAddress'],
    );
  }
}

class UserSwapEvent {
  final String id;
  final String poolLpPublicKey;
  final String amountIn;
  final String amountOut;
  final String assetInAddress;
  final String assetOutAddress;
  final String? price;
  final String timestamp;
  final String feePaid;
  final String? poolAssetAAddress;
  final String? poolAssetBAddress;
  final String inboundTransferId;
  final String outboundTransferId;

  UserSwapEvent({
    required this.id,
    required this.poolLpPublicKey,
    required this.amountIn,
    required this.amountOut,
    required this.assetInAddress,
    required this.assetOutAddress,
    this.price,
    required this.timestamp,
    required this.feePaid,
    this.poolAssetAAddress,
    this.poolAssetBAddress,
    required this.inboundTransferId,
    required this.outboundTransferId,
  });

  factory UserSwapEvent.fromJson(Map<String, dynamic> json) => UserSwapEvent(
        id: json['id'],
        poolLpPublicKey: json['poolLpPublicKey'],
        amountIn: json['amountIn'],
        amountOut: json['amountOut'],
        assetInAddress: json['assetInAddress'],
        assetOutAddress: json['assetOutAddress'],
        price: json['price'],
        timestamp: json['timestamp'],
        feePaid: json['feePaid'],
        poolAssetAAddress: json['poolAssetAAddress'],
        poolAssetBAddress: json['poolAssetBAddress'],
        inboundTransferId: json['inboundTransferId'],
        outboundTransferId: json['outboundTransferId'],
      );
}

class ListPoolSwapsQuery {
  /// ISO8601 start time to filter swaps
  final String? startTime;
  
  /// ISO8601 end time to filter swaps
  final String? endTime;
  
  final int? limit;
  
  final int? offset;

  ListPoolSwapsQuery({
    this.startTime,
    this.endTime,
    this.limit,
    this.offset,
  });

  Map<String, dynamic> toJson() => {
    if (startTime != null) 'startTime': startTime,
    if (endTime != null) 'endTime': endTime,
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  };
}

class ListPoolSwapsResponse {
  final List<PoolSwapEvent> swaps;
  final int totalCount;

  ListPoolSwapsResponse({required this.swaps, required this.totalCount});

  factory ListPoolSwapsResponse.fromJson(Map<String, dynamic> json) =>
      ListPoolSwapsResponse(
        swaps: (json['swaps'] as List)
            .map((s) => PoolSwapEvent.fromJson(s))
            .toList(),
        totalCount: json['totalCount'],
      );
}

class ListGlobalSwapsQuery {
  final int? limit;
  final int? offset;
  final String? poolType;
  final String? assetAddress;
  
  /// ISO8601 start time to filter swaps
  final String? startTime;
  
  /// ISO8601 end time to filter swaps
  final String? endTime;

  ListGlobalSwapsQuery({
    this.limit,
    this.offset,
    this.poolType,
    this.assetAddress,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() => {
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
    if (poolType != null) 'pool_type': poolType,
    if (assetAddress != null) 'asset_address': assetAddress,
    if (startTime != null) 'start_time': startTime,
    if (endTime != null) 'end_time': endTime,
  };
}

class ListGlobalSwapsResponse {
  final List<GlobalSwapEvent> swaps;
  final int totalCount;

  ListGlobalSwapsResponse({required this.swaps, required this.totalCount});

  factory ListGlobalSwapsResponse.fromJson(Map<String, dynamic> json) =>
      ListGlobalSwapsResponse(
        swaps: (json['swaps'] as List)
            .map((s) => GlobalSwapEvent.fromJson(s))
            .toList(),
        totalCount: json['totalCount'],
      );
}

class ListUserSwapsQuery {
  final String? poolLpPubkey;
  final String? assetInAddress;
  final String? assetOutAddress;
  final double? minAmountIn;
  final double? maxAmountIn;
  final String? startTime;
  final String? endTime;
  final String? sort; // "timestampDesc" | "timestampAsc" | "amountInDesc" | "amountInAsc" | "amountOutDesc" | "amountOutAsc"
  final int? limit;
  final int? offset;

  ListUserSwapsQuery({
    this.poolLpPubkey,
    this.assetInAddress,
    this.assetOutAddress,
    this.minAmountIn,
    this.maxAmountIn,
    this.startTime,
    this.endTime,
    this.sort,
    this.limit,
    this.offset,
  });

  Map<String, dynamic> toJson() => {
    if (poolLpPubkey != null) 'poolLpPubkey': poolLpPubkey,
    if (assetInAddress != null) 'assetInAddress': assetInAddress,
    if (assetOutAddress != null) 'assetOutAddress': assetOutAddress,
    if (minAmountIn != null) 'minAmountIn': minAmountIn,
    if (maxAmountIn != null) 'maxAmountIn': maxAmountIn,
    if (startTime != null) 'startTime': startTime,
    if (endTime != null) 'endTime': endTime,
    if (sort != null) 'sort': sort,
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  };
}

class ListUserSwapsResponse {
  final List<UserSwapEvent> swaps;
  final int totalCount;

  ListUserSwapsResponse({required this.swaps, required this.totalCount});

  factory ListUserSwapsResponse.fromJson(Map<String, dynamic> json) =>
      ListUserSwapsResponse(
        swaps: (json['swaps'] as List)
            .map((s) => UserSwapEvent.fromJson(s))
            .toList(),
        totalCount: json['totalCount'],
      );
}

// Config Types

typedef FeatureName = String;

class FeatureNames {
  static const FeatureName masterKillSwitch = "master_kill_switch";
  static const FeatureName allowWithdrawFees = "allow_withdraw_fees";
  static const FeatureName allowPoolCreation = "allow_pool_creation";
  static const FeatureName allowSwaps = "allow_swaps";
  static const FeatureName allowAddLiquidity = "allow_add_liquidity";
  static const FeatureName allowRouteSwaps = "allow_route_swaps";
  static const FeatureName allowWithdrawLiquidity = "allow_withdraw_liquidity";
}

class FeatureStatusItem {
  final FeatureName feature_name;
  final bool enabled;
  final String? reason;

  FeatureStatusItem({
    required this.feature_name,
    required this.enabled,
    this.reason,
  });

  factory FeatureStatusItem.fromJson(Map<String, dynamic> json) =>
      FeatureStatusItem(
        feature_name: json['feature_name'],
        enabled: json['enabled'],
        reason: json['reason'],
      );
}

class MinAmountItem {
  final String asset_identifier;
  final String min_amount;
  final bool enabled;

  MinAmountItem({
    required this.asset_identifier,
    required this.min_amount,
    required this.enabled,
  });

  factory MinAmountItem.fromJson(Map<String, dynamic> json) => MinAmountItem(
        asset_identifier: json['asset_identifier'],
        min_amount: json['min_amount'].toString(),
        enabled: json['enabled'],
      );
}

class AllowedAssetItem {
  final String asset_identifier;
  final String? asset_name;
  final bool enabled;

  AllowedAssetItem({
    required this.asset_identifier,
    this.asset_name,
    required this.enabled,
  });

  factory AllowedAssetItem.fromJson(Map<String, dynamic> json) =>
      AllowedAssetItem(
        asset_identifier: json['asset_identifier'],
        asset_name: json['asset_name'],
        enabled: json['enabled'],
      );
}

// Intent Message Types

class ValidateAmmInitializeSingleSidedPoolData {
  final String poolOwnerPublicKey;
  final String assetAAddress;
  final String assetBAddress;
  final String assetAInitialReserve;
  final String virtualReserveA;
  final String virtualReserveB;
  final String threshold;
  final String totalHostFeeRateBps;
  final String lpFeeRateBps;
  final String nonce;

  ValidateAmmInitializeSingleSidedPoolData({
    required this.poolOwnerPublicKey,
    required this.assetAAddress,
    required this.assetBAddress,
    required this.assetAInitialReserve,
    required this.virtualReserveA,
    required this.virtualReserveB,
    required this.threshold,
    required this.totalHostFeeRateBps,
    required this.lpFeeRateBps,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
        'poolOwnerPublicKey': poolOwnerPublicKey,
        'assetAAddress': assetAAddress,
        'assetBAddress': assetBAddress,
        'assetAInitialReserve': assetAInitialReserve,
        'virtualReserveA': virtualReserveA,
        'virtualReserveB': virtualReserveB,
        'threshold': threshold,
        'totalHostFeeRateBps': totalHostFeeRateBps,
        'lpFeeRateBps': lpFeeRateBps,
        'nonce': nonce,
      };
}

class ValidateAmmSwapData {
  final String userPublicKey;
  final String lpIdentityPublicKey;
  final String? assetInSparkTransferId;
  final String assetInAddress;
  final String assetOutAddress;
  final String amountIn;
  final String minAmountOut;
  final String maxSlippageBps;
  final String nonce;
  final String totalIntegratorFeeRateBps;

  ValidateAmmSwapData({
    required this.userPublicKey,
    required this.lpIdentityPublicKey,
    this.assetInSparkTransferId,
    required this.assetInAddress,
    required this.assetOutAddress,
    required this.amountIn,
    required this.minAmountOut,
    required this.maxSlippageBps,
    required this.nonce,
    required this.totalIntegratorFeeRateBps,
  });

  Map<String, dynamic> toJson() => {
        'userPublicKey': userPublicKey,
        'lpIdentityPublicKey': lpIdentityPublicKey,
        'assetInSparkTransferId': assetInSparkTransferId,
        'assetInAddress': assetInAddress,
        'assetOutAddress': assetOutAddress,
        'amountIn': amountIn,
        'minAmountOut': minAmountOut,
        'maxSlippageBps': maxSlippageBps,
        'nonce': nonce,
        'totalIntegratorFeeRateBps': totalIntegratorFeeRateBps,
      };
}

// --- Settlement & Liquidity ---

class AmmAddLiquiditySettlementRequest {
  final String userPublicKey;
  final String lpIdentityPublicKey;
  final String assetASparkTransferId;
  final String assetBSparkTransferId;
  final String assetAAmount;
  final String assetBAmount;
  final String assetAMinAmountIn;
  final String assetBMinAmountIn;
  final String nonce;

  AmmAddLiquiditySettlementRequest({
    required this.userPublicKey,
    required this.lpIdentityPublicKey,
    required this.assetASparkTransferId,
    required this.assetBSparkTransferId,
    required this.assetAAmount,
    required this.assetBAmount,
    required this.assetAMinAmountIn,
    required this.assetBMinAmountIn,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'assetASparkTransferId': assetASparkTransferId,
    'assetBSparkTransferId': assetBSparkTransferId,
    'assetAAmount': assetAAmount,
    'assetBAmount': assetBAmount,
    'assetAMinAmountIn': assetAMinAmountIn,
    'assetBMinAmountIn': assetBMinAmountIn,
    'nonce': nonce,
  };
}

class AmmRemoveLiquiditySettlementRequest {
  final String userPublicKey;
  final String lpIdentityPublicKey;
  final String lpTokensToRemove;
  final String nonce;

  AmmRemoveLiquiditySettlementRequest({
    required this.userPublicKey,
    required this.lpIdentityPublicKey,
    required this.lpTokensToRemove,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'lpTokensToRemove': lpTokensToRemove,
    'nonce': nonce,
  };
}

// --- Compatibility Aliases ---

class Pool {
  final String pool_id;
  final String lp_pubkey;
  final String asset_a_pubkey;
  final String asset_b_pubkey;
  final String asset_a_reserve;
  final String asset_b_reserve;
  final String lp_token_supply;
  final String curve_type; // "CONSTANT_PRODUCT" | "SINGLE_SIDED"
  final int lp_fee_rate_bps;
  final int total_host_fee_rate_bps;

  Pool({
    required this.pool_id,
    required this.lp_pubkey,
    required this.asset_a_pubkey,
    required this.asset_b_pubkey,
    required this.asset_a_reserve,
    required this.asset_b_reserve,
    required this.lp_token_supply,
    required this.curve_type,
    required this.lp_fee_rate_bps,
    required this.total_host_fee_rate_bps,
  });

  factory Pool.fromJson(Map<String, dynamic> json) => Pool(
    pool_id: json['pool_id'],
    lp_pubkey: json['lp_pubkey'],
    asset_a_pubkey: json['asset_a_pubkey'],
    asset_b_pubkey: json['asset_b_pubkey'],
    asset_a_reserve: json['asset_a_reserve'],
    asset_b_reserve: json['asset_b_reserve'],
    lp_token_supply: json['lp_token_supply'],
    curve_type: json['curve_type'],
    lp_fee_rate_bps: json['lp_fee_rate_bps'],
    total_host_fee_rate_bps: json['total_host_fee_rate_bps'],
  );
}

// --- Fee & Host Validation ---

class RegisterHostIntentData {
  final String namespace;
  final int minFeeBps;
  final String feeRecipientPublicKey;
  final String nonce;

  RegisterHostIntentData({
    required this.namespace,
    required this.minFeeBps,
    required this.feeRecipientPublicKey,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'namespace': namespace,
    'minFeeBps': minFeeBps,
    'feeRecipientPublicKey': feeRecipientPublicKey,
    'nonce': nonce,
  };
}

class ValidateRouteSwapData {
  final String userPublicKey;
  final List<dynamic> hops;
  final String initialSparkTransferId;
  final String inputAmount;
  final String minFinalOutputAmount;
  final String maxRouteSlippageBps;
  final String nonce;
  final String? defaultIntegratorFeeRateBps;

  ValidateRouteSwapData({
    required this.userPublicKey,
    required this.hops,
    required this.initialSparkTransferId,
    required this.inputAmount,
    required this.minFinalOutputAmount,
    required this.maxRouteSlippageBps,
    required this.nonce,
    this.defaultIntegratorFeeRateBps,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'hops': hops,
    'initialSparkTransferId': initialSparkTransferId,
    'inputAmount': inputAmount,
    'minFinalOutputAmount': minFinalOutputAmount,
    'maxRouteSlippageBps': maxRouteSlippageBps,
    'nonce': nonce,
    'defaultIntegratorFeeRateBps': defaultIntegratorFeeRateBps,
  };
}

// --- Backward Compatibility Aliases (Deprecated) ---

@Deprecated('Use assetAAddress instead')
typedef AssetATokenPublicKey = String;

@Deprecated('Use assetBAddress instead')
typedef AssetBTokenPublicKey = String;

@Deprecated('Use assetInAddress instead')
typedef AssetInTokenPublicKey = String;

@Deprecated('Use assetOutAddress instead')
typedef AssetOutTokenPublicKey = String;

// --- Integrator Fees Validation Types ---

class ValidateAmmWithdrawIntegratorFeesData {
  final String integratorPublicKey;
  final String lpIdentityPublicKey;
  final String? assetBAmount;
  final String nonce;

  ValidateAmmWithdrawIntegratorFeesData({
    required this.integratorPublicKey,
    required this.lpIdentityPublicKey,
    this.assetBAmount,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'integratorPublicKey': integratorPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'assetBAmount': assetBAmount,
    'nonce': nonce,
  };
}

// --- Clawback Validation Data ---

class ValidateClawbackData {
  final String senderPublicKey;
  final String sparkTransferId;
  final String lpIdentityPublicKey;
  final String nonce;

  ValidateClawbackData({
    required this.senderPublicKey,
    required this.sparkTransferId,
    required this.lpIdentityPublicKey,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'senderPublicKey': senderPublicKey,
    'sparkTransferId': sparkTransferId,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'nonce': nonce,
  };
}

// --- Host Fees Types ---

class GetHostFeesRequest {
  final String hostNamespace;

  GetHostFeesRequest({required this.hostNamespace});

  Map<String, dynamic> toJson() => {'hostNamespace': hostNamespace};
}

class HostPoolFees {
  final String poolId;
  final String assetBPubkey;
  final String assetBFees;

  HostPoolFees({
    required this.poolId,
    required this.assetBPubkey,
    required this.assetBFees,
  });

  factory HostPoolFees.fromJson(Map<String, dynamic> json) => HostPoolFees(
    poolId: json['poolId'],
    assetBPubkey: json['assetBPubkey'],
    assetBFees: json['assetBFees'],
  );
}

class GetHostFeesResponse {
  final String hostNamespace;
  final String feeRecipientType;
  final List<HostPoolFees> pools;
  final String? totalAssetBFees;

  GetHostFeesResponse({
    required this.hostNamespace,
    required this.feeRecipientType,
    required this.pools,
    this.totalAssetBFees,
  });

  factory GetHostFeesResponse.fromJson(Map<String, dynamic> json) => GetHostFeesResponse(
    hostNamespace: json['hostNamespace'],
    feeRecipientType: json['feeRecipientType'],
    pools: (json['pools'] as List).map((p) => HostPoolFees.fromJson(p)).toList(),
    totalAssetBFees: json['totalAssetBFees'],
  );
}

// --- Integrator Fees Types ---

class IntegratorPoolFees {
  final String poolId;
  final String? hostNamespace;
  final String assetBPubkey;
  final String assetBFees;

  IntegratorPoolFees({
    required this.poolId,
    this.hostNamespace,
    required this.assetBPubkey,
    required this.assetBFees,
  });

  factory IntegratorPoolFees.fromJson(Map<String, dynamic> json) => IntegratorPoolFees(
    poolId: json['poolId'],
    hostNamespace: json['hostNamespace'],
    assetBPubkey: json['assetBPubkey'],
    assetBFees: json['assetBFees'],
  );
}

class GetIntegratorFeesResponse {
  final String integratorPublicKey;
  final List<IntegratorPoolFees> pools;
  final String? totalAssetBFees;

  GetIntegratorFeesResponse({
    required this.integratorPublicKey,
    required this.pools,
    this.totalAssetBFees,
  });

  factory GetIntegratorFeesResponse.fromJson(Map<String, dynamic> json) => GetIntegratorFeesResponse(
    integratorPublicKey: json['integratorPublicKey'],
    pools: (json['pools'] as List).map((p) => IntegratorPoolFees.fromJson(p)).toList(),
    totalAssetBFees: json['totalAssetBFees'],
  );
}

class GetPoolIntegratorFeesRequest {
  final String poolId;

  GetPoolIntegratorFeesRequest({required this.poolId});

  Map<String, dynamic> toJson() => {'poolId': poolId};
}

class GetPoolIntegratorFeesResponse {
  final String poolId;
  final String integratorPublicKey;
  final String assetBFees;

  GetPoolIntegratorFeesResponse({
    required this.poolId,
    required this.integratorPublicKey,
    required this.assetBFees,
  });

  factory GetPoolIntegratorFeesResponse.fromJson(Map<String, dynamic> json) => GetPoolIntegratorFeesResponse(
    poolId: json['poolId'],
    integratorPublicKey: json['integratorPublicKey'],
    assetBFees: json['assetBFees'],
  );
}

// --- Fee Withdrawal & History ---

class FeeWithdrawalRecord {
  final String lpPubkey;
  final String asset;
  final String amount;
  final String transferId;
  final String timestamp;

  FeeWithdrawalRecord({
    required this.lpPubkey,
    required this.asset,
    required this.amount,
    required this.transferId,
    required this.timestamp,
  });

  factory FeeWithdrawalRecord.fromJson(Map<String, dynamic> json) => FeeWithdrawalRecord(
    lpPubkey: json['lpPubkey'],
    asset: json['asset'],
    amount: json['amount'],
    transferId: json['transferId'],
    timestamp: json['timestamp'],
  );
}

class FeeWithdrawalHistoryResponse {
  final List<FeeWithdrawalRecord> withdrawals;
  final int totalCount;
  final int page;
  final int pageSize;
  final String? totalWithdrawn;

  FeeWithdrawalHistoryResponse({
    required this.withdrawals,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    this.totalWithdrawn,
  });

  factory FeeWithdrawalHistoryResponse.fromJson(Map<String, dynamic> json) => FeeWithdrawalHistoryResponse(
    withdrawals: (json['withdrawals'] as List).map((w) => FeeWithdrawalRecord.fromJson(w)).toList(),
    totalCount: json['totalCount'],
    page: json['page'],
    pageSize: json['pageSize'],
    totalWithdrawn: json['totalWithdrawn'],
  );
}

class FeeWithdrawalHistoryQuery {
  final int? page;
  final int? pageSize;
  final String? lpPubkey;
  final String? assetB;
  final String? fromDate;
  final String? toDate;
  final String? sortOrder; // "desc" | "asc"

  FeeWithdrawalHistoryQuery({
    this.page,
    this.pageSize,
    this.lpPubkey,
    this.assetB,
    this.fromDate,
    this.toDate,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() => {
    if (page != null) 'page': page,
    if (pageSize != null) 'pageSize': pageSize,
    if (lpPubkey != null) 'lpPubkey': lpPubkey,
    if (assetB != null) 'assetB': assetB,
    if (fromDate != null) 'fromDate': fromDate,
    if (toDate != null) 'toDate': toDate,
    if (sortOrder != null) 'sortOrder': sortOrder,
  };
}

class TransferAssetRecipient {
  final String receiverSparkAddress;
  final String assetAddress;
  final String amount;

  TransferAssetRecipient({
    required this.receiverSparkAddress,
    required this.assetAddress,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'receiverSparkAddress': receiverSparkAddress,
    'assetAddress': assetAddress,
    'amount': amount,
  };
}

// --- Escrow Intent Validation Data ---

/// Data for validating an escrow claim intent.
class ValidateEscrowClaimData {
  final String escrowId;
  final String recipientPublicKey;
  final String nonce;

  ValidateEscrowClaimData({
    required this.escrowId,
    required this.recipientPublicKey,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'escrowId': escrowId,
    'recipientPublicKey': recipientPublicKey,
    'nonce': nonce,
  };
}

/// Data for validating an escrow fund intent.
class ValidateEscrowFundData {
  final String escrowId;
  final String creatorPublicKey;
  final String sparkTransferId;
  final String nonce;

  ValidateEscrowFundData({
    required this.escrowId,
    required this.creatorPublicKey,
    required this.sparkTransferId,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'escrowId': escrowId,
    'creatorPublicKey': creatorPublicKey,
    'sparkTransferId': sparkTransferId,
    'nonce': nonce,
  };
}

/// A recipient in an escrow contract for intent validation.
class EscrowRecipient {
  final String recipientId;
  final String amount;
  final bool hasClaimed;
  final String? claimedAt;

  EscrowRecipient({
    required this.recipientId,
    required this.amount,
    required this.hasClaimed,
    this.claimedAt,
  });

  factory EscrowRecipient.fromJson(Map<String, dynamic> json) => EscrowRecipient(
    recipientId: json['recipientId'],
    amount: json['amount'],
    hasClaimed: json['hasClaimed'],
    claimedAt: json['claimedAt'],
  );

  Map<String, dynamic> toJson() => {
    'recipientId': recipientId,
    'amount': amount,
    'hasClaimed': hasClaimed,
    if (claimedAt != null) 'claimedAt': claimedAt,
  };
}

// --- Escrow Enums & recursive Conditions ---

enum TimeComparison {
  TIME_COMPARISON_UNSPECIFIED,
  TIME_COMPARISON_AFTER,
  TIME_COMPARISON_BEFORE,
  TIME_COMPARISON_BETWEEN,
}

enum AmmPhase {
  AMM_PHASE_UNSPECIFIED,
  AMM_PHASE_SINGLE_SIDED,
  AMM_PHASE_DOUBLE_SIDED,
  AMM_PHASE_GRADUATED,
}

enum AmmStateCheckType {
  PHASE,
  MINIMUM_RESERVE,
  EXISTS,
}

enum ConditionType {
  TIME,
  AMM_STATE,
  LOGICAL,
}

class TimeConditionData {
  final TimeComparison comparison;
  final String timestampStart;
  final String? timestampEnd;

  TimeConditionData({required this.comparison, required this.timestampStart, this.timestampEnd});

  Map<String, dynamic> toJson() => {
    'comparison': comparison.index,
    'timestampStart': timestampStart,
    'timestampEnd': timestampEnd,
  };
}

class AmmStateConditionData {
  final String ammId;
  final AmmStateCheckType checkType;
  final AmmPhase? requiredPhase;
  final String? minimumReserveAmount;
  final bool? mustExist;

  AmmStateConditionData({
    required this.ammId,
    required this.checkType,
    this.requiredPhase,
    this.minimumReserveAmount,
    this.mustExist,
  });

  Map<String, dynamic> toJson() => {
    'ammId': ammId,
    'checkType': checkType.index,
    'requiredPhase': requiredPhase?.index,
    'minimumReserveAmount': minimumReserveAmount,
    'mustExist': mustExist,
  };
}

class EscrowCondition {
  final ConditionType conditionType;
  final TimeConditionData? timeCondition;
  final AmmStateConditionData? ammStateCondition;
  final LogicalConditionData? logicalCondition;

  EscrowCondition({
    required this.conditionType,
    this.timeCondition,
    this.ammStateCondition,
    this.logicalCondition,
  });

  Map<String, dynamic> toJson() => {
    'conditionType': conditionType.index,
    'timeCondition': timeCondition?.toJson(),
    'ammStateCondition': ammStateCondition?.toJson(),
    'logicalCondition': logicalCondition?.toJson(),
  };
}

class LogicalConditionData {
  final List<EscrowCondition> conditions;

  LogicalConditionData({required this.conditions});

  Map<String, dynamic> toJson() => {
    'conditions': conditions.map((c) => c.toJson()).toList(),
  };
}

// --- Escrow Intent Data ---

class ValidateEscrowCreateData {
  final String creatorPublicKey;
  final String assetId;
  final String assetAmount;
  final List<dynamic> recipients;
  final List<EscrowCondition> claimConditions;
  final String? abandonHost;
  final List<EscrowCondition>? abandonConditions;
  final String nonce;

  ValidateEscrowCreateData({
    required this.creatorPublicKey,
    required this.assetId,
    required this.assetAmount,
    required this.recipients,
    required this.claimConditions,
    this.abandonHost,
    this.abandonConditions,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'creatorPublicKey': creatorPublicKey,
    'assetId': assetId,
    'assetAmount': assetAmount,
    'recipients': recipients,
    'claimConditions': claimConditions.map((c) => c.toJson()).toList(),
    'abandonHost': abandonHost,
    'abandonConditions': abandonConditions?.map((c) => c.toJson()).toList(),
    'nonce': nonce,
  };
}

// --- Escrow & Condition Types ---

/// Flexible condition definition for API requests.
abstract class Condition {
  final String conditionType;
  Condition(this.conditionType);

  factory Condition.fromJson(Map<String, dynamic> json) {
    final type = json['conditionType'];
    switch (type) {
      case 'and':
      case 'or':
        return LogicCondition.fromJson(json);
      case 'time':
        return TimeCondition.fromJson(json);
      case 'amm_state':
        return AmmStateCondition.fromJson(json);
      default:
        throw Exception("Unknown condition type: $type");
    }
  }

  Map<String, dynamic> toJson();
}

class LogicCondition extends Condition {
  final List<Condition> conditions;
  final String logicType;

  LogicCondition({required this.logicType, required this.conditions}) : super(logicType);

  factory LogicCondition.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LogicCondition(
      logicType: json['conditionType'],
      conditions: (data['conditions'] as List)
          .map((c) => Condition.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'conditionType': logicType,
    'data': {
      'conditions': conditions.map((c) => c.toJson()).toList(),
    },
  };
}

class TimeCondition extends Condition {
  final String comparison;
  final String timestamp;

  TimeCondition({required this.comparison, required this.timestamp}) : super('time');

  factory TimeCondition.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return TimeCondition(
      comparison: data['comparison'],
      timestamp: data['timestamp'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'conditionType': 'time',
    'data': {
      'comparison': comparison,
      'timestamp': timestamp,
    },
  };
}

class AmmStateCondition extends Condition {
  final String ammId;
  final Map<String, dynamic> stateCheck;

  AmmStateCondition({required this.ammId, required this.stateCheck}) : super('amm_state');

  factory AmmStateCondition.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AmmStateCondition(
      ammId: data['ammId'],
      stateCheck: Map<String, dynamic>.from(data['stateCheck']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'conditionType': 'amm_state',
    'data': {
      'ammId': ammId,
      'stateCheck': stateCheck,
    },
  };
}

// --- Escrow Request/Response Types ---

class CreateEscrowRequest {
  final String creatorPublicKey;
  final String assetId;
  final String assetAmount;
  final List<dynamic> recipients;
  final List<Condition> claimConditions;
  final String? abandonHost;
  final List<Condition>? abandonConditions;
  final String nonce;
  final String signature;

  CreateEscrowRequest({
    required this.creatorPublicKey,
    required this.assetId,
    required this.assetAmount,
    required this.recipients,
    required this.claimConditions,
    this.abandonHost,
    this.abandonConditions,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'creatorPublicKey': creatorPublicKey,
    'assetId': assetId,
    'assetAmount': assetAmount,
    'recipients': recipients,
    'claimConditions': claimConditions.map((c) => c.toJson()).toList(),
    'abandonHost': abandonHost,
    'abandonConditions': abandonConditions?.map((c) => c.toJson()).toList(),
    'nonce': nonce,
    'signature': signature,
  };
}

class CreateEscrowResponse {
  final String requestId;
  final String escrowId;
  final String depositAddress;
  final String message;

  CreateEscrowResponse({
    required this.requestId,
    required this.escrowId,
    required this.depositAddress,
    required this.message,
  });

  factory CreateEscrowResponse.fromJson(Map<String, dynamic> json) => CreateEscrowResponse(
    requestId: json['requestId'],
    escrowId: json['escrowId'],
    depositAddress: json['depositAddress'],
    message: json['message'],
  );
}

// --- Clawback Types ---

class ClawbackRequest {
  final String senderPublicKey;
  final String sparkTransferId;
  final String lpIdentityPublicKey;
  final String nonce;
  final String signature;

  ClawbackRequest({
    required this.senderPublicKey,
    required this.sparkTransferId,
    required this.lpIdentityPublicKey,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'senderPublicKey': senderPublicKey,
    'sparkTransferId': sparkTransferId,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'nonce': nonce,
    'signature': signature,
  };
}

class CheckClawbackEligibilityResponse {
  final bool accepted;
  final String? error;

  CheckClawbackEligibilityResponse({required this.accepted, this.error});

  factory CheckClawbackEligibilityResponse.fromJson(Map<String, dynamic> json) =>
    CheckClawbackEligibilityResponse(
      accepted: json['accepted'],
      error: json['error'],
    );
}

class ClawbackTransfer {
  final String id;
  final String lpIdentityPublicKey;
  final String? createdAt;

  ClawbackTransfer({required this.id, required this.lpIdentityPublicKey, this.createdAt});

  factory ClawbackTransfer.fromJson(Map<String, dynamic> json) => ClawbackTransfer(
    id: json['id'],
    lpIdentityPublicKey: json['lpIdentityPublicKey'],
    createdAt: json['createdAt'],
  );
}

class ListClawbackableTransfersResponse {
  final List<ClawbackTransfer> transfers;

  ListClawbackableTransfersResponse({required this.transfers});

  factory ListClawbackableTransfersResponse.fromJson(Map<String, dynamic> json) =>
    ListClawbackableTransfersResponse(
      transfers: (json['transfers'] as List).map((t) => ClawbackTransfer.fromJson(t)).toList(),
    );
}

class ClawbackResponse {
  final String requestId;
  final bool accepted;
  final String internalRequestId;
  final String sparkStatusTrackingId;
  final String? error;

  ClawbackResponse({
    required this.requestId,
    required this.accepted,
    required this.internalRequestId,
    required this.sparkStatusTrackingId,
    this.error,
  });

  factory ClawbackResponse.fromJson(Map<String, dynamic> json) => ClawbackResponse(
    requestId: json['requestId'],
    accepted: json['accepted'],
    internalRequestId: json['internalRequestId'],
    sparkStatusTrackingId: json['sparkStatusTrackingId'],
    error: json['error'],
  );

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'accepted': accepted,
    'internalRequestId': internalRequestId,
    'sparkStatusTrackingId': sparkStatusTrackingId,
    if (error != null) 'error': error,
  };
}

// --- Validation Utilities ---

class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({required this.isValid, this.error});
}

/// Validates that a single-sided pool threshold is within range (20%-90%)
ValidationResult validateSingleSidedPoolThreshold(
  String threshold,
  String assetAInitialReserve,
) {
  try {
    final thresholdNum = BigInt.parse(threshold);
    final initialReserveNum = BigInt.parse(assetAInitialReserve);

    if (thresholdNum <= BigInt.zero || initialReserveNum <= BigInt.zero) {
      return ValidationResult(
        isValid: false,
        error: "Threshold and initial reserve must be positive values",
      );
    }

    final minThreshold = (initialReserveNum * BigInt.from(20)) ~/ BigInt.from(100);
    final maxThreshold = (initialReserveNum * BigInt.from(90)) ~/ BigInt.from(100);

    if (thresholdNum < minThreshold) {
      return ValidationResult(
        isValid: false,
        error: "Threshold must be at least 20% of initial reserve (minimum: ${minThreshold.toString()})",
      );
    }

    if (thresholdNum > maxThreshold) {
      return ValidationResult(
        isValid: false,
        error: "Threshold must not exceed 90% of initial reserve (maximum: ${maxThreshold.toString()})",
      );
    }

    return ValidationResult(isValid: true);
  } catch (_) {
    return ValidationResult(
      isValid: false,
      error: "Invalid number format for threshold or initial reserve",
    );
  }
}

/// Calculates the percentage that a threshold represents of the initial reserve
double calculateThresholdPercentage(String threshold, String assetAInitialReserve) {
  try {
    final thresholdNum = BigInt.parse(threshold);
    final initialReserveNum = BigInt.parse(assetAInitialReserve);

    if (initialReserveNum == BigInt.zero) return 0;

    final percentage = (thresholdNum * BigInt.from(10000)) ~/ initialReserveNum;
    return percentage.toInt() / 100.0;
  } catch (_) {
    return 0;
  }
}

// --- V3 Concentrated Liquidity Types ---

class ValidateConcentratedPoolData {
  final String poolOwnerPublicKey;
  final String assetAAddress;
  final String assetBAddress;
  final int tickSpacing;
  final String initialPrice;
  final String lpFeeRateBps;
  final String hostFeeRateBps;
  final String nonce;

  ValidateConcentratedPoolData({
    required this.poolOwnerPublicKey,
    required this.assetAAddress,
    required this.assetBAddress,
    required this.tickSpacing,
    required this.initialPrice,
    required this.lpFeeRateBps,
    required this.hostFeeRateBps,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'poolOwnerPublicKey': poolOwnerPublicKey,
    'assetAAddress': assetAAddress,
    'assetBAddress': assetBAddress,
    'tickSpacing': tickSpacing,
    'initialPrice': initialPrice,
    'lpFeeRateBps': lpFeeRateBps,
    'hostFeeRateBps': hostFeeRateBps,
    'nonce': nonce,
  };
}

// --- V3 Intent Validation Data Types (Part 2) ---

/// Data for validating an increase liquidity intent.
class ValidateIncreaseLiquidityData {
  final String userPublicKey;
  final String lpIdentityPublicKey;
  final int tickLower;
  final int tickUpper;
  final String assetASparkTransferId;
  final String assetBSparkTransferId;
  final String amountADesired;
  final String amountBDesired;
  final String amountAMin;
  final String amountBMin;
  final String nonce;

  ValidateIncreaseLiquidityData({
    required this.userPublicKey,
    required this.lpIdentityPublicKey,
    required this.tickLower,
    required this.tickUpper,
    required this.assetASparkTransferId,
    required this.assetBSparkTransferId,
    required this.amountADesired,
    required this.amountBDesired,
    required this.amountAMin,
    required this.amountBMin,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'tickLower': tickLower,
    'tickUpper': tickUpper,
    'assetASparkTransferId': assetASparkTransferId,
    'assetBSparkTransferId': assetBSparkTransferId,
    'amountADesired': amountADesired,
    'amountBDesired': amountBDesired,
    'amountAMin': amountAMin,
    'amountBMin': amountBMin,
    'nonce': nonce,
  };
}

/// Data for validating a decrease liquidity intent.
class ValidateDecreaseLiquidityData {
  final String userPublicKey;
  final String lpIdentityPublicKey;
  final int tickLower;
  final int tickUpper;
  final String liquidityToRemove;
  final String amountAMin;
  final String amountBMin;
  final String nonce;

  ValidateDecreaseLiquidityData({
    required this.userPublicKey,
    required this.lpIdentityPublicKey,
    required this.tickLower,
    required this.tickUpper,
    required this.liquidityToRemove,
    required this.amountAMin,
    required this.amountBMin,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'tickLower': tickLower,
    'tickUpper': tickUpper,
    'liquidityToRemove': liquidityToRemove,
    'amountAMin': amountAMin,
    'amountBMin': amountBMin,
    'nonce': nonce,
  };
}

/// Data for validating a collect fees intent.
class ValidateCollectFeesData {
  final String userPublicKey;
  final String lpIdentityPublicKey;
  final int tickLower;
  final int tickUpper;
  final String nonce;

  ValidateCollectFeesData({
    required this.userPublicKey,
    required this.lpIdentityPublicKey,
    required this.tickLower,
    required this.tickUpper,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'tickLower': tickLower,
    'tickUpper': tickUpper,
    'nonce': nonce,
  };
}

/// Data for validating a rebalance position intent.
/// Note: Optional fields serialize as null (not omitted) to match TEE's proto serde behavior.
class ValidateRebalancePositionData {
  final String userPublicKey;
  final String lpIdentityPublicKey;
  final int oldTickLower;
  final int oldTickUpper;
  final int newTickLower;
  final int newTickUpper;
  final String liquidityToMove;
  final String? assetASparkTransferId;
  final String? assetBSparkTransferId;
  final String? additionalAmountA;
  final String? additionalAmountB;
  final String nonce;

  ValidateRebalancePositionData({
    required this.userPublicKey,
    required this.lpIdentityPublicKey,
    required this.oldTickLower,
    required this.oldTickUpper,
    required this.newTickLower,
    required this.newTickUpper,
    required this.liquidityToMove,
    this.assetASparkTransferId,
    this.assetBSparkTransferId,
    this.additionalAmountA,
    this.additionalAmountB,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'oldTickLower': oldTickLower,
    'oldTickUpper': oldTickUpper,
    'newTickLower': newTickLower,
    'newTickUpper': newTickUpper,
    'liquidityToMove': liquidityToMove,
    'assetASparkTransferId': assetASparkTransferId, // explicit null
    'assetBSparkTransferId': assetBSparkTransferId, // explicit null
    'additionalAmountA': additionalAmountA,         // explicit null
    'additionalAmountB': additionalAmountB,         // explicit null
    'nonce': nonce,
  };
}

// --- V3 Request Types ---

class CreateConcentratedPoolRequest {
  final String poolOwnerPublicKey;
  final String assetAAddress;
  final String assetBAddress;
  final int tickSpacing;
  final String initialPrice;
  final String lpFeeRateBps;
  final String hostFeeRateBps;
  final String? hostNamespace;
  final String nonce;
  final String signature;

  CreateConcentratedPoolRequest({
    required this.poolOwnerPublicKey,
    required this.assetAAddress,
    required this.assetBAddress,
    required this.tickSpacing,
    required this.initialPrice,
    required this.lpFeeRateBps,
    required this.hostFeeRateBps,
    this.hostNamespace,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'poolOwnerPublicKey': poolOwnerPublicKey,
    'assetAAddress': assetAAddress,
    'assetBAddress': assetBAddress,
    'tickSpacing': tickSpacing,
    'initialPrice': initialPrice,
    'lpFeeRateBps': lpFeeRateBps,
    'hostFeeRateBps': hostFeeRateBps,
    'hostNamespace': hostNamespace,
    'nonce': nonce,
    'signature': signature,
  };
}

class IncreaseLiquidityRequest {
  final String poolId;
  final int tickLower;
  final int tickUpper;
  final String assetASparkTransferId;
  final String assetBSparkTransferId;
  final String amountADesired;
  final String amountBDesired;
  final String amountAMin;
  final String amountBMin;
  final bool? useFreeBalance;
  final bool? retainExcessInBalance;
  final String nonce;
  final String signature;

  IncreaseLiquidityRequest({
    required this.poolId,
    required this.tickLower,
    required this.tickUpper,
    required this.assetASparkTransferId,
    required this.assetBSparkTransferId,
    required this.amountADesired,
    required this.amountBDesired,
    required this.amountAMin,
    required this.amountBMin,
    this.useFreeBalance,
    this.retainExcessInBalance,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'tickLower': tickLower,
    'tickUpper': tickUpper,
    'assetASparkTransferId': assetASparkTransferId,
    'assetBSparkTransferId': assetBSparkTransferId,
    'amountADesired': amountADesired,
    'amountBDesired': amountBDesired,
    'amountAMin': amountAMin,
    'amountBMin': amountBMin,
    'useFreeBalance': useFreeBalance,
    'retainExcessInBalance': retainExcessInBalance,
    'nonce': nonce,
    'signature': signature,
  };
}

class DecreaseLiquidityRequest {
  final String poolId;
  final int tickLower;
  final int tickUpper;
  final String liquidityToRemove;
  final String amountAMin;
  final String amountBMin;
  final bool? retainInBalance;
  final String nonce;
  final String signature;

  DecreaseLiquidityRequest({
    required this.poolId,
    required this.tickLower,
    required this.tickUpper,
    required this.liquidityToRemove,
    required this.amountAMin,
    required this.amountBMin,
    this.retainInBalance,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'tickLower': tickLower,
    'tickUpper': tickUpper,
    'liquidityToRemove': liquidityToRemove,
    'amountAMin': amountAMin,
    'amountBMin': amountBMin,
    'retainInBalance': retainInBalance,
    'nonce': nonce,
    'signature': signature,
  };
}

class CollectFeesRequest {
  final String poolId;
  final int tickLower;
  final int tickUpper;
  final bool? retainInBalance;
  final String nonce;
  final String signature;

  CollectFeesRequest({
    required this.poolId,
    required this.tickLower,
    required this.tickUpper,
    this.retainInBalance,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'tickLower': tickLower,
    'tickUpper': tickUpper,
    'retainInBalance': retainInBalance,
    'nonce': nonce,
    'signature': signature,
  };
}

class RebalancePositionRequest {
  final String poolId;
  final int oldTickLower;
  final int oldTickUpper;
  final int newTickLower;
  final int newTickUpper;
  final String liquidityToMove;
  final String? assetASparkTransferId;
  final String? assetBSparkTransferId;
  final String? additionalAmountA;
  final String? additionalAmountB;
  final bool? retainInBalance;
  final String nonce;
  final String signature;

  RebalancePositionRequest({
    required this.poolId,
    required this.oldTickLower,
    required this.oldTickUpper,
    required this.newTickLower,
    required this.newTickUpper,
    required this.liquidityToMove,
    this.assetASparkTransferId,
    this.assetBSparkTransferId,
    this.additionalAmountA,
    this.additionalAmountB,
    this.retainInBalance,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'oldTickLower': oldTickLower,
    'oldTickUpper': oldTickUpper,
    'newTickLower': newTickLower,
    'newTickUpper': newTickUpper,
    'liquidityToMove': liquidityToMove,
    'assetASparkTransferId': assetASparkTransferId,
    'assetBSparkTransferId': assetBSparkTransferId,
    'additionalAmountA': additionalAmountA,
    'additionalAmountB': additionalAmountB,
    'retainInBalance': retainInBalance,
    'nonce': nonce,
    'signature': signature,
  };
}

// --- V3 Response Types ---

class V3FreeBalanceInfo {
  final String balanceA;
  final String balanceB;

  V3FreeBalanceInfo({required this.balanceA, required this.balanceB});

  factory V3FreeBalanceInfo.fromJson(Map<String, dynamic> json) => V3FreeBalanceInfo(
    balanceA: json['balanceA'],
    balanceB: json['balanceB'],
  );
}

class CreateConcentratedPoolResponse {
  final String poolId;
  final int initialTick;
  final String message;

  CreateConcentratedPoolResponse({
    required this.poolId,
    required this.initialTick,
    required this.message,
  });

  factory CreateConcentratedPoolResponse.fromJson(Map<String, dynamic> json) => CreateConcentratedPoolResponse(
    poolId: json['poolId'],
    initialTick: json['initialTick'],
    message: json['message'],
  );
}

class IncreaseLiquidityResponse {
  final String requestId;
  final bool accepted;
  final String? liquidityAdded;
  final String? amountAUsed;
  final String? amountBUsed;
  final String? amountARefund;
  final String? amountBRefund;
  final String? amountARetained;
  final String? amountBRetained;
  final bool? retainedInBalance;
  final V3FreeBalanceInfo? currentBalance;
  final String? error;

  IncreaseLiquidityResponse({
    required this.requestId,
    required this.accepted,
    this.liquidityAdded,
    this.amountAUsed,
    this.amountBUsed,
    this.amountARefund,
    this.amountBRefund,
    this.amountARetained,
    this.amountBRetained,
    this.retainedInBalance,
    this.currentBalance,
    this.error,
  });

  factory IncreaseLiquidityResponse.fromJson(Map<String, dynamic> json) => IncreaseLiquidityResponse(
    requestId: json['requestId'],
    accepted: json['accepted'],
    liquidityAdded: json['liquidityAdded'],
    amountAUsed: json['amountAUsed'],
    amountBUsed: json['amountBUsed'],
    amountARefund: json['amountARefund'],
    amountBRefund: json['amountBRefund'],
    amountARetained: json['amountARetained'],
    amountBRetained: json['amountBRetained'],
    retainedInBalance: json['retainedInBalance'],
    currentBalance: json['currentBalance'] != null ? V3FreeBalanceInfo.fromJson(json['currentBalance']) : null,
    error: json['error'],
  );
}

class DecreaseLiquidityResponse {
  final String requestId;
  final bool accepted;
  final String? liquidityRemoved;
  final String? amountA;
  final String? amountB;
  final String? feesCollectedA;
  final String? feesCollectedB;
  final String? amountARetained;
  final String? amountBRetained;
  final List<String>? outboundTransferIds;
  final bool? retainedInBalance;
  final V3FreeBalanceInfo? currentBalance;
  final String? error;

  DecreaseLiquidityResponse({
    required this.requestId,
    required this.accepted,
    this.liquidityRemoved,
    this.amountA,
    this.amountB,
    this.feesCollectedA,
    this.feesCollectedB,
    this.amountARetained,
    this.amountBRetained,
    this.outboundTransferIds,
    this.retainedInBalance,
    this.currentBalance,
    this.error,
  });

  factory DecreaseLiquidityResponse.fromJson(Map<String, dynamic> json) => DecreaseLiquidityResponse(
    requestId: json['requestId'],
    accepted: json['accepted'],
    liquidityRemoved: json['liquidityRemoved'],
    amountA: json['amountA'],
    amountB: json['amountB'],
    feesCollectedA: json['feesCollectedA'],
    feesCollectedB: json['feesCollectedB'],
    amountARetained: json['amountARetained'],
    amountBRetained: json['amountBRetained'],
    outboundTransferIds: (json['outboundTransferIds'] as List?)?.map((e) => e as String).toList(),
    retainedInBalance: json['retainedInBalance'],
    currentBalance: json['currentBalance'] != null ? V3FreeBalanceInfo.fromJson(json['currentBalance']) : null,
    error: json['error'],
  );
}

class CollectFeesResponse {
  final String requestId;
  final bool accepted;
  final String? feesCollectedA;
  final String? feesCollectedB;
  final String? assetAAddress;
  final String? assetBAddress;
  final String? feesARetained;
  final String? feesBRetained;
  final List<String>? outboundTransferIds;
  final bool? retainedInBalance;
  final V3FreeBalanceInfo? currentBalance;
  final String? error;

  CollectFeesResponse({
    required this.requestId,
    required this.accepted,
    this.feesCollectedA,
    this.feesCollectedB,
    this.assetAAddress,
    this.assetBAddress,
    this.feesARetained,
    this.feesBRetained,
    this.outboundTransferIds,
    this.retainedInBalance,
    this.currentBalance,
    this.error,
  });

  factory CollectFeesResponse.fromJson(Map<String, dynamic> json) => CollectFeesResponse(
    requestId: json['requestId'],
    accepted: json['accepted'],
    feesCollectedA: json['feesCollectedA'],
    feesCollectedB: json['feesCollectedB'],
    assetAAddress: json['assetAAddress'],
    assetBAddress: json['assetBAddress'],
    feesARetained: json['feesARetained'],
    feesBRetained: json['feesBRetained'],
    outboundTransferIds: (json['outboundTransferIds'] as List?)?.map((e) => e as String).toList(),
    retainedInBalance: json['retainedInBalance'],
    currentBalance: json['currentBalance'] != null ? V3FreeBalanceInfo.fromJson(json['currentBalance']) : null,
    error: json['error'],
  );
}

class RebalancePositionResponse {
  final String requestId;
  final bool accepted;
  final String? oldLiquidity;
  final String? newLiquidity;
  final String? netAmountA;
  final String? netAmountB;
  final String? feesCollectedA;
  final String? feesCollectedB;
  final String? amountARetained;
  final String? amountBRetained;
  final List<String>? outboundTransferIds;
  final bool? retainedInBalance;
  final V3FreeBalanceInfo? currentBalance;
  final String? error;

  RebalancePositionResponse({
    required this.requestId,
    required this.accepted,
    this.oldLiquidity,
    this.newLiquidity,
    this.netAmountA,
    this.netAmountB,
    this.feesCollectedA,
    this.feesCollectedB,
    this.amountARetained,
    this.amountBRetained,
    this.outboundTransferIds,
    this.retainedInBalance,
    this.currentBalance,
    this.error,
  });

  factory RebalancePositionResponse.fromJson(Map<String, dynamic> json) => RebalancePositionResponse(
    requestId: json['requestId'],
    accepted: json['accepted'],
    oldLiquidity: json['oldLiquidity'],
    newLiquidity: json['newLiquidity'],
    netAmountA: json['netAmountA'],
    netAmountB: json['netAmountB'],
    feesCollectedA: json['feesCollectedA'],
    feesCollectedB: json['feesCollectedB'],
    amountARetained: json['amountARetained'],
    amountBRetained: json['amountBRetained'],
    outboundTransferIds: (json['outboundTransferIds'] as List?)?.map((e) => e as String).toList(),
    retainedInBalance: json['retainedInBalance'],
    currentBalance: json['currentBalance'] != null ? V3FreeBalanceInfo.fromJson(json['currentBalance']) : null,
    error: json['error'],
  );
}

// --- V3 Position Types ---

class ListConcentratedPositionsQuery {
  final String? poolId;
  final int? page;
  final int? pageSize;

  ListConcentratedPositionsQuery({this.poolId, this.page, this.pageSize});

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'page': page,
    'pageSize': pageSize,
  };
}

class ConcentratedPosition {
  final String poolId;
  final String owner;
  final int tickLower;
  final int tickUpper;
  final String liquidity;
  final String uncollectedFeesA;
  final String uncollectedFeesB;
  final String assetAAddress;
  final String assetBAddress;
  final bool inRange;
  final String? createdAt;

  ConcentratedPosition({
    required this.poolId,
    required this.owner,
    required this.tickLower,
    required this.tickUpper,
    required this.liquidity,
    required this.uncollectedFeesA,
    required this.uncollectedFeesB,
    required this.assetAAddress,
    required this.assetBAddress,
    required this.inRange,
    this.createdAt,
  });

  factory ConcentratedPosition.fromJson(Map<String, dynamic> json) => ConcentratedPosition(
    poolId: json['poolId'],
    owner: json['owner'],
    tickLower: json['tickLower'],
    tickUpper: json['tickUpper'],
    liquidity: json['liquidity'],
    uncollectedFeesA: json['uncollectedFeesA'],
    uncollectedFeesB: json['uncollectedFeesB'],
    assetAAddress: json['assetAAddress'],
    assetBAddress: json['assetBAddress'],
    inRange: json['inRange'],
    createdAt: json['createdAt'],
  );
}

class ListConcentratedPositionsResponse {
  final List<ConcentratedPosition> positions;
  final int totalCount;
  final int page;
  final int pageSize;

  ListConcentratedPositionsResponse({
    required this.positions,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory ListConcentratedPositionsResponse.fromJson(Map<String, dynamic> json) => ListConcentratedPositionsResponse(
    positions: (json['positions'] as List).map((e) => ConcentratedPosition.fromJson(e)).toList(),
    totalCount: json['totalCount'],
    page: json['page'],
    pageSize: json['pageSize'],
  );
}

// --- V3 Pool Liquidity Types ---

typedef RangeStatus = String;

class RangeStatuses {
  static const RangeStatus belowPrice = "below_price";
  static const RangeStatus inRange = "in_range";
  static const RangeStatus abovePrice = "above_price";
}

class LiquidityRange {
  final int tickLower;
  final int tickUpper;
  final String priceLower;
  final String priceUpper;
  final String liquidity;
  final String amountA;
  final String amountB;
  final RangeStatus status;

  LiquidityRange({
    required this.tickLower,
    required this.tickUpper,
    required this.priceLower,
    required this.priceUpper,
    required this.liquidity,
    required this.amountA,
    required this.amountB,
    required this.status,
  });

  factory LiquidityRange.fromJson(Map<String, dynamic> json) => LiquidityRange(
    tickLower: json['tickLower'],
    tickUpper: json['tickUpper'],
    priceLower: json['priceLower'],
    priceUpper: json['priceUpper'],
    liquidity: json['liquidity'],
    amountA: json['amountA'],
    amountB: json['amountB'],
    status: json['status'],
  );
}

// --- V3 Pool Liquidity Visualization ---

class PoolLiquidityResponse {
  final String poolId;
  final String assetAAddress;
  final String assetBAddress;
  final int currentTick;
  final String currentPrice;
  final String currentSqrtPrice;
  final int tickSpacing;
  final String activeLiquidity;
  final String totalReserveA;
  final String totalReserveB;
  final List<LiquidityRange> ranges;

  PoolLiquidityResponse({
    required this.poolId,
    required this.assetAAddress,
    required this.assetBAddress,
    required this.currentTick,
    required this.currentPrice,
    required this.currentSqrtPrice,
    required this.tickSpacing,
    required this.activeLiquidity,
    required this.totalReserveA,
    required this.totalReserveB,
    required this.ranges,
  });

  factory PoolLiquidityResponse.fromJson(Map<String, dynamic> json) => PoolLiquidityResponse(
    poolId: json['poolId'],
    assetAAddress: json['assetAAddress'],
    assetBAddress: json['assetBAddress'],
    currentTick: json['currentTick'],
    currentPrice: json['currentPrice'],
    currentSqrtPrice: json['currentSqrtPrice'],
    tickSpacing: json['tickSpacing'],
    activeLiquidity: json['activeLiquidity'],
    totalReserveA: json['totalReserveA'],
    totalReserveB: json['totalReserveB'],
    ranges: (json['ranges'] as List).map((e) => LiquidityRange.fromJson(e)).toList(),
  );
}

// --- V3 Pool Ticks (Simulation) ---

class TickData {
  final int tick;
  final String liquidityNet;
  final String liquidityGross;
  final String sqrtPrice;

  TickData({
    required this.tick,
    required this.liquidityNet,
    required this.liquidityGross,
    required this.sqrtPrice,
  });

  factory TickData.fromJson(Map<String, dynamic> json) => TickData(
    tick: json['tick'],
    liquidityNet: json['liquidityNet'],
    liquidityGross: json['liquidityGross'],
    sqrtPrice: json['sqrtPrice'],
  );
}

class PoolTicksResponse {
  final String poolId;
  final String assetAAddress;
  final String assetBAddress;
  final int currentTick;
  final String currentSqrtPrice;
  final String currentLiquidity;
  final int tickSpacing;
  final int lpFeeBps;
  final List<TickData> ticks;

  PoolTicksResponse({
    required this.poolId,
    required this.assetAAddress,
    required this.assetBAddress,
    required this.currentTick,
    required this.currentSqrtPrice,
    required this.currentLiquidity,
    required this.tickSpacing,
    required this.lpFeeBps,
    required this.ticks,
  });

  factory PoolTicksResponse.fromJson(Map<String, dynamic> json) => PoolTicksResponse(
    poolId: json['poolId'],
    assetAAddress: json['assetAAddress'],
    assetBAddress: json['assetBAddress'],
    currentTick: json['currentTick'],
    currentSqrtPrice: json['currentSqrtPrice'],
    currentLiquidity: json['currentLiquidity'],
    tickSpacing: json['tickSpacing'],
    lpFeeBps: json['lpFeeBps'],
    ticks: (json['ticks'] as List).map((e) => TickData.fromJson(e)).toList(),
  );
}

// --- V3 Free Balance Types ---

class PoolBalanceEntry {
  final String poolId;
  final String balanceA;
  final String balanceB;
  final String availableA;
  final String availableB;
  final String lockedA;
  final String lockedB;
  final String assetAAddress;
  final String assetBAddress;

  PoolBalanceEntry({
    required this.poolId,
    required this.balanceA,
    required this.balanceB,
    required this.availableA,
    required this.availableB,
    required this.lockedA,
    required this.lockedB,
    required this.assetAAddress,
    required this.assetBAddress,
  });

  factory PoolBalanceEntry.fromJson(Map<String, dynamic> json) => PoolBalanceEntry(
    poolId: json['poolId'],
    balanceA: json['balanceA'],
    balanceB: json['balanceB'],
    availableA: json['availableA'],
    availableB: json['availableB'],
    lockedA: json['lockedA'],
    lockedB: json['lockedB'],
    assetAAddress: json['assetAAddress'],
    assetBAddress: json['assetBAddress'],
  );
}

class GetBalanceResponse {
  final String requestId;
  final String poolId;
  final String balanceA;
  final String balanceB;
  final String availableA;
  final String availableB;
  final String lockedA;
  final String lockedB;
  final String assetAAddress;
  final String assetBAddress;

  GetBalanceResponse({
    required this.requestId,
    required this.poolId,
    required this.balanceA,
    required this.balanceB,
    required this.availableA,
    required this.availableB,
    required this.lockedA,
    required this.lockedB,
    required this.assetAAddress,
    required this.assetBAddress,
  });

  factory GetBalanceResponse.fromJson(Map<String, dynamic> json) => GetBalanceResponse(
    requestId: json['requestId'],
    poolId: json['poolId'],
    balanceA: json['balanceA'],
    balanceB: json['balanceB'],
    availableA: json['availableA'],
    availableB: json['availableB'],
    lockedA: json['lockedA'],
    lockedB: json['lockedB'],
    assetAAddress: json['assetAAddress'],
    assetBAddress: json['assetBAddress'],
  );
}

class GetBalancesResponse {
  final String requestId;
  final List<PoolBalanceEntry> balances;

  GetBalancesResponse({required this.requestId, required this.balances});

  factory GetBalancesResponse.fromJson(Map<String, dynamic> json) => GetBalancesResponse(
    requestId: json['requestId'],
    balances: (json['balances'] as List).map((e) => PoolBalanceEntry.fromJson(e)).toList(),
  );
}

class WithdrawBalanceRequest {
  final String poolId;
  final String amountA;
  final String amountB;
  final String nonce;
  final String signature;

  WithdrawBalanceRequest({
    required this.poolId,
    required this.amountA,
    required this.amountB,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'amountA': amountA,
    'amountB': amountB,
    'nonce': nonce,
    'signature': signature,
  };
}

class WithdrawBalanceResponse {
  final String requestId;
  final bool accepted;
  final String? amountAWithdrawn;
  final String? amountBWithdrawn;
  final String? assetAAddress;
  final String? assetBAddress;
  final String? remainingBalanceA;
  final String? remainingBalanceB;
  final List<String>? outboundTransferIds;
  final String? error;

  WithdrawBalanceResponse({
    required this.requestId,
    required this.accepted,
    this.amountAWithdrawn,
    this.amountBWithdrawn,
    this.assetAAddress,
    this.assetBAddress,
    this.remainingBalanceA,
    this.remainingBalanceB,
    this.outboundTransferIds,
    this.error,
  });

  factory WithdrawBalanceResponse.fromJson(Map<String, dynamic> json) => WithdrawBalanceResponse(
    requestId: json['requestId'],
    accepted: json['accepted'],
    amountAWithdrawn: json['amountAWithdrawn'],
    amountBWithdrawn: json['amountBWithdrawn'],
    assetAAddress: json['assetAAddress'],
    assetBAddress: json['assetBAddress'],
    remainingBalanceA: json['remainingBalanceA'],
    remainingBalanceB: json['remainingBalanceB'],
    outboundTransferIds: (json['outboundTransferIds'] as List?)?.map((e) => e as String).toList(),
    error: json['error'],
  );
}

class DepositBalanceRequest {
  final String poolId;
  final String amountA;
  final String amountB;
  final String assetASparkTransferId;
  final String assetBSparkTransferId;
  final String nonce;
  final String signature;

  DepositBalanceRequest({
    required this.poolId,
    required this.amountA,
    required this.amountB,
    required this.assetASparkTransferId,
    required this.assetBSparkTransferId,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'amountA': amountA,
    'amountB': amountB,
    'assetASparkTransferId': assetASparkTransferId,
    'assetBSparkTransferId': assetBSparkTransferId,
    'nonce': nonce,
    'signature': signature,
  };
}

class DepositBalanceResponse {
  final String requestId;
  final bool accepted;
  final String? amountADeposited;
  final String? amountBDeposited;
  final String? currentBalanceA;
  final String? currentBalanceB;
  final String? error;

  DepositBalanceResponse({
    required this.requestId,
    required this.accepted,
    this.amountADeposited,
    this.amountBDeposited,
    this.currentBalanceA,
    this.currentBalanceB,
    this.error,
  });

  factory DepositBalanceResponse.fromJson(Map<String, dynamic> json) => DepositBalanceResponse(
    requestId: json['requestId'],
    accepted: json['accepted'] ?? false,
    amountADeposited: json['amountADeposited'],
    amountBDeposited: json['amountBDeposited'],
    currentBalanceA: json['currentBalanceA'],
    currentBalanceB: json['currentBalanceB'],
    error: json['error'],
  );
}

// --- LP Lock & Position Transfer Types ---

class LpLockInfo {
  final String poolId;
  final String ownerPublicKey;
  final String lockUntilTimestamp;
  final int? tickLower;
  final int? tickUpper;
  final bool isIndefinite;

  LpLockInfo({
    required this.poolId,
    required this.ownerPublicKey,
    required this.lockUntilTimestamp,
    this.tickLower,
    this.tickUpper,
    required this.isIndefinite,
  });

  factory LpLockInfo.fromJson(Map<String, dynamic> json) => LpLockInfo(
    poolId: json['poolId'],
    ownerPublicKey: json['ownerPublicKey'],
    lockUntilTimestamp: json['lockUntilTimestamp'],
    tickLower: json['tickLower'],
    tickUpper: json['tickUpper'],
    isIndefinite: json['isIndefinite'],
  );

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'ownerPublicKey': ownerPublicKey,
    'lockUntilTimestamp': lockUntilTimestamp,
    'tickLower': tickLower,
    'tickUpper': tickUpper,
    'isIndefinite': isIndefinite,
  };
}

class LockPositionRequest {
  final String userPublicKey;
  final String poolId;
  final String lockUntilTimestamp;
  final int? tickLower;
  final int? tickUpper;
  final String nonce;
  final String signature;

  LockPositionRequest({
    required this.userPublicKey,
    required this.poolId,
    required this.lockUntilTimestamp,
    this.tickLower,
    this.tickUpper,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'poolId': poolId,
    'lockUntilTimestamp': lockUntilTimestamp,
    'tickLower': tickLower,
    'tickUpper': tickUpper,
    'nonce': nonce,
    'signature': signature,
  };
}

class LockPositionResponse {
  final String requestId;
  final bool accepted;
  final String? lockUntilTimestamp;
  final bool? isIndefinite;
  final String? error;

  LockPositionResponse({
    required this.requestId,
    required this.accepted,
    this.lockUntilTimestamp,
    this.isIndefinite,
    this.error,
  });

  factory LockPositionResponse.fromJson(Map<String, dynamic> json) => LockPositionResponse(
    requestId: json['requestId'],
    accepted: json['accepted'],
    lockUntilTimestamp: json['lockUntilTimestamp'],
    isIndefinite: json['isIndefinite'],
    error: json['error'],
  );
}

class ValidateLpLockPositionData {
  final String userPublicKey;
  final String lpIdentityPublicKey;
  final int lockUntilTimestamp;
  final int? tickLower;
  final int? tickUpper;
  final String nonce;

  ValidateLpLockPositionData({
    required this.userPublicKey,
    required this.lpIdentityPublicKey,
    required this.lockUntilTimestamp,
    this.tickLower,
    this.tickUpper,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'lockUntilTimestamp': lockUntilTimestamp,
    'tickLower': tickLower,
    'tickUpper': tickUpper,
    'nonce': nonce,
  };
}

class TransferPositionRequest {
  final String userPublicKey;
  final String poolId;
  final String newOwnerPublicKey;
  final int? tickLower;
  final int? tickUpper;
  final String? lpTokensToTransfer;
  final String nonce;
  final String signature;

  TransferPositionRequest({
    required this.userPublicKey,
    required this.poolId,
    required this.newOwnerPublicKey,
    this.tickLower,
    this.tickUpper,
    this.lpTokensToTransfer,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'poolId': poolId,
    'newOwnerPublicKey': newOwnerPublicKey,
    'tickLower': tickLower,
    'tickUpper': tickUpper,
    'lpTokensToTransfer': lpTokensToTransfer,
    'nonce': nonce,
    'signature': signature,
  };
}

class TransferPositionResponse {
  final String requestId;
  final bool accepted;
  final String? confirmation;
  final String? error;

  TransferPositionResponse({
    required this.requestId,
    required this.accepted,
    this.confirmation,
    this.error,
  });

  factory TransferPositionResponse.fromJson(Map<String, dynamic> json) => TransferPositionResponse(
    requestId: json['requestId'],
    accepted: json['accepted'],
    confirmation: json['confirmation'],
    error: json['error'],
  );
}

class ValidateLpTransferPositionData {
  final String userPublicKey;
  final String lpIdentityPublicKey;
  final String newOwnerPublicKey;
  final int? tickLower;
  final int? tickUpper;
  final String? lpTokensToTransfer;
  final String nonce;

  ValidateLpTransferPositionData({
    required this.userPublicKey,
    required this.lpIdentityPublicKey,
    required this.newOwnerPublicKey,
    this.tickLower,
    this.tickUpper,
    this.lpTokensToTransfer,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'newOwnerPublicKey': newOwnerPublicKey,
    'tickLower': tickLower,
    'tickUpper': tickUpper,
    'lpTokensToTransfer': lpTokensToTransfer,
    'nonce': nonce,
  };
}

/// Response after successfully funding an escrow contract.
class FundEscrowResponse {
  final String requestId;
  final String escrowId;
  final String status;
  final String message;

  FundEscrowResponse({
    required this.requestId,
    required this.escrowId,
    required this.status,
    required this.message,
  });

  factory FundEscrowResponse.fromJson(Map<String, dynamic> json) => FundEscrowResponse(
    requestId: json['requestId'],
    escrowId: json['escrowId'],
    status: json['status'],
    message: json['message'],
  );
}

/// Request body for claiming funds from an escrow contract.
class ClaimEscrowRequest {
  final String escrowId;
  final String nonce;
  final String signature;

  ClaimEscrowRequest({
    required this.escrowId,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'escrowId': escrowId,
    'nonce': nonce,
    'signature': signature,
  };
}

/// Response after successfully initiating an escrow claim.
class ClaimEscrowResponse {
  final String requestId;
  final String escrowId;
  final String recipientId;
  final String claimedAmount;
  final String outboundTransferId;
  final String message;

  ClaimEscrowResponse({
    required this.requestId,
    required this.escrowId,
    required this.recipientId,
    required this.claimedAmount,
    required this.outboundTransferId,
    required this.message,
  });

  factory ClaimEscrowResponse.fromJson(Map<String, dynamic> json) => ClaimEscrowResponse(
    requestId: json['requestId'],
    escrowId: json['escrowId'],
    recipientId: json['recipientId'],
    claimedAmount: json['claimedAmount'],
    outboundTransferId: json['outboundTransferId'],
    message: json['message'],
  );
}

/// Complete state of an escrow contract.
class EscrowState {
  final String id;
  final Asset asset;
  final List<EscrowRecipientState> recipients;
  final String status; // EscrowStatus type
  final List<Condition> claimConditions;
  final String? abandonHost;
  final List<Condition>? abandonConditions;
  final String createdAt;
  final String updatedAt;
  final String totalClaimed;

  EscrowState({
    required this.id,
    required this.asset,
    required this.recipients,
    required this.status,
    required this.claimConditions,
    this.abandonHost,
    this.abandonConditions,
    required this.createdAt,
    required this.updatedAt,
    required this.totalClaimed,
  });

  factory EscrowState.fromJson(Map<String, dynamic> json) => EscrowState(
    id: json['id'],
    asset: Asset.fromJson(json['asset']),
    recipients: (json['recipients'] as List)
        .map((r) => EscrowRecipientState.fromJson(r))
        .toList(),
    status: json['status'],
    claimConditions: (json['claimConditions'] as List)
        .map((c) => Condition.fromJson(c))
        .toList(),
    abandonHost: json['abandonHost'],
    abandonConditions: json['abandonConditions'] != null
        ? (json['abandonConditions'] as List)
            .map((c) => Condition.fromJson(c))
            .toList()
        : null,
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
    totalClaimed: json['totalClaimed'],
  );
}

/// Settlement service types
class SettlementPingResponse {
  final String requestId;
  final String status;
  final String settlementTimestamp;
  final String gatewayTimestamp;

  SettlementPingResponse({
    required this.requestId,
    required this.status,
    required this.settlementTimestamp,
    required this.gatewayTimestamp,
  });

  factory SettlementPingResponse.fromJson(Map<String, dynamic> json) => SettlementPingResponse(
    requestId: json['requestId'],
    status: json['status'],
    settlementTimestamp: json['settlementTimestamp'],
    gatewayTimestamp: json['gatewayTimestamp'],
  );
}

// Type Aliases implemented as typedefs or lists where applicable
typedef FeatureStatusResponse = List<FeatureStatusItem>;
typedef MinAmountsResponse = List<MinAmountItem>;
typedef AllowedAssetsResponse = List<AllowedAssetItem>;

class CheckClawbackEligibilityRequest {
  final String sparkTransferId;

  CheckClawbackEligibilityRequest({required this.sparkTransferId});

  Map<String, dynamic> toJson() => {'sparkTransferId': sparkTransferId};
}

/// Query parameters for listing clawbackable transfers
class ListClawbackableTransfersQuery {
  final int? limit;
  final int? offset;

  ListClawbackableTransfersQuery({this.limit, this.offset});

  Map<String, dynamic> toJson() => {
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  };
}

/// Asset held in escrow.
class Asset {
  final String id;
  final String amount;

  Asset({
    required this.id,
    required this.amount,
  });

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
    id: json['id'],
    amount: json['amount'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
  };
}

/// Recipient state within an active escrow.
class EscrowRecipientState {
  final String id;
  final String amount;
  final bool hasClaimed;
  final String? claimedAt;

  EscrowRecipientState({
    required this.id,
    required this.amount,
    required this.hasClaimed,
    this.claimedAt,
  });

  factory EscrowRecipientState.fromJson(Map<String, dynamic> json) => EscrowRecipientState(
    id: json['id'],
    amount: json['amount'],
    hasClaimed: json['hasClaimed'],
    claimedAt: json['claimedAt'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'hasClaimed': hasClaimed,
    if (claimedAt != null) 'claimedAt': claimedAt,
  };
}

/// Request body for funding an escrow contract.
class FundEscrowRequest {
  final String escrowId;
  final String sparkTransferId;
  final String nonce;
  final String signature;

  FundEscrowRequest({
    required this.escrowId,
    required this.sparkTransferId,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'escrowId': escrowId,
    'sparkTransferId': sparkTransferId,
    'nonce': nonce,
    'signature': signature,
  };

  factory FundEscrowRequest.fromJson(Map<String, dynamic> json) => FundEscrowRequest(
    escrowId: json['escrowId'],
    sparkTransferId: json['sparkTransferId'],
    nonce: json['nonce'],
    signature: json['signature'],
  );
}

/// Response for listing LP position locks.
class GetPositionLocksResponse {
  final List<LpLockInfo> locks;

  GetPositionLocksResponse({required this.locks});

  factory GetPositionLocksResponse.fromJson(Map<String, dynamic> json) => 
    GetPositionLocksResponse(
      locks: (json['locks'] as List)
          .map((l) => LpLockInfo.fromJson(l as Map<String, dynamic>))
          .toList(),
    );

  Map<String, dynamic> toJson() => {
    'locks': locks.map((l) => l.toJson()).toList(),
  };
}

// --- Pool Initialization Validation ---

class ValidateAmmInitializeConstantProductPoolData {
  final String poolOwnerPublicKey;
  final String assetAAddress;
  final String assetBAddress;
  final String totalHostFeeRateBps;
  final String lpFeeRateBps;
  final String nonce;

  ValidateAmmInitializeConstantProductPoolData({
    required this.poolOwnerPublicKey,
    required this.assetAAddress,
    required this.assetBAddress,
    required this.totalHostFeeRateBps,
    required this.lpFeeRateBps,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'poolOwnerPublicKey': poolOwnerPublicKey,
    'assetAAddress': assetAAddress,
    'assetBAddress': assetBAddress,
    'totalHostFeeRateBps': totalHostFeeRateBps,
    'lpFeeRateBps': lpFeeRateBps,
    'nonce': nonce,
  };
}

class ValidateAmmConfirmInitialDepositData {
  final String poolOwnerPublicKey;
  final String lpIdentityPublicKey;
  final String assetASparkTransferId;
  final String nonce;

  ValidateAmmConfirmInitialDepositData({
    required this.poolOwnerPublicKey,
    required this.lpIdentityPublicKey,
    required this.assetASparkTransferId,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'poolOwnerPublicKey': poolOwnerPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'assetASparkTransferId': assetASparkTransferId,
    'nonce': nonce,
  };
}

// --- Route Swap Validation ---

class RouteHopValidation {
  final String lpIdentityPublicKey;
  final String inputAssetAddress;
  final String outputAssetAddress;
  final String? hopIntegratorFeeRateBps;

  RouteHopValidation({
    required this.lpIdentityPublicKey,
    required this.inputAssetAddress,
    required this.outputAssetAddress,
    this.hopIntegratorFeeRateBps,
  });

  Map<String, dynamic> toJson() => {
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'inputAssetAddress': inputAssetAddress,
    'outputAssetAddress': outputAssetAddress,
    'hopIntegratorFeeRateBps': hopIntegratorFeeRateBps, // jsonEncode will include as null if null
  };

  factory RouteHopValidation.fromJson(Map<String, dynamic> json) => RouteHopValidation(
    lpIdentityPublicKey: json['lpIdentityPublicKey'],
    inputAssetAddress: json['inputAssetAddress'],
    outputAssetAddress: json['outputAssetAddress'],
    hopIntegratorFeeRateBps: json['hopIntegratorFeeRateBps'],
  );
}

// --- V3 Balance Validation ---

/// Data for validating a withdraw balance intent.
class ValidateWithdrawBalanceData {
  final String userPublicKey;
  final String lpIdentityPublicKey;
  final String amountA;
  final String amountB;
  final String nonce;

  ValidateWithdrawBalanceData({
    required this.userPublicKey,
    required this.lpIdentityPublicKey,
    required this.amountA,
    required this.amountB,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'amountA': amountA,
    'amountB': amountB,
    'nonce': nonce,
  };
}

/// Data for validating a deposit balance intent.
class ValidateDepositBalanceData {
  final String userPublicKey;
  final String lpIdentityPublicKey;
  final String assetASparkTransferId;
  final String assetBSparkTransferId;
  final String amountA;
  final String amountB;
  final String nonce;

  ValidateDepositBalanceData({
    required this.userPublicKey,
    required this.lpIdentityPublicKey,
    required this.assetASparkTransferId,
    required this.assetBSparkTransferId,
    required this.amountA,
    required this.amountB,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'userPublicKey': userPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'assetASparkTransferId': assetASparkTransferId,
    'assetBSparkTransferId': assetBSparkTransferId,
    'amountA': amountA,
    'amountB': amountB,
    'nonce': nonce,
  };
}