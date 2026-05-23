import 'dart:convert';
import 'dart:typed_data';
import '../types/index.dart';

/// Generates a pool initialization intent message
Uint8List generatePoolInitializationIntentMessage({
  required String poolOwnerPublicKey,
  required String assetAAddress,
  required String assetBAddress,
  required String assetAInitialReserve,
  required String virtualReserveA,
  required String virtualReserveB,
  required String threshold,
  required String lpFeeRateBps,
  required String totalHostFeeRateBps,
  required String nonce,
}) {
  final intentMessage = ValidateAmmInitializeSingleSidedPoolData(
    poolOwnerPublicKey: poolOwnerPublicKey,
    assetAAddress: assetAAddress,
    assetBAddress: assetBAddress,
    assetAInitialReserve: assetAInitialReserve,
    virtualReserveA: virtualReserveA,
    virtualReserveB: virtualReserveB,
    threshold: threshold,
    totalHostFeeRateBps: totalHostFeeRateBps,
    lpFeeRateBps: lpFeeRateBps,
    nonce: nonce,
  );

  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage.toJson())));
}

/// Generates a constant product pool initialization intent message
Uint8List generateConstantProductPoolInitializationIntentMessage({
  required String poolOwnerPublicKey,
  required String assetAAddress,
  required String assetBAddress,
  required String lpFeeRateBps,
  required String totalHostFeeRateBps,
  required String nonce,
}) {
  final intentMessage = ValidateAmmInitializeConstantProductPoolData(
    poolOwnerPublicKey: poolOwnerPublicKey,
    assetAAddress: assetAAddress,
    assetBAddress: assetBAddress,
    totalHostFeeRateBps: totalHostFeeRateBps,
    lpFeeRateBps: lpFeeRateBps,
    nonce: nonce,
  );

  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage.toJson())));
}

/// Generates a pool confirm initial deposit intent message
Uint8List generatePoolConfirmInitialDepositIntentMessage({
  required String poolOwnerPublicKey,
  required String lpIdentityPublicKey,
  required String assetASparkTransferId,
  required String nonce,
}) {
  final intentMessage = ValidateAmmConfirmInitialDepositData(
    poolOwnerPublicKey: poolOwnerPublicKey,
    lpIdentityPublicKey: lpIdentityPublicKey,
    assetASparkTransferId: assetASparkTransferId,
    nonce: nonce,
  );
  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage.toJson())));
}

/// Generates a pool swap intent message
Uint8List generatePoolSwapIntentMessage({
  required String userPublicKey,
  required String lpIdentityPublicKey,
  String? assetInSparkTransferId,
  required String assetInAddress,
  required String assetOutAddress,
  required String amountIn,
  required String maxSlippageBps,
  required String minAmountOut,
  required String totalIntegratorFeeRateBps,
  required String nonce,
  bool? useFreeBalance,
}) {
  final isUsingFreeBalance = useFreeBalance == true || 
      (assetInSparkTransferId == null || assetInSparkTransferId.isEmpty);
  
  final transferId = isUsingFreeBalance ? "" : assetInSparkTransferId;

  final intentMessage = ValidateAmmSwapData(
    userPublicKey: userPublicKey,
    lpIdentityPublicKey: lpIdentityPublicKey,
    assetInSparkTransferId: transferId,
    assetInAddress: assetInAddress,
    assetOutAddress: assetOutAddress,
    amountIn: amountIn,
    minAmountOut: minAmountOut,
    maxSlippageBps: maxSlippageBps,
    nonce: nonce,
    totalIntegratorFeeRateBps: totalIntegratorFeeRateBps,
  );

  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage.toJson())));
}

/// Generate the intent message for adding liquidity
Uint8List generateAddLiquidityIntentMessage(
  AmmAddLiquiditySettlementRequest params,
) {
  final signingPayload = {
    'userPublicKey': params.userPublicKey,
    'lpIdentityPublicKey': params.lpIdentityPublicKey,
    'assetASparkTransferId': params.assetASparkTransferId,
    'assetBSparkTransferId': params.assetBSparkTransferId,
    'assetAAmount': BigInt.parse(params.assetAAmount).toString(),
    'assetBAmount': BigInt.parse(params.assetBAmount).toString(),
    'assetAMinAmountIn': BigInt.parse(params.assetAMinAmountIn).toString(),
    'assetBMinAmountIn': BigInt.parse(params.assetBMinAmountIn).toString(),
    'nonce': params.nonce,
  };

  return Uint8List.fromList(utf8.encode(jsonEncode(signingPayload)));
}

/// Generate the intent message for removing liquidity
Uint8List generateRemoveLiquidityIntentMessage(
  AmmRemoveLiquiditySettlementRequest params,
) {
  final signingPayload = {
    'userPublicKey': params.userPublicKey,
    'lpIdentityPublicKey': params.lpIdentityPublicKey,
    'lpTokensToRemove': params.lpTokensToRemove,
    'nonce': params.nonce,
  };

  return Uint8List.fromList(utf8.encode(jsonEncode(signingPayload)));
}

/// Generate the intent message for registering a host
Uint8List generateRegisterHostIntentMessage({
  required String namespace,
  required int minFeeBps,
  required String feeRecipientPublicKey,
  required String nonce,
}) {
  final signingPayload = {
    'namespace': namespace,
    'minFeeBps': minFeeBps,
    'feeRecipientPublicKey': feeRecipientPublicKey,
    'nonce': nonce,
    'signature': "",
  };

  return Uint8List.fromList(utf8.encode(jsonEncode(signingPayload)));
}

/// Generate the intent message for withdrawing host fees
Uint8List generateWithdrawHostFeesIntentMessage({
  required String hostPublicKey,
  required String lpIdentityPublicKey,
  String? assetBAmount,
  required String nonce,
}) {
  final signingPayload = {
    'hostPublicKey': hostPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'assetBAmount': assetBAmount,
    'nonce': nonce,
  };

  return Uint8List.fromList(utf8.encode(jsonEncode(signingPayload)));
}

/// Generate the intent message for withdrawing integrator fees
Uint8List generateWithdrawIntegratorFeesIntentMessage({
  required String integratorPublicKey,
  required String lpIdentityPublicKey,
  String? assetBAmount,
  required String nonce,
}) {
  final signingPayload = ValidateAmmWithdrawIntegratorFeesData(
    integratorPublicKey: integratorPublicKey,
    lpIdentityPublicKey: lpIdentityPublicKey,
    assetBAmount: assetBAmount,
    nonce: nonce,
  );

  return Uint8List.fromList(utf8.encode(jsonEncode(signingPayload.toJson())));
}

/// Generate the intent message for route swap
Uint8List generateRouteSwapIntentMessage({
  required String userPublicKey,
  required List<RouteHopValidation> hops,
  required String initialSparkTransferId,
  required String inputAmount,
  required String maxRouteSlippageBps,
  required String minAmountOut,
  required String nonce,
  String? defaultIntegratorFeeRateBps,
}) {
  final signingPayload = ValidateRouteSwapData(
    userPublicKey: userPublicKey,
    hops: hops,
    initialSparkTransferId: initialSparkTransferId,
    inputAmount: inputAmount,
    minFinalOutputAmount: minAmountOut,
    maxRouteSlippageBps: maxRouteSlippageBps,
    nonce: nonce,
    defaultIntegratorFeeRateBps: defaultIntegratorFeeRateBps ?? "0",
  );

  return Uint8List.fromList(utf8.encode(jsonEncode(signingPayload.toJson())));
}

/// Generates an escrow creation intent message.
Uint8List generateCreateEscrowIntentMessage({
  required String creatorPublicKey,
  required String assetId,
  required String assetAmount,
  required List<EscrowRecipient> recipients,
  required List<EscrowCondition> claimConditions,
  String? abandonHost,
  List<EscrowCondition>? abandonConditions,
  required String nonce,
}) {
  final intentMessage = ValidateEscrowCreateData(
    creatorPublicKey: creatorPublicKey,
    assetId: assetId,
    assetAmount: assetAmount,
    recipients: recipients,
    claimConditions: claimConditions,
    abandonHost: abandonHost,
    abandonConditions: abandonConditions,
    nonce: nonce,
  );
  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage.toJson())));
}

/// Generates an escrow funding intent message.
Uint8List generateFundEscrowIntentMessage({
  required String escrowId,
  required String creatorPublicKey,
  required String sparkTransferId,
  required String nonce,
}) {
  final intentMessage = ValidateEscrowFundData(
    escrowId: escrowId,
    creatorPublicKey: creatorPublicKey,
    sparkTransferId: sparkTransferId,
    nonce: nonce,
  );
  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage.toJson())));
}

/// Generates an escrow claim intent message.
Uint8List generateClaimEscrowIntentMessage({
  required String escrowId,
  required String recipientPublicKey,
  required String nonce,
}) {
  final intentMessage = ValidateEscrowClaimData(
    escrowId: escrowId,
    recipientPublicKey: recipientPublicKey,
    nonce: nonce,
  );
  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage.toJson())));
}

/// Generate the intent message for clawback
Uint8List generateClawbackIntentMessage({
  required String senderPublicKey,
  required String sparkTransferId,
  required String lpIdentityPublicKey,
  required String nonce,
}) {
  final signingPayload = ValidateClawbackData(
    senderPublicKey: senderPublicKey,
    sparkTransferId: sparkTransferId,
    lpIdentityPublicKey: lpIdentityPublicKey,
    nonce: nonce,
  );

  return Uint8List.fromList(utf8.encode(jsonEncode(signingPayload.toJson())));
}

// V3 CONCENTRATED LIQUIDITY INTENT GENERATORS

/// Generate the intent message for creating a concentrated liquidity pool (V3)
Uint8List generateCreateConcentratedPoolIntentMessage({
  required String poolOwnerPublicKey,
  required String assetAAddress,
  required String assetBAddress,
  required int tickSpacing,
  required String initialPrice,
  required String lpFeeRateBps,
  required String hostFeeRateBps,
  required String nonce,
}) {
  final intentMessage = ValidateConcentratedPoolData(
    poolOwnerPublicKey: poolOwnerPublicKey,
    assetAAddress: assetAAddress,
    assetBAddress: assetBAddress,
    tickSpacing: tickSpacing,
    initialPrice: initialPrice,
    lpFeeRateBps: lpFeeRateBps,
    hostFeeRateBps: hostFeeRateBps,
    nonce: nonce,
  );

  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage.toJson())));
}

/// Generate the intent message for increasing liquidity in a V3 position
Uint8List generateIncreaseLiquidityIntentMessage({
  required String userPublicKey,
  required String lpIdentityPublicKey,
  required int tickLower,
  required int tickUpper,
  required String assetASparkTransferId,
  required String assetBSparkTransferId,
  required String amountADesired,
  required String amountBDesired,
  required String amountAMin,
  required String amountBMin,
  required String nonce,
}) {
  final intentMessage = ValidateIncreaseLiquidityData(
    userPublicKey: userPublicKey,
    lpIdentityPublicKey: lpIdentityPublicKey,
    tickLower: tickLower,
    tickUpper: tickUpper,
    assetASparkTransferId: assetASparkTransferId,
    assetBSparkTransferId: assetBSparkTransferId,
    amountADesired: amountADesired,
    amountBDesired: amountBDesired,
    amountAMin: amountAMin,
    amountBMin: amountBMin,
    nonce: nonce,
  );

  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage.toJson())));
}

/// Generate the intent message for decreasing liquidity in a V3 position
Uint8List generateDecreaseLiquidityIntentMessage({
  required String userPublicKey,
  required String lpIdentityPublicKey,
  required int tickLower,
  required int tickUpper,
  required String liquidityToRemove,
  required String amountAMin,
  required String amountBMin,
  required String nonce,
}) {
  final intentMessage = ValidateDecreaseLiquidityData(
    userPublicKey: userPublicKey,
    lpIdentityPublicKey: lpIdentityPublicKey,
    tickLower: tickLower,
    tickUpper: tickUpper,
    liquidityToRemove: liquidityToRemove,
    amountAMin: amountAMin,
    amountBMin: amountBMin,
    nonce: nonce,
  );

  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage.toJson())));
}

/// Generate the intent message for collecting fees from a V3 position
Uint8List generateCollectFeesIntentMessage({
  required String userPublicKey,
  required String lpIdentityPublicKey,
  required int tickLower,
  required int tickUpper,
  required String nonce,
}) {
  final intentMessage = ValidateCollectFeesData(
    userPublicKey: userPublicKey,
    lpIdentityPublicKey: lpIdentityPublicKey,
    tickLower: tickLower,
    tickUpper: tickUpper,
    nonce: nonce,
  );

  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage.toJson())));
}

/// Generate the intent message for rebalancing a V3 position to a new tick range
Uint8List generateRebalancePositionIntentMessage({
  required String userPublicKey,
  required String lpIdentityPublicKey,
  required int oldTickLower,
  required int oldTickUpper,
  required int newTickLower,
  required int newTickUpper,
  required String liquidityToMove,
  String? assetASparkTransferId,
  String? assetBSparkTransferId,
  String? additionalAmountA,
  String? additionalAmountB,
  required String nonce,
}) {
  // Explicitly mapping to match TEE's proto serde behavior (including nulls)
  final signingPayload = {
    'userPublicKey': userPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'oldTickLower': oldTickLower,
    'oldTickUpper': oldTickUpper,
    'newTickLower': newTickLower,
    'newTickUpper': newTickUpper,
    'liquidityToMove': liquidityToMove,
    'assetASparkTransferId': assetASparkTransferId, // jsonEncode keeps nulls
    'assetBSparkTransferId': assetBSparkTransferId,
    'additionalAmountA': additionalAmountA,
    'additionalAmountB': additionalAmountB,
    'nonce': nonce,
  };

  return Uint8List.fromList(utf8.encode(jsonEncode(signingPayload)));
}

/// Generate the intent message for withdrawing free balance from a V3 pool
Uint8List generateWithdrawBalanceIntentMessage({
  required String userPublicKey,
  required String lpIdentityPublicKey,
  required String amountA,
  required String amountB,
  required String nonce,
}) {
  final intentMessage = ValidateWithdrawBalanceData(
    userPublicKey: userPublicKey,
    lpIdentityPublicKey: lpIdentityPublicKey,
    amountA: amountA,
    amountB: amountB,
    nonce: nonce,
  );

  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage.toJson())));
}

/// Generate the intent message for depositing to free balance in a V3 pool
Uint8List generateDepositBalanceIntentMessage({
  required String userPublicKey,
  required String lpIdentityPublicKey,
  required String assetASparkTransferId,
  required String assetBSparkTransferId,
  required String amountA,
  required String amountB,
  required String nonce,
}) {
  final intentMessage = ValidateDepositBalanceData(
    userPublicKey: userPublicKey,
    lpIdentityPublicKey: lpIdentityPublicKey,
    assetASparkTransferId: assetASparkTransferId,
    assetBSparkTransferId: assetBSparkTransferId,
    amountA: amountA,
    amountB: amountB,
    nonce: nonce,
  );

  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage.toJson())));
}

/// Generate the intent message for locking an LP position
Uint8List generateLockPositionIntentMessage({
  required String userPublicKey,
  required String lpIdentityPublicKey,
  required String lockUntilTimestamp,
  int? tickLower,
  int? tickUpper,
  required String nonce,
}) {
  // Validation logic mirroring the TS implementation
  final ts = int.tryParse(lockUntilTimestamp);
  
  if (ts == null || ts < 0 || lockUntilTimestamp.trim() != ts.toString()) {
    throw ArgumentError(
      'Invalid lockUntilTimestamp: "$lockUntilTimestamp" is not a non-negative integer',
    );
  }

  final intentMessage = {
    'userPublicKey': userPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'lockUntilTimestamp': ts,
    'tickLower': tickLower,
    'tickUpper': tickUpper,
    'nonce': nonce,
  };

  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage)));
}

/// Generate the intent message for transferring an LP position to a new owner.
/// Single-step: signing this hands off ownership on server acceptance.
Uint8List generateTransferPositionIntentMessage({
  required String userPublicKey,
  required String lpIdentityPublicKey,
  required String newOwnerPublicKey,
  int? tickLower,
  int? tickUpper,
  String? lpTokensToTransfer,
  required String nonce,
}) {
  // Case-insensitive self-transfer check
  if (newOwnerPublicKey.toLowerCase() == userPublicKey.toLowerCase()) {
    throw ArgumentError(
      "Self-transfer not allowed: newOwnerPublicKey must differ from userPublicKey",
    );
  }

  // V3 vs V2 Shape Validation
  final bool tlSet = tickLower != null;
  final bool tuSet = tickUpper != null;

  if (tlSet != tuSet) {
    throw ArgumentError(
      "tickLower and tickUpper must both be provided for V3, or both omitted for V2",
    );
  }

  final bool lpAmountSet = 
      lpTokensToTransfer != null && lpTokensToTransfer.isNotEmpty;

  if (!tlSet && !tuSet && !lpAmountSet) {
    throw ArgumentError(
      "Provide either V3 tickLower+tickUpper or V2 lpTokensToTransfer; neither was supplied",
    );
  }

  if (tlSet && tuSet && lpAmountSet) {
    throw ArgumentError(
      "lpTokensToTransfer (V2) cannot be combined with tickLower/tickUpper (V3); use one or the other",
    );
  }

  // V3 Specific Validation
  if (tlSet && tuSet) {
    if (tickLower >= tickUpper) {
      throw ArgumentError("tickLower must be less than tickUpper");
    }
  }

  // V2 Specific Validation: Strict positive integer check
  if (lpAmountSet) {
    // Regex: No leading zeros, digits only, positive integer
    final bool valid = RegExp(r'^[1-9][0-9]*$').hasMatch(lpTokensToTransfer);
    if (!valid) {
      throw ArgumentError(
        'Invalid lpTokensToTransfer: $lpTokensToTransfer; must be a positive integer string (digits only, no sign, no decimals, no leading zeros)',
      );
    }
  }

  // Build payload: nulls are explicitly preserved for TEE/Backend compatibility
  final intentMessage = {
    'userPublicKey': userPublicKey,
    'lpIdentityPublicKey': lpIdentityPublicKey,
    'newOwnerPublicKey': newOwnerPublicKey,
    'tickLower': tickLower,
    'tickUpper': tickUpper,
    'lpTokensToTransfer': lpTokensToTransfer,
    'nonce': nonce,
  };

  return Uint8List.fromList(utf8.encode(jsonEncode(intentMessage)));
}