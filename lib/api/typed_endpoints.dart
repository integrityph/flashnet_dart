import '../types/index.dart' as types;
import 'client.dart';

/// Typed API endpoints for the Flashnet AMM Gateway
class TypedAmmApi {
  final ApiClient client;

  TypedAmmApi(this.client);

  // Authentication Endpoints

  /// Request authentication challenge
  /// [POST] /v1/auth/challenge
  Future<types.ChallengeResponse> getChallenge(
    types.ChallengeRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/auth/challenge",
      request.toJson(),
    );
    return types.ChallengeResponse.fromJson(response);
  }

  /// Verify challenge and get access token
  /// [POST] /v1/auth/verify
  Future<types.VerifyResponse> verify(types.VerifyRequest request) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/auth/verify",
      request.toJson(),
    );
    return types.VerifyResponse.fromJson(response);
  }

  // Host Endpoints

  /// Register a new host
  /// [POST] /v1/hosts/register
  /// @requires Bearer token
  Future<types.RegisterHostResponse> registerHost(
    types.RegisterHostRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/hosts/register",
      request.toJson(),
    );
    return types.RegisterHostResponse.fromJson(response);
  }

  /// Get host information
  /// [GET] /v1/hosts/{namespace}
  Future<types.GetHostResponse> getHost(String namespace) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/hosts/$namespace",
    );
    return types.GetHostResponse.fromJson(response);
  }

  /// Withdraw host fees
  /// [POST] /v1/hosts/withdraw-fees
  /// @requires Bearer token
  Future<types.WithdrawHostFeesResponse> withdrawHostFees(
    types.WithdrawHostFeesRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/hosts/withdraw-fees",
      request.toJson(),
    );
    return types.WithdrawHostFeesResponse.fromJson(response);
  }

  /// Get pool host fees
  /// [POST] /v1/hosts/pool-fees
  /// @requires Bearer token
  Future<types.GetPoolHostFeesResponse> getPoolHostFees(
    types.GetPoolHostFeesRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/hosts/pool-fees",
      request.toJson(),
    );
    return types.GetPoolHostFeesResponse.fromJson(response);
  }

  /// Get host fees across all pools
  /// [POST] /v1/hosts/host-fees
  /// @requires Bearer token
  Future<types.GetHostFeesResponse> getHostFees(
    types.GetHostFeesRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/hosts/fees",
      request.toJson(),
    );
    return types.GetHostFeesResponse.fromJson(response);
  }

  /// Get host fee withdrawal history
  /// [GET] /v1/hosts/fee-withdrawal-history
  /// @requires Bearer token
  Future<types.FeeWithdrawalHistoryResponse> getHostFeeWithdrawalHistory([
    types.FeeWithdrawalHistoryQuery? query,
  ]) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/hosts/fee-withdrawal-history",
      RequestOptions(params: query?.toJson()),
    );
    return types.FeeWithdrawalHistoryResponse.fromJson(response);
  }

  // Pool Endpoints

  /// Create constant product pool
  /// [POST] /v1/pools/constant-product
  /// @requires Bearer token
  Future<types.CreatePoolResponse> createConstantProductPool(
    types.CreateConstantProductPoolRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/pools/constant-product",
      request.toJson(),
    );
    return types.CreatePoolResponse.fromJson(response);
  }

  /// Create single-sided pool
  /// [POST] /v1/pools/single-sided
  /// @requires Bearer token
  Future<types.CreatePoolResponse> createSingleSidedPool(
    types.CreateSingleSidedPoolRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/pools/single-sided",
      request.toJson(),
    );
    return types.CreatePoolResponse.fromJson(response);
  }

  /// Confirm initial deposit for single-sided pool
  /// [POST] /v1/pools/single-sided/confirm-initial-deposit
  /// @requires Bearer token
  Future<types.ConfirmDepositResponse> confirmInitialDeposit(
    types.ConfirmInitialDepositRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/pools/single-sided/confirm-initial-deposit",
      request.toJson(),
    );
    return types.ConfirmDepositResponse.fromJson(response);
  }

  /// List pools with filters
  /// [GET] /v1/pools
  Future<types.ListPoolsResponse> listPools([
    types.ListPoolsQuery? query,
  ]) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/pools",
      RequestOptions(params: query?.toJson()),
    );
    return types.ListPoolsResponse.fromJson(response);
  }

  /// Get pool details
  /// [GET] /v1/pools/{poolId}
  Future<types.PoolDetailsResponse> getPool(String poolId) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/pools/$poolId",
    );
    return types.PoolDetailsResponse.fromJson(response);
  }

  /// Get LP position details
  /// [GET] /v1/pools/{poolId}/lp/{providerPublicKey}
  /// @requires Bearer token
  Future<types.LpPositionDetailsResponse> getLpPosition(
    String poolId,
    String providerPublicKey,
  ) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/pools/$poolId/lp/$providerPublicKey",
    );
    return types.LpPositionDetailsResponse.fromJson(response);
  }

  /// Get all LP positions
  /// [GET] /v1/pools/lp
  /// @requires Bearer token
  Future<types.AllLpPositionsResponse> getAllLpPositions() async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/liquidity/positions",
    );
    return types.AllLpPositionsResponse.fromJson(response);
  }

  // Liquidity Endpoints

  /// Add liquidity to pool
  /// [POST] /v1/liquidity/add
  /// @requires Bearer token
  Future<types.AddLiquidityResponse> addLiquidity(
    types.AddLiquidityRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/liquidity/add",
      request.toJson(),
    );
    return types.AddLiquidityResponse.fromJson(response);
  }

  /// Simulate adding liquidity
  /// [POST] /v1/liquidity/add/simulate
  Future<types.SimulateAddLiquidityResponse> simulateAddLiquidity(
    types.SimulateAddLiquidityRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/liquidity/add/simulate",
      request.toJson(),
    );
    return types.SimulateAddLiquidityResponse.fromJson(response);
  }

  /// Remove liquidity from pool
  /// [POST] /v1/liquidity/remove
  /// @requires Bearer token
  Future<types.RemoveLiquidityResponse> removeLiquidity(
    types.RemoveLiquidityRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/liquidity/remove",
      request.toJson(),
    );
    return types.RemoveLiquidityResponse.fromJson(response);
  }

  /// Simulate removing liquidity
  /// [POST] /v1/liquidity/remove/simulate
  Future<types.SimulateRemoveLiquidityResponse> simulateRemoveLiquidity(
    types.SimulateRemoveLiquidityRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/liquidity/remove/simulate",
      request.toJson(),
    );
    return types.SimulateRemoveLiquidityResponse.fromJson(response);
  }

  // Swap Endpoints

  /// Execute swap
  /// [POST] /v1/swap
  /// @requires Bearer token
  Future<types.SwapResponse> executeSwap(
    types.ExecuteSwapRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/swap",
      request.toJson(),
    );
    return types.SwapResponse.fromJson(response);
  }

  /// Simulate swap
  /// [POST] /v1/swap/simulate
  Future<types.SimulateSwapResponse> simulateSwap(
    types.SimulateSwapRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/swap/simulate",
      request.toJson(),
    );
    return types.SimulateSwapResponse.fromJson(response);
  }

  /// Get swaps for a pool
  /// [GET] /v1/pools/{lpPubkey}/swaps
  Future<types.ListPoolSwapsResponse> getPoolSwaps(
    String lpPubkey, [
    types.ListPoolSwapsQuery? query,
  ]) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/pools/$lpPubkey/swaps",
      RequestOptions(params: query?.toJson()),
    );
    return types.ListPoolSwapsResponse.fromJson(response);
  }

  /// Get global swaps
  /// [GET] /v1/swaps
  Future<types.ListGlobalSwapsResponse> getGlobalSwaps([
    types.ListGlobalSwapsQuery? query,
  ]) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/swaps",
      RequestOptions(params: query?.toJson()),
    );
    return types.ListGlobalSwapsResponse.fromJson(response);
  }

  /// Get user swaps
  /// [GET] /v1/swaps/user/{userPublicKey}
  Future<types.ListUserSwapsResponse> getUserSwaps(
    String userPublicKey, [
    types.ListUserSwapsQuery? query,
  ]) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/swaps/user/$userPublicKey",
      RequestOptions(params: query?.toJson()),
    );
    return types.ListUserSwapsResponse.fromJson(response);
  }

  // Route Swap Endpoints

  /// Execute route swap
  /// [POST] /v1/route-swap
  /// @requires Bearer token
  Future<types.ExecuteRouteSwapResponse> executeRouteSwap(
    types.ExecuteRouteSwapRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/route-swap",
      request.toJson(),
    );
    return types.ExecuteRouteSwapResponse.fromJson(response);
  }

  /// Simulate route swap
  /// [POST] /v1/route-swap/simulate
  Future<types.SimulateRouteSwapResponse> simulateRouteSwap(
    types.SimulateRouteSwapRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/route-swap/simulate",
      request.toJson(),
    );
    return types.SimulateRouteSwapResponse.fromJson(response);
  }

  // Integrator Endpoints

  /// Get integrator fees across all pools
  /// [GET] /v1/integrators/fees
  /// @requires Bearer token
  Future<types.GetIntegratorFeesResponse> getIntegratorFees() async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/integrators/fees",
    );
    return types.GetIntegratorFeesResponse.fromJson(response);
  }

  /// Get integrator fee withdrawal history
  /// [GET] /v1/integrators/fee-withdrawal-history
  /// @requires Bearer token
  Future<types.FeeWithdrawalHistoryResponse> getIntegratorFeeWithdrawalHistory([
    types.FeeWithdrawalHistoryQuery? query,
  ]) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/integrators/fee-withdrawal-history",
      RequestOptions(params: query?.toJson()),
    );
    return types.FeeWithdrawalHistoryResponse.fromJson(response);
  }

  /// Get pool integrator fees
  /// [POST] /v1/integrators/pool-fees
  /// @requires Bearer token
  Future<types.GetPoolIntegratorFeesResponse> getPoolIntegratorFees(
    String poolId
  ) async {
    final request = types.GetPoolIntegratorFeesRequest(poolId: poolId);
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/integrators/pool-fees",
      request.toJson(),
    );
    return types.GetPoolIntegratorFeesResponse.fromJson(response);
  }

  /// Withdraw integrator fees
  /// [POST] /v1/integrators/withdraw-fees
  /// @requires Bearer token
  Future<types.WithdrawIntegratorFeesResponse> withdrawIntegratorFees(
    types.WithdrawIntegratorFeesRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/integrators/withdraw-fees",
      request.toJson(),
    );
    return types.WithdrawIntegratorFeesResponse.fromJson(response);
  }

  // Escrow Endpoints

  /// Create a new escrow contract
  /// [POST] /v1/escrows/create
  /// @requires Bearer token
  Future<types.CreateEscrowResponse> createEscrow(
    types.CreateEscrowRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/escrows/create",
      request.toJson(),
    );
    return types.CreateEscrowResponse.fromJson(response);
  }

  /// Fund an existing escrow contract
  /// [POST] /v1/escrows/fund
  /// @requires Bearer token
  Future<types.FundEscrowResponse> fundEscrow(
    types.FundEscrowRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/escrows/fund",
      request.toJson(),
    );
    return types.FundEscrowResponse.fromJson(response);
  }

  /// Claim funds from an escrow contract
  /// [POST] /v1/escrows/claim
  /// @requires Bearer token
  Future<types.ClaimEscrowResponse> claimEscrow(
    types.ClaimEscrowRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/escrows/claim",
      request.toJson(),
    );
    return types.ClaimEscrowResponse.fromJson(response);
  }

  /// Get the state of an escrow contract
  /// [GET] /v1/escrows/{escrowId}
  Future<types.EscrowState> getEscrow(String escrowId) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/escrows/$escrowId",
    );
    return types.EscrowState.fromJson(response);
  }

  // Status Endpoints

  /// Ping settlement service
  /// [GET] /v1/ping
  Future<types.SettlementPingResponse?> ping() async {
    try {
      final response = await client.ammGet<Map<String, dynamic>>(
        "/v1/ping",
      );
      return types.SettlementPingResponse.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  // Config Endpoints

  /// Get feature status flags
  /// [GET] /v1/config/feature-status
  Future<types.FeatureStatusResponse> getFeatureStatus() async {
    final response = await client.ammGet<List<dynamic>>(
      "/v1/config/feature-status",
    );
    return response.map((e) => types.FeatureStatusItem.fromJson(e)).toList();
  }

  /// Get min amount configuration per asset
  /// [GET] /v1/config/min-amounts
  Future<types.MinAmountsResponse> getMinAmounts() async {
    final response = await client.ammGet<List<dynamic>>(
      "/v1/config/min-amounts",
    );
    return response.map((e) => types.MinAmountItem.fromJson(e)).toList();
  }

  /// Get allowed Asset B list for pool creation
  /// [GET] /v1/config/allowed-assets
  Future<types.AllowedAssetsResponse> getAllowedAssets() async {
    final response = await client.ammGet<List<dynamic>>(
      "/v1/config/allowed-assets",
    );
    return response.map((e) => types.AllowedAssetItem.fromJson(e)).toList();
  }

  // Clawback Endpoint

  /// Clawback stuck funds sent to an LP wallet
  /// [POST] /v1/clawback
  /// @requires Bearer token
  Future<types.ClawbackResponse> clawback(
    types.ClawbackRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/clawback",
      request.toJson(),
    );
    return types.ClawbackResponse.fromJson(response);
  }

  /// Check if a transfer is eligible for clawback
  /// [POST] /v1/check_clawback_eligibility
  /// @requires Bearer token
  Future<types.CheckClawbackEligibilityResponse> checkClawbackEligibility(
    types.CheckClawbackEligibilityRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/check_clawback_eligibility",
      request.toJson(),
    );
    return types.CheckClawbackEligibilityResponse.fromJson(response);
  }

  /// List transfers eligible for clawback
  /// [GET] /v1/clawback-transfers/list
  /// @requires Bearer token
  Future<types.ListClawbackableTransfersResponse> listClawbackableTransfers([
    types.ListClawbackableTransfersQuery? query,
  ]) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/clawback-transfers/list",
      RequestOptions(params: query?.toJson()),
    );
    return types.ListClawbackableTransfersResponse.fromJson(response);
  }

  // V3 Concentrated Liquidity Endpoints

  /// Create a new concentrated liquidity pool (V3)
  /// [POST] /v1/pools/concentrated
  /// @requires Bearer token
  Future<types.CreateConcentratedPoolResponse> createConcentratedPool(
    types.CreateConcentratedPoolRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/pools/concentrated",
      request.toJson(),
    );
    return types.CreateConcentratedPoolResponse.fromJson(response);
  }

  /// Increase liquidity in a V3 concentrated position
  /// [POST] /v1/concentrated/liquidity/increase
  /// @requires Bearer token
  Future<types.IncreaseLiquidityResponse> increaseLiquidity(
    types.IncreaseLiquidityRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/concentrated/liquidity/increase",
      request.toJson(),
    );
    return types.IncreaseLiquidityResponse.fromJson(response);
  }

  /// Decrease liquidity in a V3 concentrated position
  /// [POST] /v1/concentrated/liquidity/decrease
  /// @requires Bearer token
  Future<types.DecreaseLiquidityResponse> decreaseLiquidity(
    types.DecreaseLiquidityRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/concentrated/liquidity/decrease",
      request.toJson(),
    );
    return types.DecreaseLiquidityResponse.fromJson(response);
  }

  /// Collect accumulated fees from a V3 position
  /// [POST] /v1/concentrated/fees/collect
  /// @requires Bearer token
  Future<types.CollectFeesResponse> collectFees(
    types.CollectFeesRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/concentrated/fees/collect",
      request.toJson(),
    );
    return types.CollectFeesResponse.fromJson(response);
  }

  // Route Swap Endpoints (Continued)

  /// Rebalance a V3 position to a new tick range
  /// [POST] /v1/concentrated/positions/rebalance
  /// @requires Bearer token
  Future<types.RebalancePositionResponse> rebalancePosition(
    types.RebalancePositionRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/concentrated/positions/rebalance",
      request.toJson(),
    );
    return types.RebalancePositionResponse.fromJson(response);
  }

  /// List V3 concentrated liquidity positions
  /// [GET] /v1/concentrated/positions
  /// @requires Bearer token
  Future<types.ListConcentratedPositionsResponse> listConcentratedPositions([
    types.ListConcentratedPositionsQuery? query,
  ]) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/concentrated/positions",
      RequestOptions(params: query?.toJson()),
    );
    return types.ListConcentratedPositionsResponse.fromJson(response);
  }

  /// Get pool liquidity distribution for visualization
  /// [GET] /v1/concentrated/pools/{poolId}/liquidity
  Future<types.PoolLiquidityResponse> getPoolLiquidity(String poolId) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/concentrated/pools/$poolId/liquidity",
    );
    return types.PoolLiquidityResponse.fromJson(response);
  }

  /// Get pool ticks for simulation
  /// [GET] /v1/concentrated/pools/{poolId}/ticks
  Future<types.PoolTicksResponse> getPoolTicks(String poolId) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/concentrated/pools/$poolId/ticks",
    );
    return types.PoolTicksResponse.fromJson(response);
  }

  /// Get user's free balance for a specific V3 pool
  /// [GET] /v1/concentrated/balance/{poolId}
  /// @requires Bearer token
  Future<types.GetBalanceResponse> getConcentratedBalance(String poolId) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/concentrated/balance/$poolId",
    );
    return types.GetBalanceResponse.fromJson(response);
  }

  /// Get user's free balances across all V3 pools
  /// [GET] /v1/concentrated/balances
  /// @requires Bearer token
  Future<types.GetBalancesResponse> getConcentratedBalances() async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/concentrated/balances",
    );
    return types.GetBalancesResponse.fromJson(response);
  }

  /// Get user's free balance for a specific V3 pool (via balances endpoint)
  /// [GET] /v1/concentrated/balances/{poolId}
  /// @requires Bearer token
  Future<types.GetBalancesResponse> getConcentratedBalanceByPool(
    String poolId,
  ) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/concentrated/balances/$poolId",
    );
    return types.GetBalancesResponse.fromJson(response);
  }

  /// Withdraw free balance from a V3 pool to user's Spark wallet
  /// [POST] /v1/concentrated/balance/withdraw
  /// @requires Bearer token
  Future<types.WithdrawBalanceResponse> withdrawConcentratedBalance(
    types.WithdrawBalanceRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/concentrated/balance/withdraw",
      request.toJson(),
    );
    return types.WithdrawBalanceResponse.fromJson(response);
  }

  /// Deposit to free balance in a V3 pool from Spark transfers
  /// [POST] /v1/concentrated/balance/deposit
  /// @requires Bearer token
  Future<types.DepositBalanceResponse> depositConcentratedBalance(
    types.DepositBalanceRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/concentrated/balance/deposit",
      request.toJson(),
    );
    return types.DepositBalanceResponse.fromJson(response);
  }

  /// Lock an LP position to prevent withdrawal until expiry
  /// [POST] /v1/liquidity/lock
  /// @requires Bearer token
  Future<types.LockPositionResponse> lockPosition(
    types.LockPositionRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/liquidity/lock",
      request.toJson(),
    );
    return types.LockPositionResponse.fromJson(response);
  }

  /// List LP position locks for a pool
  /// [GET] /v1/liquidity/locks/:poolId
  Future<types.GetPositionLocksResponse> getPositionLocks(
    String poolId, {
    String? ownerPublicKey,
  }) async {
    final response = await client.ammGet<Map<String, dynamic>>(
      "/v1/liquidity/locks/$poolId",
      ownerPublicKey != null 
          ? RequestOptions(params: {'ownerPublicKey': ownerPublicKey}) 
          : null,
    );
    return types.GetPositionLocksResponse.fromJson(response);
  }

  /// Transfer ownership of a locked LP position to a new owner
  /// [POST] /v1/liquidity/transfer/position
  /// @requires Bearer token
  Future<types.TransferPositionResponse> transferPosition(
    types.TransferPositionRequest request,
  ) async {
    final response = await client.ammPost<Map<String, dynamic>>(
      "/v1/liquidity/transfer/position",
      request.toJson(),
    );
    return types.TransferPositionResponse.fromJson(response);
  }
}

/// Error checking utilities

/// @deprecated Use isFlashnetError from types/errors instead
/// Check if error matches the legacy FlashnetErrorResponse format (code/msg)
bool isLegacyFlashnetErrorResponse(dynamic error) {
  return error is Map<String, dynamic> &&
      error.containsKey('code') &&
      error.containsKey('msg') &&
      error['code'] is int &&
      error['msg'] is String;
}

/// @deprecated Use isLegacyFlashnetErrorResponse - this name is reserved for FlashnetError class check
bool isFlashnetError(dynamic error) => isLegacyFlashnetErrorResponse(error);

bool isApiError(dynamic error) {
  return error is Map<String, dynamic> &&
      error.containsKey('error') &&
      error['error'] is Map<String, dynamic>;
}
