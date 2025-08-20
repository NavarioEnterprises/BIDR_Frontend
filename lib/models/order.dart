
class Order {
  final String vendorName;
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

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    vendorName: json['vendor_name'],
    product: json['product'],
    vehicle: json['vehicle'],
    orderNumber: json['order_number'],
    status: json['status'],
    dateTime: DateTime.parse(json['date_time']),
    price: (json['price'] as num).toDouble(),
    rating: (json['rating'] as num).toDouble(),
    distanceInKm: (json['distance_km'] as num).toDouble(),
    location: json['location'],
    comments: (json['comments'] as List)
        .map((c) => OrderComment.fromJson(c))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'vendor_name': vendorName,
    'product': product,
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

  OrderComment({
    required this.commentId,
    required this.description,
  });

  factory OrderComment.fromJson(Map<String, dynamic> json) => OrderComment(
    commentId: json['comment_id'],
    description: json['description'],
  );

  Map<String, dynamic> toJson() => {
    'comment_id': commentId,
    'description': description,
  };
}
