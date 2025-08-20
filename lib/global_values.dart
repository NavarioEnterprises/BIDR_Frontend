
import 'package:bidr/models/alert.dart';

import 'models/request_models.dart';

class   GlobalVariables{
  static List<WebNotification> alertList = [];


  static Seller seller1 = Seller(
    name: 'ABC Motors',
    bid: 2500.0,
    bidTime: DateTime.now().subtract(const Duration(hours: 2)),
    rating: 4.6,
    maxRating: 5, comment: 'trusted spares for years', radius: 30.0,
  );

  static Seller seller2 = Seller(
    name: 'TyreZone',
    bid: 3150.0,
    bidTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    rating: 4.3,
    maxRating: 5, comment: 'Our parts are fresh and new from the box', radius: 40.4,
  );
  static RimTyreProductDetails rimTyreProductDetails = RimTyreProductDetails(
    tyreWidthMm: 205,
    sidewallProfile: '55',
    wheelRimDiameterInches: '16',
    tyreType: 'Tyres',
    quantity: 4,
    urgency: '1 Day',
  );
  static RimTyreMoreFields rimTyreMoreFields = RimTyreMoreFields(
    description: 'High-performance radial tyre suitable for all-season driving.',
    vehicleType: 'Passenger Car',
    pitchCircleDiameter: '114.3',
    preferredBrand: 'Michelin',
    tyreConstructionType: 'Radial',
    fitmentRequired: true,
    balancingRequired: true,
    tyreRotationRequired: false,
    imageUrls: [
      'https://example.com/images/tyre1.jpg',
      'https://example.com/images/tyre2.jpg',
    ],
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
    imageUrls: const [],           // supply paths/URLs if you have any
  );

  static MoreFields moreFields = MoreFields(
    partNumber: 'ALT‑4282‑OEM',
    transmissionType: 'Automatic',
    mileage: '180000',
    fuelType: 'Petrol',
    bodyType: 'Sedan',
  );

  static AutoSpares autoSparesItem = AutoSpares(

    vehicleDetails: vehicleDetails,
    partDetails: partDetails,
    moreFields: moreFields,
  );

  static AutoSparesRequest autoSparesRequest = AutoSparesRequest(
    id: 101,
    status: 'Offer',
    category: 'Vehicle Spares',
    createdAt: DateTime.now(),
    autoSpares: autoSparesItem,
    sellerOffers: [seller1],
  );

  /* ---------- 2) Rim & Tyre / Electronics‑style branch ---------- */

  static ProductDetails productDetails = ProductDetails(
    typeOfElectronics: '65‑inch LED TV',
    brandPreference: 'Samsung',
    modelSeries: 'Q60A',
    quantityNeeded: 1,
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

  static RimTyre rimTyreItem = RimTyre(// keep the name you need for the backend
    moreFields: rimTyreMoreFields, productDetails: rimTyreProductDetails,
  );

  static RimTyreRequest rimTyreRequest = RimTyreRequest(
    id: 202,
    status: 'Offer',
    category: 'Vehicle Tyres and Rims',
    createdAt: DateTime.now(),
    rimTyre: rimTyreItem,
    sellerOffers: [seller2,seller1],
  );

  /* ---------- 3) Consumer‑side Tyre branch ---------- */
  static ProductDetails exampleProductDetails = ProductDetails(
    typeOfElectronics: 'Laptop',
    brandPreference: 'Dell',
    modelSeries: 'XPS 15',
    quantityNeeded: 2,
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
    additionalComments: 'Looking for devices with international warranty support.',
  );

  static ConsumerElectronics consumerElectronics = ConsumerElectronics(
    productDetails: exampleProductDetails,
    budgetTimeline: exampleBudgetTimeline,
    featuresAndSpecs: exampleFeaturesAndSpecs,
  );




  static ConsumerElectronicsRequest consumerElectronicsRequest = ConsumerElectronicsRequest(
    id: 303,
    status: 'Waiting',
    category: 'Consumer Electronics',
    createdAt: DateTime.now(),
    consumerElectronics: consumerElectronics,
    sellerOffers: const [],        // no offers yet
  );

  /* ---------- 4) Combine everything ---------- */
  static CombinedRequest combinedRequest = CombinedRequest(
    id: 1,
    autoSparesRequest: [autoSparesRequest],
    rimTyreRequest: [rimTyreRequest],
    consumerElectronicsRequest: [consumerElectronicsRequest],
  );

  // Print to verify (optional)

}