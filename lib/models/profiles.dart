enum ProductSubcategory {
  engineParts,
  bodyParts,
  suspensionParts,
  transmissionParts,
  batteries,
}
enum VettingStatus {
  pending,
  approved,
  declined,
}
enum UserRole {
  administrator,
  buyer,
  seller,
}
enum OtpType {
  sms,
  email,
}

class AppUser {
  final int id;
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final bool emailVerified;
  final bool phoneVerified;
  final UserRole role;
  final OtpType? otpType;
  final bool isStaff;
  final bool isSuperuser;
  final bool isActive;
  final bool isVerified;
  final bool isSuspended;
  final DateTime dateJoined;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.emailVerified,
    required this.phoneVerified,
    required this.role,
    this.otpType,
    required this.isStaff,
    required this.isSuperuser,
    required this.isActive,
    required this.isVerified,
    required this.isSuspended,
    required this.dateJoined,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? 0,
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      emailVerified: json['email_verified'] ?? false,
      phoneVerified: json['phone_verified'] ?? false,
      role: _userRoleFromString(json['role'] ?? 'buyer'),
      otpType: _otpTypeFromString(json['otp_type']),
      isStaff: json['is_staff'] ?? false,
      isSuperuser: json['is_superuser'] ?? false,
      isActive: json['is_active'] ?? false,
      isVerified: json['is_verified'] ?? false,
      isSuspended: json['is_suspended'] ?? false,
      dateJoined: DateTime.tryParse(json['date_joined'] ?? '') ?? DateTime(2000),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime(2000),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime(2000),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'role': _userRoleToString(role),
      'otp_type': otpType != null ? _otpTypeToString(otpType!) : null,
      'is_staff': isStaff,
      'is_superuser': isSuperuser,
      'is_active': isActive,
      'is_verified': isVerified,
      'is_suspended': isSuspended,
      'date_joined': dateJoined.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static UserRole _userRoleFromString(String value) {
    switch (value) {
      case 'administrator':
        return UserRole.administrator;
      case 'buyer':
        return UserRole.buyer;
      case 'seller':
        return UserRole.seller;
      default:
        return UserRole.buyer; // default fallback
    }
  }

  static String _userRoleToString(UserRole role) {
    switch (role) {
      case UserRole.administrator:
        return 'administrator';
      case UserRole.buyer:
        return 'buyer';
      case UserRole.seller:
        return 'seller';
    }
  }

  static OtpType? _otpTypeFromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'sms':
        return OtpType.sms;
      case 'email':
        return OtpType.email;
      default:
        return null;
    }
  }

  static String _otpTypeToString(OtpType otpType) {
    switch (otpType) {
      case OtpType.sms:
        return 'sms';
      case OtpType.email:
        return 'email';
    }
  }
}
class Seller {
  final int id;
  final AppUser user;
  final String registeredCompanyName;
  final String tradingName;
  final String registrationNumber;
  final String vatNumber;
  final String websiteUrl;
  final String productCategory;
  final ProductSubcategory? productSubcategory;
  final DateTime createdAt;
  final DateTime updatedAt;

  Seller({
    required this.id,
    required this.user,
    required this.registeredCompanyName,
    required this.tradingName,
    required this.registrationNumber,
    required this.vatNumber,
    required this.websiteUrl,
    required this.productCategory,
    this.productSubcategory,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Seller.fromJson(Map<String, dynamic> json) => Seller(
    id: json['id'] ?? 0,
    user: AppUser.fromJson(json['user'] ?? {}),
    registeredCompanyName: json['registered_company_name'] ?? '',
    tradingName: json['trading_name'] ?? '',
    registrationNumber: json['registration_number'] ?? '',
    vatNumber: json['vat_number'] ?? '',
    websiteUrl: json['website_url'] ?? '',
    productCategory: json['product_category'] ?? '',
    productSubcategory: _productSubcategoryFromString(json['product_subcategory']),
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime(2000),
    updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime(2000),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': user.toJson(),
    'registered_company_name': registeredCompanyName,
    'trading_name': tradingName,
    'registration_number': registrationNumber,
    'vat_number': vatNumber,
    'website_url': websiteUrl,
    'product_category': productCategory,
    'product_subcategory': productSubcategory != null ? _productSubcategoryToString(productSubcategory!) : null,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
class BuyersAddressDetails {
  final String uid;
  final AppUser user;
  final String postalAddress;
  final String physicalAddress;
  final String location;
  final String contactPersonName;
  final String contactPersonTelephone;
  final String contactPersonEmailAddress;
  final String platformWorkflowEmailAddress;
  final bool isPrimary;

  BuyersAddressDetails({
    required this.uid,
    required this.user,
    required this.postalAddress,
    required this.physicalAddress,
    required this.location,
    required this.contactPersonName,
    required this.contactPersonTelephone,
    required this.contactPersonEmailAddress,
    required this.platformWorkflowEmailAddress,
    required this.isPrimary,
  });

  factory BuyersAddressDetails.fromJson(Map<String, dynamic> json) => BuyersAddressDetails(
    uid: json['uid'] ?? '',
    user: AppUser.fromJson(json['user'] ?? {}),
    postalAddress: json['postal_address'] ?? '',
    physicalAddress: json['physical_address'] ?? '',
    location: json['location'] ?? '',
    contactPersonName: json['contact_person_name'] ?? '',
    contactPersonTelephone: json['contact_person_telephone'] ?? '',
    contactPersonEmailAddress: json['contact_person_email_address'] ?? '',
    platformWorkflowEmailAddress: json['platform_workflow_email_address'] ?? '',
    isPrimary: json['is_primary'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'user': user.toJson(),
    'postal_address': postalAddress,
    'physical_address': physicalAddress,
    'location': location,
    'contact_person_name': contactPersonName,
    'contact_person_telephone': contactPersonTelephone,
    'contact_person_email_address': contactPersonEmailAddress,
    'platform_workflow_email_address': platformWorkflowEmailAddress,
    'is_primary': isPrimary,
  };
}


ProductSubcategory? _productSubcategoryFromString(String? value) {
  switch (value) {
    case 'engine_parts':
      return ProductSubcategory.engineParts;
    case 'body_parts':
      return ProductSubcategory.bodyParts;
    case 'suspension_parts':
      return ProductSubcategory.suspensionParts;
    case 'transmission_parts':
      return ProductSubcategory.transmissionParts;
    case 'batteries':
      return ProductSubcategory.batteries;
    default:
      return null;
  }
}

String _productSubcategoryToString(ProductSubcategory value) {
  switch (value) {
    case ProductSubcategory.engineParts:
      return 'engine_parts';
    case ProductSubcategory.bodyParts:
      return 'body_parts';
    case ProductSubcategory.suspensionParts:
      return 'suspension_parts';
    case ProductSubcategory.transmissionParts:
      return 'transmission_parts';
    case ProductSubcategory.batteries:
      return 'batteries';
  }
}


