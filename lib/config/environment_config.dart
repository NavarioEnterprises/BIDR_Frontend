/// Defines the available runtime environments.
enum EnvironmentType { dev, uat, prod }

/// Holds the URLs and settings specific to ONE environment.
class EnvironmentConfig {
  // Service URLs
  final String authServiceUrl;
  final String chatServiceUrl;
  final String paymentServiceUrl;
  final String resolutionServiceUrl;
  final String productsServiceUrl;
  final String notificationsServiceUrl;
  final String transactionsServiceUrl;
  final String reviewsServiceUrl;

  // Admin URLs
  final String authAdminUrl;
  final String chatAdminUrl;
  final String paymentAdminUrl;
  final String resolutionAdminUrl;
  final String productsAdminUrl;
  final String notificationsAdminUrl;
  final String transactionsAdminUrl;
  final String reviewsAdminUrl;

  // Monitoring URLs
  final String grafanaUrl;
  final String prometheusUrl;

  EnvironmentConfig({
    // Service URLs
    required this.authServiceUrl,
    required this.chatServiceUrl,
    required this.paymentServiceUrl,
    required this.resolutionServiceUrl,
    required this.productsServiceUrl,
    required this.notificationsServiceUrl,
    required this.transactionsServiceUrl,
    required this.reviewsServiceUrl,
    // Admin URLs
    required this.authAdminUrl,
    required this.chatAdminUrl,
    required this.paymentAdminUrl,
    required this.resolutionAdminUrl,
    required this.productsAdminUrl,
    required this.notificationsAdminUrl,
    required this.transactionsAdminUrl,
    required this.reviewsAdminUrl,
    // Monitoring URLs
    required this.grafanaUrl,
    required this.prometheusUrl,
  });
}

/// Manages the application's environment configuration.
class AppConfig {
  static EnvironmentType _currentEnvironment = EnvironmentType.dev;

  static final Map<EnvironmentType, EnvironmentConfig> _environments = {
    EnvironmentType.dev: EnvironmentConfig(
      // Service URLs (Port-based)
      authServiceUrl: "http://localhost:8001/",
      chatServiceUrl: "http://localhost:8002/",
      paymentServiceUrl: "http://localhost:8003/",
      resolutionServiceUrl: "http://localhost:8004/",
      productsServiceUrl: "http://localhost:8005/",
      notificationsServiceUrl: "http://localhost:8006/",
      transactionsServiceUrl: "http://localhost:8007/",
      reviewsServiceUrl: "http://localhost:8008/",
      // Admin URLs
      authAdminUrl: "http://localhost:8001/admin/",
      chatAdminUrl: "http://localhost:8002/admin/",
      paymentAdminUrl: "http://localhost:8003/admin/",
      resolutionAdminUrl: "http://localhost:8004/admin/",
      productsAdminUrl: "http://localhost:8005/admin/",
      notificationsAdminUrl: "http://localhost:8006/admin/",
      transactionsAdminUrl: "http://localhost:8007/admin/",
      reviewsAdminUrl: "http://localhost:8008/admin/",
      // Monitoring
      grafanaUrl: "http://localhost:3000/",
      prometheusUrl: "http://localhost:9090/",
    ),
    EnvironmentType.uat: EnvironmentConfig(
      // Service URLs
      productsServiceUrl:
          "http://bidr-product-1756960567.westus.azurecontainer.io:8000/",
      authServiceUrl:
          "http://bidr-auth-1756961802.westus.azurecontainer.io:8001/",
      chatServiceUrl:
          "http://bidr-chat-1756963149.westus.azurecontainer.io:8002/",
      paymentServiceUrl:
          "http://bidr-payment-1756963524.westus.azurecontainer.io:8003/",
      resolutionServiceUrl:
          "http://bidr-resolution-1756963788.westus.azurecontainer.io:8004/",
      notificationsServiceUrl:
          "http://bidr-notifications-1756964056.westus.azurecontainer.io:8005/",
      transactionsServiceUrl:
          "http://bidr-transactions-1756964308.westus.azurecontainer.io:8006/",
      reviewsServiceUrl:
          "http://bidr-reviews-1756964572.westus.azurecontainer.io:8007/",

      // Admin URLs
      productsAdminUrl:
          "http://bidr-product-1756960567.westus.azurecontainer.io:8000/admin/",
      authAdminUrl:
          "http://bidr-auth-1756961802.westus.azurecontainer.io:8001/admin/",
      chatAdminUrl:
          "http://bidr-chat-1756963149.westus.azurecontainer.io:8002/admin/",
      paymentAdminUrl:
          "http://bidr-payment-1756963524.westus.azurecontainer.io:8003/admin/",
      resolutionAdminUrl:
          "http://bidr-resolution-1756963788.westus.azurecontainer.io:8004/admin/",
      notificationsAdminUrl:
          "http://bidr-notifications-1756964056.westus.azurecontainer.io:8005/admin/",
      transactionsAdminUrl:
          "http://bidr-transactions-1756964308.westus.azurecontainer.io:8006/admin/",
      reviewsAdminUrl:
          "http://bidr-reviews-1756964572.westus.azurecontainer.io:8007/admin/",
      grafanaUrl: '',
      prometheusUrl: '',
    ),
    EnvironmentType.prod: EnvironmentConfig(
      // Service URLs (Production URLs)
      authServiceUrl: "https://bidr.online/auth/",
      chatServiceUrl: "https://bidr.online/chat/",
      paymentServiceUrl: "https://bidr.online/payments/",
      resolutionServiceUrl: "https://bidr.online/resolution/",
      productsServiceUrl: "https://bidr.online/products/",
      notificationsServiceUrl: "https://bidr.online/notifications/",
      transactionsServiceUrl: "https://bidr.online/transactions/",
      reviewsServiceUrl: "https://bidr.online/reviews/",
      // Admin URLs
      authAdminUrl: "https://bidr.online/auth/admin/",
      chatAdminUrl: "https://bidr.online/chat/admin/",
      paymentAdminUrl: "https://bidr.online/payments/admin/",
      resolutionAdminUrl: "https://bidr.online/resolution/admin/",
      productsAdminUrl: "https://bidr.online/products/admin/",
      notificationsAdminUrl: "https://bidr.online/notifications/admin/",
      transactionsAdminUrl: "https://bidr.online/transactions/admin/",
      reviewsAdminUrl: "https://bidr.online/reviews/admin/",
      // Monitoring
      grafanaUrl: "https://bidr.online/grafana/",
      prometheusUrl: "https://bidr.online/prometheus/",
    ),
  };

  /// Sets the current environment (call this FIRST during app initialization).
  /// Example: AppConfig.setEnvironment(EnvironmentType.dev);
  static void setEnvironment(EnvironmentType env) {
    _currentEnvironment = env;
    print("----- APP ENVIRONMENT SET TO: ${env.name.toUpperCase()} -----");
  }

  static void switchEnvironment(EnvironmentType env) {
    if (_currentEnvironment != env) {
      _currentEnvironment = env;
      print(
        "----- APP ENVIRONMENT SWITCHED TO: ${env.name.toUpperCase()} -----",
      );
    }
  }

  /// Gets the configuration object for the currently set environment.
  static EnvironmentConfig get currentConfig =>
      _environments[_currentEnvironment]!;

  /// Convenience getter for the current environment type enum value.
  static EnvironmentType get currentEnvironmentType => _currentEnvironment;

  // --- Convenience Getters for Service URLs ---
  static String get authServiceUrl => currentConfig.authServiceUrl;
  static String get chatServiceUrl => currentConfig.chatServiceUrl;
  static String get paymentServiceUrl => currentConfig.paymentServiceUrl;
  static String get resolutionServiceUrl => currentConfig.resolutionServiceUrl;
  static String get productsServiceUrl => currentConfig.productsServiceUrl;
  static String get notificationsServiceUrl =>
      currentConfig.notificationsServiceUrl;
  static String get transactionsServiceUrl =>
      currentConfig.transactionsServiceUrl;
  static String get reviewsServiceUrl => currentConfig.reviewsServiceUrl;

  // --- Convenience Getters for Admin URLs ---
  static String get authAdminUrl => currentConfig.authAdminUrl;
  static String get chatAdminUrl => currentConfig.chatAdminUrl;
  static String get paymentAdminUrl => currentConfig.paymentAdminUrl;
  static String get resolutionAdminUrl => currentConfig.resolutionAdminUrl;
  static String get productsAdminUrl => currentConfig.productsAdminUrl;
  static String get notificationsAdminUrl =>
      currentConfig.notificationsAdminUrl;
  static String get transactionsAdminUrl => currentConfig.transactionsAdminUrl;
  static String get reviewsAdminUrl => currentConfig.reviewsAdminUrl;

  // --- Monitoring URLs ---
  static String get grafanaUrl => currentConfig.grafanaUrl;
  static String get prometheusUrl => currentConfig.prometheusUrl;
}
