
import '../vihecle_spares.dart';

class CompanyInfo {
  final String companyName;
  final String tradingName;
  final String registrationNumber;
  final String vatNumber;
  final String websiteUrl;
  final String cipcDocumentPath;

  CompanyInfo({
    required this.companyName,
    required this.tradingName,
    required this.registrationNumber,
    required this.vatNumber,
    required this.websiteUrl,
    required this.cipcDocumentPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'trading_name': tradingName,
      'registration_number': registrationNumber,
      'vat_number': vatNumber,
      'website_url': websiteUrl,
      'cipc_document_path': cipcDocumentPath,
    };
  }

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      companyName: json['company_name'] ?? '',
      tradingName: json['trading_name'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      vatNumber: json['vat_number'] ?? '',
      websiteUrl: json['website_url'] ?? '',
      cipcDocumentPath: json['cipc_document_path'] ?? '',
    );
  }
}

class CompanyContactInfo {
  final String postalAddress;
  final String physicalAddress;
  final String contactPersonName;
  final String contactPersonTelephone;
  final String contactPersonEmail;
  final String platformWorkflowEmail;
  final LocationPoint locationPoint;

  CompanyContactInfo({
    required this.postalAddress,
    required this.physicalAddress,
    required this.contactPersonName,
    required this.contactPersonTelephone,
    required this.contactPersonEmail,
    required this.platformWorkflowEmail,
    required this.locationPoint,
  });

  Map<String, dynamic> toJson() {
    return {
      'postal_address': postalAddress,
      'physical_address': physicalAddress,
      'contact_person_name': contactPersonName,
      'contact_person_telephone': contactPersonTelephone,
      'contact_person_email': contactPersonEmail,
      'platform_workflow_email': platformWorkflowEmail,
      'location_point': locationPoint.toJson(),
    };
  }

  factory CompanyContactInfo.fromJson(Map<String, dynamic> json) {
    return CompanyContactInfo(
      postalAddress: json['postal_address'] ?? '',
      physicalAddress: json['physical_address'] ?? '',
      contactPersonName: json['contact_person_name'] ?? '',
      contactPersonTelephone: json['contact_person_telephone'] ?? '',
      contactPersonEmail: json['contact_person_email'] ?? '',
      platformWorkflowEmail: json['platform_workflow_email'] ?? '',
      locationPoint: LocationPoint.fromJson(json['location_point'] ?? {}),
    );
  }
}

class BankingInfo {
  final String bankName;
  final String accountNumber;
  final String branchCode;
  final String accountHolder;

  BankingInfo({
    required this.bankName,
    required this.accountNumber,
    required this.branchCode,
    required this.accountHolder,
  });

  Map<String, dynamic> toJson() {
    return {
      'bank_name': bankName,
      'account_number': accountNumber,
      'branch_code': branchCode,
      'account_holder': accountHolder,
    };
  }

  factory BankingInfo.fromJson(Map<String, dynamic> json) {
    return BankingInfo(
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      branchCode: json['branch_code'] ?? '',
      accountHolder: json['account_holder'] ?? '',
    );
  }
}

class BusinessRegistration {
  final CompanyInfo companyInfo;
  final CompanyContactInfo contactInfo;
  final BankingInfo bankingInfo;
  final List<String> productCategories;

  BusinessRegistration({
    required this.companyInfo,
    required this.contactInfo,
    required this.bankingInfo,
    required this.productCategories,
  });

  factory BusinessRegistration.fromJson(Map<String, dynamic> json) =>
      BusinessRegistration(
        companyInfo: CompanyInfo.fromJson(json['company_info'] ?? {}),
        contactInfo: CompanyContactInfo.fromJson(json['contact_info'] ?? {}),
        bankingInfo: BankingInfo.fromJson(json['banking_info'] ?? {}),
        productCategories: List<String>.from(json['product_categories'] ?? []),
      );

  Map<String, dynamic> toJson() => {
    'company_info': companyInfo.toJson(),
    'contact_info': contactInfo.toJson(),
    'banking_info': bankingInfo.toJson(),
    'product_categories': productCategories,
  };
}


