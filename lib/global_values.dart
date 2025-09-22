import 'package:bidr/config/environment_config.dart';
import 'package:bidr/models/alert.dart';

import 'models/request_models.dart';

class GlobalVariables {
  static List<WebNotification> alertList = [];

  static RimTyreProductDetails rimTyreProductDetails = RimTyreProductDetails(
    tyreWidthMm: 205,
    sidewallProfile: '55',
    wheelRimDiameterInches: '16',
    tyreType: 'Tyres',
    quantity: 4,
    urgency: '1 Day',
    //maxDistanceKm: 0.0,
  );
  static RimTyreMoreFields rimTyreMoreFields = RimTyreMoreFields(
    description:
        'High-performance radial tyre suitable for all-season driving.',
    vehicleType: 'Passenger Car',
    pitchCircleDiameter: '114.3',
    preferredBrand: 'Michelin',
    tyreConstructionType: 'Radial',
    fitmentRequired: "",
    balancingRequired: "",
    tyreRotationRequired: "",
    imageUrls: [],
  );

  /* ---------- 1) Auto‑Spares branch ---------- */
  static VehicleDetails vehicleDetails = VehicleDetails(
    vin: '1HGCM82633A004352',
    manufacturer: 'Honda',
    makeModel: 'Accord',
    type: 'Sedan',
    condition: 'Used',
    year: '2003',
  );

  static PartDetails partDetails = PartDetails(
    partName: 'Alternator',
    quantity: 1,
    location: 'Cape Town',
    maxDistanceKm: 50,
    urgency: 'Immediately',
    productDescription: 'OEM alternator for Honda Accord 2.4 L (2003)',
    imageUrls: const [], // supply paths/URLs if you have any
  );

  static MoreFields moreFields = MoreFields(
    partNumber: 'ALT‑4282‑OEM',
    transmissionType: 'Automatic',
    mileage: '180000',
    fuelType: 'Petrol',
    bodyType: 'Sedan',
    preferredBrand: '',
    fitmentRequired: '',
    balancingRequired: '',
    tyreRotationRequired: '',
  );

  static AutoSpares autoSparesItem = AutoSpares(
    vehicleDetails: vehicleDetails,
    partDetails: partDetails,
    moreFields: moreFields,
  );

  /* ---------- 2) Rim & Tyre / Electronics‑style branch ---------- */

  static ProductDetails productDetails = ProductDetails(
    typeOfElectronics: '65‑inch LED TV',
    brandPreference: 'Samsung',
    modelSeries: 'Q60A',
    quantityNeeded: 1,
    //maxDistanceKm: 0.0,
  );

  static BudgetTimeline budgetTimeline = BudgetTimeline(
    minPrice: 8000,
    maxPrice: 12000,
    urgency: 'Within a week',
    needsInstallation: true,
  );

  static FeaturesAndSpecs featuresAndSpecs = FeaturesAndSpecs(
    requiredFeatures: '4K UHD • HDR10+',
    conditionPreference: 'New',
    purpose: 'Home Use',
    documentsOrImages: const [],
    additionalComments: 'Wall‑mount bracket preferred.',
  );

  static RimTyre rimTyreItem = RimTyre(
    // keep the name you need for the backend
    moreFields: rimTyreMoreFields,
    productDetails: rimTyreProductDetails,
  );

  /* ---------- 3) Consumer‑side Tyre branch ---------- */
  static ProductDetails exampleProductDetails = ProductDetails(
    typeOfElectronics: 'Laptop',
    brandPreference: 'Dell',
    modelSeries: 'XPS 15',
    quantityNeeded: 2,
    //maxDistanceKm: 0.0,
  );
  static BudgetTimeline exampleBudgetTimeline = BudgetTimeline(
    minPrice: 1000.0,
    maxPrice: 2000.0,
    urgency: 'Within a week',
    needsInstallation: false,
  );

  static FeaturesAndSpecs exampleFeaturesAndSpecs = FeaturesAndSpecs(
    requiredFeatures: 'Touchscreen, 16GB RAM, Backlit Keyboard',
    conditionPreference: 'New',
    purpose: 'Commercial',
    documentsOrImages: [
      'https://example.com/specsheet.pdf',
      'https://example.com/image1.jpg',
    ],
    additionalComments:
        'Looking for devices with international warranty support.',
  );

  static ConsumerElectronics consumerElectronics = ConsumerElectronics(
    productDetails: exampleProductDetails,
    budgetTimeline: exampleBudgetTimeline,
    featuresAndSpecs: exampleFeaturesAndSpecs,
  );

  /* ---------- 4) Combine everything ---------- */
  static CombinedRequest combinedRequest = CombinedRequest(
    id: 1,
    autoSparesRequest: [],
    rimTyreRequest: [],
    consumerElectronicsRequest: [],
  );

  /* ---------- Environment Configuration Getters ---------- */
  // Service URLs
  static String get authServiceUrl => AppConfig.authServiceUrl;
  static String get chatServiceUrl => AppConfig.chatServiceUrl;
  static String get paymentServiceUrl => AppConfig.paymentServiceUrl;
  static String get resolutionServiceUrl => AppConfig.resolutionServiceUrl;
  static String get productsServiceUrl => AppConfig.productsServiceUrl;
  static String get notificationsServiceUrl =>
      AppConfig.notificationsServiceUrl;
  static String get transactionsServiceUrl => AppConfig.transactionsServiceUrl;
  static String get reviewsServiceUrl => AppConfig.reviewsServiceUrl;

  // Admin URLs
  static String get authAdminUrl => AppConfig.authAdminUrl;
  static String get chatAdminUrl => AppConfig.chatAdminUrl;
  static String get paymentAdminUrl => AppConfig.paymentAdminUrl;
  static String get resolutionAdminUrl => AppConfig.resolutionAdminUrl;
  static String get productsAdminUrl => AppConfig.productsAdminUrl;
  static String get notificationsAdminUrl => AppConfig.notificationsAdminUrl;
  static String get transactionsAdminUrl => AppConfig.transactionsAdminUrl;
  static String get reviewsAdminUrl => AppConfig.reviewsAdminUrl;

  // Monitoring URLs
  static String get grafanaUrl => AppConfig.grafanaUrl;
  static String get prometheusUrl => AppConfig.prometheusUrl;
}
