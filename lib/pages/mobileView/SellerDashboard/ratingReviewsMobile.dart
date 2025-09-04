import 'package:bidr/constants/Constants.dart';
import 'package:bidr/global_values.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/review_item.dart';
import '../breakpoints.dart';


class RatingReviewMobile extends StatefulWidget {
  final String sellerId;
  final Function(String uuid, String response)? onRespond;
  final Function(String uuid, String reportType, String details)? onReport;

  const RatingReviewMobile({
    Key? key,
    required this.sellerId,
    this.onRespond,
    this.onReport,
  }) : super(key: key);

  @override
  _RatingReviewMobileState createState() => _RatingReviewMobileState();
}

class _RatingReviewMobileState extends State<RatingReviewMobile> {
  int currentPage = 1;
  final int itemsPerPage = 2;
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
        Uri.parse('${baseUrl}api/reviews/router/reviews/'),
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
            content: Text(responseData['message'] ?? 'Response sent successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the reviews list to show the new response
        _fetchReviews();
      } else {
        final errorData = json.decode(apiResponse.body);
        throw Exception(errorData['error'] ?? 'Failed to send response: ${apiResponse.statusCode}');
      }
    } catch (e) {
      print('Error responding to review: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
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
    return ResponsiveBuilder(
      builder: (context, typography, spacing) {
        if (isLoading) {
          return Center(
            child: ResponsiveContainer(
              paddingType: SpacingType.large,
              child: CircularProgressIndicator(
                color: Constants.ctaColorLight,
              ),
            ),
          );
        }

        if (error != null) {
          return Center(
            child: ResponsiveContainer(
              paddingType: SpacingType.large,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: typography.large + 10,
                    color: Colors.grey.shade600,
                  ),
                  ResponsiveGap(type: SpacingType.medium),
                  ResponsiveText(
                    text: error!,
                    type: TextType.medium,
                    color: Colors.grey.shade600,
                    textAlign: TextAlign.center,
                  ),
                  ResponsiveGap(type: SpacingType.medium),
                  ElevatedButton(
                    onPressed: _fetchReviews,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.paddingLarge,
                        vertical: spacing.paddingMedium,
                      ),
                    ),
                    child: ResponsiveText(
                      text: 'Retry',
                      type: TextType.medium,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (reviews.isEmpty) {
          return Center(
            child: ResponsiveContainer(
              paddingType: SpacingType.large,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.star_border_rounded,
                        size: 40,
                        color: Constants.ctaColorLight,
                      ),
                    ),
                  ),
                  ResponsiveGap(type: SpacingType.large),
                  ResponsiveText(
                    text: 'No Reviews Yet',
                    type: TextType.heading,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                  ResponsiveGap(type: SpacingType.small),
                  ResponsiveText(
                    text: 'Your ratings and reviews will appear here\nonce customers start sharing their feedback',
                    type: TextType.normal,
                    color: Colors.grey[600],
                    textAlign: TextAlign.center,
                  ),
                  ResponsiveGap(type: SpacingType.large),
                  Container(
                    padding: EdgeInsets.all(spacing.paddingMedium),
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
                          size: typography.normal + 4,
                          color: Constants.ctaColorLight,
                        ),
                        SizedBox(width: spacing.spacingSmall),
                        Flexible(
                          child: ResponsiveText(
                            text: 'Deliver great service to earn positive reviews',
                            type: TextType.normal,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
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

        return SingleChildScrollView(
          child: ResponsiveContainer(
            paddingType: SpacingType.medium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary information
                if (summary != null) _buildSummaryCard(typography, spacing),
                if (summary != null) ResponsiveGap(type: SpacingType.medium),
                // Reviews List - Vertical Layout with max 2 items
                _buildVerticalReviewsList(typography, spacing),
                ResponsiveGap(type: SpacingType.medium),
                // Pagination
                if (totalPages > 1) _buildPagination(typography, spacing),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(TypographyConfig typography, SpacingConfig spacing) {
    return Container(
      padding: EdgeInsets.all(spacing.paddingMedium),
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
            typography,
          ),
          _buildSummaryItem(
            'Total Ratings',
            summary!['total_ratings'].toString(),
            typography,
          ),
          _buildSummaryItem(
            'Average Rating',
            '${summary!['average_rating']} ★',
            typography,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, TypographyConfig typography) {
    return Column(
      children: [
        ResponsiveText(
          text: value,
          type: TextType.medium,
          color: Constants.ctaColorLight,
          fontWeight: FontWeight.bold,
        ),
        ResponsiveText(
          text: label,
          type: TextType.normal,
          color: Colors.grey.shade600,
        ),
      ],
    );
  }

  Widget _buildVerticalReviewsList(TypographyConfig typography, SpacingConfig spacing) {
    return Column(
      children: currentPageReviews
          .map((review) => _buildReviewCard(review, typography, spacing))
          .toList(),
    );
  }

  Widget _buildReviewCard(ReviewItem review, TypographyConfig typography, SpacingConfig spacing) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: spacing.marginMedium),
      padding: EdgeInsets.all(spacing.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Constants.ftaColorLight.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Container(
                height: 10,
                width: 2,
                color: Constants.ctaColorLight,
              ),
              SizedBox(width: spacing.spacingSmall),
              Expanded(
                child: ResponsiveText(
                  text: 'ID: ${review.uuid.length >= 8 ? review.uuid.substring(0, 8) : review.uuid}',
                  type: TextType.normal,
                  color: Constants.ftaColorLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ResponsiveGap(type: SpacingType.small),
          // Customer name
          ResponsiveText(
            text: review.customerName,
            type: TextType.medium,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          ResponsiveGap(type: SpacingType.small),
          // Description
          ResponsiveText(
            text: review.description,
            type: TextType.normal,
            color: Colors.grey.shade600,
          ),
          ResponsiveGap(type: SpacingType.small),
          // Star rating
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                size: typography.normal,
                color: index < review.rating
                    ? Constants.ctaColorLight
                    : Colors.grey.shade300,
              );
            }),
          ),
          ResponsiveGap(type: SpacingType.small),
          // Comment
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacing.paddingSmall),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ResponsiveText(
              text: review.comment,
              type: TextType.normal,
              color: Colors.black87,
            ),
          ),
          ResponsiveGap(type: SpacingType.medium),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showRespondDialog(review, typography, spacing),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ctaColorLight,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: spacing.paddingSmall,
                    ),
                  ),
                  child: ResponsiveText(
                    text: 'Respond',
                    type: TextType.normal,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: spacing.spacingSmall),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showReportDialog(review, typography, spacing),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: spacing.paddingSmall,
                    ),
                  ),
                  child: ResponsiveText(
                    text: 'Report',
                    type: TextType.normal,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(TypographyConfig typography, SpacingConfig spacing) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: spacing.paddingSmall,
        horizontal: spacing.paddingMedium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: currentPage > 1
                ? () => setState(() => currentPage--)
                : null,
            icon: const Icon(Icons.chevron_left),
            color: currentPage > 1 ? Constants.ctaColorLight : Colors.grey.shade400,
            style: IconButton.styleFrom(
              backgroundColor: currentPage > 1 
                  ? Constants.ctaColorLight.withOpacity(0.1)
                  : Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(width: spacing.spacingSmall),
          // Page info
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.paddingMedium,
              vertical: spacing.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: Constants.ctaColorLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Constants.ctaColorLight.withOpacity(0.3),
              ),
            ),
            child: ResponsiveText(
              text: '$currentPage of $totalPages',
              type: TextType.normal,
              color: Constants.ctaColorLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: spacing.spacingSmall),
          // Next button
          IconButton(
            onPressed: currentPage < totalPages
                ? () => setState(() => currentPage++)
                : null,
            icon: const Icon(Icons.chevron_right),
            color: currentPage < totalPages ? Constants.ctaColorLight : Colors.grey.shade400,
            style: IconButton.styleFrom(
              backgroundColor: currentPage < totalPages 
                  ? Constants.ctaColorLight.withOpacity(0.1)
                  : Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRespondDialog(ReviewItem review, TypographyConfig typography, SpacingConfig spacing) {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            padding: EdgeInsets.all(spacing.paddingMedium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ResponsiveText(
                      text: 'Respond to Review',
                      type: TextType.subHeading,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
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
                ResponsiveGap(type: SpacingType.medium),
                // Message field
                ResponsiveText(
                  text: 'Your Response',
                  type: TextType.medium,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                ResponsiveGap(type: SpacingType.small),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  style: TextStyle(
                    fontSize: typography.normal,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your response to this review...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: typography.normal,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Constants.ctaColorLight),
                    ),
                    contentPadding: EdgeInsets.all(spacing.paddingMedium),
                  ),
                ),
                ResponsiveGap(type: SpacingType.medium),
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
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: spacing.paddingMedium,
                      ),
                    ),
                    child: ResponsiveText(
                      text: 'Send Response',
                      type: TextType.medium,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  void _showReportDialog(ReviewItem review, TypographyConfig typography, SpacingConfig spacing) {
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                padding: EdgeInsets.all(spacing.paddingMedium),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ResponsiveText(
                          text: 'Report Review',
                          type: TextType.subHeading,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
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
                    ResponsiveGap(type: SpacingType.medium),
                    // Report options
                    _buildReportOption(
                      'Spam',
                      spamController,
                      selectedReportType,
                      setState,
                      typography,
                      spacing,
                    ),
                    ResponsiveGap(type: SpacingType.small),
                    _buildReportOption(
                      'Inappropriate Content',
                      inappropriateController,
                      selectedReportType,
                      setState,
                      typography,
                      spacing,
                    ),
                    ResponsiveGap(type: SpacingType.small),
                    _buildReportOption(
                      'Other',
                      otherController,
                      selectedReportType,
                      setState,
                      typography,
                      spacing,
                    ),
                    ResponsiveGap(type: SpacingType.medium),
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
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: spacing.paddingMedium,
                          ),
                        ),
                        child: ResponsiveText(
                          text: 'Submit Report',
                          type: TextType.medium,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
      TypographyConfig typography,
      SpacingConfig spacing,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          text: title,
          type: TextType.medium,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        ResponsiveGap(type: SpacingType.small),
        TextField(
          controller: controller,
          onTap: () => setState(() => selectedReportType = title),
          style: TextStyle(
            fontSize: typography.normal,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Describe $title details...',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: typography.normal,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            contentPadding: EdgeInsets.all(spacing.paddingSmall),
          ),
        ),
      ],
    );
  }
}

// Example usage
class ReviewMobile extends StatelessWidget {
  final String sellerId;

  const ReviewMobile({
    Key? key,
    this.sellerId = 'c97f2da1-810c-4f86-98b4-18b722d5eecb', // Default seller ID
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RatingReviewMobile(
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