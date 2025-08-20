
import 'package:bidr/models/request_models.dart';

class SellerAutoSparesRequest {
  final int id;
  final String status;
  final String category;
  final String? additionalNotes;
  final DateTime createdAt;
  final AutoSpares autoSparesRequest;

  SellerAutoSparesRequest({
    required this.id,
    this.additionalNotes,
    required this.status,
    required this.createdAt,
    required this.autoSparesRequest,
    required this.category

  });

  factory SellerAutoSparesRequest.fromJson(Map<String, dynamic> json) {
    return SellerAutoSparesRequest(
      id: json['id']??0,
      status: json['status']??"",
      additionalNotes: json['additional_notes']??"",
      category: json['category']??"",
      createdAt: DateTime.parse(json['created_at']),
        autoSparesRequest: AutoSpares.fromJson(json['auto_spares_request'])
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
class RimTyreRequest {
  final int id;
  final DateTime createdAt;
  final String status;
  final String category;
  final RimTyre rimTyreRequest;
  final String? additionalNotes;

  RimTyreRequest({
    required this.id,
    required this.status,
    required this.category,
    required this.createdAt,
    required this.rimTyreRequest,
     this.additionalNotes
  });

  factory RimTyreRequest.fromJson(Map<String, dynamic> json) {
    return RimTyreRequest(
      id: json['id'],
      status: json['status']??"",
      category: json['category']??"",
      createdAt: DateTime.parse(json['created_at']),
      rimTyreRequest:  RimTyre.fromJson(json['list_of_request']),
      additionalNotes: json['additional_notes']??"",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
    };
  }
}