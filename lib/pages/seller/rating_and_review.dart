import 'package:bidr/constants/Constants.dart';
import 'package:bidr/global_values.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/review_item.dart';
import '../../services/rewards_service.dart';

class RatingReviewWidget extends StatefulWidget {
  final String sellerId;
  final Function(String uuid, String response)? onRespond;
  final Function(String uuid, String reportType, String details)? onReport;

  const RatingReviewWidget({
    Key? key,
    required this.sellerId,
    this.onRespond,
    this.onReport,
  }) : super(key: key);

  @override
  _RatingReviewWidgetState createState() => _RatingReviewWidgetState();
}

class _RatingReviewWidgetState extends State<RatingReviewWidget> {
  int currentPage = 1;
  final int itemsPerPage = 4;
  List<ReviewItem> reviews = [];
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? summary;

  List<ReviewItem> get currentPageReviews {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > reviews.length) endIndex = reviews.length;
    return reviews.sublist(startIndex, endIndex);
  }

  int get totalPages => (reviews.length / itemsPerPage).ceil();

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  /*Future<void> _loadReviews() async {
    final result = await RewardsService.getProductReviews(widget.productId);
    if (result['success']) {
      setState(() {
        // Update your reviews list with the fetched data
        // Example: _reviews = result['data']['reviews'];
      });
    }
  }*/

  Future<void> _fetchReviews() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Fetch reviews from API
      final String baseUrl = GlobalVariables.reviewsServiceUrl;
      final response = await http
          .get(
            Uri.parse('${baseUrl}api/reviews/'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("ffgghhg ${responseData}");

        // Handle response based on format
        List<dynamic> reviewsList;
        if (responseData is Map && responseData.containsKey('results')) {
          // Django REST Framework paginated response
          reviewsList = responseData['results'] as List;
        } else if (responseData is List) {
          // Direct list response
          reviewsList = responseData;
        } else if (responseData is Map && responseData.containsKey('reviews')) {
          // Custom format with reviews key
          reviewsList = responseData['reviews'] as List;
        } else {
          reviewsList = [];
        }

        final fetchedReviews = reviewsList
            .map((json) => ReviewItem.fromJson(json as Map<String, dynamic>))
            .toList();

        // Calculate summary from fetched reviews
        double averageRating = 0.0;
        if (fetchedReviews.isNotEmpty) {
          double sum = fetchedReviews.fold(
            0.0,
            (sum, review) => sum + review.rating,
          );
          averageRating = sum / fetchedReviews.length;
        }

        setState(() {
          reviews = fetchedReviews;
          summary = {
            'total_reviews': fetchedReviews.length,
            'total_ratings': fetchedReviews.length,
            'average_rating': averageRating.toStringAsFixed(1),
          };
          isLoading = false;
        });

        // Optional: Save to local storage for offline access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('reviews_list', json.encode(reviewsList));
        await prefs.setInt('total_reviews', fetchedReviews.length);
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Try loading from local storage as fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        final reviewsJsonString = prefs.getString('reviews_list');

        if (reviewsJsonString != null) {
          final reviewsJsonList = json.decode(reviewsJsonString) as List;
          final localReviews = reviewsJsonList
              .map((json) => ReviewItem.fromJson(json as Map<String, dynamic>))
              .toList();

          double averageRating = 0.0;
          if (localReviews.isNotEmpty) {
            double sum = localReviews.fold(
              0.0,
              (sum, review) => sum + review.rating,
            );
            averageRating = sum / localReviews.length;
          }

          setState(() {
            reviews = localReviews;
            summary = {
              'total_reviews': localReviews.length,
              'total_ratings': localReviews.length,
              'average_rating': averageRating.toStringAsFixed(1),
            };
            isLoading = false;
            error = 'Using offline data. Network error: $e';
          });
        } else {
          setState(() {
            error = 'Error loading reviews: $e';
            isLoading = false;
          });
        }
      } catch (localError) {
        setState(() {
          error = 'Error loading reviews: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _respondToReview(String uuid, String response) async {
    try {
      final String baseUrl = GlobalVariables.reviewsServiceUrl;

      // Get the seller's auth_user_uid - you may need to get this from your auth service
      // For now, using a placeholder - replace with actual seller UUID
      final String authUserUid = widget.sellerId; // Or get from auth service

      final apiResponse = await http
          .post(
            Uri.parse('${baseUrl}api/reviews/router/respond/'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'uuid': uuid,
              'response': response,
              'auth_user_uid': authUserUid,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (apiResponse.statusCode == 200 || apiResponse.statusCode == 201) {
        // Parse the response
        final responseData = json.decode(apiResponse.body);

        // Handle successful response
        widget.onRespond?.call(uuid, response);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Response sent successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the reviews list to show the new response
        _fetchReviews();
      } else {
        final errorData = json.decode(apiResponse.body);
        throw Exception(
          errorData['error'] ??
              'Failed to send response: ${apiResponse.statusCode}',
        );
      }
    } catch (e) {
      print('Error responding to review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending response: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reportReview(
    String uuid,
    String reportType,
    String details,
  ) async {
    try {
      final String baseUrl = GlobalVariables.reviewsServiceUrl;
      final apiResponse = await http
          .post(
            Uri.parse('$baseUrl/api/ratings/report/'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'uuid': uuid,
              'reportType': reportType,
              'details': details,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (apiResponse.statusCode == 200) {
        // Handle successful report
        widget.onReport?.call(uuid, reportType, details);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
      } else {
        throw Exception('Failed to submit report: ${apiResponse.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting report: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              error!,
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchReviews,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (reviews.isEmpty) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Constants.ctaColorLight.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.star_border_rounded,
                    size: 60,
                    color: Constants.ctaColorLight,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Reviews Yet',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your ratings and reviews will appear here\nonce customers start sharing their feedback',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Constants.ctaColorLight,
                    ),
                    SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Deliver great service to earn positive reviews',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Summary information
        if (summary != null) _buildSummaryCard(),
        // Reviews List
        const SizedBox(height: 16),
        Row(
          children: [
            ...currentPageReviews.map((review) => _buildReviewCard(review)),
          ],
        ),
        const SizedBox(height: 20),
        // Pagination
        if (totalPages > 1) _buildPagination(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constants.ctaColorLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Constants.ctaColorLight.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Reviews',
            summary!['total_reviews'].toString(),
          ),
          _buildSummaryItem(
            'Total Ratings',
            summary!['total_ratings'].toString(),
          ),
          _buildSummaryItem(
            'Average Rating',
            '${summary!['average_rating']} ★',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Constants.ctaColorLight,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey.shade600),
        ),
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
              Container(height: 10, width: 1.8, color: Constants.ctaColorLight),
              SizedBox(width: 4),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'UUID: ${review.uuid.length >= 8 ? review.uuid.substring(0, 8) : review.uuid}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Constants.ftaColorLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Customer name and description
          Row(
            children: [
              Expanded(
                child: Text(
                  review.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
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
                color: index < review.rating
                    ? Constants.ctaColorLight
                    : Colors.grey.shade300,
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
              style: GoogleFonts.manrope(fontSize: 13, color: Colors.black87),
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
                  child: Text(
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
          onPressed: currentPage > 1
              ? () => setState(() => currentPage--)
              : null,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
          onPressed: currentPage < totalPages
              ? () => setState(() => currentPage++)
              : null,
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
                      borderSide: BorderSide(color: Constants.ctaColorLight),
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
                        Navigator.of(context).pop();
                        _respondToReview(review.uuid, messageController.text);
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
                    child: Text(
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
    final TextEditingController inappropriateController =
        TextEditingController();
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
                    _buildReportOption(
                      'Spam',
                      spamController,
                      selectedReportType,
                      setState,
                    ),
                    const SizedBox(height: 16),
                    _buildReportOption(
                      'Inappropriate Content',
                      inappropriateController,
                      selectedReportType,
                      setState,
                    ),
                    const SizedBox(height: 16),
                    _buildReportOption(
                      'Other',
                      otherController,
                      selectedReportType,
                      setState,
                    ),
                    const SizedBox(height: 24),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          String details = '';
                          if (selectedReportType == 'Spam')
                            details = spamController.text;
                          else if (selectedReportType ==
                              'Inappropriate Content')
                            details = inappropriateController.text;
                          else if (selectedReportType == 'Other')
                            details = otherController.text;

                          if (selectedReportType.isNotEmpty) {
                            Navigator.of(context).pop();
                            _reportReview(
                              review.uuid,
                              selectedReportType,
                              details,
                            );
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
                        child: Text(
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

  Widget _buildReportOption(
    String title,
    TextEditingController controller,
    String selectedReportType,
    StateSetter setState,
  ) {
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
              borderSide: BorderSide(color: Constants.ctaColorLight),
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
  final String sellerId;

  const ReviewScreen({
    Key? key,
    this.sellerId = 'c97f2da1-810c-4f86-98b4-18b722d5eecb', // Default seller ID
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RatingReviewWidget(
      sellerId: sellerId,
      onRespond: (uuid, response) {
        print('Responding to $uuid: $response');
      },
      onReport: (uuid, reportType, details) {
        print('Reporting $uuid for $reportType: $details');
      },
    );
  }
}
