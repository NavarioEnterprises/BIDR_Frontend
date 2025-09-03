class Order {
  final String vendorName;
  final String? productId;
  final String? sellerId;
  final String? requestId;
  final String product;
  final String vehicle;
  final String orderNumber;
  final String status;
  final DateTime dateTime;
  final double price;
  final double rating;
  final double distanceInKm;
  final String location;
  final List<OrderComment> comments;

  Order({
    required this.vendorName,
    required this.product,
    this.productId,
    this.sellerId,
    this.requestId,
    required this.vehicle,
    required this.orderNumber,
    required this.status,
    required this.dateTime,
    required this.price,
    required this.rating,
    required this.distanceInKm,
    required this.location,
    required this.comments,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    print("hghgjh $json");
    // Extract seller information from seller_id (can be either string or object)
    String vendorName = 'Unknown Vendor';

    final sellerId = json['seller_id'];
    if (sellerId != null) {
      if (sellerId is Map<String, dynamic>) {
        // Handle case where seller_id is an object
        final sellerName =
            '${sellerId['first_name'] ?? ''} ${sellerId['last_name'] ?? ''}'
                .trim();
        vendorName = sellerName.isNotEmpty
            ? sellerName
            : (sellerId['username'] ?? 'Unknown Vendor');
      } else if (sellerId is String) {
        // Handle case where seller_id is just a string UID
        vendorName = 'Seller ${sellerId.substring(0, 8)}...';
      }
    }

    // Extract buyer information from buyer_id (can be either string or object)
    final buyerId = json['buyer_id'];
    Map<String, dynamic>? buyerData;
    if (buyerId != null && buyerId is Map<String, dynamic>) {
      buyerData = buyerId;
    }

    return Order(
      vendorName: vendorName,
      product: json['request_title'] ?? json['product'] ?? 'Unknown Product',
      productId: json['product_id']?.toString(),
      sellerId: json['seller_id']?.toString(),
      requestId: json['request_id']?.toString(),
      vehicle: _extractVehicleInfo(json),
      orderNumber:
          json['order_number'] ?? json['orderNumber'] ?? 'Unknown Order',
      status: json['status_display'] ?? json['status'] ?? 'Unknown',
      dateTime: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : json['dateTime'] != null
          ? DateTime.tryParse(json['dateTime']) ?? DateTime.now()
          : json['date_time'] != null
          ? DateTime.tryParse(json['date_time']) ?? DateTime.now()
          : DateTime.now(),
      price:
          _parseDouble(json['total_amount']) ??
          _parseDouble(json['price']) ??
          0.0,
      rating: _parseDouble(json['rating']) ?? 0.0,
      distanceInKm:
          _parseDouble(json['distanceInKm']) ??
          _parseDouble(json['distance_km']) ??
          0.0,
      location: _extractLocation(json),
      comments: _extractComments(json),
    );
  }

  /// Helper method to safely parse double values from dynamic data
  /// Handles both num and String types
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static String _extractVehicleInfo(Map<String, dynamic> json) {
    // Try to extract vehicle info from request category or other fields
    final category = json['request_category'] ?? '';
    final title = json['request_title'] ?? '';

    if (category.toString().contains('VEHICLE')) {
      return title;
    }

    return json['vehicle'] ?? 'Unknown Vehicle';
  }

  static String _extractLocation(Map<String, dynamic> json) {
    // Try to extract location from seller data or other fields
    final sellerId = json['seller_id'];
    if (sellerId != null && sellerId is Map<String, dynamic>) {
      // If we have seller data object, try to extract location from it
      final location = sellerId['location'] ?? sellerId['address'];
      if (location != null) return location.toString();
    }
    return json['location'] ?? 'Location not specified';
  }

  static List<OrderComment> _extractComments(Map<String, dynamic> json) {
    if (json['comments'] != null) {
      return (json['comments'] as List)
          .map((c) => OrderComment.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    // Create a default comment from available data
    final paymentMethod = json['payment_method'];
    final trackingNumber = json['tracking_number'];
    List<OrderComment> comments = [];

    if (paymentMethod != null) {
      comments.add(
        OrderComment(
          commentId: '1',
          description: 'Payment method: $paymentMethod',
        ),
      );
    }

    if (trackingNumber != null) {
      comments.add(
        OrderComment(commentId: '2', description: 'Tracking: $trackingNumber'),
      );
    }

    if (comments.isEmpty) {
      comments.add(
        OrderComment(commentId: '0', description: 'No additional comments'),
      );
    }

    return comments;
  }

  Map<String, dynamic> toJson() => {
    'vendor_name': vendorName,
    'product': product,
    'product_id': productId,
    'seller_id': sellerId,
    'request_id': requestId,
    'vehicle': vehicle,
    'order_number': orderNumber,
    'status': status,
    'date_time': dateTime.toIso8601String(),
    'price': price,
    'rating': rating,
    'distance_km': distanceInKm,
    'location': location,
    'comments': comments.map((c) => c.toJson()).toList(),
  };
}

class OrderComment {
  final String commentId;
  final String description;

  OrderComment({required this.commentId, required this.description});

  factory OrderComment.fromJson(Map<String, dynamic> json) => OrderComment(
    commentId: json['commentId'] ?? json['comment_id'] ?? 'unknown',
    description: json['description'] ?? 'No description available',
  );

  Map<String, dynamic> toJson() => {
    'comment_id': commentId,
    'description': description,
  };
}
