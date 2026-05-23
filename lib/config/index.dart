import '../types/index.dart';

class NetworkConfig {
  final String ammGatewayUrl;
  final String mempoolApiUrl;
  final String explorerUrl;
  final String? sparkScanUrl;

  NetworkConfig({
    required this.ammGatewayUrl,
    required this.mempoolApiUrl,
    required this.explorerUrl,
    this.sparkScanUrl,
  });
}

/// Client network configurations mapped by environment
/// Each environment can be combined with any Spark network type
final Map<String, ClientNetworkConfig> CLIENT_NETWORK_CONFIGS = {
  'mainnet': ClientNetworkConfig(
    ammGatewayUrl: "https://api.flashnet.xyz",
    mempoolApiUrl: "https://mempool.space",
    explorerUrl: "https://mempool.space",
    sparkScanUrl: "https://api.sparkscan.io",
  ),
  'regtest': ClientNetworkConfig(
    ammGatewayUrl: "https://api.amm.makebitcoingreatagain.dev",
    mempoolApiUrl: "https://mempool.regtest.flashnet.xyz",
    explorerUrl: "https://mempool.regtest.flashnet.xyz",
    sparkScanUrl: "https://api.sparkscan.io",
  ),
  'testnet': ClientNetworkConfig(
    ammGatewayUrl: "https://api.amm.makebitcoingreatagain.dev",
    mempoolApiUrl: "https://mempool.regtest.flashnet.xyz",
    explorerUrl: "https://mempool.regtest.flashnet.xyz",
    sparkScanUrl: "https://api.sparkscan.io",
  ),
  'signet': ClientNetworkConfig(
    ammGatewayUrl: "https://api.amm.makebitcoingreatagain.dev",
    mempoolApiUrl: "https://mempool.regtest.flashnet.xyz",
    explorerUrl: "https://mempool.regtest.flashnet.xyz",
    sparkScanUrl: "https://api.sparkscan.io",
  ),
  'local': ClientNetworkConfig(
    ammGatewayUrl: "http://localhost:8090",
    mempoolApiUrl: "https://mempool.regtest.flashnet.xyz",
    explorerUrl: "https://mempool.regtest.flashnet.xyz",
    sparkScanUrl: "https://api.sparkscan.io",
  ),
};

/// Get client network configuration by environment
/// [environment] The client environment
/// Returns Client network configuration
ClientNetworkConfig getClientNetworkConfig(ClientEnvironment environment) {
  final config = CLIENT_NETWORK_CONFIGS[environment];
  if (config == null) {
    throw Exception('Unknown client environment: $environment');
  }
  return config;
}

/// Maps client environment to default Spark network type
/// This is used for backward compatibility and sensible defaults
/// [environment] The client environment
/// Returns Default Spark network type for the environment
SparkNetworkType getDefaultSparkNetworkForEnvironment(ClientEnvironment environment) {
  switch (environment) {
    case 'mainnet':
      return 'MAINNET' as SparkNetworkType;
    case 'regtest':
    case 'local':
      return 'REGTEST' as SparkNetworkType;
    case 'testnet':
      return 'TESTNET' as SparkNetworkType;
    case 'signet':
      return 'SIGNET' as SparkNetworkType;
    default:
      throw Exception('Unknown client environment: $environment');
  }
}

/// Validates a custom client network configuration
/// [config] Custom client network configuration
/// Returns Validation result with error details if invalid
({bool valid, List<String> errors}) validateClientNetworkConfig(ClientNetworkConfig config) {
  final errors = <String>[];

  if (config.ammGatewayUrl.isEmpty) {
    errors.add("ammGatewayUrl is required and must be a string");
  }

  if (config.mempoolApiUrl.isEmpty) {
    errors.add("mempoolApiUrl is required and must be a string");
  }

  if (config.explorerUrl.isEmpty) {
    errors.add("explorerUrl is required and must be a string");
  }

  // Validate URL formats
  final urlFields = [
    ('ammGatewayUrl', config.ammGatewayUrl),
    ('mempoolApiUrl', config.mempoolApiUrl),
    ('explorerUrl', config.explorerUrl),
  ];

  if (config.sparkScanUrl != null) {
    urlFields.add(('sparkScanUrl', config.sparkScanUrl!));
  }

  for (final field in urlFields) {
    if (field.$2.isNotEmpty) {
      final uri = Uri.tryParse(field.$2);
      if (uri == null || !uri.hasAbsolutePath) {
        errors.add("${field.$1} must be a valid URL");
      }
    }
  }

  return (
    valid: errors.isEmpty,
    errors: errors,
  );
}

/// Resolves client configuration from either environment name or custom config
/// [clientConfig] Either a ClientEnvironment string or ClientNetworkConfig object
/// Returns Resolved ClientNetworkConfig
ClientNetworkConfig resolveClientNetworkConfig(Object clientConfig) {
  // Check if it's a string (environment name)
  if (clientConfig is String) {
    return getClientNetworkConfig(clientConfig as ClientEnvironment);
  }

  // It's a custom configuration object - validate it
  if (clientConfig is ClientNetworkConfig) {
    final validation = validateClientNetworkConfig(clientConfig);
    if (!validation.valid) {
      throw Exception(
        'Invalid client network configuration: ${validation.errors.join(", ")}'
      );
    }
    return clientConfig;
  }

  throw Exception('Invalid client configuration type');
}

/// Determines the client environment from a configuration
/// [clientConfig] Either a ClientEnvironment string or ClientNetworkConfig object
/// Returns ClientEnvironment name or 'custom' for custom configs
String getClientEnvironmentName(Object clientConfig) {
  if (clientConfig is String) {
    return clientConfig;
  }

  if (clientConfig is ClientNetworkConfig) {
    // Try to match against known environments
    for (final entry in CLIENT_NETWORK_CONFIGS.entries) {
      final envName = entry.key;
      final envConfig = entry.value;

      if (envConfig.ammGatewayUrl == clientConfig.ammGatewayUrl &&
          envConfig.mempoolApiUrl == clientConfig.mempoolApiUrl &&
          envConfig.explorerUrl == clientConfig.explorerUrl &&
          envConfig.sparkScanUrl == clientConfig.sparkScanUrl) {
        return envName;
      }
    }
  }

  return "custom";
}

// BACKWARD COMPATIBILITY LAYER

/// @deprecated Use CLIENT_NETWORK_CONFIGS with getClientNetworkConfig() instead
/// This will be removed in v3.0.0
@Deprecated('Use CLIENT_NETWORK_CONFIGS with getClientNetworkConfig() instead')
final Map<String, NetworkConfig> NETWORK_CONFIGS = {
  'MAINNET': NetworkConfig(
    ammGatewayUrl: "https://api.flashnet.xyz",
    mempoolApiUrl: "https://mempool.space",
    explorerUrl: "https://mempool.space",
    sparkScanUrl: "https://api.sparkscan.io",
  ),
  'REGTEST': NetworkConfig(
    ammGatewayUrl: "https://api.amm.makebitcoingreatagain.dev",
    mempoolApiUrl: "https://mempool.regtest.flashnet.xyz",
    explorerUrl: "https://mempool.regtest.flashnet.xyz",
    sparkScanUrl: "https://api.sparkscan.io",
  ),
  'TESTNET': NetworkConfig(
    ammGatewayUrl: "https://api.amm.makebitcoingreatagain.dev",
    mempoolApiUrl: "https://mempool.regtest.flashnet.xyz",
    explorerUrl: "https://mempool.regtest.flashnet.xyz",
    sparkScanUrl: "https://api.sparkscan.io",
  ),
  'SIGNET': NetworkConfig(
    ammGatewayUrl: "https://api.amm.makebitcoingreatagain.dev",
    mempoolApiUrl: "https://mempool.regtest.flashnet.xyz",
    explorerUrl: "https://mempool.regtest.flashnet.xyz",
    sparkScanUrl: "https://api.sparkscan.io",
  ),
  'LOCAL': NetworkConfig(
    ammGatewayUrl: "http://localhost:8090",
    mempoolApiUrl: "https://mempool.regtest.flashnet.xyz",
    explorerUrl: "https://mempool.regtest.flashnet.xyz",
    sparkScanUrl: "https://api.sparkscan.io",
  ),
};

/// @deprecated Use getClientNetworkConfig() instead
/// This will be removed in v3.0.0
@Deprecated('Use getClientNetworkConfig() instead')
NetworkConfig getNetworkConfig(NetworkType network) {
  final config = NETWORK_CONFIGS[network];
  if (config == null) {
     throw Exception('Unknown network type: $network');
  }
  return config;
}

const String BTC_ASSET_PUBKEY = "020202020202020202020202020202020202020202020202020202020202020202";
const int BTC_DECIMALS = 8;
const int DEFAULT_SLIPPAGE_BPS = 500; // 5%
const String DEFAULT_HOST_NAMESPACE = "flashnet_pools";