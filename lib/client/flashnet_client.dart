// import 'package:issuer_sdk/issuer_sdk.dart'; // I don't support issuer wallets for now
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:spark_dart/spark_wallet/spark_wallet.dart';
import 'package:boringssl_ffi/boringssl_ffi.dart' as bssl;
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:spark_dart/spark_wallet/types.dart';
import 'package:spark_dart/utils/token_identifier.dart';

import '../api/client.dart';
import '../api/typed_endpoints.dart';
import '../config/index.dart';
import '../types/errors.dart';
import '../types/index.dart';
import '../utils/index.dart';
import '../utils/auth.dart';
import '../utils/hex.dart';
import '../utils/intents.dart';
import '../utils/spark_address.dart';
import '../utils/token_address.dart';


class TokenInfo {
  final String tokenIdentifier;
  final String tokenAddress;
  final String tokenName;
  final String tokenSymbol;
  final int tokenDecimals;
  final BigInt maxSupply;

  TokenInfo({
    required this.tokenIdentifier,
    required this.tokenAddress,
    required this.tokenName,
    required this.tokenSymbol,
    required this.tokenDecimals,
    required this.maxSupply,
  });
}

class TokenBalance {
  /// Total token balance owned (includes locked/pending)
  final BigInt balance;
  
  /// Token balance available to send (excludes locked/pending)
  final BigInt availableToSendBalance;
  
  final TokenInfo? tokenInfo;

  TokenBalance({
    required this.balance,
    required this.availableToSendBalance,
    this.tokenInfo,
  });
}

class WalletBalance {
  /// BTC balance in sats
  final BigInt balance;
  
  final Map<String, TokenBalance> tokenBalances;

  WalletBalance({
    required this.balance,
    required this.tokenBalances,
  });
}

/// Options for paying a Lightning invoice with a token
class PayLightningWithTokenOptions {
  /// BOLT11-encoded Lightning invoice to pay
  final String invoice;
  
  /// Token identifier (hex or bech32m format) to use for payment
  final String tokenAddress;
  
  /// Maximum slippage for the AMM swap in basis points (default: 500 = 5%)
  final int? maxSlippageBps;
  
  /// Maximum Lightning routing fee in sats (default: uses estimated fee from quote)
  final int? maxLightningFeeSats;
  
  /// Prefer Spark transfers when possible (default: true)
  final bool? preferSpark;
  
  /// Integrator fee rate in basis points for the swap (optional)
  final int? integratorFeeRateBps;
  
  /// Integrator public key for fee collection (optional)
  final String? integratorPublicKey;
  
  /// Maximum time to wait for swap transfer completion in ms (default: 30000)
  final int? transferTimeoutMs;
  
  /// If true, attempt to swap BTC back to token if Lightning payment fails (default: false)
  final bool? rollbackOnFailure;
  
  /// If true, pay Lightning invoice immediately using existing BTC balance instead of waiting
  /// for the swap transfer to complete. The swap BTC will arrive asynchronously.
  /// Requires sufficient existing BTC balance in wallet. (default: false)
  /// Ignored for zero-amount invoices.
  final bool? useExistingBtcBalance;
  
  /// Token amount to spend. Required for zero-amount invoices.
  /// The swap output (minus lightning fees) becomes the payment amount.
  /// Ignored for invoices with a specified amount.
  final String? tokenAmount;
  
  /// When true, checks against availableToSendBalance instead of total balance (default: false)
  final bool? useAvailableBalance;

  PayLightningWithTokenOptions({
    required this.invoice,
    required this.tokenAddress,
    this.maxSlippageBps,
    this.maxLightningFeeSats,
    this.preferSpark,
    this.integratorFeeRateBps,
    this.integratorPublicKey,
    this.transferTimeoutMs,
    this.rollbackOnFailure,
    this.useExistingBtcBalance,
    this.tokenAmount,
    this.useAvailableBalance,
  });
}

/// Result of paying a Lightning invoice with a token
class PayLightningWithTokenResult {
  /// Whether the payment was successful
  final bool success;
  
  /// The pool used for the swap
  final String poolId;
  
  /// Amount of token spent (including fees)
  final String tokenAmountSpent;
  
  /// Amount of BTC received from swap
  final String btcAmountReceived;
  
  /// Swap transaction ID
  final String swapTransferId;
  
  /// Lightning payment SSP request ID (e.g. SparkLightningSendRequest:...)
  final String? lightningPaymentId;
  
  /// AMM fee paid in token units
  final String ammFeePaid;
  
  /// Lightning routing fee paid in sats
  final int? lightningFeePaid;
  
  /// For zero-amount invoices: BTC amount actually paid to the invoice
  final int? invoiceAmountPaid;
  
  /// Spark transfer ID for the token transfer to the pool
  final String? sparkTokenTransferId;
  
  /// Spark transfer ID for the Lightning payment
  final String? sparkLightningTransferId;
  
  /// Error message if failed
  final String? error;

  PayLightningWithTokenResult({
    required this.success,
    required this.poolId,
    required this.tokenAmountSpent,
    required this.btcAmountReceived,
    required this.swapTransferId,
    this.lightningPaymentId,
    required this.ammFeePaid,
    this.lightningFeePaid,
    this.invoiceAmountPaid,
    this.sparkTokenTransferId,
    this.sparkLightningTransferId,
    this.error,
  });
}

class PoolReserves {
  final String assetAReserve;
  final String assetBReserve;

  PoolReserves({
    required this.assetAReserve,
    required this.assetBReserve,
  });
}

/// Quote for paying a Lightning invoice with a token
class PayLightningWithTokenQuote {
  /// The pool that offers the best rate
  final String poolId;
  
  /// Token address being swapped
  final String tokenAddress;
  
  /// Amount of token required (including all fees)
  final String tokenAmountRequired;
  
  /// BTC amount needed for the invoice (in sats), rounded up for AMM bit masking
  final String btcAmountRequired;
  
  /// Original invoice amount in sats (before Lightning fee and AMM adjustments)
  final int invoiceAmountSats;
  
  /// Estimated AMM fee in token units
  final String estimatedAmmFee;
  
  /// Estimated Lightning routing fee in sats
  final int estimatedLightningFee;
  
  /// Extra sats added due to AMM BTC variable fee (bit masking rounds down by up to 63 sats). 0 for V3 pools.
  final int btcVariableFeeAdjustment;
  
  /// Execution price (token per sat)
  final String executionPrice;
  
  /// Price impact percentage
  final String priceImpactPct;
  
  /// Whether the token is asset A or B in the pool
  final bool tokenIsAssetA;
  
  /// Pool reserves for reference
  final PoolReserves poolReserves;
  
  /// Warning message if any
  final String? warningMessage;
  
  /// Curve type of the selected pool
  final String curveType;
  
  /// Whether this quote is for a zero-amount invoice
  final bool isZeroAmountInvoice;

  PayLightningWithTokenQuote({
    required this.poolId,
    required this.tokenAddress,
    required this.tokenAmountRequired,
    required this.btcAmountRequired,
    required this.invoiceAmountSats,
    required this.estimatedAmmFee,
    required this.estimatedLightningFee,
    required this.btcVariableFeeAdjustment,
    required this.executionPrice,
    required this.priceImpactPct,
    required this.tokenIsAssetA,
    required this.poolReserves,
    this.warningMessage,
    required this.curveType,
    required this.isZeroAmountInvoice,
  });
}

/// Result of a single clawback monitor poll cycle
class ClawbackPollResult {
  /// Number of clawbackable transfers found
  final int transfersFound;
  
  /// Number of clawback attempts made
  final int clawbacksAttempted;
  
  /// Number of successful clawbacks
  final int clawbacksSucceeded;
  
  /// Number of failed clawbacks
  final int clawbacksFailed;
  
  /// Detailed results for each clawback attempt
  final List<ClawbackAttemptResult> results;

  ClawbackPollResult({
    required this.transfersFound,
    required this.clawbacksAttempted,
    required this.clawbacksSucceeded,
    required this.clawbacksFailed,
    required this.results,
  });
}

/// Options for configuring the clawback monitor
class ClawbackMonitorOptions {
  /// Polling interval in milliseconds (default: 60000 = 1 minute)
  final int? intervalMs;
  
  /// Number of clawbacks to process per batch (default: 2, for rate limit safety)
  final int? batchSize;
  
  /// Delay between batches in milliseconds (default: 500ms)
  final int? batchDelayMs;
  
  /// Maximum transfers to fetch per poll (default: 100)
  final int? maxTransfersPerPoll;
  
  /// Called when a clawback succeeds
  final void Function(ClawbackAttemptResult result)? onClawbackSuccess;
  
  /// Called when a clawback fails
  final void Function(String transferId, Object error)? onClawbackError;
  
  /// Called after each poll cycle completes
  final void Function(ClawbackPollResult result)? onPollComplete;
  
  /// Called if the poll itself fails (e.g., network error fetching transfers)
  final void Function(Object error)? onPollError;

  ClawbackMonitorOptions({
    this.intervalMs,
    this.batchSize,
    this.batchDelayMs,
    this.maxTransfersPerPoll,
    this.onClawbackSuccess,
    this.onClawbackError,
    this.onPollComplete,
    this.onPollError,
  });
}

abstract class ClawbackMonitorHandle {
  /// Check if the monitor is currently running
  bool isRunning();
  
  /// Stop the monitor (waits for current poll to complete)
  Future<void> stop();
  
  /// Trigger an immediate poll (throws if monitor is stopped)
  Future<ClawbackPollResult> pollNow();
}

/// @deprecated Use FlashnetClientConfig instead
@Deprecated('Use FlashnetClientConfig instead')
class FlashnetClientOptions {
  final bool? autoAuthenticate; // Default: true

  FlashnetClientOptions({
    this.autoAuthenticate,
  });
}

typedef Tuple<T> = List<T>;

/// Helper type that works for both fixed and unknown length lists
typedef TupleArray<T> = List<T>;

/// FlashnetClient - A comprehensive client for interacting with Flashnet AMM
///
/// This client wraps a SparkWallet and provides:
/// - Automatic network detection from the wallet
/// - Automatic authentication
/// - Balance checking before operations
/// - All AMM operations (pools, swaps, liquidity, hosts)
/// - Direct wallet access via client.wallet
class FlashnetClient {
  late final SparkWallet _wallet;
  late final ApiClient _apiClient;
  late final TypedAmmApi _typedApi;
  late AuthManager _authManager;
  late final SparkNetworkType _sparkNetwork;
  late final ClientEnvironment _clientEnvironment;
  
  String _publicKey = "";
  String _sparkAddress = "";
  bool _isAuthenticated = false;

  // Ephemeral caches for config endpoints and ping using Dart 3 Named Records
  ({FeatureStatusResponse data, int expiryMs})? _featureStatusCache;
  ({Map<String, BigInt> map, int expiryMs})? _minAmountsCache;
  ({AllowedAssetsResponse data, int expiryMs})? _allowedAssetsCache;
  ({bool ok, int expiryMs})? _pingCache;

  // TTLs (milliseconds)
  static const int _featureStatusTtlMs = 5000; // 5s
  static const int _minAmountsTtlMs = 5000; // 5s
  static const int _allowedAssetsTtlMs = 60000; // 60s
  static const int _pingTtlMs = 2000; // 2s

  /// Get the underlying wallet instance for direct wallet operations
  SparkWallet get wallet => _wallet;

  /// Get the Spark network type (for blockchain operations)
  SparkNetworkType get sparkNetworkType => _sparkNetwork;

  /// Get the client environment (for API configuration)
  ClientEnvironment get clientEnvironmentType => _clientEnvironment;

  /// @deprecated Use sparkNetworkType instead
  /// Get the network type
  @Deprecated('Use sparkNetworkType instead')
  NetworkType get networkType {
    // Map Spark network back to legacy network type
    // This is for backward compatibility
    // Note: Assuming these are strings or comparable types based on the TS code
    if (_sparkNetwork == 'REGTEST' && _clientEnvironment == 'local') {
      return 'LOCAL' as NetworkType;
    }
    return _sparkNetwork as NetworkType;
  }

  /// Get the wallet's public key
  String get pubkey => _publicKey;

  /// Get the wallet's Spark address
  String get address => _sparkAddress;

  // --- Constructors ---
  // Dart uses named constructors to handle TypeScript's union-type constructor overloads

  /// Create a new FlashnetClient instance with new configuration system
  FlashnetClient.withConfig(SparkWallet wallet, FlashnetClientConfig config) {
    _wallet = wallet;
    _sparkNetwork = config.sparkNetworkType;
    
    final environmentName = getClientEnvironmentName(config.clientConfig);
    _clientEnvironment = environmentName == "custom" 
        ? 'local' as ClientEnvironment 
        : environmentName as ClientEnvironment;
        
    final resolvedClientConfig = resolveClientNetworkConfig(config.clientConfig);
    _initApis(resolvedClientConfig);
  }

  /// Create a new FlashnetClient instance with custom configuration
  FlashnetClient.withCustomConfig(SparkWallet wallet, FlashnetClientCustomConfig config) {
    _wallet = wallet;
    _sparkNetwork = config.sparkNetworkType;
    
    final environmentName = getClientEnvironmentName(config.clientNetworkConfig);
    _clientEnvironment = environmentName == "custom" 
        ? 'local' as ClientEnvironment 
        : environmentName as ClientEnvironment;
        
    final resolvedClientConfig = resolveClientNetworkConfig(config.clientNetworkConfig);
    _initApis(resolvedClientConfig);
  }

  /// Create a new FlashnetClient instance with environment configuration
  FlashnetClient.withEnvironmentConfig(SparkWallet wallet, FlashnetClientEnvironmentConfig config) {
    _wallet = wallet;
    _sparkNetwork = config.sparkNetworkType;
    
    final environmentName = getClientEnvironmentName(config.clientEnvironment);
    _clientEnvironment = environmentName == "custom" 
        ? 'local' as ClientEnvironment 
        : environmentName as ClientEnvironment;
        
    final resolvedClientConfig = resolveClientNetworkConfig(config.clientEnvironment);
    _initApis(resolvedClientConfig);
  }

  /// @deprecated Use the new named constructors with Config classes instead
  /// Create a new FlashnetClient instance with legacy configuration
  @Deprecated('Use named constructors like .withConfig instead')
  FlashnetClient.legacy(SparkWallet wallet, [FlashnetClientLegacyConfig? options]) {
    _wallet = wallet;

    if (options?.network != null) {
      // Use provided legacy network
      _sparkNetwork = getSparkNetworkFromLegacy(options!.network!);
      _clientEnvironment = getClientEnvironmentFromLegacy(options.network!);
    } else {
      // Auto-detect from wallet (existing behavior)
      final networkEnum = wallet.config.getNetwork();
      // Assuming Network is an enum-like class/extension where .name gets the string value
      final networkName = networkEnum.name; 
      final detectedNetwork = networkName == "MAINNET" ? "MAINNET" : "REGTEST";

      _sparkNetwork = getSparkNetworkFromLegacy(detectedNetwork);
      _clientEnvironment = getClientEnvironmentFromLegacy(detectedNetwork);
    }

    final resolvedClientConfig = getClientNetworkConfig(_clientEnvironment);
    _initApis(resolvedClientConfig);
  }

  // --- Internal Initializer ---
  
  void _initApis(ClientNetworkConfig resolvedClientConfig) {
    _apiClient = ApiClient(resolvedClientConfig);
    _typedApi = TypedAmmApi(_apiClient);
    _authManager = AuthManager(_apiClient, "", _wallet);
  }

  /// Initialize the client by deducing network and authenticating
  /// This is called automatically on first use if not called manually
  Future<void> initialize() async {
    if (_isAuthenticated) {
      return;
    }

    // Get wallet details
    _publicKey = await _wallet.getIdentityPublicKey();
    _sparkAddress = await _wallet.getSparkAddress();

    // Deduce Spark network from spark address and validate consistency
    final detectedSparkNetwork = getSparkNetworkFromAddress(_sparkAddress);
    if (detectedSparkNetwork == null) {
      throw Exception(
          'Unable to determine Spark network from spark address: $_sparkAddress');
    }

    // Warn if configured Spark network doesn't match detected network
    if (_sparkNetwork != detectedSparkNetwork) {
      print(
          'Warning: Configured Spark network ($_sparkNetwork) doesn\'t match detected network from address ($detectedSparkNetwork). Using detected network.');
      _sparkNetwork = detectedSparkNetwork;
    }

    // Re-initialize auth manager with correct public key
    _authManager = AuthManager(
      _apiClient,
      _publicKey,
      _wallet,
    );

    // Authenticate
    final token = await _authManager.authenticate();
    _apiClient.setAuthToken(token);
    _isAuthenticated = true;
  }

  /// Ensure the client is initialized
  Future<void> _ensureInitialized() async {
    if (!_isAuthenticated) {
      await initialize();
    }
  }

  /// Ensure a token identifier is in human-readable (Bech32m) form expected by the Spark SDK.
  /// If the identifier is already human-readable or it is the BTC constant, it is returned unchanged.
  /// Otherwise, it is encoded from the raw hex form using the client's Spark network.
  String _toHumanReadableTokenIdentifier(String tokenIdentifier) {
    if (tokenIdentifier == BTC_ASSET_PUBKEY) {
      return tokenIdentifier;
    }
    if (tokenIdentifier.startsWith('btkn')) {
      return tokenIdentifier;
    }
    return encodeSparkHumanReadableTokenIdentifier(
      tokenIdentifier,
      _sparkNetwork,
    );
  }

  /// Convert a token identifier into the raw hex string form expected by the Flashnet backend.
  /// Handles BTC constant, hex strings, and Bech32m human-readable format.
  String _toHexTokenIdentifier(String tokenIdentifier) {
    if (tokenIdentifier == BTC_ASSET_PUBKEY) {
      return tokenIdentifier;
    }
    if (tokenIdentifier.startsWith('btkn')) {
      // Assuming decodeSparkHumanReadableTokenIdentifier returns an object/record with a tokenIdentifier property
      return decodeSparkHumanReadableTokenIdentifier(
        tokenIdentifier,
        _sparkNetwork,
      ).tokenIdentifier;
    }
    return tokenIdentifier;
  }

  /// Get wallet balance including BTC and token balances
  Future<WalletBalance> getBalance() async {
    Map<Bech32mTokenIdentifier, TokenBalanceInfo>? tokenBalanceRaw;
    try {
      tokenBalanceRaw = await _wallet.getTokenBalance();
    } catch (_) {}
    ({BigInt balance, BigInt incoming, BigInt owned})? balance;
    try {
      balance = await wallet.getBalance();
    } catch (_) {}
    
    

    // Convert the wallet's balance format to our format
    final tokenBalances = <String, TokenBalance>{};

    if (tokenBalanceRaw != null) {
      for (final entry in tokenBalanceRaw.entries) {
        final tokenPubkey = entry.key;
        final tokenData = entry.value;
        final info = tokenData.tokenMetadata;

        // Convert raw token identifier to hex and human-readable forms
        final tokenIdentifierHex = getHexFromUint8Array(info.rawTokenIdentifier);
        final tokenAddress = encodeSparkHumanReadableTokenIdentifier(
          info.rawTokenIdentifier,
          _sparkNetwork,
        );

        // Fallback checks mirroring the TS behavior of `(tokenData as any).balance`
        // assuming standard properties available on the dart side.
        final rawOwnedBalance = tokenData.ownedBalance;
        final rawAvailableBalance = tokenData.availableToSendBalance;

        tokenBalances[tokenPubkey] = TokenBalance(
          balance: safeBigInt(rawOwnedBalance),
          availableToSendBalance: safeBigInt(rawAvailableBalance),
          tokenInfo: TokenInfo(
            tokenIdentifier: tokenIdentifierHex,
            tokenAddress: tokenAddress,
            tokenName: info.tokenName,
            tokenSymbol: info.tokenTicker,
            tokenDecimals: info.decimals,
            maxSupply: info.maxSupply,
          ),
        );
      }
    }

    final currectBalance = WalletBalance(
      balance: balance?.balance ?? BigInt.zero,
      tokenBalances: tokenBalances,
    );

    debugPrint("currectBalance.balance: ${currectBalance.balance}, currectBalance.tokenBalances: ${currectBalance.tokenBalances.entries.map<String>((entry)=>"${entry.key}: {balance:${entry.value.balance}, availableToSendBalance:${entry.value.availableToSendBalance}}")}");

    return currectBalance;
  }

  /// Check if wallet has sufficient balance for an operation
  Future<void> checkBalance({
    required List<({String assetAddress, Object amount})> balancesToCheck,
    String? errorPrefix,
    WalletBalance? walletBalance,
    /// When true, checks against availableToSendBalance instead of total balance
    bool? useAvailableBalance,
  }) async {
    final balance = walletBalance ?? (await getBalance());

    // Check balance
    BigInt? requiredBtc;
    final requiredTokens = <String, BigInt>{};

    for (final b in balancesToCheck) {
      // Handle the union type (string | bigint)
      final amt = b.amount is BigInt 
          ? b.amount as BigInt 
          : BigInt.parse(b.amount.toString());

      if (b.assetAddress == BTC_ASSET_PUBKEY) {
        requiredBtc = amt;
      } else {
        requiredTokens[b.assetAddress] = amt;
      }
    }

    // Check BTC balance
    if (requiredBtc != null && balance.balance < requiredBtc) {
      throw Exception(
        '${errorPrefix ?? ""}'
        'Insufficient BTC balance. '
        'Required: $requiredBtc sats, Available: ${balance.balance} sats',
      );
    }

    // Check token balances
    if (requiredTokens.isNotEmpty) {
      for (final entry in requiredTokens.entries) {
        final tokenPubkey = entry.key;
        final requiredAmount = entry.value;

        // Support both hex and Bech32m token identifiers by trying all representations
        final hrKey = _toHumanReadableTokenIdentifier(tokenPubkey);
        final hexKey = _toHexTokenIdentifier(tokenPubkey);
        
        final effectiveTokenBalance = balance.tokenBalances[tokenPubkey] ??
            balance.tokenBalances[hrKey] ??
            balance.tokenBalances[hexKey];
            
        final available = useAvailableBalance == true
            ? (effectiveTokenBalance?.availableToSendBalance ?? BigInt.zero)
            : (effectiveTokenBalance?.balance ?? BigInt.zero);

        debugPrint("balance.tokenBalances: ${balance.tokenBalances}, hrKey:${hrKey}, effectiveTokenBalance:${effectiveTokenBalance} available:${available}");

        if (available < requiredAmount) {
          throw Exception(
            '${errorPrefix ?? ""}'
            'Insufficient token balance for $tokenPubkey. '
            'Required: $requiredAmount, Available: $available',
          );
        }
      }
    }
  }

  // Pool Operations

  /// List pools with optional filters
  Future<ListPoolsResponse> listPools([ListPoolsQuery? query]) async {
    await _ensureInitialized();
    final poolList = await _typedApi.listPools(query);
    return poolList;
  }

  /// Get detailed information about a specific pool
  Future<PoolDetailsResponse> getPool(String poolId) async {
    await _ensureInitialized();
    return _typedApi.getPool(poolId);
  }

  /// Get LP position details for a provider in a pool
  Future<LpPositionDetailsResponse> getLpPosition(
    String poolId, [
    String? providerPublicKey,
  ]) async {
    await _ensureInitialized();
    final provider = providerPublicKey ?? _publicKey;
    return _typedApi.getLpPosition(poolId, provider);
  }

  /// Get LP position details for a provider in a pool
  Future<AllLpPositionsResponse> getAllLpPositions() async {
    await _ensureInitialized();
    return _typedApi.getAllLpPositions();
  }

  /// Create a constant product pool
  Future<CreatePoolResponse> createConstantProductPool({
    required String assetAAddress,
    required String assetBAddress,
    required int lpFeeRateBps,
    required int totalHostFeeRateBps,
    String? poolOwnerPublicKey,
    String? hostNamespace,
    ({
      BigInt assetAAmount,
      BigInt assetBAmount,
      BigInt assetAMinAmountIn,
      BigInt assetBMinAmountIn,
    })? initialLiquidity,
    /// When true, checks against availableToSendBalance instead of total balance
    bool? useAvailableBalance,
  }) async {
    await _ensureInitialized();

    // Note: ensureAmmOperationAllowed and assertAllowedAssetBForPoolCreation 
    // are assumed to be ported in a future chunk.
    await ensureAmmOperationAllowed('allow_pool_creation');
    await assertAllowedAssetBForPoolCreation(
      _toHexTokenIdentifier(assetBAddress),
    );

    // Check if we need to add initial liquidity
    if (initialLiquidity != null) {
      await checkBalance(
        balancesToCheck: [
          (assetAddress: assetAAddress, amount: initialLiquidity.assetAAmount),
          (assetAddress: assetBAddress, amount: initialLiquidity.assetBAmount),
        ],
        errorPrefix: 'Insufficient balance for initial liquidity: ',
        useAvailableBalance: useAvailableBalance,
      );
    }

    final effectivePoolOwnerPublicKey = poolOwnerPublicKey ?? _publicKey;

    // Generate intent
    final nonce = generateNonce();
    final intentMessage = generateConstantProductPoolInitializationIntentMessage(
      poolOwnerPublicKey: effectivePoolOwnerPublicKey,
      assetAAddress: _toHexTokenIdentifier(assetAAddress),
      assetBAddress: _toHexTokenIdentifier(assetBAddress),
      lpFeeRateBps: lpFeeRateBps.toString(),
      totalHostFeeRateBps: totalHostFeeRateBps.toString(),
      nonce: nonce,
    );

    // Sign intent
    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!; 
    
    // Replicating TS `(this._wallet as any)` bypass using dynamic
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    // Create pool
    final request = CreateConstantProductPoolRequest(
      poolOwnerPublicKey: effectivePoolOwnerPublicKey,
      assetAAddress: _toHexTokenIdentifier(assetAAddress),
      assetBAddress: _toHexTokenIdentifier(assetBAddress),
      lpFeeRateBps: lpFeeRateBps.toString(),
      totalHostFeeRateBps: totalHostFeeRateBps.toString(),
      hostNamespace: hostNamespace ?? '',
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final response = await _typedApi.createConstantProductPool(request);

    // Add initial liquidity if specified
    if (initialLiquidity != null && response.poolId.isNotEmpty) {
      // Note: addInitialLiquidity is assumed to be ported in a future chunk.
      await addInitialLiquidity(
        response.poolId,
        assetAAddress,
        assetBAddress,
        initialLiquidity.assetAAmount.toString(),
        initialLiquidity.assetBAmount.toString(),
        initialLiquidity.assetAMinAmountIn.toString(),
        initialLiquidity.assetBMinAmountIn.toString(),
      );
    }

    return response;
  }

  // Validate and normalize inputs to bigint
  // Object is used to accept BigInt, num, or String like TS's union type
  static BigInt _parsePositiveIntegerToBigInt(Object value, String name) {
    if (value is BigInt) {
      if (value <= BigInt.zero) {
        throw Exception('$name must be positive integer');
      }
      return value;
    }
    if (value is num) {
      if (!value.isFinite || value.truncate() != value || value <= 0) {
        throw Exception('$name must be positive integer');
      }
      return BigInt.from(value);
    }
    try {
      final v = BigInt.parse(value.toString());
      if (v <= BigInt.zero) {
        throw Exception('$name must be positive integer');
      }
      return v;
    } catch (_) {
      throw Exception('$name must be positive integer');
    }
  }

  /// Calculates virtual reserves for a bonding curve AMM.
  ///
  /// This helper function calculates the initial virtual reserves (`v_A^0`, `v_B^0`)
  /// based on the bonding curve parameters. These virtual reserves ensure smooth
  /// pricing and price continuity during graduation to the double-sided phase.
  static ({BigInt virtualReserveA, BigInt virtualReserveB, BigInt threshold}) calculateVirtualReserves({
    required Object initialTokenSupply,
    required num graduationThresholdPct,
    required Object targetRaise,
  }) {
    if (!graduationThresholdPct.isFinite || graduationThresholdPct.truncate() != graduationThresholdPct) {
      throw Exception('Graduation threshold percentage must be an integer number of percent');
    }

    final supply = _parsePositiveIntegerToBigInt(initialTokenSupply, 'Initial token supply');
    final targetB = _parsePositiveIntegerToBigInt(targetRaise, 'Target raise');
    final thresholdPct = BigInt.from(graduationThresholdPct);

    // Align bounds with Rust AMM (20%..95%), then check feasibility for g=1 (requires >50%).
    final minPct = BigInt.from(20);
    final maxPct = BigInt.from(95);
    
    if (thresholdPct < minPct || thresholdPct > maxPct) {
      throw Exception('Graduation threshold percentage must be between $minPct and $maxPct');
    }

    // Feasibility: denom = f - g*(1-f) > 0 with g=1 -> 2f - 1 > 0 -> pct > 50
    final denomNormalized = (BigInt.two * thresholdPct) - BigInt.from(100); // equals 100*(f - (1-f))
    if (denomNormalized <= BigInt.zero) {
      throw Exception('Invalid configuration: threshold must be greater than 50% when LP fraction is 1.0');
    }

    // v_A = S * f^2 / (f - (1-f)) ; using integer math with pct where
    // v_A = S * p^2 / (100 * (2p - 100))
    final vANumerator = supply * thresholdPct * thresholdPct;
    final vADenominator = BigInt.from(100) * denomNormalized;
    // Use ~/ for integer division (floor) in Dart
    final virtualA = vANumerator ~/ vADenominator; 

    // v_B = T * (1 - f) / (f - (1-f)) ; with pct => T * (100 - p) / (2p - 100)
    final vBNumerator = targetB * (BigInt.from(100) - thresholdPct);
    final vBDenominator = denomNormalized;
    final virtualB = vBNumerator ~/ vBDenominator;

    // Threshold amount in A
    final threshold = (supply * thresholdPct) ~/ BigInt.from(100);

    return (
      virtualReserveA: virtualA,
      virtualReserveB: virtualB,
      threshold: threshold,
    );
  }

  /// Create a single-sided pool with automatic initial deposit
  ///
  /// This method creates a single-sided pool and by default automatically handles the initial deposit.
  /// The initial reserve amount will be transferred to the pool and confirmed.
  Future<CreatePoolResponse> createSingleSidedPool({
    required String assetAAddress,
    required String assetBAddress,
    required Object assetAInitialReserve, // Accepts String or BigInt
    required Object virtualReserveA,      // Accepts String, num, or BigInt
    required Object virtualReserveB,      // Accepts String, num, or BigInt
    required Object threshold,            // Accepts String, num, or BigInt
    required int lpFeeRateBps,
    required int totalHostFeeRateBps,
    String? poolOwnerPublicKey,
    String? hostNamespace,
    bool? disableInitialDeposit,
    /// When true, checks against availableToSendBalance instead of total balance
    bool? useAvailableBalance,
  }) async {
    await _ensureInitialized();

    await ensureAmmOperationAllowed('allow_pool_creation');
    await assertAllowedAssetBForPoolCreation(
      _toHexTokenIdentifier(assetBAddress),
    );

    if (hostNamespace == null && totalHostFeeRateBps < 10) {
      throw Exception('Host fee must be greater than 10 bps when no host namespace is provided');
    }

    // Validate reserves are valid positive integers before any operations
    final parsedAssetAInitialReserve = _parsePositiveIntegerToBigInt(
      assetAInitialReserve,
      'Asset A Initial Reserve',
    ).toString();
    final parsedVirtualReserveA = _parsePositiveIntegerToBigInt(
      virtualReserveA,
      'Virtual Reserve A',
    ).toString();
    final parsedVirtualReserveB = _parsePositiveIntegerToBigInt(
      virtualReserveB,
      'Virtual Reserve B',
    ).toString();

    await checkBalance(
      balancesToCheck: [
        (assetAddress: assetAAddress, amount: parsedAssetAInitialReserve),
      ],
      errorPrefix: 'Insufficient balance for pool creation: ',
      useAvailableBalance: useAvailableBalance,
    );

    final effectivePoolOwnerPublicKey = poolOwnerPublicKey ?? _publicKey;

    // Generate intent
    final nonce = generateNonce();
    final intentMessage = generatePoolInitializationIntentMessage(
      poolOwnerPublicKey: effectivePoolOwnerPublicKey,
      assetAAddress: _toHexTokenIdentifier(assetAAddress),
      assetBAddress: _toHexTokenIdentifier(assetBAddress),
      assetAInitialReserve: parsedAssetAInitialReserve,
      virtualReserveA: parsedVirtualReserveA,
      virtualReserveB: parsedVirtualReserveB,
      threshold: threshold.toString(),
      lpFeeRateBps: lpFeeRateBps.toString(),
      totalHostFeeRateBps: totalHostFeeRateBps.toString(),
      nonce: nonce,
    );

    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    // Create pool
    final request = CreateSingleSidedPoolRequest(
      poolOwnerPublicKey: effectivePoolOwnerPublicKey,
      assetAAddress: _toHexTokenIdentifier(assetAAddress),
      assetBAddress: _toHexTokenIdentifier(assetBAddress),
      assetAInitialReserve: parsedAssetAInitialReserve,
      virtualReserveA: parsedVirtualReserveA,
      virtualReserveB: parsedVirtualReserveB,
      threshold: threshold.toString(),
      lpFeeRateBps: lpFeeRateBps.toString(),
      totalHostFeeRateBps: totalHostFeeRateBps.toString(),
      hostNamespace: hostNamespace ?? '',
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final createResponse = await _typedApi.createSingleSidedPool(request);

    if (disableInitialDeposit == true) {
      return createResponse;
    }

    // Transfer initial reserve to the pool using new address encoding
    // Note: Assuming createResponse.poolId is non-null as per TS typings
    final lpSparkAddress = encodeSparkAddressNew(SparkAddressDataNew(
      identityPublicKey: createResponse.poolId,
      network: _sparkNetwork,
    ));

    final assetATransferId = await transferAsset(
      receiverSparkAddress: lpSparkAddress,
      assetAddress: assetAAddress,
      amount: parsedAssetAInitialReserve,
    );

    // Execute confirm with auto-clawback on failure
    await executeWithAutoClawback(
      () async {
        final confirmResponse = await confirmInitialDeposit(
          createResponse.poolId,
          assetATransferId,
          effectivePoolOwnerPublicKey,
        );

        if (confirmResponse.confirmed != true) {
          throw Exception('Failed to confirm initial deposit: ${confirmResponse.message}');
        }

        return confirmResponse;
      },
      [assetATransferId],
      createResponse.poolId,
    );

    return createResponse;
  }

  /// Confirm initial deposit for single-sided pool
  ///
  /// Note: This is typically handled automatically by createSingleSidedPool().
  /// Use this method only if you need to manually confirm a deposit (e.g., after a failed attempt).
  Future<ConfirmDepositResponse> confirmInitialDeposit(
    String poolId,
    String assetASparkTransferId, [
    String? poolOwnerPublicKey,
  ]) async {
    await _ensureInitialized();

    final nonce = generateNonce();
    final effectivePoolOwnerPublicKey = poolOwnerPublicKey ?? _publicKey;
    
    final intentMessage = generatePoolConfirmInitialDepositIntentMessage(
      poolOwnerPublicKey: effectivePoolOwnerPublicKey,
      lpIdentityPublicKey: poolId,
      assetASparkTransferId: assetASparkTransferId,
      nonce: nonce,
    );

    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = ConfirmInitialDepositRequest(
      poolId: poolId,
      assetASparkTransferId: assetASparkTransferId,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
      poolOwnerPublicKey: effectivePoolOwnerPublicKey,
    );

    return _typedApi.confirmInitialDeposit(request);
  }

  // Swap Operations

  /// Simulate a swap without executing it
  Future<SimulateSwapResponse> simulateSwap(SimulateSwapRequest params) async {
    await _ensureInitialized();
    await ensurePingOk();

    // Note: In TypeScript, they floor the integratorBps because JS numbers are floating point. 
    // In Dart, if `SimulateSwapRequest.integratorBps` is strongly typed as an `int?`, 
    // it is already a strict integer and no math flooring is needed.
    return _typedApi.simulateSwap(params);
  }

  /// Execute a swap
  ///
  /// If the swap fails with a clawbackable error, the SDK will automatically
  /// attempt to recover the transferred funds via clawback.
  ///
  /// [useFreeBalance] When true, uses free balance from V3 pool instead of making a Spark transfer.
  ///  Note: Only works for V3 concentrated liquidity pools. Does NOT work for route swaps.
  Future<({SwapResponse response, String? inboundSparkTransferId})> executeSwap({
    required String poolId,
    required String assetInAddress,
    required String assetOutAddress,
    required String amountIn,
    required int maxSlippageBps,
    required String minAmountOut,
    int? integratorFeeRateBps,
    String? integratorPublicKey,
    /// When true, uses free balance from V3 pool instead of making a Spark transfer
    bool? useFreeBalance,
    /// When true, checks against availableToSendBalance instead of total balance
    bool? useAvailableBalance,
  }) async {
    await _ensureInitialized();

    // Gate by feature flags and ping, and enforce min-amount policy before transfers
    await ensureAmmOperationAllowed('allow_swaps');
    await assertSwapMeetsMinAmounts(
      assetInAddress: assetInAddress,
      assetOutAddress: assetOutAddress,
      amountIn: amountIn,
      minAmountOut: minAmountOut,
    );

    // If using free balance (V3 pools only), skip the Spark transfer
    if (useFreeBalance == true) {
      final swapResponse = await executeSwapIntent(
        poolId: poolId,
        assetInAddress: assetInAddress,
        assetOutAddress: assetOutAddress,
        amountIn: amountIn,
        maxSlippageBps: maxSlippageBps,
        minAmountOut: minAmountOut,
        integratorFeeRateBps: integratorFeeRateBps,
        integratorPublicKey: integratorPublicKey,
        // No transferId - triggers free balance mode
      );
      
      return (
        response: swapResponse,
        inboundSparkTransferId: swapResponse.requestId,
      );
    }

    // Transfer assets to pool using new address encoding
    final lpSparkAddress = encodeSparkAddressNew(SparkAddressDataNew(
      identityPublicKey: poolId,
      network: _sparkNetwork,
    ));

    final transferId = await transferAsset(
      receiverSparkAddress: lpSparkAddress,
      assetAddress: assetInAddress,
      amount: amountIn,
      errorPrefix: 'Insufficient balance for swap: ',
      useAvailableBalance: useAvailableBalance,
    );

    // Execute with auto-clawback on failure
    final swapResponse = await executeWithAutoClawback(
      () => executeSwapIntent(
        poolId: poolId,
        assetInAddress: assetInAddress,
        assetOutAddress: assetOutAddress,
        amountIn: amountIn,
        maxSlippageBps: maxSlippageBps,
        minAmountOut: minAmountOut,
        integratorFeeRateBps: integratorFeeRateBps,
        integratorPublicKey: integratorPublicKey,
        transferId: transferId,
      ),
      [transferId],
      poolId,
    );

    return (
      response: swapResponse,
      inboundSparkTransferId: transferId,
    );
  }

  /// Execute a swap with a pre-created transfer or using free balance.
  ///
  /// When transferId is provided, uses that Spark transfer. If transferId is a null UUID, treats it as a transfer reference.
  /// When transferId is omitted/undefined, uses free balance (V3 pools only).
  Future<SwapResponse> executeSwapIntent({
    required String poolId,
    String? transferId,
    required String assetInAddress,
    required String assetOutAddress,
    required String amountIn,
    required int maxSlippageBps,
    required String minAmountOut,
    int? integratorFeeRateBps,
    String? integratorPublicKey,
  }) async {
    await _ensureInitialized();

    // Also enforce gating and min amounts for direct intent usage
    await ensureAmmOperationAllowed('allow_swaps');
    await assertSwapMeetsMinAmounts(
      assetInAddress: assetInAddress,
      assetOutAddress: assetOutAddress,
      amountIn: amountIn,
      minAmountOut: minAmountOut,
    );

    // Determine if using free balance based on whether transferId is provided
    final isUsingFreeBalance = transferId == null || transferId.isEmpty;

    // Generate swap intent
    final nonce = generateNonce();
    final intentMessage = generatePoolSwapIntentMessage(
      userPublicKey: _publicKey,
      lpIdentityPublicKey: poolId,
      assetInSparkTransferId: transferId,
      assetInAddress: _toHexTokenIdentifier(assetInAddress),
      assetOutAddress: _toHexTokenIdentifier(assetOutAddress),
      amountIn: amountIn,
      maxSlippageBps: maxSlippageBps.toString(),
      minAmountOut: minAmountOut,
      totalIntegratorFeeRateBps: integratorFeeRateBps?.toString() ?? '0',
      nonce: nonce,
    );

    // Sign intent
    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = ExecuteSwapRequest(
      userPublicKey: _publicKey,
      poolId: poolId,
      assetInAddress: _toHexTokenIdentifier(assetInAddress),
      assetOutAddress: _toHexTokenIdentifier(assetOutAddress),
      amountIn: amountIn,
      maxSlippageBps: maxSlippageBps.toString(),
      minAmountOut: minAmountOut,
      assetInSparkTransferId: transferId ?? '',
      totalIntegratorFeeRateBps: integratorFeeRateBps?.toString() ?? '0',
      integratorPublicKey: integratorPublicKey ?? '',
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final response = await _typedApi.executeSwap(request);

    // Check if the swap was accepted
    if (response.accepted != true) {
      final errorMessage = response.error ?? 'Swap rejected by the AMM';
      final hasRefund = response.refundedAmount != null && response.refundedAmount!.isNotEmpty;
      final refundInfo = hasRefund
          ? ' Refunded ${response.refundedAmount} of ${response.refundedAssetAddress} via transfer ${response.refundTransferId}'
          : '';

      // If refund was provided, funds are safe - use auto_refund recovery
      // If no refund and not using free balance, funds may need clawback
      throw FlashnetError(
        '$errorMessage.$refundInfo',
        // Note: adjust named parameters based on your FlashnetError dart class implementation
        FlashnetErrorOptions(
          response: FlashnetErrorResponseBody(
            errorCode: hasRefund ? 'FSAG-4202' : 'UNKNOWN', // Slippage if refunded
            errorCategory: hasRefund ? 'Business' : 'System',
            message: '$errorMessage.$refundInfo',
            requestId: '',
            timestamp: DateTime.now().toUtc().toIso8601String(),
            service: 'amm-gateway',
            severity: 'Error',
          ),
          httpStatus: 400,
          // Don't include transferIds if refunded or using free balance - no clawback needed
          transferIds: hasRefund || isUsingFreeBalance ? [] : [(transferId)],
          lpIdentityPublicKey: poolId,
        ),
        
      );
    }

    return response;
  }

  /// Simulate a route swap (multi-hop swap)
  Future<SimulateRouteSwapResponse> simulateRouteSwap(
    SimulateRouteSwapRequest params,
  ) async {
    if (params.hops.length > 4) {
      throw Exception('Route swap cannot have more than 4 hops');
    }
    await _ensureInitialized();
    await ensurePingOk();
    return _typedApi.simulateRouteSwap(params);
  }

  /// Execute a route swap (multi-hop swap)
  ///
  /// If the route swap fails with a clawbackable error, the SDK will automatically
  /// attempt to recover the transferred funds via clawback.
  Future<ExecuteRouteSwapResponse> executeRouteSwap({
    required List<({
      String poolId,
      String assetInAddress,
      String assetOutAddress,
      int? hopIntegratorFeeRateBps,
    })> hops,
    required String initialAssetAddress,
    required String inputAmount,
    required String maxRouteSlippageBps,
    required String minAmountOut,
    int? integratorFeeRateBps,
    String? integratorPublicKey,
    /// When true, checks against availableToSendBalance instead of total balance
    bool? useAvailableBalance,
  }) async {
    await _ensureInitialized();

    await ensureAmmOperationAllowed('allow_route_swaps');
    
    // Validate min-amount policy for route: check initial input and final output asset
    final finalOutputAsset = hops.isNotEmpty ? hops.last.assetOutAddress : null;
    if (finalOutputAsset == null || finalOutputAsset.isEmpty) {
      throw Exception('Route swap requires at least one hop with output asset');
    }
    
    await assertSwapMeetsMinAmounts(
      assetInAddress: initialAssetAddress,
      assetOutAddress: finalOutputAsset,
      amountIn: inputAmount,
      minAmountOut: minAmountOut,
    );

    // Validate hops array
    if (hops.length > 4) {
      throw Exception('Route swap cannot have more than 4 hops');
    }
    if (hops.isEmpty) {
      throw Exception('Route swap requires at least one hop');
    }

    // Transfer initial asset to first pool using new address encoding
    final firstPoolId = hops.first.poolId;
    if (firstPoolId.isEmpty) {
      throw Exception('First pool ID is required');
    }

    final lpSparkAddress = encodeSparkAddressNew(SparkAddressDataNew(
      identityPublicKey: firstPoolId,
      network: _sparkNetwork,
    ));

    final initialTransferId = await transferAsset(
      receiverSparkAddress: lpSparkAddress,
      assetAddress: initialAssetAddress,
      amount: inputAmount,
      errorPrefix: 'Insufficient balance for route swap: ',
      useAvailableBalance: useAvailableBalance,
    );

    // Execute with auto-clawback on failure
    return executeWithAutoClawback(
      () async {
        // Prepare hops for validation & Request building
        final requestHops = hops.map((hop) => RouteHopRequest(
          poolId: hop.poolId,
          assetInAddress: _toHexTokenIdentifier(hop.assetInAddress),
          assetOutAddress: _toHexTokenIdentifier(hop.assetOutAddress),
          hopIntegratorFeeRateBps: hop.hopIntegratorFeeRateBps?.toString() ?? '0',
        )).toList();

        // Generate route swap intent
        final nonce = generateNonce();
        final intentMessage = generateRouteSwapIntentMessage(
          userPublicKey: _publicKey,
          hops: hops.map((hop) => RouteHopValidation(
            lpIdentityPublicKey: hop.poolId,
            inputAssetAddress: _toHexTokenIdentifier(hop.assetInAddress),
            outputAssetAddress: _toHexTokenIdentifier(hop.assetOutAddress),
            hopIntegratorFeeRateBps: hop.hopIntegratorFeeRateBps?.toString() ?? '0',
          )).toList(),
          initialSparkTransferId: initialTransferId,
          inputAmount: inputAmount,
          maxRouteSlippageBps: maxRouteSlippageBps,
          minAmountOut: minAmountOut,
          nonce: nonce,
          defaultIntegratorFeeRateBps: integratorFeeRateBps?.toString(),
        );

        // Sign intent
        final messageBytes = intentMessage;
        final messageHash = bssl.sha256.hash(messageBytes)!;
        
        final signature = await _wallet
            .config
            .signer
            .signMessageWithIdentityKey(messageHash, compact: true);

        final request = ExecuteRouteSwapRequest(
          userPublicKey: _publicKey,
          hops: requestHops,
          initialSparkTransferId: initialTransferId,
          inputAmount: inputAmount,
          maxRouteSlippageBps: maxRouteSlippageBps,
          minAmountOut: minAmountOut,
          nonce: nonce,
          signature: getHexFromUint8Array(signature),
          integratorFeeRateBps: integratorFeeRateBps?.toString() ?? '0',
          integratorPublicKey: integratorPublicKey ?? '',
        );

        final response = await _typedApi.executeRouteSwap(request);

        // Check if the route swap was accepted
        if (response.accepted != true) {
          final errorMessage = response.error ?? 'Route swap rejected by the AMM';
          final hasRefund = response.refundedAmount != null && response.refundedAmount!.isNotEmpty;
          final refundInfo = hasRefund
              ? ' Refunded ${response.refundedAmount} of ${response.refundedAssetPublicKey} via transfer ${response.refundTransferId}'
              : '';

          throw FlashnetError(
            '$errorMessage.$refundInfo',
            // Note: adjust named parameters based on your FlashnetError dart class implementation
            FlashnetErrorOptions(
              response: FlashnetErrorResponseBody(
                errorCode: hasRefund ? 'FSAG-4202' : 'UNKNOWN',
                errorCategory: hasRefund ? 'Business' : 'System',
                message: '$errorMessage.$refundInfo',
                requestId: '',
                timestamp: DateTime.now().toUtc().toIso8601String(),
                service: 'amm-gateway',
                severity: 'Error',
              ),
              httpStatus: 400,
              transferIds: hasRefund ? [] : [initialTransferId],
              lpIdentityPublicKey: firstPoolId,
            ),
          );
        }

        return response;
      },
      [initialTransferId],
      firstPoolId,
    );
  }

  // Liquidity Operations

  /// Simulate adding liquidity
  Future<SimulateAddLiquidityResponse> simulateAddLiquidity(
    SimulateAddLiquidityRequest params,
  ) async {
    await _ensureInitialized();
    await ensurePingOk();
    return _typedApi.simulateAddLiquidity(params);
  }

  /// Add liquidity to a pool
  ///
  /// If adding liquidity fails with a clawbackable error, the SDK will automatically
  /// attempt to recover the transferred funds via clawback.
  Future<AddLiquidityResponse> addLiquidity({
    required String poolId,
    required String assetAAmount,
    required String assetBAmount,
    required String assetAMinAmountIn,
    required String assetBMinAmountIn,
    /// When true, checks against availableToSendBalance instead of total balance
    bool? useAvailableBalance,
  }) async {
    await _ensureInitialized();

    await ensureAmmOperationAllowed('allow_add_liquidity');

    // Get pool details to know which assets we're dealing with
    final pool = await getPool(poolId);

    // Enforce min-amount policy for inputs based on pool assets
    await assertAddLiquidityMeetsMinAmounts(
      poolId: poolId,
      assetAAmount: assetAAmount,
      assetBAmount: assetBAmount,
    );

    // Transfer assets to pool using new address encoding
    final lpSparkAddress = encodeSparkAddressNew(SparkAddressDataNew(
      identityPublicKey: poolId,
      network: _sparkNetwork,
    ));

    // Note: Assuming transferAssets is ported in a future chunk and takes a List of Records
    final transferIds = await transferAssets(
      [
        (
          receiverSparkAddress: lpSparkAddress,
          assetAddress: pool.assetAAddress,
          amount: assetAAmount,
        ),
        (
          receiverSparkAddress: lpSparkAddress,
          assetAddress: pool.assetBAddress,
          amount: assetBAmount,
        ),
      ],
      'Insufficient balance for adding liquidity: ',
      useAvailableBalance,
    );
    
    final assetATransferId = transferIds[0];
    final assetBTransferId = transferIds[1];

    // Execute with auto-clawback on failure
    return executeWithAutoClawback(
      () async {
        // Generate add liquidity intent
        final nonce = generateNonce();
        final intentMessage = generateAddLiquidityIntentMessage(
          AmmAddLiquiditySettlementRequest(
          userPublicKey: _publicKey,
          lpIdentityPublicKey: poolId,
          assetASparkTransferId: assetATransferId,
          assetBSparkTransferId: assetBTransferId,
          assetAAmount: assetAAmount,
          assetBAmount: assetBAmount,
          assetAMinAmountIn: assetAMinAmountIn,
          assetBMinAmountIn: assetBMinAmountIn,
          nonce: nonce,
        ));

        // Sign intent
        final messageBytes = intentMessage;
        final messageHash = bssl.sha256.hash(messageBytes)!;
        
        final signature = await _wallet
            .config
            .signer
            .signMessageWithIdentityKey(messageHash, compact: true);

        final request = AddLiquidityRequest(
          userPublicKey: _publicKey,
          poolId: poolId,
          assetASparkTransferId: assetATransferId,
          assetBSparkTransferId: assetBTransferId,
          assetAAmountToAdd: assetAAmount,
          assetBAmountToAdd: assetBAmount,
          assetAMinAmountIn: assetAMinAmountIn,
          assetBMinAmountIn: assetBMinAmountIn,
          nonce: nonce,
          signature: getHexFromUint8Array(signature),
        );

        final response = await _typedApi.addLiquidity(request);

        // Check if the liquidity addition was accepted
        if (response.accepted != true) {
          final errorMessage = response.error ?? 'Add liquidity rejected by the AMM';
          
          final hasRefund = (response.refund?.assetAAmount != null && response.refund!.assetAAmount!.isNotEmpty) || 
                            (response.refund?.assetBAmount != null && response.refund!.assetBAmount!.isNotEmpty);
                            
          final refundInfo = response.refund != null
              ? ' Refunds: Asset A: ${response.refund!.assetAAmount ?? 0}, Asset B: ${response.refund!.assetBAmount ?? 0}'
              : '';

          throw FlashnetError(
            '$errorMessage.$refundInfo',
            // Note: adjust named parameters based on your FlashnetError dart class implementation
            FlashnetErrorOptions(
              response: FlashnetErrorResponseBody(
                errorCode: hasRefund ? 'FSAG-4203' : 'UNKNOWN', // Phase error if refunded
                errorCategory: hasRefund ? 'Business' : 'System',
                message: '$errorMessage.$refundInfo',
                requestId: '',
                timestamp: DateTime.now().toUtc().toIso8601String(),
                service: 'amm-gateway',
                severity: 'Error',
              ),
              httpStatus: 400,
              transferIds: hasRefund ? [] : [assetATransferId, assetBTransferId],
              lpIdentityPublicKey: poolId,
            )
          );
        }

        return response;
      },
      [assetATransferId, assetBTransferId],
      poolId,
    );
  }

  /// Simulate removing liquidity
  Future<SimulateRemoveLiquidityResponse> simulateRemoveLiquidity(
    SimulateRemoveLiquidityRequest params,
  ) async {
    await _ensureInitialized();
    await ensurePingOk();
    return _typedApi.simulateRemoveLiquidity(params);
  }

  /// Remove liquidity from a pool
  Future<RemoveLiquidityResponse> removeLiquidity({
    required String poolId,
    required String lpTokensToRemove,
  }) async {
    await _ensureInitialized();

    await ensureAmmOperationAllowed('allow_withdraw_liquidity');

    // Check LP token balance
    final position = await getLpPosition(poolId);
    final lpTokensOwned = position.lpTokensOwned;
    final tokensToRemove = lpTokensToRemove;

    if (compareDecimalStrings(lpTokensOwned, tokensToRemove) < 0) {
      throw Exception(
        'Insufficient LP tokens. Owned: $lpTokensOwned, Requested: $tokensToRemove'
      );
    }

    // Pre-simulate and enforce min-amount policy for outputs
    await assertRemoveLiquidityMeetsMinAmounts(
      poolId: poolId,
      lpTokensToRemove: lpTokensToRemove,
    );

    // Generate remove liquidity intent
    final nonce = generateNonce();
    final intentMessage = generateRemoveLiquidityIntentMessage(AmmRemoveLiquiditySettlementRequest(
      userPublicKey: _publicKey,
      lpIdentityPublicKey: poolId,
      lpTokensToRemove: lpTokensToRemove,
      nonce: nonce,
    ));

    // Sign intent
    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = RemoveLiquidityRequest(
      userPublicKey: _publicKey,
      poolId: poolId,
      lpTokensToRemove: lpTokensToRemove,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final response = await _typedApi.removeLiquidity(request);

    // Check if the liquidity removal was accepted
    if (response.accepted != true) {
      final errorMessage = response.error ?? 'Remove liquidity rejected by the AMM';
      throw Exception(errorMessage);
    }

    return response;
  }

  // LP Lock & Transfer Operations

  /// Lock an LP position to prevent withdrawal until expiry.
  /// Locks can only be set or extended, never shortened.
  /// [poolId] Pool ID (LP identity public key)
  /// [lockUntilTimestamp] Unix timestamp (seconds). "0" = indefinite lock.
  Future<LockPositionResponse> lockPosition(
    String poolId,
    String lockUntilTimestamp, {
    int? tickLower,
    int? tickUpper,
  }) async {
    await _ensureInitialized();
    await ensurePingOk();

    final nonce = generateNonce();
    final intentMessage = generateLockPositionIntentMessage(
      userPublicKey: _publicKey,
      lpIdentityPublicKey: poolId,
      lockUntilTimestamp: lockUntilTimestamp,
      tickLower: tickLower,
      tickUpper: tickUpper,
      nonce: nonce,
    );

    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = LockPositionRequest(
      userPublicKey: _publicKey,
      poolId: poolId,
      lockUntilTimestamp: lockUntilTimestamp,
      tickLower: tickLower,
      tickUpper: tickUpper,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final response = await _typedApi.lockPosition(request);

    if (response.accepted != true) {
      final errorMessage = response.error ?? 'Lock position rejected by the AMM';
      throw Exception(errorMessage);
    }

    return response;
  }

  /// List LP position locks for a pool. Read-only, no signature required.
  /// [poolId] Pool ID (LP identity public key)
  /// [ownerPublicKey] Optional filter by owner
  Future<List<LpLockInfo>> getPositionLocks(
    String poolId, [
    String? ownerPublicKey,
  ]) async {
    await _ensureInitialized();

    final response = await _typedApi.getPositionLocks(
      poolId,
      ownerPublicKey: ownerPublicKey,
    );
    // Assuming GetPositionLocksResponse has a `locks` property of type List<LpLockInfo>
    return response.locks;
  }

  /// Transfer ownership of a locked LP position to a new owner.
  ///
  /// Single-step: signing this immediately transfers the position on server
  /// acceptance. There is no propose/accept handshake — verify the recipient
  /// before calling. The lock metadata travels with the position; you cannot
  /// use this to bypass an active lock.
  ///
  /// V3 (concentrated liquidity): pass `tickLower` and `tickUpper`; the
  /// entire position at that tick range moves to the new owner.
  ///
  /// V2 (constant-product): pass `lpTokensToTransfer` as a positive-integer
  /// string; the named amount of LP shares transfers to the new owner. The
  /// sender keeps the residual; if the transfer drains the sender to zero,
  /// the sender's lock row is deleted and the recipient gets a new lock at
  /// the same expiry. If the recipient already has a lock, the stronger of
  /// the two (later expiry, or indefinite) wins.
  ///
  /// [poolId] Pool ID (LP identity public key)
  /// [newOwnerPublicKey] Recipient's compressed secp256k1 pubkey (hex)
  /// [tickLower] V3 lower tick (required for V3, must pair with tickUpper)
  /// [tickUpper] V3 upper tick
  /// [lpTokensToTransfer] V2 only; positive integer string in atomic units
  Future<TransferPositionResponse> transferPosition(
    String poolId,
    String newOwnerPublicKey, {
    int? tickLower,
    int? tickUpper,
    String? lpTokensToTransfer,
  }) async {
    await _ensureInitialized();
    await ensurePingOk();

    final nonce = generateNonce();
    final intentMessage = generateTransferPositionIntentMessage(
      userPublicKey: _publicKey,
      lpIdentityPublicKey: poolId,
      newOwnerPublicKey: newOwnerPublicKey,
      tickLower: tickLower,
      tickUpper: tickUpper,
      lpTokensToTransfer: lpTokensToTransfer,
      nonce: nonce,
    );

    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = TransferPositionRequest(
      userPublicKey: _publicKey,
      poolId: poolId,
      newOwnerPublicKey: newOwnerPublicKey,
      tickLower: tickLower,
      tickUpper: tickUpper,
      lpTokensToTransfer: lpTokensToTransfer,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final response = await _typedApi.transferPosition(request);

    if (response.accepted != true) {
      final errorMessage = response.error ?? 'Transfer position rejected by the AMM';
      throw Exception(errorMessage);
    }

    return response;
  }

  // Host Operations

  /// Register as a host
  Future<RegisterHostResponse> registerHost({
    required String namespace,
    required int minFeeBps,
    String? feeRecipientPublicKey,
  }) async {
    await _ensureInitialized();
    await ensurePingOk();

    final feeRecipient = feeRecipientPublicKey ?? _publicKey;
    final nonce = generateNonce();

    // Generate intent
    final intentMessage = generateRegisterHostIntentMessage(
      namespace: namespace,
      minFeeBps: minFeeBps,
      feeRecipientPublicKey: feeRecipient,
      nonce: nonce,
    );

    // Sign intent
    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = RegisterHostRequest(
      namespace: namespace,
      minFeeBps: minFeeBps,
      feeRecipientPublicKey: feeRecipient,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    return _typedApi.registerHost(request);
  }

  /// Get host information
  Future<GetHostResponse> getHost(String namespace) async {
    await _ensureInitialized();
    return _typedApi.getHost(namespace);
  }

  /// Get pool host fees
  Future<GetPoolHostFeesResponse> getPoolHostFees(
    String hostNamespace,
    String poolId,
  ) async {
    await _ensureInitialized();
    await ensurePingOk();
    // Assuming getPoolHostFees on typedApi uses named parameters
    return _typedApi.getPoolHostFees(GetPoolHostFeesRequest(
      hostNamespace: hostNamespace, 
      poolId: poolId,
    ));
  }

  /// Get host fee withdrawal history
  Future<FeeWithdrawalHistoryResponse> getHostFeeWithdrawalHistory([
    FeeWithdrawalHistoryQuery? query,
  ]) async {
    await _ensureInitialized();
    return _typedApi.getHostFeeWithdrawalHistory(query);
  }

  /// Withdraw host fees
  Future<WithdrawHostFeesResponse> withdrawHostFees({
    required String lpIdentityPublicKey,
    String? assetBAmount,
  }) async {
    await _ensureInitialized();

    await ensureAmmOperationAllowed('allow_withdraw_fees');

    final nonce = generateNonce();
    final amount = assetBAmount ?? '0';
    final intentMessage = generateWithdrawHostFeesIntentMessage(
      hostPublicKey: _publicKey,
      lpIdentityPublicKey: lpIdentityPublicKey,
      assetBAmount: amount,
      nonce: nonce,
    );

    // Sign intent
    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = WithdrawHostFeesRequest(
      lpIdentityPublicKey: lpIdentityPublicKey,
      assetBAmount: amount,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final response = await _typedApi.withdrawHostFees(request);

    // Check if the withdrawal was accepted
    if (response.accepted != true) {
      final errorMessage = response.error ?? 'Withdraw host fees rejected by the AMM';
      throw Exception(errorMessage);
    }

    return response;
  }

  /// Get host fees across all pools
  Future<GetHostFeesResponse> getHostFees(String hostNamespace) async {
    await _ensureInitialized();
    await ensurePingOk();

    final request = GetHostFeesRequest(
      hostNamespace: hostNamespace,
    );

    return _typedApi.getHostFees(request);
  }

  /// Get integrator fee withdrawal history
  Future<FeeWithdrawalHistoryResponse> getIntegratorFeeWithdrawalHistory([
    FeeWithdrawalHistoryQuery? query,
  ]) async {
    await _ensureInitialized();
    return _typedApi.getIntegratorFeeWithdrawalHistory(query);
  }

  /// Get fees for a specific pool for an integrator
  Future<GetPoolIntegratorFeesResponse> getPoolIntegratorFees(String poolId) async {
    await _ensureInitialized();
    await ensurePingOk();
    // Assuming getPoolIntegratorFees on typedApi uses named parameters based on the object passed in TS
    return _typedApi.getPoolIntegratorFees(poolId);
  }

  /// Withdraw integrator fees
  Future<WithdrawIntegratorFeesResponse> withdrawIntegratorFees({
    required String lpIdentityPublicKey,
    String? assetBAmount,
  }) async {
    await _ensureInitialized();

    await ensureAmmOperationAllowed('allow_withdraw_fees');

    final nonce = generateNonce();
    final amount = assetBAmount ?? '0';
    final intentMessage = generateWithdrawIntegratorFeesIntentMessage(
      integratorPublicKey: _publicKey,
      lpIdentityPublicKey: lpIdentityPublicKey,
      assetBAmount: amount,
      nonce: nonce,
    );

    // Sign intent
    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = WithdrawIntegratorFeesRequest(
      integratorPublicKey: _publicKey,
      lpIdentityPublicKey: lpIdentityPublicKey,
      assetBAmount: amount,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final response = await _typedApi.withdrawIntegratorFees(request);

    // Check if the withdrawal was accepted
    if (response.accepted != true) {
      final errorMessage = response.error ?? 'Withdraw integrator fees rejected by the AMM';
      throw Exception(errorMessage);
    }

    return response;
  }

  /// Get integrator fees across all pools
  Future<GetIntegratorFeesResponse> getIntegratorFees() async {
    await _ensureInitialized();
    return _typedApi.getIntegratorFees();
  }

  // Escrow Operations

  /// Creates a new escrow contract.
  /// This is the first step in a two-step process: create, then fund.
  ///
  /// Returns a record where either createResponse or fundResponse will be non-null 
  /// depending on whether autoFund was true.
  Future<({CreateEscrowResponse? createResponse, FundEscrowResponse? fundResponse})> createEscrow({
    required String assetId,
    required String assetAmount,
    required List<({String id, String amount})> recipients,
    required List<Condition> claimConditions,
    String? abandonHost,
    List<Condition>? abandonConditions,
    bool? autoFund,
    /// When true, checks against availableToSendBalance instead of total balance
    bool? useAvailableBalance,
  }) async {
    await _ensureInitialized();
    await ensurePingOk();

    final nonce = generateNonce();
    
    // The intent message requires a different structure for recipients and conditions
    final intentRecipients = recipients.map((r) => EscrowRecipient(
      recipientId: r.id,
      amount: r.amount,
      hasClaimed: false, // Default value for creation
    )).toList();

    // Note: In TS they cast `Condition[] as unknown as EscrowCondition[]`. 
    // If Dart requires explicit mapping between these classes, you will need to map them here. 
    // Assuming for now they share an interface or can be cast.
    final intentMessage = generateCreateEscrowIntentMessage(
      creatorPublicKey: _publicKey,
      assetId: assetId,
      assetAmount: assetAmount,
      recipients: intentRecipients,
      claimConditions: claimConditions.cast<EscrowCondition>(), 
      abandonHost: abandonHost,
      abandonConditions: abandonConditions?.cast<EscrowCondition>(),
      nonce: nonce,
    );

    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = CreateEscrowRequest(
      creatorPublicKey: _publicKey,
      assetId: assetId,
      assetAmount: assetAmount,
      // Note: Assuming CreateEscrowRequest.recipients takes the original format or EscrowRecipient. 
      // If it takes a specific class, you might need to map it here.
      recipients: recipients, 
      claimConditions: claimConditions,
      abandonHost: abandonHost,
      abandonConditions: abandonConditions,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final createResponse = await _typedApi.createEscrow(request);

    final shouldAutoFund = autoFund != false; // true by default

    if (!shouldAutoFund) {
      return (createResponse: createResponse, fundResponse: null);
    }

    // Auto-fund the escrow
    // Note: Assuming fundEscrow is ported in a future chunk
    final fundResponse = await fundEscrow(
      escrowId: createResponse.escrowId,
      depositAddress: createResponse.depositAddress,
      assetId: assetId,
      assetAmount: assetAmount,
      useAvailableBalance: useAvailableBalance,
    );
    
    return (createResponse: null, fundResponse: fundResponse);
  }

  /// Funds an escrow contract to activate it.
  /// This handles the asset transfer and confirmation in one step.
  Future<FundEscrowResponse> fundEscrow({
    required String escrowId,
    required String depositAddress,
    required String assetId,
    required String assetAmount,
    /// When true, checks against availableToSendBalance instead of total balance
    bool? useAvailableBalance,
  }) async {
    await _ensureInitialized();
    await ensurePingOk();

    // 1. Balance check
    await checkBalance(
      balancesToCheck: [
        (assetAddress: assetId, amount: assetAmount),
      ],
      errorPrefix: 'Insufficient balance to fund escrow: ',
      useAvailableBalance: useAvailableBalance,
    );

    // 2. Perform transfer
    final escrowSparkAddress = encodeSparkAddressNew(SparkAddressDataNew(
      identityPublicKey: depositAddress,
      network: _sparkNetwork,
    ));

    final sparkTransferId = await transferAsset(
      receiverSparkAddress: escrowSparkAddress,
      assetAddress: assetId,
      amount: assetAmount,
    );

    // 3. Execute signed intent
    return await executeFundEscrowIntent(
      escrowId: escrowId,
      sparkTransferId: sparkTransferId,
    );
  }

  Future<FundEscrowResponse> executeFundEscrowIntent({
    required String escrowId,
    required String sparkTransferId,
  }) async {
    await ensurePingOk();
    // Generate intent
    final nonce = generateNonce();
    final intentMessage = generateFundEscrowIntentMessage(
      escrowId: escrowId,
      sparkTransferId: sparkTransferId,
      creatorPublicKey: _publicKey,
      nonce: nonce,
    );

    // Sign
    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    // Call API
    final request = FundEscrowRequest(
      escrowId: escrowId,
      sparkTransferId: sparkTransferId,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    return _typedApi.fundEscrow(request);
  }

  /// Claims funds from an active escrow contract.
  /// The caller must be a valid recipient and all claim conditions must be met.
  Future<ClaimEscrowResponse> claimEscrow({
    required String escrowId,
  }) async {
    await _ensureInitialized();
    await ensurePingOk();

    final nonce = generateNonce();
    final intentMessage = generateClaimEscrowIntentMessage(
      escrowId: escrowId,
      recipientPublicKey: _publicKey,
      nonce: nonce,
    );

    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = ClaimEscrowRequest(
      escrowId: escrowId,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    return _typedApi.claimEscrow(request);
  }

  /// Retrieves the current state of an escrow contract.
  /// This is a read-only operation and does not require authentication.
  Future<EscrowState> getEscrow(String escrowId) async {
    await _ensureInitialized();
    return _typedApi.getEscrow(escrowId);
  }

  // Swap History

  /// Get swaps for a specific pool
  Future<ListPoolSwapsResponse> getPoolSwaps(
    String lpPubkey, [
    ListPoolSwapsQuery? query,
  ]) async {
    await _ensureInitialized();
    return _typedApi.getPoolSwaps(lpPubkey, query);
  }

  /// Get global swaps across all pools
  Future<ListGlobalSwapsResponse> getGlobalSwaps([
    ListGlobalSwapsQuery? query,
  ]) async {
    await _ensureInitialized();
    return _typedApi.getGlobalSwaps(query);
  }

  /// Get swaps for a specific user
  Future<ListUserSwapsResponse> getUserSwaps({
    String? userPublicKey,
    ListUserSwapsQuery? query,
  }) async {
    await _ensureInitialized();
    final user = userPublicKey ?? _publicKey;
    return _typedApi.getUserSwaps(user, query);
  }

  // Clawback
  
  /// Request clawback of a stuck inbound transfer to an LP wallet
  Future<ClawbackResponse> clawback({
    required String sparkTransferId,
    required String lpIdentityPublicKey,
  }) async {
    await _ensureInitialized();
    await ensurePingOk();

    final nonce = generateNonce();
    final intentMessage = generateClawbackIntentMessage(
      senderPublicKey: _publicKey,
      sparkTransferId: sparkTransferId,
      lpIdentityPublicKey: lpIdentityPublicKey,
      nonce: nonce,
    );

    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = ClawbackRequest(
      senderPublicKey: _publicKey,
      sparkTransferId: sparkTransferId,
      lpIdentityPublicKey: lpIdentityPublicKey,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final response = await _typedApi.clawback(request);

    if (response.accepted != true) {
      final errorMessage = response.error ?? 'Clawback request was rejected';
      throw Exception(errorMessage);
    }

    return response;
  }

  /// Check if a transfer is eligible for clawback
  ///
  /// This is a read-only check that verifies:
  /// - The transfer exists and is valid
  /// - The authenticated user is the original sender
  /// - The transfer is not already reserved or spent
  /// - The transfer has not been claimed/settled
  /// - The transfer is less than 23 hours old
  ///
  /// Note: This does NOT initiate a clawback, only checks eligibility.
  ///
  /// [sparkTransferId] - The Spark transfer ID to check
  Future<CheckClawbackEligibilityResponse> checkClawbackEligibility({
    required String sparkTransferId,
  }) async {
    await _ensureInitialized();
    await ensurePingOk();

    final request = CheckClawbackEligibilityRequest(
      sparkTransferId: sparkTransferId,
    );

    return _typedApi.checkClawbackEligibility(request);
  }

  /// List transfers eligible for clawback
  ///
  /// Returns a paginated list of transfers that the authenticated user
  /// can potentially clawback. Filters based on:
  /// - Transfers sent by the authenticated user
  /// - Transfers to pools the user has interacted with
  /// - Not already spent or reserved
  /// - Less than 10 days old
  Future<ListClawbackableTransfersResponse> listClawbackableTransfers([
    ListClawbackableTransfersQuery? query,
  ]) async {
    await _ensureInitialized();
    await ensurePingOk();
    return _typedApi.listClawbackableTransfers(query);
  }

  /// Attempt to clawback multiple transfers
  ///
  /// [transferIds] - Array of transfer IDs to clawback
  /// [lpIdentityPublicKey] - The LP wallet public key
  Future<List<ClawbackAttemptResult>> clawbackMultiple(
    List<String> transferIds,
    String lpIdentityPublicKey,
  ) async {
    final results = <ClawbackAttemptResult>[];

    for (final transferId in transferIds) {
      try {
        final response = await clawback(
          sparkTransferId: transferId,
          lpIdentityPublicKey: lpIdentityPublicKey,
        );
        results.add(ClawbackAttemptResult(
          transferId: transferId,
          success: true,
          response: response.toJson(),
        ));
      } catch (err) {
        results.add(ClawbackAttemptResult(
          transferId: transferId,
          success: false,
          error: err is Exception ? err.toString() : err.toString(),
        ));
      }
    }

    return results;
  }

  /// Internal helper to execute an operation with automatic clawback on failure
  ///
  /// [operation] - The async operation to execute
  /// [transferIds] - Transfer IDs that were sent and may need clawback
  /// [lpIdentityPublicKey] - The LP wallet public key for clawback
  /// Returns The result of the operation
  /// Throws FlashnetError with typed clawbackSummary attached
  Future<T> executeWithAutoClawback<T>(
    Future<T> Function() operation,
    List<String> transferIds,
    String lpIdentityPublicKey,
  ) async {
    try {
      return await operation();
    } catch (error) {
      // Convert to FlashnetError if not already
      // Note: Assuming FlashnetError has a static/factory method fromUnknown
      final flashnetError = FlashnetError.fromUnknown(
        error, 
        transferIds: transferIds,
        lpIdentityPublicKey: lpIdentityPublicKey,
      );

      // Check if we should attempt clawback
      if (flashnetError.shouldClawback() && transferIds.isNotEmpty) {
        // Attempt to clawback all transfers
        final clawbackResults = await clawbackMultiple(
          transferIds,
          lpIdentityPublicKey,
        );

        // Separate successful and failed clawbacks
        final successfulClawbacks = clawbackResults.where((r) => r.success).toList();
        final failedClawbacks = clawbackResults.where((r) => !r.success).toList();

        // Build typed clawback summary
        final clawbackSummary = AutoClawbackSummary(
          attempted: true,
          totalTransfers: transferIds.length,
          successCount: successfulClawbacks.length,
          failureCount: failedClawbacks.length,
          results: clawbackResults,
          recoveredTransferIds: successfulClawbacks.map((r) => r.transferId).toList(),
          unrecoveredTransferIds: failedClawbacks.map((r) => r.transferId).toList(),
        );

        // Create enhanced error message
        var enhancedMessage = flashnetError.message;
        if (successfulClawbacks.isNotEmpty) {
          enhancedMessage += ' [Auto-clawback: ${successfulClawbacks.length}/${transferIds.length} transfers recovered]';
        }
        if (failedClawbacks.isNotEmpty) {
          final failedIds = failedClawbacks.map((r) => r.transferId).join(', ');
          enhancedMessage += ' [Clawback failed for: $failedIds]';
        }

        // Determine remediation based on clawback results
        String remediation;
        if (clawbackSummary.failureCount == 0) {
          remediation = 'Your funds have been automatically recovered. No action needed.';
        } else if (clawbackSummary.successCount > 0) {
          remediation = '${clawbackSummary.successCount} transfer(s) recovered. Manual clawback needed for remaining transfers.';
        } else {
          remediation = flashnetError.remediation ??
              'Automatic recovery failed. Please initiate a manual clawback.';
        }

        // Throw new error with typed clawback summary
        final errorWithClawback = FlashnetError(
          enhancedMessage,
          FlashnetErrorOptions(
          response: FlashnetErrorResponseBody(
            errorCode: flashnetError.errorCode,
            errorCategory: flashnetError.category.toString(),
            message: enhancedMessage,
            details: flashnetError.details,
            requestId: flashnetError.requestId,
            timestamp: flashnetError.timestamp,
            service: flashnetError.service,
            severity: flashnetError.severity,
            remediation: remediation,
          ),
          httpStatus: flashnetError.httpStatus,
          transferIds: clawbackSummary.unrecoveredTransferIds,
          lpIdentityPublicKey: lpIdentityPublicKey,
          clawbackSummary: clawbackSummary,
          ),
        );

        throw errorWithClawback;
      }

      // Not a clawbackable error, just re-throw
      throw flashnetError;
    }
  }

  // Token Address Operations

  /// Encode a token identifier into a human-readable token address using the client's Spark network
  /// [tokenIdentifier] - Token identifier as hex string or Uint8Array
  /// Returns Human-readable token address
  String encodeTokenAddress(Object tokenIdentifier) {
    // Assuming encodeSparkHumanReadableTokenIdentifier can handle both String and Uint8List
    return encodeSparkHumanReadableTokenIdentifier(
      tokenIdentifier,
      _sparkNetwork,
    );
  }

  /// Decode a human-readable token address back to its identifier
  /// [address] - Human-readable token address
  /// Returns Record containing the token identifier (as hex string) and Spark network
  ({String tokenIdentifier, SparkNetworkType network}) decodeTokenAddress(
    String address,
  ) {
    // Assuming decodeSparkHumanReadableTokenIdentifier returns a Record or Object 
    // with tokenIdentifier and network properties.
    final result = decodeSparkHumanReadableTokenIdentifier(address, _sparkNetwork);
    return (
      tokenIdentifier: result.tokenIdentifier,
      network: result.network,
    );
  }

  /// @deprecated Use encodeTokenAddress instead - this method uses legacy types
  /// Encode a token identifier into a human-readable token address using legacy types
  /// [tokenIdentifier] - Token identifier as hex string or Uint8Array
  /// Returns Human-readable token address
  @Deprecated('Use encodeTokenAddress instead')
  String encodeLegacyTokenAddress(Object tokenIdentifier) {
    return encodeSparkHumanReadableTokenIdentifier(
      tokenIdentifier,
      _sparkNetwork,
    );
  }

  /// @deprecated Use decodeTokenAddress instead - this method uses legacy types
  /// Decode a human-readable token address back to its identifier using legacy types
  /// [address] - Human-readable token address
  /// Returns Record containing the token identifier (as hex string) and network
  @Deprecated('Use decodeTokenAddress instead')
  ({String tokenIdentifier, NetworkType network}) decodeLegacyTokenAddress(
    String address,
  ) {
    final result = decodeSparkHumanReadableTokenIdentifier(address, _sparkNetwork);
    return (
      tokenIdentifier: result.tokenIdentifier,
      // Note: Assuming a simple cast here based on the TS code, though a proper 
      // mapping function might be needed depending on your enum setup.
      network: result.network, 
    );
  }

  // Status

  // Config Inspection
  
  /// Get raw feature status list (cached briefly)
  Future<FeatureStatusResponse> getFeatureStatus() async {
    await _ensureInitialized();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (_featureStatusCache != null && _featureStatusCache!.expiryMs > now) {
      return _featureStatusCache!.data;
    }
    
    final data = await _typedApi.getFeatureStatus();
    _featureStatusCache = (
      data: data,
      expiryMs: now + _featureStatusTtlMs,
    );
    return data;
  }

  /// Get feature flags as a map of feature name to boolean (cached briefly)
  Future<Map<String, bool>> getFeatureFlags() async {
    await _ensureInitialized();
    // Assuming getFeatureStatusMap is ported in a future chunk
    return getFeatureStatusMap();
  }

  /// Get raw min-amounts configuration list from the backend
  Future<MinAmountsResponse> getMinAmounts() async {
    await _ensureInitialized();
    return _typedApi.getMinAmounts();
  }

  /// Get enabled min-amounts as a map keyed by hex asset identifier
  Future<Map<String, BigInt>> getMinAmountsMap() async {
    await _ensureInitialized();
    // Assuming getEnabledMinAmountsMap is ported in a future chunk
    return getEnabledMinAmountsMap();
  }

  /// Get allowed Asset B list for pool creation (cached for 60s)
  Future<AllowedAssetsResponse> getAllowedAssets() async {
    await _ensureInitialized();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (_allowedAssetsCache != null && _allowedAssetsCache!.expiryMs > now) {
      return _allowedAssetsCache!.data;
    }
    
    final allowed = await _typedApi.getAllowedAssets();
    _allowedAssetsCache = (
      data: allowed,
      expiryMs: now + _allowedAssetsTtlMs,
    );
    return allowed;
  }

  /// Ping the settlement service
  Future<SettlementPingResponse?> ping() async {
    await _ensureInitialized();
    return _typedApi.ping();
  }

  // Helper Methods

  /// Performs asset transfer using generalized asset address for both BTC and tokens.
  Future<String> transferAsset({
    required String receiverSparkAddress,
    required String assetAddress,
    required Object amount, // String, num, or BigInt
    String? errorPrefix,
    bool? useAvailableBalance,
  }) async {
    final transferIds = await transferAssets(
      [
        (
          receiverSparkAddress: receiverSparkAddress,
          assetAddress: assetAddress,
          amount: amount,
        ),
      ],
      errorPrefix,
      useAvailableBalance,
    );
    return transferIds[0];
  }

  /// Performs asset transfers using generalized asset addresses for both BTC and tokens.
  Future<List<String>> transferAssets(
    List<({String receiverSparkAddress, String assetAddress, Object amount})> recipients, [
    String? checkBalanceErrorPrefix,
    bool? useAvailableBalance,
  ]) async {
    if (checkBalanceErrorPrefix != null) {
      await checkBalance(
        balancesToCheck: recipients.map((v)=>(amount:v.amount, assetAddress: v.assetAddress)).toList(),
        errorPrefix: checkBalanceErrorPrefix,
        useAvailableBalance: useAvailableBalance,
      );
    }

    final transferIds = <String>[];
    for (final recipient in recipients) {
      final amountStr = recipient.amount.toString();

      if (recipient.assetAddress == BTC_ASSET_PUBKEY) {
        // Assuming wallet.transfer returns a transfer object with an `id`
        final transfer = await _wallet.transfer(
          amountSats: BigInt.parse(amountStr),
          receiverSparkAddress: recipient.receiverSparkAddress,
        );
        transferIds.add(transfer.id);
      } else {
        final transferId = await _wallet.transferTokens(
          tokenIdentifier: _toHumanReadableTokenIdentifier(recipient.assetAddress),
          tokenAmount: BigInt.parse(amountStr),
          receiverSparkAddress: recipient.receiverSparkAddress,
        );
        transferIds.add(transferId!);
      }
    }

    return transferIds;
  }

  /// Helper method to add initial liquidity after pool creation
  Future<void> addInitialLiquidity(
    String poolId,
    String assetAAddress,
    String assetBAddress,
    String assetAAmount,
    String assetBAmount,
    String assetAMinAmountIn,
    String assetBMinAmountIn,
  ) async {
    // Enforce gating and min-amount policy for initial liquidity
    await ensureAmmOperationAllowed('allow_add_liquidity');
    await assertAddLiquidityMeetsMinAmounts(
      poolId: poolId,
      assetAAmount: assetAAmount,
      assetBAmount: assetBAmount,
    );

    final lpSparkAddress = encodeSparkAddressNew(SparkAddressDataNew(
      identityPublicKey: poolId,
      network: _sparkNetwork,
    ));

    final transferIds = await transferAssets([
      (
        receiverSparkAddress: lpSparkAddress,
        assetAddress: assetAAddress,
        amount: assetAAmount,
      ),
      (
        receiverSparkAddress: lpSparkAddress,
        assetAddress: assetBAddress,
        amount: assetBAmount,
      ),
    ]);

    final assetATransferId = transferIds[0];
    final assetBTransferId = transferIds[1];

    // Add liquidity
    final nonce = generateNonce();
    final intentMessage = generateAddLiquidityIntentMessage(AmmAddLiquiditySettlementRequest(
      userPublicKey: _publicKey,
      lpIdentityPublicKey: poolId,
      assetASparkTransferId: assetATransferId,
      assetBSparkTransferId: assetBTransferId,
      assetAAmount: assetAAmount,
      assetBAmount: assetBAmount,
      assetAMinAmountIn: assetAMinAmountIn,
      assetBMinAmountIn: assetBMinAmountIn,
      nonce: nonce,
    ));

    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = AddLiquidityRequest(
      userPublicKey: _publicKey,
      poolId: poolId,
      assetASparkTransferId: assetATransferId,
      assetBSparkTransferId: assetBTransferId,
      assetAAmountToAdd: assetAAmount,
      assetBAmountToAdd: assetBAmount,
      assetAMinAmountIn: assetAMinAmountIn,
      assetBMinAmountIn: assetBMinAmountIn,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final response = await _typedApi.addLiquidity(request);

    // Check if the initial liquidity addition was accepted
    if (response.accepted != true) {
      final errorMessage = response.error ?? 'Initial liquidity addition rejected by the AMM';
      throw Exception(errorMessage);
    }
  }

  // Lightning Payment with Token

  /// Get a quote for paying a Lightning invoice with a token.
  /// This calculates the optimal pool and token amount needed.
  ///
  /// [invoice] - BOLT11-encoded Lightning invoice
  /// [tokenAddress] - Token identifier to use for payment
  /// [maxSlippageBps] - Optional maximum slippage
  /// [integratorFeeRateBps] - Optional integrator fee rate
  /// [tokenAmount] - Optional token amount (required for zero-amount invoices)
  /// Returns Quote with pricing details
  /// Throws Exception if invoice amount or token amount is below Flashnet minimums
  Future<PayLightningWithTokenQuote> getPayLightningWithTokenQuote(
    String invoice,
    String tokenAddress, {
    int? maxSlippageBps,
    int? integratorFeeRateBps,
    String? tokenAmount,
  }) async {
    await _ensureInitialized();

    // Decode the invoice to get the amount (assuming this returns int?)
    final invoiceAmountSats = await decodeInvoiceAmount(invoice);

    // Zero-amount invoice: forward-direction quoting using caller-specified tokenAmount
    if (invoiceAmountSats <= 0) {
      if (tokenAmount == null || BigInt.parse(tokenAmount) <= BigInt.zero) {
        throw FlashnetError(
          'Zero-amount invoice requires tokenAmount in options.',
          FlashnetErrorOptions(
            response: FlashnetErrorResponseBody(
                errorCode: 'FSAG-1002',
                errorCategory: 'Validation',
                message: 'Zero-amount invoice requires tokenAmount in options.',
                requestId: '',
                timestamp: DateTime.now().toUtc().toIso8601String(),
                service: 'sdk',
                severity: 'Error',
                remediation: 'Provide tokenAmount when using a zero-amount invoice.',
            ),
          ),
        );
      }
      return _getZeroAmountInvoiceQuote(
        invoice,
        tokenAddress,
        tokenAmount,
        maxSlippageBps: maxSlippageBps,
        integratorFeeRateBps: integratorFeeRateBps,
      );
    }

    // Get Lightning fee estimate (assuming this returns int)
    final lightningFeeEstimate = await getLightningFeeEstimate(invoice);

    // Total BTC needed = invoice amount + lightning fee (unmasked).
    // Bitmasking for V2 pools is handled inside findBestPoolForTokenToBtc.
    final baseBtcNeeded = BigInt.from(invoiceAmountSats) + BigInt.from(lightningFeeEstimate);

    // Check Flashnet minimum amounts early to provide clear error messages
    final minAmounts = await getEnabledMinAmountsMap();

    // Check BTC minimum (output from swap)
    final btcMinAmount = minAmounts[BTC_ASSET_PUBKEY.toLowerCase()];
    if (btcMinAmount != null && baseBtcNeeded < btcMinAmount) {
      final msg = 'Invoice amount too small. Minimum BTC output is $btcMinAmount sats, but invoice + lightning fee totals only $baseBtcNeeded sats.';
      throw FlashnetError(
        msg,
        FlashnetErrorOptions(
          response: FlashnetErrorResponseBody(
            errorCode: 'FSAG-1003',
            errorCategory: 'Validation',
            message: msg,
            requestId: '',
            timestamp: DateTime.now().toUtc().toIso8601String(),
            service: 'sdk',
            severity: 'Error',
            remediation: 'Use an invoice of at least $btcMinAmount sats.',
          ),
        ),
      );
    }

    // Find the best pool to swap token -> BTC.
    // Bitmasking is applied per-pool inside this function (V2 pools get masked, V3 pools don't).
    final poolQuote = await findBestPoolForTokenToBtc(
      tokenAddress,
      baseBtcNeeded.toString(),
      integratorFeeRateBps,
    );

    // Check token minimum (input to swap)
    final tokenHex = _toHexTokenIdentifier(tokenAddress).toLowerCase();
    final tokenMinAmount = minAmounts[tokenHex];
    if (tokenMinAmount != null && safeBigInt(poolQuote.tokenAmountRequired) < tokenMinAmount) {
      final msg = 'Token amount too small. Minimum input is $tokenMinAmount units, but calculated amount is only ${poolQuote.tokenAmountRequired} units.';
      throw FlashnetError(
        msg,
        FlashnetErrorOptions(
          response: FlashnetErrorResponseBody(
            errorCode: 'FSAG-1003',
            errorCategory: 'Validation',
            message: msg,
            requestId: '',
            timestamp: DateTime.now().toUtc().toIso8601String(),
            service: 'sdk',
            severity: 'Error',
            remediation: 'Use a larger invoice amount.',
          ),
        ),
      );
    }

    // BTC variable fee adjustment: difference between what the pool targets and unmasked base.
    // For V3 pools this is 0 (no masking). For V2 it's the rounding overhead.
    final btcVariableFeeAdjustment = (safeBigInt(poolQuote.btcAmountUsed) - baseBtcNeeded).toInt();

    return PayLightningWithTokenQuote(
      poolId: poolQuote.poolId,
      tokenAddress: _toHexTokenIdentifier(tokenAddress),
      tokenAmountRequired: poolQuote.tokenAmountRequired,
      btcAmountRequired: poolQuote.btcAmountUsed,
      invoiceAmountSats: invoiceAmountSats,
      estimatedAmmFee: poolQuote.estimatedAmmFee,
      estimatedLightningFee: lightningFeeEstimate,
      btcVariableFeeAdjustment: btcVariableFeeAdjustment,
      executionPrice: poolQuote.executionPrice,
      priceImpactPct: poolQuote.priceImpactPct,
      tokenIsAssetA: poolQuote.tokenIsAssetA,
      poolReserves: poolQuote.poolReserves, // Assumes this is the mapped PoolReserves class
      warningMessage: poolQuote.warningMessage,
      curveType: poolQuote.curveType,
      isZeroAmountInvoice: false,
    );
  }

  /// Generate a quote for a zero-amount invoice.
  /// Forward-direction: simulate swapping tokenAmount and pick the pool with the best BTC output.
  Future<PayLightningWithTokenQuote> _getZeroAmountInvoiceQuote(
    String invoice,
    String tokenAddress,
    String tokenAmount, {
    int? maxSlippageBps,
    int? integratorFeeRateBps,
  }) async {
    final tokenHex = _toHexTokenIdentifier(tokenAddress);
    final btcHex = BTC_ASSET_PUBKEY;

    // Discover all token/BTC pools
    final results = await Future.wait([
      listPools(ListPoolsQuery(assetAAddress: tokenHex, assetBAddress: btcHex)),
      listPools(ListPoolsQuery(assetAAddress: btcHex, assetBAddress: tokenHex)),
    ]);
    
    final poolsWithTokenAsA = results[0];
    final poolsWithTokenAsB = results[1];

    // Using a Record here to match the TS anonymous object mapping
    final poolMap = <String, ({dynamic pool, bool tokenIsAssetA})>{};
    
    for (final p in [...poolsWithTokenAsA.pools, ...poolsWithTokenAsB.pools]) {
      // Assuming 'lpPublicKey' exists on the pool object
      if (!poolMap.containsKey(p.lpPublicKey)) {
        final tokenIsAssetA = p.assetAAddress.toLowerCase() == tokenHex.toLowerCase();
        poolMap[p.lpPublicKey] = (pool: p, tokenIsAssetA: tokenIsAssetA);
      }
    }

    final allPools = poolMap.values.toList();
    if (allPools.isEmpty) {
      throw FlashnetError(
        'No liquidity pool found for token $tokenAddress paired with BTC',
        FlashnetErrorOptions(         
          response: FlashnetErrorResponseBody(
            errorCode: 'FSAG-4001',
            errorCategory: 'Business',
            message: 'No liquidity pool found for token $tokenAddress paired with BTC',
            requestId: '',
            timestamp: DateTime.now().toUtc().toIso8601String(),
            service: 'sdk',
            severity: 'Error',
          ),
        ),
      );
    }

    // Simulate each pool with tokenAmount as input, pick highest BTC output
    ({
      String poolId,
      bool tokenIsAssetA,
      SimulateSwapResponse simulation,
      String curveType,
      PoolReserves poolReserves,
    })? bestResult;
    
    var bestBtcOut = BigInt.zero;

    for (final entry in allPools) {
      final pool = entry.pool;
      final tokenIsAssetA = entry.tokenIsAssetA;
      
      try {
        final poolDetails = await getPool(pool.lpPublicKey);
        final assetInAddress = tokenIsAssetA ? poolDetails.assetAAddress : poolDetails.assetBAddress;
        final assetOutAddress = tokenIsAssetA ? poolDetails.assetBAddress : poolDetails.assetAAddress;

        final simulation = await simulateSwap(
          SimulateSwapRequest(
            poolId: pool.lpPublicKey,
            assetInAddress: assetInAddress,
            assetOutAddress: assetOutAddress,
            amountIn: tokenAmount,
            integratorBps: integratorFeeRateBps,
          )
        );

        final btcOut = safeBigInt(simulation.amountOut);
        if (btcOut > bestBtcOut) {
          bestBtcOut = btcOut;
          bestResult = (
            poolId: pool.lpPublicKey,
            tokenIsAssetA: tokenIsAssetA,
            simulation: simulation,
            curveType: poolDetails.curveType,
            poolReserves: PoolReserves(
              assetAReserve: poolDetails.assetAReserve,
              assetBReserve: poolDetails.assetBReserve,
            ),
          );
        }
      } catch (_) {
        // Skip pools that fail simulation
      }
    }

    if (bestResult == null || bestBtcOut <= BigInt.zero) {
      throw FlashnetError(
        'No pool can produce BTC output for the given token amount',
        FlashnetErrorOptions(          
          response: FlashnetErrorResponseBody(
            errorCode: 'FSAG-4201',
            errorCategory: 'Business',
            message: 'No pool can produce BTC output for the given token amount',
            requestId: '',
            timestamp: DateTime.now().toUtc().toIso8601String(),
            service: 'sdk',
            severity: 'Error',
            remediation: 'Try a larger token amount.',
          ),
        ),
      );
    }

    // Estimate lightning fee from the BTC output
    int lightningFeeEstimate;
    try {
      lightningFeeEstimate = await getLightningFeeEstimate(invoice);
    } catch (_) {
      lightningFeeEstimate = math.max(
        5,
        (bestBtcOut.toDouble() * 0.0017).ceil(),
      );
    }

    // Check minimum amounts
    final minAmounts = await getEnabledMinAmountsMap();
    final btcMinAmount = minAmounts[BTC_ASSET_PUBKEY.toLowerCase()];
    if (btcMinAmount != null && bestBtcOut < btcMinAmount) {
      final msg = 'BTC output too small. Minimum is $btcMinAmount sats, but swap would produce only $bestBtcOut sats.';
      throw FlashnetError(
        msg,
        FlashnetErrorOptions(          
          response: FlashnetErrorResponseBody(
            errorCode: 'FSAG-1003',
            errorCategory: 'Validation',
            message: msg,
            requestId: '',
            timestamp: DateTime.now().toUtc().toIso8601String(),
            service: 'sdk',
            severity: 'Error',
            remediation: 'Use a larger token amount.',
          ),
        ),
      );
    }

    return PayLightningWithTokenQuote(
      poolId: bestResult.poolId,
      tokenAddress: tokenHex,
      tokenAmountRequired: tokenAmount,
      btcAmountRequired: bestBtcOut.toString(),
      invoiceAmountSats: 0,
      estimatedAmmFee: bestResult.simulation.feePaidAssetIn ?? '0',
      estimatedLightningFee: lightningFeeEstimate,
      btcVariableFeeAdjustment: 0,
      executionPrice: bestResult.simulation.executionPrice ?? '0',
      priceImpactPct: bestResult.simulation.priceImpactPct ?? '0',
      tokenIsAssetA: bestResult.tokenIsAssetA,
      poolReserves: bestResult.poolReserves,
      warningMessage: bestResult.simulation.warningMessage,
      curveType: bestResult.curveType,
      isZeroAmountInvoice: true,
    );
  }



  // Clawback Monitor

  /// Start a background job that periodically polls for clawbackable transfers
  /// and automatically claws them back.
  ///
  /// [options] - Monitor configuration options
  /// Returns ClawbackMonitorHandle to control the monitor
  ClawbackMonitorHandle startClawbackMonitor([ClawbackMonitorOptions? options]) {
    final intervalMs = options?.intervalMs ?? 60000; // Default: 1 minute
    final batchSize = options?.batchSize ?? 2; // Default: 2 clawbacks per batch (rate limit safe)
    final batchDelayMs = options?.batchDelayMs ?? 500; // Default: 500ms between batches
    final maxTransfersPerPoll = options?.maxTransfersPerPoll ?? 100; // Default: max 100 transfers per poll
    
    final onClawbackSuccess = options?.onClawbackSuccess;
    final onClawbackError = options?.onClawbackError;
    final onPollComplete = options?.onPollComplete;
    final onPollError = options?.onPollError;

    // Use the private implementation class defined below to hold state
    return _ClawbackMonitorHandleImpl(
      client: this,
      intervalMs: intervalMs,
      batchSize: batchSize,
      batchDelayMs: batchDelayMs,
      maxTransfersPerPoll: maxTransfersPerPoll,
      onClawbackSuccess: onClawbackSuccess,
      onClawbackError: onClawbackError,
      onPollComplete: onPollComplete,
      onPollError: onPollError,
    );
  }

  /// Pay a Lightning invoice using a token.
  /// This swaps the token to BTC on Flashnet and uses the BTC to pay the invoice.
  ///
  /// [options] - Payment options including invoice and token address
  /// Returns Payment result with transaction details
  Future<PayLightningWithTokenResult> payLightningWithToken(
    PayLightningWithTokenOptions options,
  ) async {
    await _ensureInitialized();

    final invoice = options.invoice;
    final tokenAddress = options.tokenAddress;
    final tokenAmount = options.tokenAmount;
    final maxSlippageBps = options.maxSlippageBps ?? 500; // 5% default
    final maxLightningFeeSats = options.maxLightningFeeSats;
    final preferSpark = options.preferSpark ?? true;
    final integratorFeeRateBps = options.integratorFeeRateBps;
    final integratorPublicKey = options.integratorPublicKey;
    final transferTimeoutMs = options.transferTimeoutMs ?? 30000; // 30s default
    final rollbackOnFailure = options.rollbackOnFailure ?? false;
    final useExistingBtcBalance = options.useExistingBtcBalance ?? false;
    final useAvailableBalance = options.useAvailableBalance ?? false;

    try {
      // Step 1: Get a quote for the payment
      final quote = await getPayLightningWithTokenQuote(
        invoice,
        tokenAddress,
        maxSlippageBps: maxSlippageBps,
        integratorFeeRateBps: integratorFeeRateBps,
        tokenAmount: tokenAmount,
      );

      // Step 2: Check token balance (always required)
      await checkBalance(
        balancesToCheck: [
          (assetAddress: tokenAddress, amount: quote.tokenAmountRequired),
        ],
        errorPrefix: 'Insufficient token balance for Lightning payment: ',
        useAvailableBalance: useAvailableBalance,
      );

      // Step 3: Get pool details
      final pool = await getPool(quote.poolId);

      // Step 4: Determine swap direction and execute
      final assetInAddress = quote.tokenIsAssetA
          ? pool.assetAAddress
          : pool.assetBAddress;
      final assetOutAddress = quote.tokenIsAssetA
          ? pool.assetBAddress
          : pool.assetAAddress;

      final effectiveMaxLightningFee = maxLightningFeeSats ?? quote.estimatedLightningFee;

      // Floor minAmountOut at invoiceAmount + fee so the swap never returns
      // less BTC than the lightning payment requires.
      final slippageMin = calculateMinAmountOut(
        quote.btcAmountRequired,
        maxSlippageBps,
      );
      
      final baseBtcNeeded = !quote.isZeroAmountInvoice
          ? BigInt.from(quote.invoiceAmountSats) + BigInt.from(effectiveMaxLightningFee)
          : BigInt.zero;
          
      final minBtcOut = BigInt.parse(slippageMin) >= baseBtcNeeded
          ? slippageMin
          : baseBtcNeeded.toString();

      // Execute the swap
      // Note: Using the Record structure we created in the earlier executeSwap port
      final swapResult = await executeSwap(
        poolId: quote.poolId,
        assetInAddress: assetInAddress,
        assetOutAddress: assetOutAddress,
        amountIn: quote.tokenAmountRequired,
        maxSlippageBps: maxSlippageBps,
        minAmountOut: minBtcOut,
        integratorFeeRateBps: integratorFeeRateBps,
        integratorPublicKey: integratorPublicKey,
        useAvailableBalance: useAvailableBalance,
      );
      
      final swapResponse = swapResult.response;
      final inboundSparkTransferId = swapResult.inboundSparkTransferId;

      if (swapResponse.accepted != true || swapResponse.outboundTransferId == null || swapResponse.outboundTransferId!.isEmpty) {
        return PayLightningWithTokenResult(
          success: false,
          poolId: quote.poolId,
          tokenAmountSpent: quote.tokenAmountRequired,
          btcAmountReceived: '0',
          swapTransferId: swapResponse.outboundTransferId ?? '',
          ammFeePaid: quote.estimatedAmmFee,
          sparkTokenTransferId: inboundSparkTransferId,
          error: swapResponse.error ?? 'Swap was not accepted',
        );
      }

      // Step 5: Claim the swap output and refresh wallet state.
      // Suppress leaf optimization for the entire claim-to-pay window so
      // the SSP cannot swap away the leaves we need for lightning payment.
      final restoreOptimization = suppressOptimization();
      try {
        var canPayImmediately = false;
        if (!quote.isZeroAmountInvoice && useExistingBtcBalance) {
          final invoiceAmountSats = await decodeInvoiceAmount(invoice);
          if (invoiceAmountSats == 0) {
            final btcNeededForPayment = invoiceAmountSats + effectiveMaxLightningFee;
            final balance = await getBalance();
            canPayImmediately = balance.balance >= BigInt.from(btcNeededForPayment);
          }
        }

        if (!canPayImmediately) {
          final claimed = await instaClaimTransfer(
            swapResponse.outboundTransferId!,
            transferTimeoutMs,
          );

          if (!claimed) {
            return PayLightningWithTokenResult(
              success: false,
              poolId: quote.poolId,
              tokenAmountSpent: quote.tokenAmountRequired,
              btcAmountReceived: swapResponse.amountOut ?? '0',
              swapTransferId: swapResponse.outboundTransferId!,
              ammFeePaid: quote.estimatedAmmFee,
              sparkTokenTransferId: inboundSparkTransferId,
              error: 'Transfer did not complete within timeout',
            );
          }
        }

        // Step 6: Calculate payment amount
        final requestedMaxLightningFee = effectiveMaxLightningFee;
        final btcReceived = swapResponse.amountOut ?? quote.btcAmountRequired;

        // Cap the lightning fee budget to what the wallet can actually cover.
        // The swap output may be slightly less than quoted due to rounding or
        // price movement between quote and execution. The Spark SDK requires
        // invoiceAmount + maxFeeSats <= balance, so we adjust maxFeeSats down
        // when the actual BTC received is less than expected.
        var cappedMaxLightningFee = requestedMaxLightningFee;
        if (!quote.isZeroAmountInvoice) {
          final actualBtc = safeBigInt(btcReceived);
          final invoiceAmount = BigInt.from(quote.invoiceAmountSats);
          final available = actualBtc - invoiceAmount;
          if (available > BigInt.zero && available < BigInt.from(cappedMaxLightningFee)) {
            cappedMaxLightningFee = available.toInt();
          }
        }

        // Step 7: Pay the Lightning invoice
        try {
          dynamic lightningPayment;
          int? invoiceAmountPaid;

          if (quote.isZeroAmountInvoice) {
            final actualBtc = safeBigInt(btcReceived);
            final lnFee = BigInt.from(cappedMaxLightningFee);
            final amountToPay = actualBtc - lnFee;

            if (amountToPay <= BigInt.zero) {
              return PayLightningWithTokenResult(
                success: false,
                poolId: quote.poolId,
                tokenAmountSpent: quote.tokenAmountRequired,
                btcAmountReceived: btcReceived,
                swapTransferId: swapResponse.outboundTransferId!,
                ammFeePaid: quote.estimatedAmmFee,
                sparkTokenTransferId: inboundSparkTransferId,
                error: 'BTC received ($btcReceived sats) is not enough to cover lightning fee ($cappedMaxLightningFee sats).',
              );
            }

            lightningPayment = await _wallet.payLightningInvoice(
              invoice: invoice,
              amountSatsToSend: amountToPay,
              maxFeeSats: cappedMaxLightningFee,
              preferSpark: preferSpark,
            );
          } else {
            lightningPayment = await _wallet.payLightningInvoice(
              invoice: invoice,
              maxFeeSats: cappedMaxLightningFee,
              preferSpark: preferSpark,
            );
          }

          // Extract the Spark transfer ID from the lightning payment result.
          // payLightningInvoice returns LightningSendRequest | WalletTransfer:
          //   - LightningSendRequest has .transfer?.sparkId (the Sparkscan-visible transfer ID)
          //   - WalletTransfer (Spark-to-Spark) has .id directly as the transfer ID
          // Note: lightningPayment.id (the SSP request ID) is already returned as lightningPaymentId
          final sparkLightningTransferId = lightningPayment.transfer?.sparkId as String?;

          return PayLightningWithTokenResult(
            success: true,
            poolId: quote.poolId,
            tokenAmountSpent: quote.tokenAmountRequired,
            btcAmountReceived: btcReceived,
            swapTransferId: swapResponse.outboundTransferId!,
            lightningPaymentId: lightningPayment.id as String?,
            ammFeePaid: quote.estimatedAmmFee,
            lightningFeePaid: cappedMaxLightningFee,
            invoiceAmountPaid: invoiceAmountPaid,
            sparkTokenTransferId: inboundSparkTransferId,
            sparkLightningTransferId: sparkLightningTransferId,
          );
        } catch (lightningError) {
          // Lightning payment failed after swap succeeded
          final lightningErrorMessage = lightningError is Exception 
              ? lightningError.toString() 
              : lightningError.toString();

          // Attempt rollback if requested
          if (rollbackOnFailure) {
            try {
              final rollbackResult = await rollbackSwap(
                quote.poolId,
                btcReceived,
                tokenAddress,
                maxSlippageBps,
              );

              // Assuming rollbackResult returns an object with a boolean success property
              if (rollbackResult.success == true) { 
                return PayLightningWithTokenResult(
                  success: false,
                  poolId: quote.poolId,
                  tokenAmountSpent: '0', // Rolled back
                  btcAmountReceived: '0',
                  swapTransferId: swapResponse.outboundTransferId!,
                  ammFeePaid: quote.estimatedAmmFee,
                  sparkTokenTransferId: inboundSparkTransferId,
                  error: 'Lightning payment failed: $lightningErrorMessage. Funds rolled back to ${rollbackResult.tokenAmount} tokens.',
                );
              }
            } catch (rollbackError) {
              final rollbackErrorMessage = rollbackError is Exception 
                  ? rollbackError.toString() 
                  : rollbackError.toString();
                  
              return PayLightningWithTokenResult(
                success: false,
                poolId: quote.poolId,
                tokenAmountSpent: quote.tokenAmountRequired,
                btcAmountReceived: btcReceived,
                swapTransferId: swapResponse.outboundTransferId!,
                ammFeePaid: quote.estimatedAmmFee,
                sparkTokenTransferId: inboundSparkTransferId,
                error: 'Lightning payment failed: $lightningErrorMessage. Rollback also failed: $rollbackErrorMessage. BTC remains in wallet.',
              );
            }
          }

          return PayLightningWithTokenResult(
            success: false,
            poolId: quote.poolId,
            tokenAmountSpent: quote.tokenAmountRequired,
            btcAmountReceived: btcReceived,
            swapTransferId: swapResponse.outboundTransferId!,
            ammFeePaid: quote.estimatedAmmFee,
            sparkTokenTransferId: inboundSparkTransferId,
            error: 'Lightning payment failed: $lightningErrorMessage. BTC ($btcReceived sats) remains in wallet.',
          );
        }
      } finally {
        restoreOptimization();
      }
    } catch (error) {
      final errorMessage = error is Exception ? error.toString() : error.toString();
      return PayLightningWithTokenResult(
        success: false,
        poolId: '',
        tokenAmountSpent: '0',
        btcAmountReceived: '0',
        swapTransferId: '',
        ammFeePaid: '0',
        error: errorMessage,
      );
    }
  }

  /// Attempt to rollback a swap by swapping BTC back to the original token
  Future<({bool success, String? tokenAmount})> rollbackSwap(
    String poolId,
    String btcAmount,
    String tokenAddress,
    int maxSlippageBps,
  ) async {
    final pool = await getPool(poolId);
    final tokenHex = _toHexTokenIdentifier(tokenAddress);

    // Determine swap direction (BTC -> Token)
    final tokenIsAssetA = pool.assetAAddress == tokenHex;
    final assetInAddress = tokenIsAssetA
        ? pool.assetBAddress
        : pool.assetAAddress; // BTC
    final assetOutAddress = tokenIsAssetA
        ? pool.assetAAddress
        : pool.assetBAddress; // Token

    // Calculate expected token output and min amount with slippage
    // For rollback, we accept more slippage since we're recovering from failure
    const minAmountOut = '0'; // Accept any amount to ensure rollback succeeds

    // Execute reverse swap
    final swapResult = await executeSwap(
      poolId: poolId,
      assetInAddress: assetInAddress,
      assetOutAddress: assetOutAddress,
      amountIn: btcAmount,
      maxSlippageBps: maxSlippageBps * 2, // Double slippage for rollback
      minAmountOut: minAmountOut,
    );
    
    final swapResponse = swapResult.response;

    if (swapResponse.accepted != true) {
      throw Exception(swapResponse.error ?? 'Rollback swap not accepted');
    }

    // Wait for the rollback transfer
    // Note: Assuming waitForTransferCompletion is ported in a future chunk
    if (swapResponse.outboundTransferId != null && swapResponse.outboundTransferId!.isNotEmpty) {
      await waitForTransferCompletion(
        swapResponse.outboundTransferId!,
        30000,
      );
    }

    return (
      success: true,
      tokenAmount: swapResponse.amountOut,
    );
  }

  /// Find the best pool for swapping a token to BTC
  Future<({
    String poolId,
    String tokenAmountRequired,
    String estimatedAmmFee,
    String executionPrice,
    String priceImpactPct,
    bool tokenIsAssetA,
    PoolReserves poolReserves,
    String? warningMessage,
    String btcAmountUsed,
    String curveType,
  })> findBestPoolForTokenToBtc(
    String tokenAddress,
    String baseBtcNeeded, [
    int? integratorFeeRateBps,
  ]) async {
    final tokenHex = _toHexTokenIdentifier(tokenAddress);
    final btcHex = BTC_ASSET_PUBKEY;

    // Find all pools that have this token paired with BTC
    // Note: The API may return the same pool for both filter combinations,
    // so we need to deduplicate and determine tokenIsAssetA from actual pool data
    final results = await Future.wait([
      listPools(ListPoolsQuery(assetAAddress: tokenHex, assetBAddress: btcHex)),
      listPools(ListPoolsQuery(assetAAddress: btcHex, assetBAddress: tokenHex)),
    ]);
    
    final poolsWithTokenAsA = results[0];
    final poolsWithTokenAsB = results[1];

    // Deduplicate pools by poolId and determine tokenIsAssetA from actual pool addresses
    final poolMap = <String, ({dynamic pool, bool tokenIsAssetA})>{};

    for (final p in [...poolsWithTokenAsA.pools, ...poolsWithTokenAsB.pools]) {
      if (!poolMap.containsKey(p.lpPublicKey)) {
        // Determine tokenIsAssetA from actual pool asset addresses, not from which query returned it
        final tokenIsAssetA = p.assetAAddress.toLowerCase() == tokenHex.toLowerCase();
        poolMap[p.lpPublicKey] = (pool: p, tokenIsAssetA: tokenIsAssetA);
      }
    }

    final allPools = poolMap.values.toList();

    if (allPools.isEmpty) {
      throw FlashnetError(
        'No liquidity pool found for token $tokenAddress paired with BTC',
        FlashnetErrorOptions(
          response: FlashnetErrorResponseBody(
            errorCode: 'FSAG-4001',
            errorCategory: 'Business',
            message: 'No liquidity pool found for token $tokenAddress paired with BTC',
            requestId: '',
            timestamp: DateTime.now().toUtc().toIso8601String(),
            service: 'sdk',
            severity: 'Error',
          ),
        ),
      );
    }

    // Pre-check: Get minimum amounts to provide clear error if invoice is too small
    final minAmounts = await getMinAmountsMap();
    final btcMinAmount = minAmounts[BTC_ASSET_PUBKEY.toLowerCase()];

    // Check if the BTC amount needed is below the minimum
    if (btcMinAmount != null && BigInt.parse(baseBtcNeeded) < btcMinAmount) {
      final msg = 'Invoice amount too small. Minimum $btcMinAmount sats required, but invoice only requires $baseBtcNeeded sats.';
      throw FlashnetError(
        msg,
        FlashnetErrorOptions(
          response: FlashnetErrorResponseBody(
            errorCode: 'FSAG-1003',
            errorCategory: 'Validation',
            message: msg,
            requestId: '',
            timestamp: DateTime.now().toUtc().toIso8601String(),
            service: 'sdk',
            severity: 'Error',
            remediation: 'Use an invoice with at least $btcMinAmount sats.',
          ),
        ),
      );
    }

    // Compute V2 masked BTC amount (round up to next multiple of 64 for bit masking)
    final baseBtc = BigInt.parse(baseBtcNeeded);
    const btcVariableFeeBits = 6;
    // 1n << 6n translates cleanly in Dart
    final btcVariableFeeMask = BigInt.one << btcVariableFeeBits; // 64
    final maskedBtc = ((baseBtc + btcVariableFeeMask - BigInt.one) ~/ btcVariableFeeMask) * btcVariableFeeMask;

    // Find the best pool (lowest token cost for the required BTC)
    ({dynamic pool, bool tokenIsAssetA})? bestPool;
    BigInt? bestTokenAmount; // Using null instead of MAX_SAFE_INTEGER
    var bestBtcTarget = BigInt.zero;
    var bestCurveType = '';
    ({
      String amountIn,
      String fee,
      String executionPrice,
      String priceImpactPct,
      String? warningMessage,
    })? bestSimulation;

    // Track errors for each pool to provide better diagnostics
    final poolErrors = <({String poolId, String error, String? btcReserve})>[];

    for (final entry in allPools) {
      final pool = entry.pool;
      final tokenIsAssetA = entry.tokenIsAssetA;
      
      try {
        // Get pool details for reserves and curve type
        final poolDetails = await getPool(pool.lpPublicKey);
        final isV3 = poolDetails.curveType == 'V3_CONCENTRATED';

        // V3 pools use exact BTC amount, V2 pools use masked amount
        final btcTarget = isV3 ? baseBtc : maskedBtc;

        final assetInAddress = tokenIsAssetA
            ? poolDetails.assetAAddress
            : poolDetails.assetBAddress;
        final assetOutAddress = tokenIsAssetA
            ? poolDetails.assetBAddress
            : poolDetails.assetAAddress;

        BigInt tokenAmount;
        String fee;
        String executionPrice;
        String priceImpactPct;
        String? warningMessage;

        if (isV3) {
          // V3: binary search with simulateSwap
          // Note: Assuming findV3TokenAmountForBtcOutput is ported in a future chunk
          final v3Result = await findV3TokenAmountForBtcOutput(
            poolId: pool.lpPublicKey,
            assetInAddress: assetInAddress,
            assetOutAddress: assetOutAddress,
            desiredBtcOut: btcTarget,
            currentPriceAInB: poolDetails.currentPriceAInB,
            tokenIsAssetA: tokenIsAssetA,
            integratorBps: integratorFeeRateBps,
          );

          tokenAmount = safeBigInt(v3Result.amountIn);
          fee = v3Result.totalFee;
          executionPrice = v3Result.simulation.executionPrice ?? '0';
          priceImpactPct = v3Result.simulation.priceImpactPct ?? '0';
          warningMessage = v3Result.simulation.warningMessage;
        } else {
          // V2: constant product math + simulation verification
          // Note: Assuming calculateTokenAmountForBtcOutput is ported in a future chunk
          final calculation = calculateTokenAmountForBtcOutput(
            btcTarget.toString(),
            poolDetails.assetAReserve,
            poolDetails.assetBReserve,
            poolDetails.lpFeeBps,
            poolDetails.hostFeeBps,
            tokenIsAssetA,
            integratorFeeRateBps,
          );

          tokenAmount = safeBigInt(calculation.amountIn);

          // Verify with simulation
          final simulation = await simulateSwap(
            SimulateSwapRequest(
              poolId: pool.lpPublicKey,
              assetInAddress: assetInAddress,
              assetOutAddress: assetOutAddress,
              amountIn: calculation.amountIn,
              integratorBps: integratorFeeRateBps,
            )
          );

          if (safeBigInt(simulation.amountOut) < btcTarget) {
            final btcReserve = tokenIsAssetA
                ? poolDetails.assetBReserve
                : poolDetails.assetAReserve;
            poolErrors.add((
              poolId: pool.lpPublicKey,
              error: 'Simulation output (${simulation.amountOut} sats) < required ($btcTarget sats)',
              btcReserve: btcReserve,
            ));
            continue;
          }

          fee = calculation.totalFee;
          executionPrice = simulation.executionPrice ?? '0';
          priceImpactPct = simulation.priceImpactPct ?? '0';
          warningMessage = simulation.warningMessage;
        }

        // Check if this pool offers a better rate
        if (bestTokenAmount == null || tokenAmount < bestTokenAmount) {
          bestPool = entry;
          bestTokenAmount = tokenAmount;
          bestBtcTarget = btcTarget;
          bestCurveType = poolDetails.curveType;
          bestSimulation = (
            amountIn: tokenAmount.toString(),
            fee: fee,
            executionPrice: executionPrice,
            priceImpactPct: priceImpactPct,
            warningMessage: warningMessage,
          );
        }
      } catch (e) {
        final errorMessage = e is Exception ? e.toString() : e.toString();
        poolErrors.add((
          poolId: pool.lpPublicKey,
          error: errorMessage,
          btcReserve: null,
        ));
      }
    }

    if (bestPool == null || bestSimulation == null) {
      var errorMessage = 'No pool has sufficient liquidity for $baseBtcNeeded sats';
      if (poolErrors.isNotEmpty) {
        final details = poolErrors.map((pe) {
          final reserveInfo = pe.btcReserve != null
              ? ' (BTC reserve: ${pe.btcReserve})'
              : '';
          final shortId = pe.poolId.length > 12 ? pe.poolId.substring(0, 12) : pe.poolId;
          return '  - Pool $shortId...$reserveInfo: ${pe.error}';
        }).join('\n');
        errorMessage += '\n\nPool evaluation details:\n$details';
      }
      throw FlashnetError(
        errorMessage,
        FlashnetErrorOptions(
          response: FlashnetErrorResponseBody(
            errorCode: 'FSAG-4201',
            errorCategory: 'Business',
            message: errorMessage,
            requestId: '',
            timestamp: DateTime.now().toUtc().toIso8601String(),
            service: 'sdk',
            severity: 'Error',
            remediation: 'Try a smaller amount or wait for more liquidity.',
          ),
        ),
      );
    }

    final poolDetails = await getPool(bestPool.pool.lpPublicKey);

    return (
      poolId: bestPool.pool.lpPublicKey.toString(),
      tokenAmountRequired: bestSimulation.amountIn,
      estimatedAmmFee: bestSimulation.fee,
      executionPrice: bestSimulation.executionPrice,
      priceImpactPct: bestSimulation.priceImpactPct,
      tokenIsAssetA: bestPool.tokenIsAssetA,
      poolReserves: PoolReserves(
        assetAReserve: poolDetails.assetAReserve,
        assetBReserve: poolDetails.assetBReserve,
      ),
      warningMessage: bestSimulation.warningMessage,
      btcAmountUsed: bestBtcTarget.toString(),
      curveType: bestCurveType,
    );
  }

  /// Calculate the token amount needed to get a specific BTC output.
  /// Implements the AMM fee-inclusive model.
  ({String amountIn, String totalFee}) calculateTokenAmountForBtcOutput(
    String btcAmountOut,
    String reserveA,
    String reserveB,
    int lpFeeBps,
    int hostFeeBps,
    bool tokenIsAssetA, [
    int? integratorFeeBps,
  ]) {
    final amountOut = safeBigInt(btcAmountOut);
    final resA = safeBigInt(reserveA);
    final resB = safeBigInt(reserveB);
    final totalFeeBps = lpFeeBps + hostFeeBps + (integratorFeeBps ?? 0);
    final feeRate = totalFeeBps / 10000.0; // Convert bps to decimal

    // Token is the input asset
    // BTC is the output asset

    if (tokenIsAssetA) {
      // Token is asset A, BTC is asset B
      // A → B swap: we want BTC out (asset B)
      // reserve_in = reserveA (token), reserve_out = reserveB (BTC)

      // Constant product formula for amount_in given amount_out:
      // amount_in_effective = (reserve_in * amount_out) / (reserve_out - amount_out)
      final reserveIn = resA;
      final reserveOut = resB;

      if (amountOut >= reserveOut) {
        throw Exception('Insufficient liquidity: requested BTC amount exceeds reserve');
      }

      // Calculate effective amount in (before fees)
      // Note: Integer division in BigInt automatically truncates (floors)
      final amountInEffective = (reserveIn * amountOut) ~/ (reserveOut - amountOut) + BigInt.one; // +1 for rounding up

      // A→B swap: LP fee deducted from input A, integrator fee from output B
      // amount_in = amount_in_effective * (1 + lp_fee_rate)
      // Then integrator fee is deducted from output, so we need slightly more input
      final lpFeeRate = lpFeeBps / 10000.0;
      final integratorFeeRate = (integratorFeeBps ?? 0) / 10000.0;

      // Account for LP fee on input
      final amountInWithLpFee = BigInt.from(
        (amountInEffective.toDouble() * (1 + lpFeeRate)).ceil()
      );

      // Account for integrator fee on output (need more input to get same output after fee)
      final amountIn = integratorFeeRate > 0
          ? BigInt.from((amountInWithLpFee.toDouble() * (1 + integratorFeeRate)).ceil())
          : amountInWithLpFee;

      final totalFee = amountIn - amountInEffective;

      return (
        amountIn: amountIn.toString(),
        totalFee: totalFee.toString(),
      );
    } else {
      // Token is asset B, BTC is asset A
      // B → A swap: we want BTC out (asset A)
      // reserve_in = reserveB (token), reserve_out = reserveA (BTC)

      final reserveIn = resB;
      final reserveOut = resA;

      if (amountOut >= reserveOut) {
        throw Exception('Insufficient liquidity: requested BTC amount exceeds reserve');
      }

      // Calculate effective amount in (before fees)
      final amountInEffective = (reserveIn * amountOut) ~/ (reserveOut - amountOut) + BigInt.one; // +1 for rounding up

      // B→A swap: ALL fees (LP + integrator) deducted from input B
      // amount_in = amount_in_effective * (1 + total_fee_rate)
      final amountIn = BigInt.from(
        (amountInEffective.toDouble() * (1 + feeRate)).ceil()
      );

      // Fee calculation: fee = amount_in * fee_rate / (1 + fee_rate)
      final totalFee = BigInt.from(
        ((amountIn.toDouble() * feeRate) / (1 + feeRate)).ceil()
      );

      return (
        amountIn: amountIn.toString(),
        totalFee: totalFee.toString(),
      );
    }
  }

  /// Find the token amount needed to get a specific BTC output from a V3 concentrated liquidity pool.
  /// Uses binary search with simulateSwap since V3 tick-based math can't be inverted locally.
  Future<({
    String amountIn,
    String totalFee,
    SimulateSwapResponse simulation,
  })> findV3TokenAmountForBtcOutput({
    required String poolId,
    required String assetInAddress,
    required String assetOutAddress,
    required BigInt desiredBtcOut,
    String? currentPriceAInB,
    required bool tokenIsAssetA,
    int? integratorBps,
  }) async {
    // Step 1: Compute initial estimate from pool price
    late BigInt estimate;
    if (currentPriceAInB != null && currentPriceAInB != '0') {
      final price = double.parse(currentPriceAInB);
      if (tokenIsAssetA) {
        // priceAInB = how much B (BTC) per 1 A (token), so tokenNeeded = btcOut / price
        estimate = BigInt.from((desiredBtcOut.toDouble() / price).ceil());
      } else {
        // priceAInB = how much B (token) per 1 A (BTC), so tokenNeeded = btcOut * price
        estimate = BigInt.from((desiredBtcOut.toDouble() * price).ceil());
      }
      // Ensure non-zero
      if (estimate <= BigInt.zero) {
        estimate = desiredBtcOut * BigInt.two;
      }
    } else {
      estimate = desiredBtcOut * BigInt.two;
    }

    // Step 2: Find upper bound by simulating with estimate + 10% buffer
    var upperBound = (estimate * BigInt.from(110)) ~/ BigInt.from(100);
    if (upperBound <= BigInt.zero) {
      upperBound = BigInt.one;
    }
    
    SimulateSwapResponse? upperSim;

    for (var attempt = 0; attempt < 3; attempt++) {
      final sim = await simulateSwap(
        SimulateSwapRequest(
          poolId: poolId,
          assetInAddress: assetInAddress,
          assetOutAddress: assetOutAddress,
          amountIn: upperBound.toString(),
          integratorBps: integratorBps,
        )
      );

      if (safeBigInt(sim.amountOut) >= desiredBtcOut) {
        upperSim = sim;
        break;
      }
      // Double the upper bound
      upperBound = upperBound * BigInt.two;
    }

    if (upperSim == null) {
      throw Exception('V3 pool $poolId has insufficient liquidity for $desiredBtcOut sats');
    }

    // Step 3: Refine estimate via linear interpolation
    final upperOut = safeBigInt(upperSim.amountOut);
    // Scale proportionally: if upperBound produced upperOut, we need roughly
    // (upperBound * desiredBtcOut / upperOut). Add +1 to avoid undershoot from truncation.
    var refined = (upperBound * desiredBtcOut) ~/ upperOut + BigInt.one;
    if (refined <= BigInt.zero) {
      refined = BigInt.one;
    }

    var bestAmountIn = upperBound;
    var bestSim = upperSim;

    // Check if the refined estimate is tighter
    if (refined < upperBound) {
      final refinedSim = await simulateSwap(
        SimulateSwapRequest(
          poolId: poolId,
          assetInAddress: assetInAddress,
          assetOutAddress: assetOutAddress,
          amountIn: refined.toString(),
          integratorBps: integratorBps,
        )
      );

      if (safeBigInt(refinedSim.amountOut) >= desiredBtcOut) {
        bestAmountIn = refined;
        bestSim = refinedSim;
      } else {
        // Refined estimate was slightly too low. Keep upperBound as best,
        // and let binary search narrow between refined (too low) and upperBound (sufficient).
        bestAmountIn = upperBound;
        bestSim = upperSim;
      }
    }

    // Step 4: Binary search to converge on minimum amountIn
    // Use a tight range: the interpolation is close, so search between 99.5% and 100% of best
    late BigInt lo;
    if (bestAmountIn == upperBound) {
      lo = refined < upperBound
          ? refined
          : (bestAmountIn * BigInt.from(99)) ~/ BigInt.from(100);
    } else {
      lo = (bestAmountIn * BigInt.from(999)) ~/ BigInt.from(1000);
    }
    
    if (lo <= BigInt.zero) {
      lo = BigInt.one;
    }
    
    var hi = bestAmountIn;

    for (var i = 0; i < 6; i++) {
      if (hi - lo <= BigInt.one) {
        break;
      }

      final mid = (lo + hi) ~/ BigInt.two;
      final midSim = await simulateSwap(
        SimulateSwapRequest(
          poolId: poolId,
          assetInAddress: assetInAddress,
          assetOutAddress: assetOutAddress,
          amountIn: mid.toString(),
          integratorBps: integratorBps,
        )
      );

      if (safeBigInt(midSim.amountOut) >= desiredBtcOut) {
        hi = mid;
        bestAmountIn = mid;
        bestSim = midSim;
      } else {
        lo = mid;
      }
    }

    // Compute fee from the best simulation
    final totalFee = bestSim.feePaidAssetIn ?? '0';

    return (
      amountIn: bestAmountIn.toString(),
      totalFee: totalFee,
      simulation: bestSim,
    );
  }

  /// Calculate minimum amount out with slippage protection
  String calculateMinAmountOut(String expectedAmount, int slippageBps) {
    final amount = BigInt.parse(expectedAmount);
    final slippageFactor = BigInt.from(10000 - slippageBps);
    // Integer division in Dart BigInt uses ~/
    final minAmount = (amount * slippageFactor) ~/ BigInt.from(10000);
    return minAmount.toString();
  }

  /// Wait for a transfer to be claimed using wallet events.
  /// This is more efficient than polling as it uses the wallet's event stream.
  Future<bool> waitForTransferCompletion(String transferId, int timeoutMs) async {
    final completer = Completer<bool>();
    Timer? timeout;

    timeout = Timer(Duration(milliseconds: timeoutMs), () {
      _wallet.removeListener(SparkWalletEvent.transferClaimed, _fallbackHandler);
      if (!completer.isCompleted) completer.complete(false);
    });

    void handler(String claimedTransferId, BigInt balance) {
      if (claimedTransferId == transferId) {
        timeout?.cancel();
        _wallet.removeListener(SparkWalletEvent.transferClaimed, handler);
        if (!completer.isCompleted) completer.complete(true);
      }
    }

    // Subscribe to transfer claimed events
    // The wallet's RPC stream will automatically claim incoming transfers
    try {
      // Note: If your Dart SparkWallet uses Streams instead of EventEmitters, 
      // replace this with: _wallet.transferClaimedStream.listen(...)
      _wallet.onTransferClaimed(handler);
    } catch (_) {
      // If event subscription fails, fall back to polling
      timeout.cancel();
      final result = await pollForTransferCompletion(transferId, timeoutMs);
      if (!completer.isCompleted) completer.complete(result);
    }

    return completer.future;
  }

  // A dummy handler reference just for the timeout catch above
  void _fallbackHandler(String _, BigInt _) {}

  /// Fallback polling method for transfer completion
  Future<bool> pollForTransferCompletion(String transferId, int timeoutMs) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    const pollIntervalMs = 500;

    while (DateTime.now().millisecondsSinceEpoch - startTime < timeoutMs) {
      try {
        final transfer = await _wallet.getTransfer(transferId);

        if (transfer != null) {
          // Check status. Casting to dynamic handles both enum .name or String properties
          final status = (transfer as dynamic).status;
          if (status == 'TRANSFER_STATUS_COMPLETED' || status?.name == 'TRANSFER_STATUS_COMPLETED') {
            return true;
          }
        }
      } catch (_) {
        // Ignore errors and continue polling
      }

      await Future.delayed(const Duration(milliseconds: pollIntervalMs));
    }

    return false;
  }

  /// Suppress leaf optimization on the wallet. Sets the internal
  /// optimizationInProgress flag so optimizeLeaves() returns immediately.
  /// Returns a restore function that clears the flag.
  void Function() suppressOptimization() {
    final w = _wallet as dynamic;
    
    bool? was;
    try {
      was = w.optimizationInProgress as bool?;
      w.optimizationInProgress = true;
    } catch (_) {
      // Ignore if property is entirely missing
    }

    return () {
      try {
        w.optimizationInProgress = was;
      } catch (_) {
        // Ignore
      }
    };
  }

  /// Insta-claim: listen for the wallet's stream event that fires when
  /// the coordinator broadcasts the transfer. The stream auto-claims
  /// incoming transfers, so no polling is needed.
  ///
  /// After claim, refreshes the leaf cache from the coordinator to
  /// ensure the balance is current.
  ///
  /// Caller is responsible for suppressing optimization around this call
  /// if the claimed leaves must not be swapped before spending.
  Future<bool> instaClaimTransfer(String transferId, int timeoutMs) async {
    final completer = Completer<bool>();
    var done = false;
    Timer? timer;

    void finish(bool value) {
      if (done) return;
      done = true;
      timer?.cancel();
      try {
        _wallet.removeListener(SparkWalletEvent.transferClaimed, _fallbackHandler);
      } catch (_) {
        // Ignore
      }
      completer.complete(value);
    }

    timer = Timer(Duration(milliseconds: timeoutMs), () => finish(false));

    void handler(String claimedId, BigInt balance) {
      if (claimedId == transferId) {
        finish(true);
      }
    }

    // The wallet's background gRPC stream auto-claims transfers.
    // We just listen for the event.
    try {
      // Using a try-catch dynamic invocation to map `typeof w.on === "function"`
      _wallet.onTransferClaimed(handler);
    } catch (_) {
      // No event support, fall back to passive polling
      timer.cancel();
      pollForTransferCompletion(transferId, timeoutMs).then((result) {
        if (!done) {
          done = true;
          completer.complete(result);
        }
      });
    }

    final claimed = await completer.future;

    if (claimed) {
      try {
        final leaves = await _wallet.getLeaves(true);
        _wallet.leafManager.addLeaves(leaves);
      } catch (_) {
        // Ignore if updating leaves fails
      }
    }

    return claimed;
  }

  /// Get Lightning fee estimate for an invoice
  Future<int> getLightningFeeEstimate(String invoice) async {
    try {
      final feeEstimate = await _wallet.getLightningSendFeeEstimate(
        encodedInvoice: invoice,
      );

      // The fee estimate might be returned as a number or an object
      if (feeEstimate is num) {
        return feeEstimate.toInt();
      }
      
      final dynamic feeObj = feeEstimate;
      if (feeObj?.fee != null || feeObj?.feeEstimate != null) {
        final val = feeObj.fee ?? feeObj.feeEstimate;
        return num.parse(val.toString()).toInt();
      }

      // Fallback to invoice amount-based estimate
      final invoiceAmount = await decodeInvoiceAmount(invoice);
      return math.max(5, (invoiceAmount * 0.0017).ceil());
    } catch (_) {
      // Fallback to invoice amount-based estimate
      final invoiceAmount = await decodeInvoiceAmount(invoice);
      return math.max(5, (invoiceAmount * 0.0017).ceil());
    }
  }

  /// Decode the amount from a Lightning invoice (in sats)
  /// Uses bolt11_decoder for reliable parsing.
  Future<int> decodeInvoiceAmount(String invoice) async {
    try {
      final Bolt11PaymentRequest decoded = Bolt11PaymentRequest(invoice);
      
      // 1_0000_0000_000
      // To_Check
      // The library returns amount in millisatoshis as a string
      final amountMSats = BigInt.parse(decoded.amount.toString());
      return (amountMSats ~/ BigInt.from(1000)).toInt();
    } catch (_) {
      // Fallback: if library fails, return 0 (treated as zero-amount invoice)
      return 0;
    }
  }

  /// Clean up wallet connections
  Future<void> cleanup() async {
    await _wallet.cleanupConnections();
  }

  // Config and Policy Enforcement Helpers

  Future<void> ensureAmmOperationAllowed(String requiredFeature) async {
    await ensurePingOk();
    final featureMap = await getFeatureStatusMap();

    if (featureMap['master_kill_switch'] == true) {
      throw Exception('Service is temporarily disabled by master kill switch');
    }

    if (featureMap[requiredFeature] != true) {
      throw Exception("Operation not allowed: feature '$requiredFeature' is disabled");
    }
  }

  Future<void> ensurePingOk() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (_pingCache != null && _pingCache!.expiryMs > now) {
      if (!_pingCache!.ok) {
        throw Exception('Settlement service unavailable. Only read (GET) operations are allowed right now.');
      }
      return;
    }
    
    final pingResult = await _typedApi.ping();
    final ok = pingResult != null &&
      pingResult.status.toLowerCase() == 'ok';
        
    _pingCache = (ok: ok, expiryMs: now + _pingTtlMs);
    
    if (!ok) {
      throw Exception('Settlement service unavailable. Only read (GET) operations are allowed right now.');
    }
  }

  Future<Map<String, bool>> getFeatureStatusMap() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (_featureStatusCache != null && _featureStatusCache!.expiryMs > now) {
      final map = <String, bool>{};
      // Assuming FeatureStatusResponse acts as an Iterable
      for (final item in (_featureStatusCache!.data as Iterable)) {
        map[(item as dynamic).feature_name as String] = (item as dynamic).enabled == true;
      }
      return map;
    }

    final data = await _typedApi.getFeatureStatus();
    _featureStatusCache = (
      data: data,
      expiryMs: now + _featureStatusTtlMs,
    );
    
    final map = <String, bool>{};
    for (final item in (data as Iterable)) {
      map[(item as dynamic).feature_name as String] = (item as dynamic).enabled == true;
    }
    return map;
  }

  Future<Map<String, BigInt>> getEnabledMinAmountsMap() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (_minAmountsCache != null && _minAmountsCache!.expiryMs > now) {
      return _minAmountsCache!.map;
    }

    final config = await _typedApi.getMinAmounts();
    final map = <String, BigInt>{};
    
    // Assuming MinAmountsResponse acts as an Iterable
    for (final item in (config as Iterable)) {
      final dynamicItem = item as dynamic;
      if (dynamicItem.enabled == true) {
        if (dynamicItem.min_amount == null) {
          continue;
        }
        final key = (dynamicItem.asset_identifier as String).toLowerCase();
        final value = safeBigInt(dynamicItem.min_amount);
        map[key] = value;
      }
    }
    
    _minAmountsCache = (
      map: map,
      expiryMs: now + _minAmountsTtlMs,
    );
    
    return map;
  }

  String _getHexAddress(String addr) {
    return _toHexTokenIdentifier(addr).toLowerCase();
  }

  Future<void> assertSwapMeetsMinAmounts({
    required String assetInAddress,
    required String assetOutAddress,
    required Object amountIn, // String, BigInt, or num
    required Object minAmountOut, // String, BigInt, or num
  }) async {
    final minMap = await getEnabledMinAmountsMap();
    if (minMap.isEmpty) {
      return;
    }

    final inHex = _getHexAddress(assetInAddress);
    final outHex = _getHexAddress(assetOutAddress);
    final minIn = minMap[inHex];
    final minOut = minMap[outHex];

    final parsedAmountIn = BigInt.parse(amountIn.toString());
    final parsedMinAmountOut = BigInt.parse(minAmountOut.toString());

    if (minIn != null && minOut != null) {
      if (parsedAmountIn < minIn) {
        throw Exception('Minimum amount not met for input asset. Required $minIn, provided $parsedAmountIn');
      }
      return;
    }

    if (minIn != null) {
      if (parsedAmountIn < minIn) {
        throw Exception('Minimum amount not met for input asset. Required $minIn, provided $parsedAmountIn');
      }
      return;
    }

    if (minOut != null) {
      final relaxed = minOut ~/ BigInt.two; // 50% relaxation for slippage
      if (parsedMinAmountOut < relaxed) {
        throw Exception('Minimum amount not met for output asset. Required at least $relaxed (50% relaxed), provided minAmountOut $parsedMinAmountOut');
      }
    }
  }

  Future<void> assertAddLiquidityMeetsMinAmounts({
    required String poolId,
    required Object assetAAmount, // String, BigInt, or num
    required Object assetBAmount, // String, BigInt, or num
  }) async {
    final minMap = await getEnabledMinAmountsMap();
    if (minMap.isEmpty) {
      return;
    }

    final pool = await getPool(poolId);
    final aHex = pool.assetAAddress.toLowerCase();
    final bHex = pool.assetBAddress.toLowerCase();
    final aMin = minMap[aHex];
    final bMin = minMap[bHex];

    if (aMin != null) {
      final aAmt = BigInt.parse(assetAAmount.toString());
      if (aAmt < aMin) {
        throw Exception('Minimum amount not met for Asset A. Required $aMin, provided $aAmt');
      }
    }

    if (bMin != null) {
      final bAmt = BigInt.parse(assetBAmount.toString());
      if (bAmt < bMin) {
        throw Exception('Minimum amount not met for Asset B. Required $bMin, provided $bAmt');
      }
    }
  }

  Future<void> assertRemoveLiquidityMeetsMinAmounts({
    required String poolId,
    required Object lpTokensToRemove, // String, BigInt, or num
  }) async {
    final minMap = await getEnabledMinAmountsMap();
    if (minMap.isEmpty) {
      return;
    }

    final simulation = await simulateRemoveLiquidity(
      SimulateRemoveLiquidityRequest(
        poolId: poolId,
        providerPublicKey: _publicKey,
        lpTokensToRemove: lpTokensToRemove.toString(),
      ),
    );

    final pool = await getPool(poolId);
    final aHex = pool.assetAAddress.toLowerCase();
    final bHex = pool.assetBAddress.toLowerCase();
    final aMin = minMap[aHex];
    final bMin = minMap[bHex];

    if (aMin != null) {
      final predictedAOut = safeBigInt(simulation.assetAAmount);
      final relaxedA = aMin ~/ BigInt.two; // apply 50% relaxation for outputs
      if (predictedAOut < relaxedA) {
        throw Exception(
          'Minimum amount not met for Asset A on withdrawal. Required at least $relaxedA (50% relaxed), predicted $predictedAOut'
        );
      }
    }

    if (bMin != null) {
      final predictedBOut = safeBigInt(simulation.assetBAmount);
      final relaxedB = bMin ~/ BigInt.two;
      if (predictedBOut < relaxedB) {
        throw Exception(
          'Minimum amount not met for Asset B on withdrawal. Required at least $relaxedB (50% relaxed), predicted $predictedBOut'
        );
      }
    }
  }

  Future<void> assertAllowedAssetBForPoolCreation(String assetBHex) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    AllowedAssetsResponse? allowed;
    
    if (_allowedAssetsCache != null && _allowedAssetsCache!.expiryMs > now) {
      allowed = _allowedAssetsCache!.data;
    } else {
      allowed = await _typedApi.getAllowedAssets();
      _allowedAssetsCache = (
        data: allowed,
        expiryMs: now + _allowedAssetsTtlMs,
      );
    }
    
    // Assuming AllowedAssetsResponse acts as a List/Iterable in TS based on .length and .some()
    final allowedIterable = allowed as Iterable?;
    
    if (allowedIterable == null || allowedIterable.isEmpty) {
      // Wildcard allowance
      return;
    }

    final isAllowed = allowedIterable.any((it) {
      final dynamicIt = it as dynamic;
      return dynamicIt.enabled == true &&
             (dynamicIt.asset_identifier as String).toLowerCase() == assetBHex.toLowerCase();
    });

    if (!isAllowed) {
      throw Exception('Asset B is not allowed for pool creation: $assetBHex');
    }
  }

  // V3 Concentrated Liquidity Operations

  /// Create a V3 concentrated liquidity pool
  ///
  /// Concentrated liquidity pools allow LPs to provide liquidity within specific
  /// price ranges (tick ranges) for higher capital efficiency.
  ///
  /// [assetAAddress] - Address of asset A (base asset)
  /// [assetBAddress] - Address of asset B (quote asset)
  /// [tickSpacing] - Tick spacing (common values: 10, 60, 200)
  /// [initialPrice] - Initial price of asset A in terms of asset B
  /// [lpFeeRateBps] - LP fee rate in basis points
  /// [hostFeeRateBps] - Host fee rate in basis points
  /// [hostNamespace] - Optional host namespace
  /// [poolOwnerPublicKey] - Optional pool owner (defaults to wallet pubkey)
  Future<CreateConcentratedPoolResponse> createConcentratedPool({
    required String assetAAddress,
    required String assetBAddress,
    required int tickSpacing,
    required String initialPrice,
    required int lpFeeRateBps,
    required int hostFeeRateBps,
    String? hostNamespace,
    String? poolOwnerPublicKey,
  }) async {
    await _ensureInitialized();

    await ensureAmmOperationAllowed('allow_pool_creation');
    await assertAllowedAssetBForPoolCreation(
      _toHexTokenIdentifier(assetBAddress)
    );

    final effectivePoolOwnerPublicKey = poolOwnerPublicKey ?? _publicKey;

    // Generate intent
    final nonce = generateNonce();
    final intentMessage = generateCreateConcentratedPoolIntentMessage(
      poolOwnerPublicKey: effectivePoolOwnerPublicKey,
      assetAAddress: _toHexTokenIdentifier(assetAAddress),
      assetBAddress: _toHexTokenIdentifier(assetBAddress),
      tickSpacing: tickSpacing,
      initialPrice: initialPrice,
      lpFeeRateBps: lpFeeRateBps.toString(),
      hostFeeRateBps: hostFeeRateBps.toString(),
      nonce: nonce,
    );

    // Sign intent
    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = CreateConcentratedPoolRequest(
      poolOwnerPublicKey: effectivePoolOwnerPublicKey,
      assetAAddress: _toHexTokenIdentifier(assetAAddress),
      assetBAddress: _toHexTokenIdentifier(assetBAddress),
      tickSpacing: tickSpacing,
      initialPrice: initialPrice,
      lpFeeRateBps: lpFeeRateBps.toString(),
      hostFeeRateBps: hostFeeRateBps.toString(),
      hostNamespace: hostNamespace,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    return _typedApi.createConcentratedPool(request);
  }

  /// Add liquidity to a V3 concentrated position
  ///
  /// Increases liquidity within a specific tick range. If the position doesn't exist,
  /// a new position is created.
  ///
  /// [poolId] - Pool ID (LP identity public key)
  /// [tickLower] - Lower tick of the position
  /// [tickUpper] - Upper tick of the position
  /// [amountADesired] - Desired amount of asset A to add
  /// [amountBDesired] - Desired amount of asset B to add
  /// [amountAMin] - Minimum amount of asset A (slippage protection)
  /// [amountBMin] - Minimum amount of asset B (slippage protection)
  /// [useFreeBalance] - If true, use free balance from pool instead of Spark transfers
  /// [retainExcessInBalance] - If true, retain any excess amounts in pool free balance instead of refunding via Spark
  /// [useAvailableBalance] - When true, checks against availableToSendBalance instead of total balance
  Future<IncreaseLiquidityResponse> increaseLiquidity({
    required String poolId,
    required int tickLower,
    required int tickUpper,
    required String amountADesired,
    required String amountBDesired,
    required String amountAMin,
    required String amountBMin,
    bool? useFreeBalance,
    bool? retainExcessInBalance,
    bool? useAvailableBalance,
  }) async {
    await _ensureInitialized();

    await ensureAmmOperationAllowed('allow_add_liquidity');

    // Get pool details to know asset addresses
    final pool = await getPool(poolId);

    // Transfer assets to pool (unless using free balance)
    final lpSparkAddress = encodeSparkAddressNew(SparkAddressDataNew(
      identityPublicKey: poolId,
      network: _sparkNetwork,
    ));

    var assetATransferId = '';
    var assetBTransferId = '';
    final transferIds = <String>[];

    // Transfer assets if not using free balance
    if (useFreeBalance != true) {
      if (BigInt.parse(amountADesired) > BigInt.zero) {
        assetATransferId = await transferAsset(
          receiverSparkAddress: lpSparkAddress,
          assetAddress: pool.assetAAddress,
          amount: amountADesired,
          errorPrefix: 'Insufficient balance for adding V3 liquidity (Asset A): ',
          useAvailableBalance: useAvailableBalance,
        );
        transferIds.add(assetATransferId);
      }

      if (BigInt.parse(amountBDesired) > BigInt.zero) {
        assetBTransferId = await transferAsset(
          receiverSparkAddress: lpSparkAddress,
          assetAddress: pool.assetBAddress,
          amount: amountBDesired,
          errorPrefix: 'Insufficient balance for adding V3 liquidity (Asset B): ',
          useAvailableBalance: useAvailableBalance,
        );
        transferIds.add(assetBTransferId);
      }
    }

    Future<IncreaseLiquidityResponse> executeIncrease() async {
      // Generate intent
      final nonce = generateNonce();
      final intentMessage = generateIncreaseLiquidityIntentMessage(
        userPublicKey: _publicKey,
        lpIdentityPublicKey: poolId,
        tickLower: tickLower,
        tickUpper: tickUpper,
        assetASparkTransferId: assetATransferId,
        assetBSparkTransferId: assetBTransferId,
        amountADesired: amountADesired,
        amountBDesired: amountBDesired,
        amountAMin: amountAMin,
        amountBMin: amountBMin,
        nonce: nonce,
      );

      // Sign intent
      final messageBytes = intentMessage;
      final messageHash = bssl.sha256.hash(messageBytes)!;
      
      final signature = await _wallet
          .config
          .signer
          .signMessageWithIdentityKey(messageHash, compact: true);

      final request = IncreaseLiquidityRequest(
        poolId: poolId,
        tickLower: tickLower,
        tickUpper: tickUpper,
        assetASparkTransferId: assetATransferId,
        assetBSparkTransferId: assetBTransferId,
        amountADesired: amountADesired,
        amountBDesired: amountBDesired,
        amountAMin: amountAMin,
        amountBMin: amountBMin,
        useFreeBalance: useFreeBalance,
        retainExcessInBalance: retainExcessInBalance,
        nonce: nonce,
        signature: getHexFromUint8Array(signature),
      );

      final response = await _typedApi.increaseLiquidity(request);

      if (response.accepted != true) {
        final errorMessage = response.error ?? 'Increase liquidity rejected by the AMM';
        
        final hasRefund = (response.amountARefund != null && response.amountARefund!.isNotEmpty) || 
                          (response.amountBRefund != null && response.amountBRefund!.isNotEmpty);
                          
        final refundInfo = hasRefund
            ? ' Refunds: Asset A: ${response.amountARefund ?? "0"}, Asset B: ${response.amountBRefund ?? "0"}'
            : '';

        throw FlashnetError(
          '$errorMessage.$refundInfo',
          FlashnetErrorOptions(            
            response: FlashnetErrorResponseBody(
              errorCode: hasRefund ? 'FSAG-4203' : 'UNKNOWN',
              errorCategory: hasRefund ? 'Business' : 'System',
              message: '$errorMessage.$refundInfo',
              requestId: response.requestId,
              timestamp: DateTime.now().toUtc().toIso8601String(),
              service: 'amm-gateway',
              severity: 'Error',
            ),
            httpStatus: 400,
            transferIds: hasRefund ? <String>[] : transferIds,
            lpIdentityPublicKey: poolId,
          ),
        );
      }

      return response;
    }

    // Execute with auto-clawback if we made transfers
    if (transferIds.isNotEmpty) {
      return executeWithAutoClawback(
        executeIncrease,
        transferIds,
        poolId,
      );
    }

    return executeIncrease();
  }

  /// Remove liquidity from a V3 concentrated position
  ///
  /// Decreases liquidity from a specific tick range position.
  ///
  /// [poolId] - Pool ID (LP identity public key)
  /// [tickLower] - Lower tick of the position
  /// [tickUpper] - Upper tick of the position
  /// [liquidityToRemove] - Amount of liquidity to remove (use "0" to remove all)
  /// [amountAMin] - Minimum amount of asset A to receive (slippage protection)
  /// [amountBMin] - Minimum amount of asset B to receive (slippage protection)
  /// [retainInBalance] - If true, retain withdrawn assets in pool free balance instead of sending via Spark
  Future<DecreaseLiquidityResponse> decreaseLiquidity({
    required String poolId,
    required int tickLower,
    required int tickUpper,
    required String liquidityToRemove,
    required String amountAMin,
    required String amountBMin,
    bool? retainInBalance,
  }) async {
    await _ensureInitialized();

    await ensureAmmOperationAllowed('allow_withdraw_liquidity');

    // Generate intent
    final nonce = generateNonce();
    final intentMessage = generateDecreaseLiquidityIntentMessage(
      userPublicKey: _publicKey,
      lpIdentityPublicKey: poolId,
      tickLower: tickLower,
      tickUpper: tickUpper,
      liquidityToRemove: liquidityToRemove,
      amountAMin: amountAMin,
      amountBMin: amountBMin,
      nonce: nonce,
    );

    // Sign intent
    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = DecreaseLiquidityRequest(
      poolId: poolId,
      tickLower: tickLower,
      tickUpper: tickUpper,
      liquidityToRemove: liquidityToRemove,
      amountAMin: amountAMin,
      amountBMin: amountBMin,
      retainInBalance: retainInBalance,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final response = await _typedApi.decreaseLiquidity(request);

    if (response.accepted != true) {
      final errorMessage = response.error ?? 'Decrease liquidity rejected by the AMM';
      throw Exception(errorMessage);
    }

    return response;
  }

  /// Collect accumulated fees from a V3 position
  ///
  /// Collects fees earned from trading activity without removing liquidity.
  ///
  /// [poolId] - Pool ID (LP identity public key)
  /// [tickLower] - Lower tick of the position
  /// [tickUpper] - Upper tick of the position
  /// [retainInBalance] - If true, retain collected fees in pool free balance instead of sending via Spark
  Future<CollectFeesResponse> collectFees({
    required String poolId,
    required int tickLower,
    required int tickUpper,
    bool? retainInBalance,
  }) async {
    await _ensureInitialized();

    await ensureAmmOperationAllowed('allow_withdraw_fees');

    // Generate intent
    final nonce = generateNonce();
    final intentMessage = generateCollectFeesIntentMessage(
      userPublicKey: _publicKey,
      lpIdentityPublicKey: poolId,
      tickLower: tickLower,
      tickUpper: tickUpper,
      nonce: nonce,
    );

    // Sign intent
    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = CollectFeesRequest(
      poolId: poolId,
      tickLower: tickLower,
      tickUpper: tickUpper,
      retainInBalance: retainInBalance,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final response = await _typedApi.collectFees(request);

    if (response.accepted != true) {
      final errorMessage = response.error ?? 'Collect fees rejected by the AMM';
      throw Exception(errorMessage);
    }

    return response;
  }

  /// Rebalance a V3 position to a new tick range
  ///
  /// Atomically moves liquidity from an old position to a new tick range.
  /// Optionally can add additional funds during rebalancing.
  ///
  /// [poolId] - Pool ID (LP identity public key)
  /// [oldTickLower] - Lower tick of the current position
  /// [oldTickUpper] - Upper tick of the current position
  /// [newTickLower] - Lower tick for the new position
  /// [newTickUpper] - Upper tick for the new position
  /// [liquidityToMove] - Amount of liquidity to move (use "0" to move all)
  /// [additionalAmountA] - Optional additional asset A to add
  /// [additionalAmountB] - Optional additional asset B to add
  /// [retainInBalance] - If true, retain any excess amounts in pool free balance instead of sending via Spark
  /// [useAvailableBalance] - When true, checks against availableToSendBalance instead of total balance
  Future<RebalancePositionResponse> rebalancePosition({
    required String poolId,
    required int oldTickLower,
    required int oldTickUpper,
    required int newTickLower,
    required int newTickUpper,
    required String liquidityToMove,
    String? additionalAmountA,
    String? additionalAmountB,
    bool? retainInBalance,
    bool? useAvailableBalance,
  }) async {
    await _ensureInitialized();

    await ensureAmmOperationAllowed('allow_add_liquidity');

    // Get pool details
    final pool = await getPool(poolId);

    // Transfer additional assets if provided
    String? assetATransferId;
    String? assetBTransferId;

    final lpSparkAddress = encodeSparkAddressNew(SparkAddressDataNew(
      identityPublicKey: poolId,
      network: _sparkNetwork,
    ));

    if (additionalAmountA != null && BigInt.parse(additionalAmountA) > BigInt.zero) {
      assetATransferId = await transferAsset(
        receiverSparkAddress: lpSparkAddress,
        assetAddress: pool.assetAAddress,
        amount: additionalAmountA,
        errorPrefix: 'Insufficient balance for rebalance (Asset A): ',
        useAvailableBalance: useAvailableBalance,
      );
    }

    if (additionalAmountB != null && BigInt.parse(additionalAmountB) > BigInt.zero) {
      assetBTransferId = await transferAsset(
        receiverSparkAddress: lpSparkAddress,
        assetAddress: pool.assetBAddress,
        amount: additionalAmountB,
        errorPrefix: 'Insufficient balance for rebalance (Asset B): ',
        useAvailableBalance: useAvailableBalance,
      );
    }

    // Collect transfer IDs for potential clawback
    final transferIds = <String>[];
    if (assetATransferId != null) {
      transferIds.add(assetATransferId);
    }
    if (assetBTransferId != null) {
      transferIds.add(assetBTransferId);
    }

    // Execute (with auto-clawback if we have transfers)
    Future<RebalancePositionResponse> executeRebalance() async {
      // Generate intent
      final nonce = generateNonce();
      final intentMessage = generateRebalancePositionIntentMessage(
        userPublicKey: _publicKey,
        lpIdentityPublicKey: poolId,
        oldTickLower: oldTickLower,
        oldTickUpper: oldTickUpper,
        newTickLower: newTickLower,
        newTickUpper: newTickUpper,
        liquidityToMove: liquidityToMove,
        assetASparkTransferId: assetATransferId,
        assetBSparkTransferId: assetBTransferId,
        additionalAmountA: additionalAmountA,
        additionalAmountB: additionalAmountB,
        nonce: nonce,
      );

      // Sign intent
      final messageBytes = intentMessage;
      final messageHash = bssl.sha256.hash(messageBytes)!;
      
      final signature = await _wallet
          .config
          .signer
          .signMessageWithIdentityKey(messageHash, compact: true);

      final request = RebalancePositionRequest(
        poolId: poolId,
        oldTickLower: oldTickLower,
        oldTickUpper: oldTickUpper,
        newTickLower: newTickLower,
        newTickUpper: newTickUpper,
        liquidityToMove: liquidityToMove,
        assetASparkTransferId: assetATransferId,
        assetBSparkTransferId: assetBTransferId,
        additionalAmountA: additionalAmountA,
        additionalAmountB: additionalAmountB,
        retainInBalance: retainInBalance,
        nonce: nonce,
        signature: getHexFromUint8Array(signature),
      );

      final response = await _typedApi.rebalancePosition(request);

      if (response.accepted != true) {
        final errorMessage = response.error ?? 'Rebalance position rejected by the AMM';

        throw FlashnetError(
          errorMessage,
          FlashnetErrorOptions(
            response: FlashnetErrorResponseBody(
              errorCode: 'UNKNOWN',
              errorCategory: 'System',
              message: errorMessage,
              requestId: response.requestId,
              timestamp: DateTime.now().toUtc().toIso8601String(),
              service: 'amm-gateway',
              severity: 'Error',
            ),
            httpStatus: 400,
            transferIds: transferIds,
            lpIdentityPublicKey: poolId,
          ),
        );
      }

      return response;
    }

    // Use auto-clawback if we made transfers
    if (transferIds.isNotEmpty) {
      return executeWithAutoClawback(
        executeRebalance,
        transferIds,
        poolId,
      );
    }

    return executeRebalance();
  }

  /// List V3 concentrated liquidity positions
  ///
  /// [query] Optional query parameters
  Future<ListConcentratedPositionsResponse> listConcentratedPositions([
    ListConcentratedPositionsQuery? query,
  ]) async {
    await _ensureInitialized();
    return _typedApi.listConcentratedPositions(query);
  }

  /// Get pool liquidity distribution for visualization
  ///
  /// Returns aggregated liquidity ranges for visualizing the liquidity distribution.
  ///
  /// [poolId] - Pool ID (LP identity public key)
  Future<PoolLiquidityResponse> getPoolLiquidity(String poolId) async {
    await _ensureInitialized();
    return _typedApi.getPoolLiquidity(poolId);
  }

  /// Get pool ticks for simulation
  ///
  /// Returns all initialized ticks with their liquidity deltas for swap simulation.
  ///
  /// [poolId] - Pool ID (LP identity public key)
  Future<PoolTicksResponse> getPoolTicks(String poolId) async {
    await _ensureInitialized();
    return _typedApi.getPoolTicks(poolId);
  }

  // V3 Free Balance Methods

  /// Get user's free balance for a specific V3 pool
  ///
  /// Returns the user's current free balance in the pool, which can be used for
  /// liquidity operations without needing to transfer from the wallet.
  ///
  /// [poolId] - Pool ID (LP identity public key)
  Future<GetBalanceResponse> getConcentratedBalance(String poolId) async {
    await _ensureInitialized();
    return _typedApi.getConcentratedBalance(poolId);
  }

  /// Get user's free balances across all V3 pools
  ///
  /// Returns all free balances for the authenticated user across all V3 pools.
  Future<GetBalancesResponse> getConcentratedBalances() async {
    await _ensureInitialized();
    return _typedApi.getConcentratedBalances();
  }

  /// Withdraw free balance from a V3 pool to user's Spark wallet
  ///
  /// Withdraws accumulated free balance from a pool. Use "0" to skip an asset,
  /// or "max" to withdraw all available balance of that asset.
  ///
  /// [poolId] - Pool ID (LP identity public key)
  /// [amountA] - Amount of asset A to withdraw ("0" to skip, "max" to withdraw all)
  /// [amountB] - Amount of asset B to withdraw ("0" to skip, "max" to withdraw all)
  Future<WithdrawBalanceResponse> withdrawConcentratedBalance({
    required String poolId,
    required String amountA,
    required String amountB,
  }) async {
    await _ensureInitialized();

    // Generate intent
    final nonce = generateNonce();
    final intentMessage = generateWithdrawBalanceIntentMessage(
      userPublicKey: _publicKey,
      lpIdentityPublicKey: poolId,
      amountA: amountA,
      amountB: amountB,
      nonce: nonce,
    );

    // Sign intent
    final messageBytes = intentMessage;
    final messageHash = bssl.sha256.hash(messageBytes)!;
    
    final signature = await _wallet
        .config
        .signer
        .signMessageWithIdentityKey(messageHash, compact: true);

    final request = WithdrawBalanceRequest(
      poolId: poolId,
      amountA: amountA,
      amountB: amountB,
      nonce: nonce,
      signature: getHexFromUint8Array(signature),
    );

    final response = await _typedApi.withdrawConcentratedBalance(request);

    if (response.accepted != true) {
      final errorMessage = response.error ?? 'Withdraw balance rejected by the AMM';
      throw Exception(errorMessage);
    }

    return response;
  }

  /// Deposits assets to your free balance in a V3 concentrated liquidity pool.
  ///
  /// Free balance can be used for adding liquidity to positions without requiring
  /// additional Spark transfers. The SDK handles the Spark transfers internally.
  ///
  /// [poolId] - The pool identifier (LP identity public key)
  /// [amountA] - Amount of asset A to deposit (use "0" to skip)
  /// [amountB] - Amount of asset B to deposit (use "0" to skip)
  /// [useAvailableBalance] - When true, checks against availableToSendBalance instead of total balance
  Future<DepositBalanceResponse> depositConcentratedBalance({
    required String poolId,
    required String amountA,
    required String amountB,
    bool? useAvailableBalance,
  }) async {
    await _ensureInitialized();

    // Get pool details to know asset addresses
    final pool = await getPool(poolId);

    final lpSparkAddress = encodeSparkAddressNew(SparkAddressDataNew(
      identityPublicKey: poolId,
      network: _sparkNetwork,
    ));

    var assetATransferId = '';
    var assetBTransferId = '';
    final transferIds = <String>[];

    // Transfer assets to pool
    if (BigInt.parse(amountA) > BigInt.zero) {
      assetATransferId = await transferAsset(
        receiverSparkAddress: lpSparkAddress,
        assetAddress: pool.assetAAddress,
        amount: amountA,
        errorPrefix: 'Insufficient balance for depositing to V3 pool (Asset A): ',
        useAvailableBalance: useAvailableBalance,
      );
      transferIds.add(assetATransferId);
    }

    if (BigInt.parse(amountB) > BigInt.zero) {
      assetBTransferId = await transferAsset(
        receiverSparkAddress: lpSparkAddress,
        assetAddress: pool.assetBAddress,
        amount: amountB,
        errorPrefix: 'Insufficient balance for depositing to V3 pool (Asset B): ',
        useAvailableBalance: useAvailableBalance,
      );
      transferIds.add(assetBTransferId);
    }

    Future<DepositBalanceResponse> executeDeposit() async {
      // Generate intent
      final nonce = generateNonce();
      final intentMessage = generateDepositBalanceIntentMessage(
        userPublicKey: _publicKey,
        lpIdentityPublicKey: poolId,
        assetASparkTransferId: assetATransferId,
        assetBSparkTransferId: assetBTransferId,
        amountA: amountA,
        amountB: amountB,
        nonce: nonce,
      );

      // Sign intent
      final messageBytes = intentMessage;
      final messageHash = bssl.sha256.hash(messageBytes)!;
      
      final signature = await _wallet
          .config
          .signer
          .signMessageWithIdentityKey(messageHash, compact: true);

      final request = DepositBalanceRequest(
        poolId: poolId,
        amountA: amountA,
        amountB: amountB,
        assetASparkTransferId: assetATransferId,
        assetBSparkTransferId: assetBTransferId,
        nonce: nonce,
        signature: getHexFromUint8Array(signature),
      );

      final response = await _typedApi.depositConcentratedBalance(request);

      if (response.accepted != true) {
        final errorMessage = response.error ?? 'Deposit balance rejected by the AMM';
        throw FlashnetError(
          errorMessage,
          FlashnetErrorOptions(
            response: FlashnetErrorResponseBody(
              errorCode: 'UNKNOWN',
              errorCategory: 'System',
              message: errorMessage,
              requestId: '',
              timestamp: DateTime.now().toUtc().toIso8601String(),
              service: 'amm-gateway',
              severity: 'Error',
            ),
            httpStatus: 400,
            transferIds: transferIds,
            lpIdentityPublicKey: poolId,
          ),
        );
      }

      return response;
    }

    // Execute with auto-clawback if we made transfers
    if (transferIds.isNotEmpty) {
      return executeWithAutoClawback(
        executeDeposit,
        transferIds,
        poolId,
      );
    }

    return executeDeposit();
  }
}


/// Private implementation of ClawbackMonitorHandle
class _ClawbackMonitorHandleImpl implements ClawbackMonitorHandle {
  final FlashnetClient client;
  final int intervalMs;
  final int batchSize;
  final int batchDelayMs;
  final int maxTransfersPerPoll;
  
  final void Function(ClawbackAttemptResult)? onClawbackSuccess;
  final void Function(String, Object)? onClawbackError;
  final void Function(ClawbackPollResult)? onPollComplete;
  final void Function(Object)? onPollError;

  bool _isRunning = true;
  Timer? _timer;
  Future<void>? _currentPollFuture;

  _ClawbackMonitorHandleImpl({
    required this.client,
    required this.intervalMs,
    required this.batchSize,
    required this.batchDelayMs,
    required this.maxTransfersPerPoll,
    this.onClawbackSuccess,
    this.onClawbackError,
    this.onPollComplete,
    this.onPollError,
  }) {
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    if (!_isRunning) return;
    _timer = Timer(Duration(milliseconds: intervalMs), _executePollCycle);
  }

  Future<void> _executePollCycle() async {
    if (!_isRunning) return;
    
    _currentPollFuture = _doPoll().then((result) {
      onPollComplete?.call(result);
    });

    await _currentPollFuture;
    _currentPollFuture = null;
    
    _scheduleNextPoll();
  }

  Future<ClawbackPollResult> _doPoll() async {
    var transfersFound = 0;
    var clawbacksAttempted = 0;
    var clawbacksSucceeded = 0;
    var clawbacksFailed = 0;
    final results = <ClawbackAttemptResult>[];

    try {
      // Fetch clawbackable transfers
      final response = await client.listClawbackableTransfers(
        ListClawbackableTransfersQuery(limit: maxTransfersPerPoll),
      );

      transfersFound = response.transfers.length;

      if (response.transfers.isEmpty) {
        return ClawbackPollResult(
          transfersFound: transfersFound,
          clawbacksAttempted: clawbacksAttempted,
          clawbacksSucceeded: clawbacksSucceeded,
          clawbacksFailed: clawbacksFailed,
          results: results,
        );
      }

      // Process in batches to respect rate limits
      for (var i = 0; i < response.transfers.length; i += batchSize) {
        if (!_isRunning) break;

        final end = (i + batchSize < response.transfers.length) 
            ? i + batchSize 
            : response.transfers.length;
        final batch = response.transfers.sublist(i, end);

        // Process batch concurrently
        final batchResults = await Future.wait(batch.map((transfer) async {
          clawbacksAttempted++;
          try {
            final clawbackResponse = await client.clawback(
              sparkTransferId: transfer.id,
              lpIdentityPublicKey: transfer.lpIdentityPublicKey,
            );

            final attemptResult = ClawbackAttemptResult(
              transferId: transfer.id,
              success: true,
              response: clawbackResponse.toJson(),
            );

            clawbacksSucceeded++;
            onClawbackSuccess?.call(attemptResult);
            return attemptResult;
          } catch (err) {
            final attemptResult = ClawbackAttemptResult(
              transferId: transfer.id,
              success: false,
              error: err is Exception ? err.toString() : err.toString(),
            );

            clawbacksFailed++;
            onClawbackError?.call(transfer.id, err);
            return attemptResult;
          }
        }));

        results.addAll(batchResults);

        // Wait between batches if there are more to process
        if (end < response.transfers.length && _isRunning) {
          await Future.delayed(Duration(milliseconds: batchDelayMs));
        }
      }
    } catch (err) {
      onPollError?.call(err);
    }

    return ClawbackPollResult(
      transfersFound: transfersFound,
      clawbacksAttempted: clawbacksAttempted,
      clawbacksSucceeded: clawbacksSucceeded,
      clawbacksFailed: clawbacksFailed,
      results: results,
    );
  }

  @override
  bool isRunning() => _isRunning;

  @override
  Future<void> stop() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    if (_currentPollFuture != null) {
      await _currentPollFuture;
    }
  }

  @override
  Future<ClawbackPollResult> pollNow() async {
    if (!_isRunning) {
      throw Exception('Cannot trigger poll: Clawback monitor is stopped');
    }
    
    // Cancel the pending scheduled poll to avoid overlap
    _timer?.cancel();
    
    // Wait for any currently executing poll to finish
    if (_currentPollFuture != null) {
      await _currentPollFuture;
    }

    // Execute immediately
    final result = await _doPoll();
    onPollComplete?.call(result);
    
    // Reschedule the next automated poll
    _scheduleNextPoll();
    
    return result;
  }
}