import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/Constants.dart';

class RequestInfoWidget extends StatelessWidget {
  final Map<String, dynamic> request;

  const RequestInfoWidget({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final requestId = request['request_id']?.toString() ?? '';
    final title = request['title']?.toString() ?? '';
    final description = request['description']?.toString() ?? '';
    final createdAt = request['created_at']?.toString() ?? '';
    final category = request['category']?.toString() ?? '';
    final vehicleSparesSummary =
        request['vehicle_spares_summary']?.toString() ?? '';
    final tyresRimsSummary = request['tyres_rims_summary']?.toString() ?? '';
    final electronicssSummary =
        request['consumer_electronics_summary']?.toString() ?? '';
    final budget = request['budget']?.toString() ?? '';
    final maxBudget = request['max_budget']?.toString() ?? '';
    final urgencyTimeline = request['urgency_timeline']?.toString() ?? '';
    final images = request['images'] ?? [];
    final quantity = request['quantity']?.toString() ?? '';
    final conditionPreference =
        request['condition_preference']?.toString() ?? '';
    final productSpecifications = request['product_specifications'] ?? {};
    final vehicleSparesData = request['vehicle_spares_data'] ?? {};
    final electronicsData = request['consumer_electronics_data'] ?? {};
    final tyresRimsData = request['vehicle_tyres_rims_data'] ?? {};

    // Format the request number for display
    final requestNumber = requestId.substring(0, 6).toUpperCase();

    if (category == 'VEHICLE_SPARES') {
      // Use the exact design from _SparesDetailScreenState
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading:IconButton(
            onPressed:(){
              Navigator.pop(context);
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Constants.ftaColorLight,
              elevation: 5,
              shadowColor: Colors.black54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              CupertinoIcons.back,
              color: Constants.ftaColorLight,
            ),
          ),
          title: Text(
            "Request Details",
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,

          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Request #$requestNumber Information',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Constants.ctaColorLight,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle Details Card
                      _buildVehicleDetailCard(
                        "Vehicle Details",
                        Constants.ctaColorLight,
                        vehicleSparesData.isNotEmpty
                            ? vehicleSparesData
                            : {
                          'VIN Number': 'Not specified',
                          'Manufacturer': 'Not specified',
                          'Make & Model': title.isNotEmpty
                              ? title
                              : 'Not specified',
                          'Year': '',
                          'Type': 'Not specified',
                          'Condition':
                          conditionPreference.isNotEmpty
                              ? conditionPreference
                              .replaceAll('_', ' ')
                              .toLowerCase()
                              .split(' ')
                              .map(
                                (word) => word.isNotEmpty
                                ? '${word[0].toUpperCase()}${word.substring(1)}'
                                : word,
                          )
                              .join(' ')
                              : 'Not specified',
                        },
                      ),
                      SizedBox(height: 16),

                      // Part Details Card
                      _buildVehicleDetailCard(
                        "Part Details",
                        Colors.orange,
                        {
                          'Part Name/Description':
                          vehicleSparesSummary.isNotEmpty
                              ? vehicleSparesSummary
                              : (title.isNotEmpty
                              ? title
                              : 'Not specified'),
                          'Quantity': quantity.isNotEmpty
                              ? quantity
                              : 'Not specified',
                          'Budget': budget.isNotEmpty
                              ? 'R$budget'
                              : 'Not specified',
                          'Urgency': urgencyTimeline.isNotEmpty
                              ? urgencyTimeline
                              .replaceAll('_', ' ')
                              .toLowerCase()
                              .split(' ')
                              .map(
                                (word) => word.isNotEmpty
                                ? '${word[0].toUpperCase()}${word.substring(1)}'
                                : word,
                          )
                              .join(' ')
                              : 'Not specified',
                          'Description': description.isNotEmpty
                              ? description
                              : 'No description provided',
                          'Product Images': images.isNotEmpty
                              ? '${images.length} image(s) available'
                              : 'No images',
                        },
                      ),
                      SizedBox(height: 16),

                      // More Details Card
                      _buildVehicleDetailCard(
                        "More Details",
                        Colors.orange,
                        {
                          ...productSpecifications,
                          'Request ID': requestNumber,
                          'Created': createdAt.isNotEmpty
                              ? DateTime.tryParse(
                            createdAt,
                          )?.toString().split(' ')[0] ??
                              createdAt
                              : 'Not specified',
                          'Category': category
                              .replaceAll('_', ' ')
                              .toLowerCase()
                              .split(' ')
                              .map(
                                (word) => word.isNotEmpty
                                ? '${word[0].toUpperCase()}${word.substring(1)}'
                                : word,
                          )
                              .join(' '),
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // For other categories, use simplified design
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading:IconButton(
            onPressed:(){
              Navigator.pop(context);
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Constants.ftaColorLight,
              elevation: 5,
              shadowColor: Colors.black54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              CupertinoIcons.back,
              color: Constants.ftaColorLight,
            ),
          ),
          title: Text(
            "Request Details",
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Request Information',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Request summary card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.orange,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REQUEST #$requestNumber',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              title.isNotEmpty
                                  ? title
                                  : (description.isNotEmpty
                                  ? description
                                  : 'No title provided'),
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                category
                                    .replaceAll('_', ' ')
                                    .toLowerCase()
                                    .split(' ')
                                    .map(
                                      (word) => word.isNotEmpty
                                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                                      : word,
                                )
                                    .join(' '),
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Product Details (changed from Row to Column)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Details',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildDetailItem(
                            'Category',
                            category.isNotEmpty
                                ? category
                                .replaceAll('_', ' ')
                                .toLowerCase()
                                .split(' ')
                                .map(
                                  (word) => word.isNotEmpty
                                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                                  : word,
                            )
                                .join(' ')
                                : 'Not specified',
                          ),
                          if (electronicsData['brand'] != null)
                            _buildDetailItem(
                              'Brand',
                              electronicsData['brand']?.toString() ??
                                  'Not specified',
                            ),
                          if (electronicsData['model'] != null)
                            _buildDetailItem(
                              'Model',
                              electronicsData['model']?.toString() ??
                                  'Not specified',
                            ),
                          if (tyresRimsData['tyre_brand'] != null)
                            _buildDetailItem(
                              'Tyre Brand',
                              tyresRimsData['tyre_brand']
                                  ?.toString() ??
                                  'Not specified',
                            ),
                          _buildDetailItem(
                            'Quantity',
                            quantity.isNotEmpty
                                ? quantity
                                : 'Not specified',
                          ),
                          if (conditionPreference.isNotEmpty)
                            _buildDetailItem(
                              'Condition',
                              conditionPreference
                                  .replaceAll('_', ' ')
                                  .toLowerCase()
                                  .split(' ')
                                  .map(
                                    (word) => word.isNotEmpty
                                    ? '${word[0].toUpperCase()}${word.substring(1)}'
                                    : word,
                              )
                                  .join(' '),
                            ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Budget and Timeline
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget and Timeline',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildDetailItem(
                            'Budget',
                            budget.isNotEmpty
                                ? 'R$budget'
                                : 'Not specified',
                          ),
                          if (maxBudget.isNotEmpty)
                            _buildDetailItem(
                              'Max Budget',
                              'R$maxBudget',
                            ),
                          _buildDetailItem(
                            'Urgency Required',
                            urgencyTimeline.isNotEmpty
                                ? urgencyTimeline
                                .replaceAll('_', ' ')
                                .toLowerCase()
                                .split(' ')
                                .map(
                                  (word) => word.isNotEmpty
                                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                                  : word,
                            )
                                .join(' ')
                                : 'Not specified',
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Features and Specifications
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Features and Specifications',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(height: 12),
                          if (productSpecifications.isNotEmpty)
                            ...productSpecifications.entries
                                .map(
                                  (entry) => _buildDetailItem(
                                entry.key
                                    .toString()
                                    .replaceAll('_', ' ')
                                    .split(' ')
                                    .map(
                                      (word) => word.isNotEmpty
                                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                                      : word,
                                )
                                    .join(' '),
                                entry.value.toString(),
                              ),
                            )
                                .toList(),
                          if (description.isNotEmpty)
                            _buildDetailItem(
                              'Description',
                              description,
                            ),
                          if (images.isNotEmpty)
                            _buildDetailItem(
                              'Images',
                              '${images.length} image(s) available',
                            ),
                        ],
                      ),

                      if (description.isNotEmpty) ...[
                        SizedBox(height: 24),
                        Text(
                          'Additional Notes',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          description,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailCard(
      String title,
      Color titleColor,
      Map<String, dynamic> data,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: titleColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ),

          // Card content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 12),
                      Text(
                        entry.key
                            .toString()
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map(
                              (word) => word.isNotEmpty
                              ? '${word[0].toUpperCase()}${word.substring(1)}'
                              : word,
                        )
                            .join(' '),
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        entry.value?.toString() ?? 'Not specified',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
