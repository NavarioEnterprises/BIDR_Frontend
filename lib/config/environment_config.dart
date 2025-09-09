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
      productsServiceUrl: "https://products-management.bidr.co.za/",
      authServiceUrl: "https://api.bidr.co.za/",
      chatServiceUrl: "http://chat-service.bidr.co.za/",
      paymentServiceUrl: "https://resolutions.bidr.co.za/",
      resolutionServiceUrl:
          "https://bidr-resolution-1756963788.westus.azurecontainer.io:8004/",
      notificationsServiceUrl: "https://notifications.bidr.co.za/",
      transactionsServiceUrl:
          "https://bidr-transactions-1756964308.westus.azurecontainer.io:8006/",
      reviewsServiceUrl: "https://reviews.bidr.co.za/",

      // Admin URLs
      productsAdminUrl:
          "https://bidr-product-1756960567.westus.azurecontainer.io:8000/admin/",
      authAdminUrl:
          "https://bidr-auth-1756961802.westus.azurecontainer.io:8001/admin/",
      chatAdminUrl:
          "https://bidr-chat-1756963149.westus.azurecontainer.io:8002/admin/",
      paymentAdminUrl:
          "https://bidr-payment-1756963524.westus.azurecontainer.io:8003/admin/",
      resolutionAdminUrl:
          "https://bidr-resolution-1756963788.westus.azurecontainer.io:8004/admin/",
      notificationsAdminUrl:
          "https://bidr-notifications-1756964056.westus.azurecontainer.io:8005/admin/",
      transactionsAdminUrl:
          "https://bidr-transactions-1756964308.westus.azurecontainer.io:8006/admin/",
      reviewsAdminUrl:
          "https://bidr-reviews-1756964572.westus.azurecontainer.io:8007/admin/",
      grafanaUrl: '',
      prometheusUrl: '',
    ),
    EnvironmentType.prod: EnvironmentConfig(
      // Service URLs (Production URLs)
      authServiceUrl: "https://bidr-auth.ngrok.io/",
      chatServiceUrl: "https://bidr-chat.ngrok.io/",
      paymentServiceUrl: "https://bidr-payment.ngrok.io/",
      resolutionServiceUrl: "https://bidr-resolution.ngrok.io/",
      productsServiceUrl: "https://bidr-products.ngrok.io/",
      notificationsServiceUrl: "https://bidr-notifications.ngrok.io/",
      transactionsServiceUrl: "https://bidr-transactions.ngrok.io/",
      reviewsServiceUrl: "https://bidr-reviews.ngrok.io/",
      // Admin URLs
      authAdminUrl: "https://bidr-auth.ngrok.io/admin/",
      chatAdminUrl: "https://bidr-chat.ngrok.io/admin/",
      paymentAdminUrl: "https://bidr-payment.ngrok.io/admin/",
      resolutionAdminUrl: "https://bidr-resolution.ngrok.io/admin/",
      productsAdminUrl: "https://bidr-products.ngrok.io/admin/",
      notificationsAdminUrl: "https://bidr-notifications.ngrok.io/admin/",
      transactionsAdminUrl: "https://bidr-transactions.ngrok.io/admin/",
      reviewsAdminUrl: "https://bidr-reviews.ngrok.io/admin/",
      // Monitoring
      grafanaUrl: "https://bidr-grafana.ngrok.io/",
      prometheusUrl: "https://bidr-prometheus.ngrok.io/",
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
