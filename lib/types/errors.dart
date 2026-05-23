/// Flashnet AMM Gateway Error System
///
/// Error code format: FSAG-XXXX
/// Categories by range:
///   - 1000–1999: Validation
///   - 2000–2999: Security/Auth
///   - 3000–3999: Infrastructure/External
///   - 4000–4999: Business/AMM Logic
///   - 5000–5999: System/Service
/// 
/// Result of an automatic clawback attempt for a single transfer
class ClawbackAttemptResult {
  /// The transfer ID that was clawed back
  final String transferId;
  
  /// Whether the clawback was successful
  final bool success;
  
  /// The clawback response if successful
  final Map<String, dynamic>? response;
  
  /// Error message if clawback failed
  final String? error;

  ClawbackAttemptResult({
    required this.transferId,
    required this.success,
    this.response,
    this.error,
  });

  factory ClawbackAttemptResult.fromJson(Map<String, dynamic> json) => ClawbackAttemptResult(
    transferId: json['transferId'],
    success: json['success'],
    response: json['response'],
    error: json['error'],
  );

  Map<String, dynamic> toJson() => {
    'transferId': transferId,
    'success': success,
    if (response != null) 'response': response,
    if (error != null) 'error': error,
  };
}

/// Summary of auto-clawback results after an operation failure
class AutoClawbackSummary {
  final bool attempted;
  final int totalTransfers;
  final int successCount;
  final int failureCount;
  final List<ClawbackAttemptResult> results;
  final List<String> recoveredTransferIds;
  final List<String> unrecoveredTransferIds;

  AutoClawbackSummary({
    required this.attempted,
    required this.totalTransfers,
    required this.successCount,
    required this.failureCount,
    required this.results,
    required this.recoveredTransferIds,
    required this.unrecoveredTransferIds,
  });

  factory AutoClawbackSummary.fromJson(Map<String, dynamic> json) => AutoClawbackSummary(
    attempted: json['attempted'],
    totalTransfers: json['totalTransfers'],
    successCount: json['successCount'],
    failureCount: json['failureCount'],
    results: (json['results'] as List).map((r) => ClawbackAttemptResult.fromJson(r)).toList(),
    recoveredTransferIds: List<String>.from(json['recoveredTransferIds']),
    unrecoveredTransferIds: List<String>.from(json['unrecoveredTransferIds']),
  );

  Map<String, dynamic> toJson() => {
    'attempted': attempted,
    'totalTransfers': totalTransfers,
    'successCount': successCount,
    'failureCount': failureCount,
    'results': results.map((r) => r.toJson()).toList(),
    'recoveredTransferIds': recoveredTransferIds,
    'unrecoveredTransferIds': unrecoveredTransferIds,
  };
}

/// Namespace for Flashnet AMM Gateway error codes
class FlashnetErrorCodes {
  // Validation (1000-1999)
  static const String validationFailed = "FSAG-1000";
  static const String requiredFieldMissing = "FSAG-1001";
  static const String invalidFieldFormat = "FSAG-1002";
  static const String valueOutOfRange = "FSAG-1003";
  static const String duplicateValue = "FSAG-1004";

  // Security/Auth (2000-2999)
  static const String signatureVerificationFailed = "FSAG-2001";
  static const String tokenIdentityMismatch = "FSAG-2002";
  static const String authTokenMissing = "FSAG-2003";
  static const String authTokenInvalid = "FSAG-2004";
  static const String nonceVerificationFailed = "FSAG-2005";
  static const String publicKeyInvalid = "FSAG-2101";

  // Infrastructure/External (3000-3999)
  static const String internalError3001 = "FSAG-3001";
  static const String internalError3002 = "FSAG-3002";
  // ... maps to "Internal server error"

  // Business/AMM Logic (4000-4999)
  static const String poolNotFound = "FSAG-4001";
  static const String hostNotFound = "FSAG-4002";
  static const String authSessionNotFound = "FSAG-4101";
  static const String incorrectAuthFlow = "FSAG-4102";
  static const String insufficientLiquidity = "FSAG-4201";
  static const String slippageExceeded = "FSAG-4202";
  static const String operationNotAllowed = "FSAG-4203";
  static const String insufficientLpBalance = "FSAG-4204";
  static const String invalidFeeConfig = "FSAG-4301";
  static const String transferIdUsed = "FSAG-4401";

  // System/Service (5000-5999)
  static const String idGenerationFailed = "FSAG-5001";
  static const String featureNotImplemented = "FSAG-5002";
  static const String inconsistentState = "FSAG-5003";
  static const String invalidConfigParam = "FSAG-5004";
  static const String unexpectedPanic = "FSAG-5100";
}

enum FlashnetErrorCategory {
  validation,
  security,
  infrastructure,
  business,
  system
}

enum ErrorRecoveryStrategy {
  /// Must clawback any transfer IDs sent
  clawbackRequired,
  /// Should attempt clawback where state is uncertain
  clawbackRecommended,
  /// Funds return automatically via refund
  autoRefund,
  /// No funds at risk
  none
}

/// Metadata for error codes to guide client behavior
class ErrorCodeMetadata {
  final int httpStatus;
  final FlashnetErrorCategory category;
  final ErrorRecoveryStrategy recovery;
  final String summary;
  final String userMessage;
  final String actionHint;
  final bool isRetryable;

  ErrorCodeMetadata({
    required this.httpStatus,
    required this.category,
    required this.recovery,
    required this.summary,
    required this.userMessage,
    required this.actionHint,
    required this.isRetryable,
  });
}

/// Comprehensive metadata for all FSAG error codes
final Map<String, ErrorCodeMetadata> ERROR_CODE_METADATA = {
  // Validation Errors (1000-1999) - Clawback Required
  "FSAG-1000": ErrorCodeMetadata(
    httpStatus: 400,
    category: FlashnetErrorCategory.validation,
    recovery: ErrorRecoveryStrategy.clawbackRequired,
    summary: "Validation failed",
    userMessage: "The request failed validation checks.",
    actionHint: "Check your input parameters and try again. If you sent funds, initiate a clawback.",
    isRetryable: false,
  ),
  "FSAG-1001": ErrorCodeMetadata(
    httpStatus: 400,
    category: FlashnetErrorCategory.validation,
    recovery: ErrorRecoveryStrategy.clawbackRequired,
    summary: "Required field missing",
    userMessage: "A required field is missing from your request.",
    actionHint: "Ensure all required fields are provided. If you sent funds, initiate a clawback.",
    isRetryable: false,
  ),
  "FSAG-1002": ErrorCodeMetadata(
    httpStatus: 400,
    category: FlashnetErrorCategory.validation,
    recovery: ErrorRecoveryStrategy.clawbackRequired,
    summary: "Invalid field format",
    userMessage: "One or more fields have an invalid format.",
    actionHint: "Check the format of your inputs (addresses, amounts, etc.). If you sent funds, initiate a clawback.",
    isRetryable: false,
  ),
  "FSAG-1003": ErrorCodeMetadata(
    httpStatus: 400,
    category: FlashnetErrorCategory.validation,
    recovery: ErrorRecoveryStrategy.clawbackRequired,
    summary: "Value out of range",
    userMessage: "A value is outside the acceptable range.",
    actionHint: "Adjust the value to be within valid bounds. If you sent funds, initiate a clawback.",
    isRetryable: false,
  ),
  "FSAG-1004": ErrorCodeMetadata(
    httpStatus: 409,
    category: FlashnetErrorCategory.validation,
    recovery: ErrorRecoveryStrategy.clawbackRequired,
    summary: "Duplicate value",
    userMessage: "This value already exists and must be unique.",
    actionHint: "Use a different value or check if the operation was already completed.",
    isRetryable: false,
  ),

  // Security/Auth Errors (2000-2999) - Clawback Required
  "FSAG-2001": ErrorCodeMetadata(
    httpStatus: 403,
    category: FlashnetErrorCategory.security,
    recovery: ErrorRecoveryStrategy.clawbackRequired,
    summary: "Signature verification failed",
    userMessage: "Your request signature could not be verified.",
    actionHint: "Ensure you're signing with the correct key. If you sent funds, initiate a clawback.",
    isRetryable: false,
  ),
  "FSAG-2002": ErrorCodeMetadata(
    httpStatus: 403,
    category: FlashnetErrorCategory.security,
    recovery: ErrorRecoveryStrategy.clawbackRequired,
    summary: "Token identity mismatch",
    userMessage: "The token identity doesn't match the expected public key.",
    actionHint: "Ensure you're using the correct wallet/identity. If you sent funds, initiate a clawback.",
    isRetryable: false,
  ),
  "FSAG-2003": ErrorCodeMetadata(
    httpStatus: 401,
    category: FlashnetErrorCategory.security,
    recovery: ErrorRecoveryStrategy.none,
    summary: "Authorization token missing",
    userMessage: "Authentication is required for this operation.",
    actionHint: "Authenticate first by calling the auth flow.",
    isRetryable: true,
  ),
  "FSAG-2004": ErrorCodeMetadata(
    httpStatus: 401,
    category: FlashnetErrorCategory.security,
    recovery: ErrorRecoveryStrategy.none,
    summary: "Authorization token invalid or expired",
    userMessage: "Your session has expired or the token is invalid.",
    actionHint: "Re-authenticate to get a new access token.",
    isRetryable: true,
  ),
  "FSAG-2005": ErrorCodeMetadata(
    httpStatus: 403,
    category: FlashnetErrorCategory.security,
    recovery: ErrorRecoveryStrategy.clawbackRequired,
    summary: "Nonce verification failed",
    userMessage: "The request nonce is invalid or has already been used.",
    actionHint: "Generate a new nonce and retry. If you sent funds, initiate a clawback.",
    isRetryable: false,
  ),
  "FSAG-2101": ErrorCodeMetadata(
    httpStatus: 400,
    category: FlashnetErrorCategory.security,
    recovery: ErrorRecoveryStrategy.clawbackRequired,
    summary: "Public key invalid",
    userMessage: "The provided public key is invalid.",
    actionHint: "Check that the public key is correctly formatted. If you sent funds, initiate a clawback.",
    isRetryable: false,
  ),

  // Infrastructure Errors (3000-3999) - Clawback Recommended
  "FSAG-3001": ErrorCodeMetadata(
    httpStatus: 503,
    category: FlashnetErrorCategory.infrastructure,
    recovery: ErrorRecoveryStrategy.clawbackRecommended,
    summary: "Internal server error",
    userMessage: "A temporary service issue occurred. Please try again.",
    actionHint: "Wait a moment and retry. If you sent funds, consider initiating a clawback.",
    isRetryable: true,
  ),
  "FSAG-3002": ErrorCodeMetadata(
    httpStatus: 500,
    category: FlashnetErrorCategory.infrastructure,
    recovery: ErrorRecoveryStrategy.clawbackRecommended,
    summary: "Internal server error",
    userMessage: "A temporary service issue occurred. Please try again.",
    actionHint: "Wait a moment and retry. If you sent funds, consider initiating a clawback.",
    isRetryable: true,
  ),
  "FSAG-3101": ErrorCodeMetadata(
    httpStatus: 500,
    category: FlashnetErrorCategory.infrastructure,
    recovery: ErrorRecoveryStrategy.clawbackRecommended,
    summary: "Internal server error",
    userMessage: "A database error occurred. Please try again.",
    actionHint: "Wait a moment and retry. If you sent funds, consider initiating a clawback.",
    isRetryable: true,
  ),
  "FSAG-3201": ErrorCodeMetadata(
    httpStatus: 503,
    category: FlashnetErrorCategory.infrastructure,
    recovery: ErrorRecoveryStrategy.clawbackRecommended,
    summary: "Internal server error",
    userMessage: "The settlement service is temporarily unavailable.",
    actionHint: "Wait and retry. If you sent funds and they haven't been processed, consider initiating a clawback.",
    isRetryable: true,
  ),
  "FSAG-3201T1": ErrorCodeMetadata(
    httpStatus: 503,
    category: FlashnetErrorCategory.infrastructure,
    recovery: ErrorRecoveryStrategy.clawbackRecommended,
    summary: "Internal server error",
    userMessage: "The settlement service is temporarily unavailable.",
    actionHint: "Wait and retry. If you sent funds and they haven't been processed, consider initiating a clawback.",
    isRetryable: true,
  ),
  "FSAG-3201T2": ErrorCodeMetadata(
    httpStatus: 503,
    category: FlashnetErrorCategory.infrastructure,
    recovery: ErrorRecoveryStrategy.clawbackRecommended,
    summary: "Internal server error",
    userMessage: "The settlement request timed out.",
    actionHint: "Check if your transaction was processed. If not, you may retry or initiate a clawback.",
    isRetryable: true,
  ),
  "FSAG-3202": ErrorCodeMetadata(
    httpStatus: 503,
    category: FlashnetErrorCategory.infrastructure,
    recovery: ErrorRecoveryStrategy.clawbackRecommended,
    summary: "Internal server error",
    userMessage: "A dependent service is temporarily unavailable.",
    actionHint: "Wait a moment and retry.",
    isRetryable: true,
  ),
  "FSAG-3301": ErrorCodeMetadata(
    httpStatus: 500,
    category: FlashnetErrorCategory.infrastructure,
    recovery: ErrorRecoveryStrategy.clawbackRecommended,
    summary: "Internal server error",
    userMessage: "The AMM processor couldn't receive your request.",
    actionHint: "Wait and retry. If you sent funds, consider initiating a clawback.",
    isRetryable: true,
  ),
  "FSAG-3302": ErrorCodeMetadata(
    httpStatus: 503,
    category: FlashnetErrorCategory.infrastructure,
    recovery: ErrorRecoveryStrategy.clawbackRecommended,
    summary: "Internal server error",
    userMessage: "The AMM processor timed out while processing your request.",
    actionHint: "Check if your transaction was processed. If not, you may retry or initiate a clawback.",
    isRetryable: true,
  ),
  "FSAG-3401": ErrorCodeMetadata(
    httpStatus: 500,
    category: FlashnetErrorCategory.infrastructure,
    recovery: ErrorRecoveryStrategy.clawbackRecommended,
    summary: "Internal server error",
    userMessage: "An internal processing error occurred.",
    actionHint: "This is likely a temporary issue. Wait and retry. If you sent funds, consider initiating a clawback.",
    isRetryable: true,
  ),
  "FSAG-3402": ErrorCodeMetadata(
    httpStatus: 500,
    category: FlashnetErrorCategory.infrastructure,
    recovery: ErrorRecoveryStrategy.clawbackRecommended,
    summary: "Internal server error",
    userMessage: "An internal processing error occurred.",
    actionHint: "This is likely a temporary issue. Wait and retry. If you sent funds, consider initiating a clawback.",
    isRetryable: true,
  ),

  // Business/AMM Logic Errors (4000-4999) - Auto Refund
  "FSAG-4001": ErrorCodeMetadata(
    httpStatus: 404,
    category: FlashnetErrorCategory.business,
    recovery: ErrorRecoveryStrategy.autoRefund,
    summary: "Pool not found",
    userMessage: "The specified pool does not exist.",
    actionHint: "Verify the pool ID is correct. Your funds will be automatically refunded.",
    isRetryable: false,
  ),
  "FSAG-4002": ErrorCodeMetadata(
    httpStatus: 404,
    category: FlashnetErrorCategory.business,
    recovery: ErrorRecoveryStrategy.none,
    summary: "Host not found",
    userMessage: "The specified host namespace does not exist.",
    actionHint: "Verify the host namespace is correct.",
    isRetryable: false,
  ),
  "FSAG-4101": ErrorCodeMetadata(
    httpStatus: 404,
    category: FlashnetErrorCategory.business,
    recovery: ErrorRecoveryStrategy.none,
    summary: "Auth session not found",
    userMessage: "Your authentication session was not found or has expired.",
    actionHint: "Start a new authentication flow.",
    isRetryable: true,
  ),
  "FSAG-4102": ErrorCodeMetadata(
    httpStatus: 400,
    category: FlashnetErrorCategory.business,
    recovery: ErrorRecoveryStrategy.none,
    summary: "Incorrect authentication flow",
    userMessage: "The authentication flow was not followed correctly.",
    actionHint: "Complete the authentication steps in the correct order.",
    isRetryable: true,
  ),
  "FSAG-4201": ErrorCodeMetadata(
    httpStatus: 400,
    category: FlashnetErrorCategory.business,
    recovery: ErrorRecoveryStrategy.autoRefund,
    summary: "Insufficient liquidity",
    userMessage: "The pool doesn't have enough liquidity to complete this swap.",
    actionHint: "Try a smaller amount or wait for more liquidity. Your funds will be automatically refunded.",
    isRetryable: true,
  ),
  "FSAG-4202": ErrorCodeMetadata(
    httpStatus: 400,
    category: FlashnetErrorCategory.business,
    recovery: ErrorRecoveryStrategy.autoRefund,
    summary: "Slippage exceeded",
    userMessage: "The price moved more than your allowed slippage tolerance.",
    actionHint: "Try increasing slippage tolerance, reducing trade size, or waiting for less volatile conditions. Your funds will be automatically refunded.",
    isRetryable: true,
  ),
  "FSAG-4203": ErrorCodeMetadata(
    httpStatus: 409,
    category: FlashnetErrorCategory.business,
    recovery: ErrorRecoveryStrategy.autoRefund,
    summary: "Operation not allowed in current phase",
    userMessage: "This operation cannot be performed while the pool is in its current phase.",
    actionHint: "Wait for the pool to transition to the appropriate phase. Your funds will be automatically refunded.",
    isRetryable: true,
  ),
  "FSAG-4204": ErrorCodeMetadata(
    httpStatus: 400,
    category: FlashnetErrorCategory.business,
    recovery: ErrorRecoveryStrategy.none,
    summary: "Insufficient LP tokens",
    userMessage: "You don't have enough LP tokens to complete this withdrawal.",
    actionHint: "Check your LP token balance and reduce the withdrawal amount.",
    isRetryable: false,
  ),
  "FSAG-4301": ErrorCodeMetadata(
    httpStatus: 400,
    category: FlashnetErrorCategory.business,
    recovery: ErrorRecoveryStrategy.none,
    summary: "Invalid fee configuration",
    userMessage: "The fee configuration is invalid.",
    actionHint: "Check that fee rates are within acceptable bounds.",
    isRetryable: false,
  ),
  "FSAG-4401": ErrorCodeMetadata(
    httpStatus: 409,
    category: FlashnetErrorCategory.business,
    recovery: ErrorRecoveryStrategy.none,
    summary: "Transfer ID already used",
    userMessage: "This Spark transfer has already been used in an operation.",
    actionHint: "Each transfer can only be used once. Use a new transfer for this operation.",
    isRetryable: false,
  ),

  // System/Service Errors (5000-5999) - Clawback Required
  "FSAG-5001": ErrorCodeMetadata(
    httpStatus: 500,
    category: FlashnetErrorCategory.system,
    recovery: ErrorRecoveryStrategy.clawbackRequired,
    summary: "Failed to generate unique ID",
    userMessage: "An internal error occurred while processing your request.",
    actionHint: "Please try again. If you sent funds, initiate a clawback.",
    isRetryable: true,
  ),
  "FSAG-5002": ErrorCodeMetadata(
    httpStatus: 501,
    category: FlashnetErrorCategory.system,
    recovery: ErrorRecoveryStrategy.none,
    summary: "Feature not implemented",
    userMessage: "This feature is not yet available.",
    actionHint: "This operation is not currently supported.",
    isRetryable: false,
  ),
  "FSAG-5003": ErrorCodeMetadata(
    httpStatus: 500,
    category: FlashnetErrorCategory.system,
    recovery: ErrorRecoveryStrategy.clawbackRequired,
    summary: "Internal state inconsistent",
    userMessage: "An internal error occurred. Please contact support if this persists.",
    actionHint: "If you sent funds, initiate a clawback and contact support.",
    isRetryable: false,
  ),
  "FSAG-5004": ErrorCodeMetadata(
    httpStatus: 500,
    category: FlashnetErrorCategory.system,
    recovery: ErrorRecoveryStrategy.clawbackRequired,
    summary: "Invalid configuration parameter",
    userMessage: "A system configuration error occurred.",
    actionHint: "This is a server-side issue. If you sent funds, initiate a clawback.",
    isRetryable: false,
  ),
  "FSAG-5100": ErrorCodeMetadata(
    httpStatus: 500,
    category: FlashnetErrorCategory.system,
    recovery: ErrorRecoveryStrategy.clawbackRequired,
    summary: "Unexpected panic",
    userMessage: "An unexpected error occurred on the server.",
    actionHint: "Please try again later. If you sent funds, initiate a clawback immediately.",
    isRetryable: false,
  ),
};

// Helper Functions

/// Check if a string is a valid FlashnetErrorCode
bool isFlashnetErrorCode(String code) {
  return ERROR_CODE_METADATA.containsKey(code);
}

/// Get error category from error code
FlashnetErrorCategory? getErrorCategory(String code) {
  return ERROR_CODE_METADATA[code]?.category;
}

/// Get recovery strategy from error code
ErrorRecoveryStrategy? getErrorRecovery(String code) {
  return ERROR_CODE_METADATA[code]?.recovery;
}

/// Get metadata for an error code
ErrorCodeMetadata? getErrorMetadata(String code) {
  return ERROR_CODE_METADATA[code];
}

/// Determine category from error code prefix (for unknown codes)
FlashnetErrorCategory? getCategoryFromCodeRange(String code) {
  final match = RegExp(r'^FSAG-(\d)').firstMatch(code);
  if (match == null) {
    return null;
  }

  final prefix = match.group(1);
  switch (prefix) {
    case '1':
      return FlashnetErrorCategory.validation;
    case '2':
      return FlashnetErrorCategory.security;
    case '3':
      return FlashnetErrorCategory.infrastructure;
    case '4':
      return FlashnetErrorCategory.business;
    case '5':
      return FlashnetErrorCategory.system;
    default:
      return null;
  }
}

// Data Structures

/// Raw error response from the AMM Gateway API
class FlashnetErrorResponseBody {
  final String errorCode;
  final String errorCategory;
  final String message;
  final dynamic details;
  final String requestId;
  final String timestamp;
  final String service;
  final String severity;
  final String? remediation;

  FlashnetErrorResponseBody({
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

  factory FlashnetErrorResponseBody.fromJson(Map<String, dynamic> json) =>
      FlashnetErrorResponseBody(
        errorCode: json['errorCode'] as String,
        errorCategory: json['errorCategory'] as String,
        message: json['message'] as String,
        details: json['details'],
        requestId: json['requestId'] as String,
        timestamp: json['timestamp'] as String,
        service: json['service'] as String,
        severity: json['severity'] as String,
        remediation: json['remediation'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'errorCode': errorCode,
        'errorCategory': errorCategory,
        'message': message,
        'details': details,
        'requestId': requestId,
        'timestamp': timestamp,
        'service': service,
        'severity': severity,
        'remediation': remediation,
      };
}

/// Options for creating a FlashnetError
class FlashnetErrorOptions {
  /// The raw error response from the API
  final FlashnetErrorResponseBody? response;

  /// HTTP status code
  final int? httpStatus;

  /// Transfer IDs that may need to be clawed back
  final List<String>? transferIds;

  /// LP identity public key for clawback
  final String? lpIdentityPublicKey;

  /// Results from automatic clawback attempts
  final AutoClawbackSummary? clawbackSummary;

  /// Original cause of this error
  final Object? cause;

  FlashnetErrorOptions({
    this.response,
    this.httpStatus,
    this.transferIds,
    this.lpIdentityPublicKey,
    this.clawbackSummary,
    this.cause,
  });
}

/// Error class for Flashnet AMM Gateway errors
///
/// Provides:
/// - Typed error codes with full metadata
/// - Recovery strategy information
/// - Human-readable messages
/// - Transfer tracking for clawback operations
class FlashnetError implements Exception {
  final String message;

  /// The FSAG error code (e.g., "FSAG-4202")
  late final String errorCode;

  /// Error category
  late final FlashnetErrorCategory category;

  /// Recovery strategy for this error
  late final ErrorRecoveryStrategy recovery;

  /// HTTP status code
  late final int httpStatus;

  /// Unique request ID for debugging
  late final String requestId;

  /// ISO timestamp when error occurred
  late final String timestamp;

  /// Service that generated the error
  late final String service;

  /// Error severity
  late final String severity;

  /// Additional error details
  late final dynamic details;

  /// Server-provided remediation hint
  late final String? remediation;

  /// Transfer IDs that may need clawback (unrecovered transfers)
  late final List<String> transferIds;

  /// LP identity public key for clawback operations
  late final String? lpIdentityPublicKey;

  /// Summary of automatic clawback attempts (if any were made)
  late final AutoClawbackSummary? clawbackSummary;

  /// Whether this error type is generally retryable
  late final bool isRetryable;

  /// Human-readable summary
  late final String summary;

  /// User-friendly message explaining the error
  late final String userMessage;

  /// Suggested action for the user
  late final String actionHint;

  FlashnetError(this.message, [FlashnetErrorOptions? options]) {
    final response = options?.response;
    final rawCode = response?.errorCode ?? "UNKNOWN";

    // Determine if we have a known error code
    if (isFlashnetErrorCode(rawCode)) {
      errorCode = rawCode;
      final metadata = ERROR_CODE_METADATA[rawCode]!;
      category = metadata.category;
      recovery = metadata.recovery;
      httpStatus = options?.httpStatus ?? metadata.httpStatus;
      isRetryable = metadata.isRetryable;
      summary = metadata.summary;
      userMessage = metadata.userMessage;
      // Prefer remediation from response
      actionHint = response?.remediation ?? metadata.actionHint;
    } else {
      // Unknown error code - try to determine category from range
      errorCode = rawCode;
      category = getCategoryFromCodeRange(rawCode) ?? FlashnetErrorCategory.system;
      httpStatus = options?.httpStatus ?? 500;

      // Default recovery based on category
      switch (category) {
        case FlashnetErrorCategory.validation:
        case FlashnetErrorCategory.security:
        case FlashnetErrorCategory.system:
          recovery = ErrorRecoveryStrategy.clawbackRequired;
          break;
        case FlashnetErrorCategory.infrastructure:
          recovery = ErrorRecoveryStrategy.clawbackRecommended;
          break;
        case FlashnetErrorCategory.business:
          recovery = ErrorRecoveryStrategy.autoRefund;
          break;
        default:
          recovery = ErrorRecoveryStrategy.clawbackRequired;
      }

      isRetryable = category == FlashnetErrorCategory.infrastructure;
      summary = response?.message ?? "Unknown error";
      userMessage = response?.message ?? "An unexpected error occurred.";
      actionHint = response?.remediation ?? "Please try again or contact support.";
    }

    requestId = response?.requestId ?? "";
    timestamp = response?.timestamp ?? DateTime.now().toUtc().toIso8601String();
    service = response?.service ?? "unknown";
    severity = response?.severity ?? "Error";
    details = response?.details;
    remediation = response?.remediation;
    transferIds = options?.transferIds ?? [];
    lpIdentityPublicKey = options?.lpIdentityPublicKey;
    clawbackSummary = options?.clawbackSummary;
  }

  // --- Recovery Status Methods ---

  bool isClawbackRequired() =>
      recovery == ErrorRecoveryStrategy.clawbackRequired && transferIds.isNotEmpty;

  bool isClawbackRecommended() =>
      recovery == ErrorRecoveryStrategy.clawbackRecommended && transferIds.isNotEmpty;

  bool shouldClawback() => isClawbackRequired() || isClawbackRecommended();

  bool willAutoRefund() => recovery == ErrorRecoveryStrategy.autoRefund;

  bool hasTransfersAtRisk() =>
      transferIds.isNotEmpty && recovery != ErrorRecoveryStrategy.autoRefund;

  // --- Category Check Methods ---

  bool isValidationError() => category == FlashnetErrorCategory.validation;
  bool isSecurityError() => category == FlashnetErrorCategory.security;
  bool isInfrastructureError() => category == FlashnetErrorCategory.infrastructure;
  bool isBusinessError() => category == FlashnetErrorCategory.business;
  bool isSystemError() => category == FlashnetErrorCategory.system;

  // --- Specific Error Checks ---

  bool isSlippageError() => errorCode == "FSAG-4202";
  bool isInsufficientLiquidityError() => errorCode == "FSAG-4201";
  bool isAuthError() => errorCode == "FSAG-2003" || errorCode == "FSAG-2004";
  bool isPoolNotFoundError() => errorCode == "FSAG-4001";
  bool isTransferAlreadyUsedError() => errorCode == "FSAG-4401";

  // --- Clawback Status Methods ---

  bool wasClawbackAttempted() => clawbackSummary?.attempted ?? false;

  bool wereAllTransfersRecovered() {
    if (clawbackSummary?.attempted != true) return false;
    return clawbackSummary!.failureCount == 0;
  }

  int getRecoveredTransferCount() => clawbackSummary?.successCount ?? 0;

  List<String> getRecoveredTransferIds() => clawbackSummary?.recoveredTransferIds ?? [];

  List<String> getUnrecoveredTransferIds() =>
      clawbackSummary?.unrecoveredTransferIds ?? transferIds;

  // --- Formatting & Serialization ---

  @override
  String toString() => "[$errorCode] $message (requestId: $requestId)";

  String getUserFriendlyMessage() {
    final parts = [userMessage];
    if (shouldClawback()) {
      parts.add("Your funds may need to be recovered via clawback.");
    } else if (willAutoRefund()) {
      parts.add("Your funds will be automatically refunded.");
    }
    return parts.join(" ");
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'errorCode': errorCode,
      'category': category.name,
      'recovery': recovery.name,
      'httpStatus': httpStatus,
      'requestId': requestId,
      'timestamp': timestamp,
      'service': service,
      'severity': severity,
      'details': details,
      'remediation': remediation,
      'transferIds': transferIds,
      'lpIdentityPublicKey': lpIdentityPublicKey,
      'clawbackSummary': clawbackSummary?.toJson(),
      'isRetryable': isRetryable,
      'summary': summary,
      'userMessage': userMessage,
      'actionHint': actionHint,
    };
  }

  // --- Static Factories ---

  static FlashnetError fromResponse(
    FlashnetErrorResponseBody? response,
    int httpStatus, {
    List<String>? transferIds,
    String? lpIdentityPublicKey,
  }) {
    return FlashnetError(
      response?.message ?? "null",
      FlashnetErrorOptions(
        response: response,
        httpStatus: httpStatus,
        transferIds: transferIds,
        lpIdentityPublicKey: lpIdentityPublicKey,
      ),
    );
  }

  static FlashnetError fromUnknown(
    dynamic error, {
    List<String>? transferIds,
    String? lpIdentityPublicKey,
  }) {
    if (error is FlashnetError) {
      final shouldPreserveTransferIds = error.recovery == ErrorRecoveryStrategy.autoRefund;

      if (lpIdentityPublicKey != null && error.lpIdentityPublicKey == null) {
        return FlashnetError(
          error.message,
          FlashnetErrorOptions(
            response: FlashnetErrorResponseBody(
              errorCode: error.errorCode,
              errorCategory: error.category.name,
              message: error.message,
              details: error.details,
              requestId: error.requestId,
              timestamp: error.timestamp,
              service: error.service,
              severity: error.severity,
              remediation: error.remediation,
            ),
            httpStatus: error.httpStatus,
            transferIds: shouldPreserveTransferIds ? error.transferIds : (transferIds ?? error.transferIds),
            lpIdentityPublicKey: lpIdentityPublicKey,
            cause: error,
          ),
        );
      }
      return error;
    }

    if (error is Exception || error is Error) {
      // Logic for generic Exception objects
      return FlashnetError(
        error.toString(),
        FlashnetErrorOptions(
          httpStatus: 500,
          transferIds: transferIds,
          lpIdentityPublicKey: lpIdentityPublicKey,
          cause: error,
        ),
      );
    }

    return FlashnetError(
      error.toString(),
      FlashnetErrorOptions(
        httpStatus: 500,
        transferIds: transferIds,
        lpIdentityPublicKey: lpIdentityPublicKey,
      ),
    );
  }
}

/// Type guard to check if an error is a FlashnetError
bool isFlashnetError(dynamic error) => error is FlashnetError;