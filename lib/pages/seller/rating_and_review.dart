

import 'package:bidr/constants/Constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReviewItem {
  final String uuid;
  final String customerName;
  final String description;
  final int rating;
  final String comment;

  ReviewItem({
    required this.uuid,
    required this.customerName,
    required this.description,
    required this.rating,
    required this.comment,
  });
}

class RatingReviewWidget extends StatefulWidget {
  final List<ReviewItem> reviews;
  final Function(String uuid, String response)? onRespond;
  final Function(String uuid, String reportType, String details)? onReport;

  const RatingReviewWidget({
    Key? key,
    required this.reviews,
    this.onRespond,
    this.onReport,
  }) : super(key: key);

  @override
  _RatingReviewWidgetState createState() => _RatingReviewWidgetState();
}

class _RatingReviewWidgetState extends State<RatingReviewWidget> {
  int currentPage = 1;
  final int itemsPerPage = 4;

  List<ReviewItem> get currentPageReviews {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > widget.reviews.length) endIndex = widget.reviews.length;
    return widget.reviews.sublist(startIndex, endIndex);
  }

  int get totalPages => (widget.reviews.length / itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Reviews List
        const SizedBox(height: 16),
        Row(
          children: [
            ...currentPageReviews.map((review) => _buildReviewCard(review)),
          ],
        ),
        const SizedBox(height: 20),
        // Pagination
        _buildPagination(),
      ],
    );
  }

  Widget _buildReviewCard(ReviewItem review) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Constants.ftaColorLight.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with UUID
          Row(
            children: [
              Container(height: 10,width: 1.8,color: Constants.ctaColorLight,),
              SizedBox(width: 4,),
              Text(
                'UUID: ${review.uuid}',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Constants.ftaColorLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Customer name and description
          Text(
            review.customerName,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Description: ${review.description}',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          // Star rating
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                size: 16,
                color: index < review.rating ? Constants.ctaColorLight : Colors.grey.shade300,
              );
            }),
          ),
          const SizedBox(height: 12),
          // Comment
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Comment: ${review.comment}',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showRespondDialog(review),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ctaColorLight,
                    foregroundColor: Constants.ftaColorLight,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Respond',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showReportDialog(review),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ftaColorLight,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child:  Text(
                    'Report',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous button
        IconButton(
          onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
          icon: const Icon(Icons.chevron_left),
          color: Colors.grey.shade600,
        ),
        // Page numbers
        ...List.generate(totalPages, (index) {
          int pageNumber = index + 1;
          bool isCurrentPage = pageNumber == currentPage;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: isCurrentPage
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Constants.ctaColorLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                pageNumber.toString(),
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
                : TextButton(
              onPressed: () => setState(() => currentPage = pageNumber),
              child: Text(
                pageNumber.toString(),
                style: GoogleFonts.manrope(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
        // Next button
        IconButton(
          onPressed: currentPage < totalPages ? () => setState(() => currentPage++) : null,
          icon: const Icon(Icons.chevron_right),
          color: Colors.grey.shade600,
        ),
      ],
    );
  }

  void _showRespondDialog(ReviewItem review) {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      'Respond',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.grey.shade600,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Message field
                 Text(
                  'Message',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter Message',
                    hintStyle: GoogleFonts.manrope(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(36),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(36),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(36),
                      borderSide:  BorderSide(color: Constants.ctaColorLight),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 24),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (messageController.text.isNotEmpty) {
                        widget.onRespond?.call(review.uuid, messageController.text);
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:  Text(
                      'Submit',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportDialog(ReviewItem review) {
    String selectedReportType = '';
    final TextEditingController spamController = TextEditingController();
    final TextEditingController inappropriateController = TextEditingController();
    final TextEditingController otherController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(
                          'Report',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          color: Colors.grey.shade600,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Report options
                    _buildReportOption('Spam', spamController, selectedReportType, setState),
                    const SizedBox(height: 16),
                    _buildReportOption('Inappropriate Content', inappropriateController, selectedReportType, setState),
                    const SizedBox(height: 16),
                    _buildReportOption('Other', otherController, selectedReportType, setState),
                    const SizedBox(height: 24),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          String details = '';
                          if (selectedReportType == 'Spam') details = spamController.text;
                          else if (selectedReportType == 'Inappropriate Content') details = inappropriateController.text;
                          else if (selectedReportType == 'Other') details = otherController.text;

                          if (selectedReportType.isNotEmpty) {
                            widget.onReport?.call(review.uuid, selectedReportType, details);
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.ctaColorLight,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(36),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:  Text(
                          'Submit',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportOption(String title, TextEditingController controller, String selectedReportType, StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onTap: () => setState(() => selectedReportType = title),
          decoration: InputDecoration(
            hintText: 'Enter $title',
            hintStyle: GoogleFonts.manrope(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(36),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:  BorderSide(color: Constants.ctaColorLight),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}

// Example usage
class ReviewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<ReviewItem> sampleReviews = [
      ReviewItem(
        uuid: '000100',
        customerName: 'Mr. Joseph Anthony',
        description: 'Fuel Filter, Toyota Corolla, 2016',
        rating: 5,
        comment: 'Good Service',
      ),
      ReviewItem(
        uuid: '000180',
        customerName: 'Benjamin Thompson',
        description: 'Tail light, BMW M3, 2024',
        rating: 5,
        comment: 'Good Service',
      ),
      ReviewItem(
        uuid: '003100',
        customerName: 'Miss Jane Smith',
        description: 'Fuel Filter, Toyota Corolla, 2016',
        rating: 5,
        comment: 'Good Service',
      ),
      ReviewItem(
        uuid: '000100',
        customerName: 'Mr. Joseph Anthony',
        description: 'Fuel Filter, Toyota Corolla, 2016',
        rating: 5,
        comment: 'Good Service',
      ),

    ];

    return RatingReviewWidget(
      reviews: sampleReviews,
      onRespond: (uuid, response) {
        print('Responding to $uuid: $response');
      },
      onReport: (uuid, reportType, details) {
        print('Reporting $uuid for $reportType: $details');
      },
    );
  }
}