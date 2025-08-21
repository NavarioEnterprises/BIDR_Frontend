import 'package:bidr/constants/Constants.dart';
import 'package:bidr/customWdget/customCard.dart';
import 'package:bidr/global_values.dart';
import 'package:bidr/pages/buyer_home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/request_models.dart';
import 'package:gradient_glow_border/gradient_glow_border.dart';

import 'buyer/account_management.dart';
import 'buyer/share_with_friends.dart';
import 'buyer/transaction_management.dart';
import 'group_chat.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
  }
  int dashboardIndex =0;
  bool isActive = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 68, right: 68),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: 1600),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Constants.ftaColorLight,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                          (){
                            dashboardIndex =0;
                    setState(() {

                    });
                  },HugeIcons.strokeRoundedDashboardSquare01, "Categories",dashboardIndex==0?true:false),
                  _buildNavItem((){
                    dashboardIndex =1;
                    setState(() {

                    });
                  },HugeIcons.strokeRoundedShare01, "Refer A Friend/Business", dashboardIndex==1?true:false),
                  _buildNavItem((){
                    dashboardIndex =2;
                    setState(() {

                    });
                  },HugeIcons.strokeRoundedTransaction, "Transaction Management", dashboardIndex==2?true:false),
                  _buildNavItem((){
                    dashboardIndex =3;
                    setState(() {

                    });
                  },HugeIcons.strokeRoundedUserAccount, "Account Management", dashboardIndex==3?true:false),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
        // Requests Grid
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0, right: 0),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 600,
                      constraints: BoxConstraints(maxWidth: 1400),
                      child: dashboardIndex ==0?
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildAllRequestCards(),
                      ):
                      dashboardIndex ==1?
                      Container(
                          width: MediaQuery.of(context).size.width*0.35,
                          height: 400,
                          child: ShareWidget()):
                      dashboardIndex ==2?
                      TransactionDashboard():
                      dashboardIndex ==3?
                      AccountManagementPage():
                      Container(),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                FooterSection(logo: "lib/assets/images/bidr_logo2.png")
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAllRequestCards() {
    List<Widget> cards = [];

    try {
      // Auto Spares Requests
      if (GlobalVariables.combinedRequest.autoSparesRequest.isNotEmpty) {
        final autoSpareCards = GlobalVariables.combinedRequest.autoSparesRequest.map((spare) {
          if (spare.status== "Waiting") {
            return _buildWaitingRequestCard(spare);
          } else {
            return _buildActiveRequestCard(spare);
          }
        }).toList();

        cards.addAll(autoSpareCards);
        if (autoSpareCards.isNotEmpty) cards.add(SizedBox(width: 22));
      }

      // Rim Tyre Requests
      if ( GlobalVariables.combinedRequest.rimTyreRequest.isNotEmpty) {
        final rimTyreCards = GlobalVariables.combinedRequest.rimTyreRequest.map((tyre) {
          if (tyre== "Waiting") {
            return _buildWaitingRequestCard(tyre);
          } else {
            return _buildActiveRequestCard(tyre);
          }
        }).toList();

        cards.addAll(rimTyreCards);
        if (rimTyreCards.isNotEmpty) cards.add(SizedBox(width: 22));
      }

      // Consumer Electronics Requests
      if ( GlobalVariables.combinedRequest.consumerElectronicsRequest.isNotEmpty) {
        final electronicsCards = GlobalVariables.combinedRequest.consumerElectronicsRequest.map((electronics) {
          if (electronics.status == "Waiting") {
            return _buildWaitingRequestCard(electronics);
          } else {
            return _buildActiveRequestCard(electronics);
          }
        }).toList();

        cards.addAll(electronicsCards);
        if (electronicsCards.isNotEmpty) cards.add(SizedBox(width: 22));
      }

    } catch (e) {
      print('Error building request cards: $e');
      cards.add(_buildErrorCard("Error loading requests"));
    }

    // Show empty state if no cards
    if (cards.isEmpty) {
      cards.add(_buildEmptyStateCard());
    }

    return cards;
  }


  Widget _buildErrorCard(String message) {
    return Container(
      padding: EdgeInsets.all(16),
      width: 350,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.manrope(
                color: Colors.red[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      padding: EdgeInsets.all(16),
      width: 350,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, color: Colors.grey[400], size: 48),
            SizedBox(height: 16),
            Text(
              "No requests available",
              style: GoogleFonts.manrope(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(VoidCallback voidCallBack, IconData icon, String title, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: voidCallBack,
          icon: Icon(
            icon, color: Colors.white, size: 22,
       ),
          label: Text(
            title,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (isActive) ...[
          SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  String _getRequestDescription(dynamic request) {
    try {
      if (request?.category == null) return "No description available";

      switch (request.category) {
        case "Vehicle Spares":
          if (request?.partDetails?.partName != null &&
              request?.vehicleDetails?.makeModel != null &&
              request?.vehicleDetails?.year != null) {
            return "${request.partDetails.partName}, ${request.vehicleDetails.makeModel}, ${request.vehicleDetails.year}";
          }
          return "Vehicle Spares Request";

        case "Vehicle Tyres and Rims":
          if (request?.productDetails != null) {
            final typeOfElectronics = request.productDetails.typeOfElectronics ?? "Electronics";
            final brandPreference = request.productDetails.brandPreference ?? "Various Brands";
            final modelSeries = request.productDetails.modelSeries;
            return "$typeOfElectronics, $brandPreference${modelSeries != null ? ', $modelSeries' : ''}";
          }
          return "Electronics Request";

        case "Consumer Electronics":
          if (request?.productDetails != null) {
            final tyreType = request.productDetails.tyreType ?? "Tyres";
            final tyreWidth = request.productDetails.tyreWidthMm ?? 0;
            final sidewall = request.productDetails.sidewallProfile ?? "";
            final rimDiameter = request.productDetails.wheelRimDiameterInches ?? "";
            final brand = request.moreFields?.preferredBrand ?? "Various Brands";
            return "$tyreType, $tyreWidth/$sidewall" + "R$rimDiameter, $brand";
          }
          return "Tyre/Rim Request";

        default:
          return "Request #${request.id ?? 'Unknown'}";
      }
    } catch (e) {
      print('Error getting description: $e');
      return "Request information unavailable";
    }
  }

  void _navigateToDetailScreen(dynamic request) {
    try {
      if (request?.category == null) {
        _showErrorSnackBar("Cannot open request details: Invalid request data");
        return;
      }

      switch (request.category) {
        case "Vehicle Spares":
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SparesDetailScreen(
                request: request,
                autoSpare: request.autoSpare,
                bids: request.sellerOffers ?? [],
              ),
            ),
          );
          break;

        case "Vehicle Tyres and Rims":
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RimTyreDetailScreen(
                request: request,
                rimTyre: request.rimTyre,
                bids: request.sellerOffers ?? [],
              ),
            ),
          );
          break;

        case "Consumer Electronics":
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConsumerElectronicsDetailScreen(
                request: request,
                consumerElectronics: request.consumerElectronics,
                bids: request.sellerOffers ?? [],
              ),
            ),
          );
          break;

        default:
          _showErrorSnackBar("Unknown request category: ${request.category}");
      }
    } catch (e) {
      print('Navigation error: $e');
      _showErrorSnackBar("Error opening request details");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(),
        ),
        backgroundColor: Colors.red[600],
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildWaitingRequestCard(dynamic request,) {
    return GestureDetector(
      onTap: () => _navigateToDetailScreen(request),
      child: Container(
        padding: EdgeInsets.all(16),
        width: 350,
        height: 410,
        constraints: BoxConstraints(minWidth: 300),
        decoration: BoxDecoration(
          color: Constants.dtaColorLight.withOpacity(0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Constants.ctaColorLight, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _formatDate(request.createdAt),
                  style: GoogleFonts.manrope(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red[300]!),
                        borderRadius: BorderRadius.circular(360),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.manrope(
                          color: Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {});
                      },
                      icon: Icon(HugeIcons.strokeRoundedFilter, color: Colors.grey[600], size: 18),
                    )
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            // Request title
            Text(
              "REQUEST #${request?.id ?? 'Unknown'}",
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Constants.ftaColorLight,
              ),
            ),
            SizedBox(height: 8),
            // Description label
            Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.orange, width: 3)),
              ),
              padding: EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Description -",
                    style: GoogleFonts.manrope(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getRequestDescription(request),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    request?.category ?? "Unknown Category",
                    style: GoogleFonts.manrope(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Status dots
            Row(
              children: [
                Expanded(child: Container()),
                Center(
                  child: Row(
                    children: [
                      _buildStatusDot("D", (request?.createdAt?.day ?? 0).toString()),
                      SizedBox(width: 8),
                      _buildStatusDot("H", (request?.createdAt?.hour ?? 0).toString()),
                      SizedBox(width: 8),
                      _buildStatusDot("M", (request?.createdAt?.minute ?? 0).toString()),
                      SizedBox(width: 8),
                      _buildStatusDot("S", (request?.createdAt?.second ?? 0).toString()),
                    ],
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
            SizedBox(height: 24),
            // Waiting message
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Waiting For",
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                    Text(
                      "Seller Response",
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: Text(
                          "Refresh",
                          style: GoogleFonts.manrope(
                            color: Constants.ctaColorLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // View Details button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _navigateToDetailScreen(request),
                child: Text(
                  "View Details",
                  style: GoogleFonts.manrope(
                    color: Color(0xFF2B3A5C),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRequestCard(dynamic request) {
    return GestureDetector(
      onTap: () => _navigateToDetailScreen(request),
      child: Container(
        padding: EdgeInsets.all(16),
        width: 350,
        //height: 410,
        constraints: BoxConstraints(minWidth: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _formatDate(request.createdAt),
                  style: GoogleFonts.manrope(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red[300]!),
                        borderRadius: BorderRadius.circular(360),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.manrope(
                          color: Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {});
                      },
                      icon: Icon(HugeIcons.strokeRoundedFilter, color: Colors.grey[600], size: 18),
                    )
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            // Request title
            Text(
              "REQUEST #${request?.id ?? 'Unknown'}",
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Constants.ftaColorLight,
              ),
            ),
            SizedBox(height: 8),
            // Description label
            Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.orange, width: 3)),
              ),
              padding: EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Description -",
                        style: GoogleFonts.manrope(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                   TextButton(
                onPressed: () => _navigateToDetailScreen(request),
                child: Text(
                  "View Details",
                  style: GoogleFonts.manrope(
                    color: Color(0xFF2B3A5C),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getRequestDescription(request),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    request.category ?? "Unknown Category",
                    style: GoogleFonts.manrope(
                      color: Colors.orange[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Status dots - showing elapsed time
            Row(
              children: [
                Spacer(),
                _buildStatusDot("D", _getElapsedTime(request.createdAt, 'days')),
                SizedBox(width: 8),
                _buildStatusDot("H", _getElapsedTime(request.createdAt, 'hours')),
                SizedBox(width: 8),
                _buildStatusDot("M", _getElapsedTime(request.createdAt, 'minutes')),
                SizedBox(width: 8),
                _buildStatusDot("S", _getElapsedTime(request.createdAt, 'seconds')),
                Spacer(),
              ],
            ),
            SizedBox(height: 20),
            // Seller bids
            Expanded(
              child: SingleChildScrollView(

                child: Column(
                  children: [
                    if (request?.sellerOffers != null && request.sellerOffers.isNotEmpty) ...[
                      ...request.sellerOffers.take(2).map((bid) =>  _buildSellerBid(bid,request)),
                      SizedBox(height: 16),
                      // View All Bids button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "View All Bids",
                            style: GoogleFonts.manrope(
                              color: Constants.ftaColorLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Constants.ftaColorLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "${request.sellerOffers.length}",
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Center(
                        child: Text(
                          "No bids yet",
                          style: GoogleFonts.manrope(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // View Details button
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Date unavailable";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _getElapsedTime(DateTime? createdAt, String unit) {
    if (createdAt == null) return "0";

    final difference = DateTime.now().difference(createdAt);

    switch (unit) {
      case 'days':
        return difference.inDays.toString();
      case 'hours':
        return difference.inHours.toString();
      case 'minutes':
        return difference.inMinutes.toString();
      case 'seconds':
        return difference.inSeconds.toString();
      default:
        return "0";
    }
  }

  Widget _buildSellerBid(Seller? seller, dynamic request) {
    if (seller == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Constants.ftaColorLight),
          color: Colors.transparent
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 12,right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    seller.name ?? "Unknown Seller",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2B3A5C),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: (){
                    _showConfirmationDialog(context, seller);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shadowColor: Colors.grey.shade400,
                    backgroundColor: Colors.green,
                    foregroundColor: Constants.ftaColorLight,
                    elevation: 3,
                  ),
                  child: Text(
                    "Accept",
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12,right: 12),
            child: Text(
              _formatBidDateTime(seller.bidTime),
              style: GoogleFonts.manrope(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ),
          SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12,right: 12),
            child: RichText(
              text: TextSpan(
                text: 'Bid: ',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: " R${seller.bid?.toInt() ?? 0}",
                    style:  GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12,right: 12),
            child: RichText(
              text: TextSpan(
                text: 'Radius/Distance: ',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: "${seller.radius}Km",
                    style:  GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12,right: 12),
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: 'Comments: ',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: seller.comment,

                    style:  GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Constants.ftaColorLight,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24),bottomRight: Radius.circular(24)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Rating: ${seller.rating ?? 0}/${seller.maxRating ?? 5}",
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      Spacer(),
                      OutlinedButton.icon(
                        onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChatScreen(
                                groupChat: GroupChat(uuid: request.id.toString(), request: ProductRequest(description: _getRequestDescription(request),), messages: [Message(
                                  sender: User(name: Constants.myDisplayname, role: "Buyer"),
                                  content: "Hello, I need a quote for a fuel filter for my Toyota Corolla 2015. Please provide availability and details.",
                                  timestamp: DateTime.now().subtract(Duration(minutes: 10)),
                                ),
                                  Message(
                                    sender: User(name: "Seller 1", role: "Seller"),
                                    content: "Understood! We have options available that match your vehicle model. Would you like delivery, or pick-up from a nearby location?",
                                    timestamp: DateTime.now().subtract(Duration(minutes: 4)),
                                    isReply: true,
                                  ),
                                  Message(
                                    sender: User(name: Constants.myDisplayname, role: "Buyer"),
                                    content: "I prefer an OEM part, but I'm open to aftermarket options if they meet quality standards.",
                                    timestamp: DateTime.now().subtract(Duration(minutes: 8)),
                                  ),
                                  Message(
                                      sender: User(name: "Seller 1", role: "Seller"),
                                      content: "Hi John, are you specifically looking for an OEM fuel filter, or would you consider a high-quality aftermarket option?",
                                      timestamp: DateTime.now().subtract(Duration(minutes: 9)),
                                      isReply: true,
                                      replies: [  Message(
                                        sender: User(name: "Seller 1", role: "Seller"),
                                        content: "Do you want OEM or aftermarket?",
                                        timestamp: DateTime.now(),
                                        isReply: true,
                                      ),
                                        Message(
                                          sender: User(name: "Seller 2", role: "Seller"),
                                          content: "We have both options in stock.",
                                          timestamp: DateTime.now(),
                                          isReply: true,
                                        ),]
                                  ),
                                  Message(
                                    sender: User(name: Constants.myDisplayname, role: "Buyer"),
                                    content: "Just the filter for now, but I'd like to know if installation is an option.",
                                    timestamp: DateTime.now().subtract(Duration(minutes: 5)),
                                  ),
                                  Message(
                                    sender: User(name: "Seller 2", role: "Seller"),
                                    content: "Thanks for reaching out! Do you need only the filter, or are you also interested in an installation service?",
                                    timestamp: DateTime.now().subtract(Duration(minutes: 7)),
                                    isReply: true,
                                  ),
                                  Message(
                                    sender: User(name: Constants.myDisplayname, role: "Buyer"),
                                    content: "I only need the filter for now, but I appreciate the suggestion. Please share the details so I can compare my options.",
                                    timestamp: DateTime.now().subtract(Duration(minutes: 3)),
                                  ),

                                  Message(
                                    sender: User(name: "Seller 2", role: "Seller"),
                                    content: "We have a compatible filter in stock. Could you confirm if you need any additional parts, like a seal or gasket, to ensure a proper fit?",
                                    timestamp: DateTime.now().subtract(Duration(minutes: 2)),
                                    isReply: true,
                                  ),]),

                              ),
                            ),
                          );
                          setState(() {

                          });
                        },
                        icon: Icon(
                          HugeIcons.strokeRoundedBubbleChat,
                          color: Constants.ctaColorLight,
                          size: 18,
                        ),
                        label: Text(
                          "Group Chat",
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Confirmation Dialog
  void _showConfirmationDialog(BuildContext context,Seller seller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.exclamationmark_circle_fill,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Are You Sure !",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "By clicking the pay button you accept the offer made by this seller",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(360),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showPaymentDialog(context, seller);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(360),
                          ),
                        ),
                        child: Text(
                          "Pay",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPaymentSuccessfulDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Center(
                    child: Image.asset(
                      "lib/assets/images/bag_logo.png",
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Center(
                    child: Image.asset(
                      "lib/assets/images/pay_image.png",
                      width: 250,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Payment Done",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Your Payment Has Been Successfully Done",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {

                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(360),
                          ),
                        ),
                        child: Text(
                          "Done",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Payment Dialog
  void _showPaymentDialog(BuildContext context, Seller seller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width*0.3,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Payment",
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:Constants.ftaColorLight,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Credit Card Payments
              Text(
                "Credit Card Payments",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Constants.ftaColorLight,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildPaymentIcon("lib/assets/images/Visa.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/Mastercard.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/DinnersClub.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/American-Express.png"),
                ],
              ),
              SizedBox(height: 20),

              // Instant EFT
              Text(
                "Instant EFT",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Constants.ftaColorLight,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildPaymentIcon("lib/assets/images/absa.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/sid.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/standard.png"),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  _buildPaymentIcon("lib/assets/images/sid.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/nedbank.png"),
                ],
              ),
              SizedBox(height: 20),

              // QR Code Payments
              Text(
                "QR Code Payments",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Constants.ftaColorLight,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildPaymentIcon("lib/assets/images/zapper.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/snapscan.png"),
                ],
              ),
              SizedBox(height: 20),

              // UPI
              Text(
                "UPI",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Constants.ftaColorLight,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildPaymentIcon("lib/assets/images/applePay.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/GPay.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/SamsungPay.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/mobi.png"),
                ],
              ),
              SizedBox(height: 20),

              // Debit Cards
              Text(
                "Debit Cards",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Constants.ftaColorLight,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildPaymentIcon("lib/assets/images/Mastercard.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/visa2.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/American-Express.png"),
                ],
              ),
              SizedBox(height: 20),

              // Total and Continue Button
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "R${seller.bid.toStringAsFixed(2)}",
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "Total Amount",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          "View Details",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Handle payment completion
                        _showPaymentSuccessfulDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(360),
                        ),
                      ),
                      child: Text(
                        "Continue",
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentIcon(String assetPath) {
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Image.asset(
          assetPath,
          width: 40,
          height: 25,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  String _formatBidDateTime(DateTime? bidTime) {
    if (bidTime == null) return "Time unavailable";

    return "${bidTime.day.toString().padLeft(2, '0')}/${bidTime.month.toString().padLeft(2, '0')}/${bidTime.year} - ${bidTime.hour.toString().padLeft(2, '0')}:${bidTime.minute.toString().padLeft(2, '0')} ${bidTime.hour >= 12 ? 'PM' : 'AM'}";
  }

  Widget _buildStatusDot(String letter, String time) {
    return Column(
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: GradientGlowBorder.normalGradient(
            borderRadius: BorderRadius.circular(360),
            blurRadius: 1,
            spreadRadius: 1,
            colors: [Colors.transparent, Constants.ftaColorLight.withOpacity(0.4)],
            glowOpacity: 1,
            duration: Duration(milliseconds: 800),
            thickness: 2,
            child: Center(
              child: Text(
                time,
                style: GoogleFonts.manrope(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Text(
          letter.toString(),
          style: GoogleFonts.manrope(
            color: Constants.ftaColorLight,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class SparesDetailScreen extends StatefulWidget {
  final AutoSparesRequest request;
  final AutoSpares autoSpare;
  final List<Seller> bids;

  const SparesDetailScreen({
    Key? key,
    required this.request,
    required this.autoSpare,
    required this.bids,
  }) : super(key: key);

  @override
  State<SparesDetailScreen> createState() => _SparesDetailScreenState();
}

class _SparesDetailScreenState extends State<SparesDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Request Header Card
            SizedBox(height: 24),
            Container(
              height: 50,
              width: MediaQuery.of(context).size.width,
              color: Constants.ctaColorLight,
              padding: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                      onPressed: (){
                        Navigator.pop(context);
                        setState(() {
                          
                        });
                      }, icon: Icon(Icons.arrow_back_ios_new, size: 20,)
                  ),
                  SizedBox(width: 16,),
                  Text(
                    'Request ',
                    style: GoogleFonts.manrope(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    '2',
                    style: GoogleFonts.manrope(color: Constants.ftaColorLight, fontSize: 24),
                  ),
                  Text(
                    '\t\t\tInformation',
                    style: GoogleFonts.manrope(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        constraints: BoxConstraints(maxWidth: 1400),
                        decoration: BoxDecoration(
                          color: Constants.dtaColorLight.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Constants.ctaColorLight, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _formatDate(widget.request.createdAt),
                                  style: GoogleFonts.manrope(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                Spacer(),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.red[300]!),
                                        borderRadius: BorderRadius.circular(360),
                                      ),
                                      child: Text(
                                        "Cancel",
                                        style: GoogleFonts.manrope(
                                          color: Colors.red,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {});
                                      },
                                      icon: Icon(HugeIcons.strokeRoundedFilter, color: Colors.grey[600], size: 18),
                                    )
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Request title
                            Text(
                              "REQUEST ID: ${widget.request.id ?? 'Unknown'}",
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Constants.ftaColorLight,
                              ),
                            ),
                            SizedBox(height: 8),
                            // Description label
                            Container(
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: Colors.orange, width: 3)),
                              ),
                              padding: EdgeInsets.only(left: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Description -",
                                        style: GoogleFonts.manrope(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: (){},
                                        child: Text(
                                          "View Details",
                                          style: GoogleFonts.manrope(
                                            color: Color(0xFF2B3A5C),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _getRequestDescription(widget.request, widget.autoSpare),
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    widget.request.category ?? "Unknown Category",
                                    style: GoogleFonts.manrope(
                                      color: Colors.orange[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            // Status dots - showing elapsed time
                            Row(
                              children: [
                                Spacer(),
                                _buildStatusDot("D", _getElapsedTime(widget.request.createdAt, 'days')),
                                SizedBox(width: 8),
                                _buildStatusDot("H", _getElapsedTime(widget.request.createdAt, 'hours')),
                                SizedBox(width: 8),
                                _buildStatusDot("M", _getElapsedTime(widget.request.createdAt, 'minutes')),
                                SizedBox(width: 8),
                                _buildStatusDot("S", _getElapsedTime(widget.request.createdAt, 'seconds')),
                                Spacer(),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: 1400),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Vehicle Details Card
                            Expanded(
                              child: _buildDetailCard(
                                "Vehicle Details",
                                Constants.ctaColorLight,
                                [
                                  _buildDetailItem("VIN Number", widget.autoSpare.vehicleDetails.vin, showImage: true),
                                  _buildDetailItem("Manufacturer", widget.autoSpare.vehicleDetails.manufacturer),
                                  _buildDetailItem("Makes & Models", widget.autoSpare.vehicleDetails.makeModel),
                                  _buildDetailItem("Year", widget.autoSpare.vehicleDetails.year),
                                  _buildDetailItem("Type", widget.autoSpare.vehicleDetails.type),
                                  _buildDetailItem("Vehicle", "${widget.autoSpare.vehicleDetails.makeModel} ${widget.autoSpare.vehicleDetails.year}"),
                                  _buildDetailItem("New/Used Part", widget.autoSpare.vehicleDetails.condition),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // Part Details Card
                            Expanded(
                              child: _buildDetailCard(
                                "Part Details",
                                Colors.orange,
                                [
                                  _buildDetailItem("Part Name/Description", widget.autoSpare.partDetails.partName),
                                  _buildDetailItem("Quantity", widget.autoSpare.partDetails.quantity.toString()),
                                  _buildDetailItem("Your Location", widget.autoSpare.partDetails.location),
                                  _buildDetailItem("Max Distance You Want to Travel (km)", widget.autoSpare.partDetails.maxDistanceKm.toString()),
                                  _buildDetailItem("How soon do you need to buy this product?", widget.autoSpare.partDetails.urgency),
                                  _buildDetailItem("Description of the Product", widget.autoSpare.partDetails.productDescription),
                                  _buildDetailItem("Product Images", "", isProductImages: true),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // More Details Card
                            Expanded(
                              child: _buildDetailCard(
                                "More Details",
                                Colors.orange,
                                [
                                  _buildDetailItem("Part Number", widget.autoSpare.moreFields.partNumber),
                                  _buildDetailItem("Transmission Type", widget.autoSpare.moreFields.transmissionType),
                                  _buildDetailItem("Mileage of Vehicle", widget.autoSpare.moreFields.mileage),
                                  _buildDetailItem("Fuel Type", widget.autoSpare.moreFields.fuelType),
                                  _buildDetailItem("Body Type", widget.autoSpare.moreFields.bodyType),
                                  _buildDetailItem("Enquiry Time", "24 Hours"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    FooterSection(logo: "lib/assets/images/bidr_logo2.png")
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  String _getRequestDescription(dynamic request, dynamic item) {
    try {
      if (request?.category == null) return "No description available";

      switch (request.category) {
        case "Vehicle Spares":
          if (item?.partDetails?.partName != null &&
              item?.vehicleDetails?.makeModel != null &&
              item?.vehicleDetails?.year != null) {
            return "${item.partDetails.partName}, ${item.vehicleDetails.makeModel}, ${item.vehicleDetails.year}";
          }
          return "Vehicle Spares Request";

        case "Vehicle Tyres and Rims":
          if (item?.productDetails != null) {
            final typeOfElectronics = item.productDetails.typeOfElectronics ?? "Electronics";
            final brandPreference = item.productDetails.brandPreference ?? "Various Brands";
            final modelSeries = item.productDetails.modelSeries;
            return "$typeOfElectronics, $brandPreference${modelSeries != null ? ', $modelSeries' : ''}";
          }
          return "Electronics Request";

        case "Consumer Electronics":
          if (item?.productDetails != null) {
            final tyreType = item.productDetails.tyreType ?? "Tyres";
            final tyreWidth = item.productDetails.tyreWidthMm ?? 0;
            final sidewall = item.productDetails.sidewallProfile ?? "";
            final rimDiameter = item.productDetails.wheelRimDiameterInches ?? "";
            final brand = item.moreFields?.preferredBrand ?? "Various Brands";
            return "$tyreType, $tyreWidth/$sidewall" + "R$rimDiameter, $brand";
          }
          return "Tyre/Rim Request";

        default:
          return "Request #${request.id ?? 'Unknown'}";
      }
    } catch (e) {
      print('Error getting description: $e');
      return "Request information unavailable";
    }
  }
  String _formatDate(DateTime? date) {
    if (date == null) return "Date unavailable";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _getElapsedTime(DateTime? createdAt, String unit) {
    if (createdAt == null) return "0";

    final difference = DateTime.now().difference(createdAt);

    switch (unit) {
      case 'days':
        return difference.inDays.toString();
      case 'hours':
        return difference.inHours.toString();
      case 'minutes':
        return difference.inMinutes.toString();
      case 'seconds':
        return difference.inSeconds.toString();
      default:
        return "0";
    }
  }

  Widget _buildStatusDot(String letter, String time) {
    return Column(
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: GradientGlowBorder.normalGradient(
            borderRadius: BorderRadius.circular(360),
            blurRadius: 1,
            spreadRadius: 1,
            colors: [Colors.transparent, Constants.ftaColorLight.withOpacity(0.4)],
            glowOpacity: 1,
            duration: Duration(milliseconds: 800),
            thickness: 2,
            child: Center(
              child: Text(
                time,
                style: GoogleFonts.manrope(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Text(
          letter.toString(),
          style: GoogleFonts.manrope(
            color: Constants.ftaColorLight,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(String title, Color borderColor, List<Widget> children) {
    return CustomCard(
      elevation: 3,
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with colored border
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: borderColor,
              ),
            ),
            // Content
            SizedBox(height: 16,),
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    color: borderColor,
                  ),
                  SizedBox(width: 16,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
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

  Widget _buildDetailItem(String label, String value, {bool showImage = false, bool isProductImages = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          if (showImage) ...[
            // Show placeholder image for VIN
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFE0E0E0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/mechanic_working.jpg', // You would replace this with actual image
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 6),
          ],
          if (isProductImages) ...[
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFE0E0E0)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/mechanic_working.jpg', // You would replace this with actual image
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.grey[400],
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Navigation arrows
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: IconButton(
                            onPressed: (){
                              setState(() {

                              });
                            },
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: Constants.ftaColorLight,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: IconButton(
                            onPressed: (){
                              setState(() {

                              });
                            },
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              color: Constants.ftaColorLight,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!showImage) ...[
            Text(
              value.isEmpty ? "-" : value,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Constants.ftaColorLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (showImage && value.isNotEmpty) ...[
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ConsumerElectronicsDetailScreen extends StatefulWidget {
  final ConsumerElectronicsRequest request;
  final ConsumerElectronics consumerElectronics;
  final List<Seller> bids;

  const ConsumerElectronicsDetailScreen({
    super.key,
    required this.request,
    required this.consumerElectronics,
    required this.bids,
  });

  @override
  State<ConsumerElectronicsDetailScreen> createState() => _ConsumerElectronicsDetailScreenState();
}

class _ConsumerElectronicsDetailScreenState extends State<ConsumerElectronicsDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Request Header Card
            SizedBox(height: 24),
            Container(
              height: 50,
              width: MediaQuery.of(context).size.width,
              color: Constants.ctaColorLight,
              padding: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                      onPressed: (){
                        Navigator.pop(context);
                        setState(() {

                        });
                      }, icon: Icon(Icons.arrow_back_ios_new, size: 20,)
                  ),
                  SizedBox(width: 16,),
                  Text(
                    'Request ',
                    style: GoogleFonts.manrope(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    '${widget.request.id}',
                    style: GoogleFonts.manrope(color: Constants.ftaColorLight, fontSize: 24),
                  ),
                  Text(
                    '\t\t\tInformation',
                    style: GoogleFonts.manrope(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        constraints: BoxConstraints(maxWidth: 1400),
                        decoration: BoxDecoration(
                          color: Constants.dtaColorLight.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Constants.ctaColorLight, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _formatDate(widget.request.createdAt),
                                  style: GoogleFonts.manrope(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                Spacer(),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.red[300]!),
                                        borderRadius: BorderRadius.circular(360),
                                      ),
                                      child: Text(
                                        "Cancel",
                                        style: GoogleFonts.manrope(
                                          color: Colors.red,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {});
                                      },
                                      icon: Icon(HugeIcons.strokeRoundedFilter, color: Colors.grey[600], size: 18),
                                    )
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Request title
                            Text(
                              "REQUEST ID: ${widget.request.id ?? 'Unknown'}",
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Constants.ftaColorLight,
                              ),
                            ),
                            SizedBox(height: 8),
                            // Description label
                            Container(
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: Colors.orange, width: 3)),
                              ),
                              padding: EdgeInsets.only(left: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Description -",
                                        style: GoogleFonts.manrope(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: (){},
                                        child: Text(
                                          "View Details",
                                          style: GoogleFonts.manrope(
                                            color: Color(0xFF2B3A5C),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _getRequestDescription(widget.request, widget.consumerElectronics),
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    widget.request.category ?? "Unknown Category",
                                    style: GoogleFonts.manrope(
                                      color: Colors.orange[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            // Status dots - showing elapsed time
                            Row(
                              children: [
                                Spacer(),
                                _buildStatusDot("D", _getElapsedTime(widget.request.createdAt, 'days')),
                                SizedBox(width: 8),
                                _buildStatusDot("H", _getElapsedTime(widget.request.createdAt, 'hours')),
                                SizedBox(width: 8),
                                _buildStatusDot("M", _getElapsedTime(widget.request.createdAt, 'minutes')),
                                SizedBox(width: 8),
                                _buildStatusDot("S", _getElapsedTime(widget.request.createdAt, 'seconds')),
                                Spacer(),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: 1400),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Details Card
                            Expanded(
                              child: _buildDetailCard(
                                "Product Details",
                                Constants.ctaColorLight,
                                [
                                  _buildDetailItem("Type of Electronics", widget.consumerElectronics.productDetails.typeOfElectronics),
                                  _buildDetailItem("Brand Preference", widget.consumerElectronics.productDetails.brandPreference),
                                  _buildDetailItem("Model Series", widget.consumerElectronics.productDetails.modelSeries ?? "-"),
                                  _buildDetailItem("Quantity Needed", widget.consumerElectronics.productDetails.quantityNeeded.toString()),
                                  _buildDetailItem("Purpose", widget.consumerElectronics.featuresAndSpecs.purpose),
                                  _buildDetailItem("Condition Preference", widget.consumerElectronics.featuresAndSpecs.conditionPreference),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // Budget & Timeline Card
                            Expanded(
                              child: _buildDetailCard(
                                "Budget & Timeline",
                                Colors.orange,
                                [
                                  _buildDetailItem("Min Price", widget.consumerElectronics.budgetTimeline.minPrice != null ? "\$${widget.consumerElectronics.budgetTimeline.minPrice!.toStringAsFixed(2)}" : "-"),
                                  _buildDetailItem("Max Price", widget.consumerElectronics.budgetTimeline.maxPrice != null ? "\$${widget.consumerElectronics.budgetTimeline.maxPrice!.toStringAsFixed(2)}" : "-"),
                                  _buildDetailItem("Urgency", widget.consumerElectronics.budgetTimeline.urgency),
                                  _buildDetailItem("Needs Installation", widget.consumerElectronics.budgetTimeline.needsInstallation ? "Yes" : "No"),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // Features & Specifications Card
                            Expanded(
                              child: _buildDetailCard(
                                "Features & Specifications",
                                Colors.orange,
                                [
                                  _buildDetailItem("Required Features", widget.consumerElectronics.featuresAndSpecs.requiredFeatures ?? "-"),
                                  _buildDetailItem("Additional Comments", widget.consumerElectronics.featuresAndSpecs.additionalComments ?? "-"),
                                  _buildDetailItem("Documents/Images", "", isProductImages: true, imageList: widget.consumerElectronics.featuresAndSpecs.documentsOrImages),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    FooterSection(logo: "lib/assets/images/bidr_logo2.png")
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _getRequestDescription(dynamic request, dynamic item) {
    try {
      if (request?.category == null) return "No description available";

      switch (request.category) {
        case "Vehicle Spares":
          if (item?.partDetails?.partName != null &&
              item?.vehicleDetails?.makeModel != null &&
              item?.vehicleDetails?.year != null) {
            return "${item.partDetails.partName}, ${item.vehicleDetails.makeModel}, ${item.vehicleDetails.year}";
          }
          return "Vehicle Spares Request";

        case "Vehicle Tyres and Rims":
          if (item?.productDetails != null) {
            final typeOfElectronics = item.productDetails.typeOfElectronics ?? "Electronics";
            final brandPreference = item.productDetails.brandPreference ?? "Various Brands";
            final modelSeries = item.productDetails.modelSeries;
            return "$typeOfElectronics, $brandPreference${modelSeries != null ? ', $modelSeries' : ''}";
          }
          return "Electronics Request";

        case "Consumer Electronics":
          if (item?.productDetails != null) {
            final tyreType = item.productDetails.tyreType ?? "Tyres";
            final tyreWidth = item.productDetails.tyreWidthMm ?? 0;
            final sidewall = item.productDetails.sidewallProfile ?? "";
            final rimDiameter = item.productDetails.wheelRimDiameterInches ?? "";
            final brand = item.moreFields?.preferredBrand ?? "Various Brands";
            return "$tyreType, $tyreWidth/$sidewall" + "R$rimDiameter, $brand";
          }
          return "Tyre/Rim Request";

        default:
          return "Request #${request.id ?? 'Unknown'}";
      }
    } catch (e) {
      print('Error getting description: $e');
      return "Request information unavailable";
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Date unavailable";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _getElapsedTime(DateTime? createdAt, String unit) {
    if (createdAt == null) return "0";

    final difference = DateTime.now().difference(createdAt);

    switch (unit) {
      case 'days':
        return difference.inDays.toString();
      case 'hours':
        return difference.inHours.toString();
      case 'minutes':
        return difference.inMinutes.toString();
      case 'seconds':
        return difference.inSeconds.toString();
      default:
        return "0";
    }
  }

  Widget _buildStatusDot(String letter, String time) {
    return Column(
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: GradientGlowBorder.normalGradient(
            borderRadius: BorderRadius.circular(360),
            blurRadius: 1,
            spreadRadius: 1,
            colors: [Colors.transparent, Constants.ftaColorLight.withOpacity(0.4)],
            glowOpacity: 1,
            duration: Duration(milliseconds: 800),
            thickness: 2,
            child: Center(
              child: Text(
                time,
                style: GoogleFonts.manrope(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Text(
          letter.toString(),
          style: GoogleFonts.manrope(
            color: Constants.ftaColorLight,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(String title, Color borderColor, List<Widget> children) {
    return CustomCard(
      elevation: 3,
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with colored border
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: borderColor,
              ),
            ),
            // Content
            SizedBox(height: 16,),
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    color: borderColor,
                  ),
                  SizedBox(width: 16,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
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

  Widget _buildDetailItem(String label, String value, {bool showImage = false, bool isProductImages = false, List<String>? imageList}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          if (showImage) ...[
            // Show placeholder image
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFE0E0E0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/mechanic_working.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 6),
          ],
          if (isProductImages) ...[
            if (imageList != null && imageList.isNotEmpty) ...[
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageList.first, // Show first image
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.image,
                                color: Colors.grey[400],
                                size: 30,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Navigation arrows
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: (){
                                setState(() {

                                });
                              },
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: (){
                                setState(() {

                                });
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Image counter
                    if (imageList.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "1/${imageList.length}",
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              // No images available
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    // Navigation arrows
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: (){
                                setState(() {

                                });
                              },
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: (){
                                setState(() {

                                });
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (!showImage) ...[
            Text(
              value.isEmpty ? "-" : value,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Constants.ftaColorLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (showImage && value.isNotEmpty) ...[
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RimTyreDetailScreen extends StatefulWidget {
  final RimTyreRequest request;
  final RimTyre rimTyre;
  final List<Seller> bids;

  const RimTyreDetailScreen({
    Key? key,
    required this.request,
    required this.rimTyre,
    required this.bids,
  }) : super(key: key);

  @override
  State<RimTyreDetailScreen> createState() => _RimTyreDetailScreenState();
}

class _RimTyreDetailScreenState extends State<RimTyreDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Request Header Card
            SizedBox(height: 24),
            Container(
              height: 50,
              width: MediaQuery.of(context).size.width,
              color: Constants.ctaColorLight,
              padding: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                      onPressed: (){
                        Navigator.pop(context);
                        setState(() {

                        });
                      }, icon: Icon(Icons.arrow_back_ios_new, size: 20,)
                  ),
                  SizedBox(width: 16,),
                  Text(
                    'Request ',
                    style: GoogleFonts.manrope(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    '${widget.request.id}',
                    style: GoogleFonts.manrope(color: Constants.ftaColorLight, fontSize: 24),
                  ),
                  Text(
                    '\t\t\tInformation',
                    style: GoogleFonts.manrope(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        constraints: BoxConstraints(maxWidth: 1400),
                        decoration: BoxDecoration(
                          color: Constants.dtaColorLight.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Constants.ctaColorLight, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _formatDate(widget.request.createdAt),
                                  style: GoogleFonts.manrope(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                Spacer(),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.red[300]!),
                                        borderRadius: BorderRadius.circular(360),
                                      ),
                                      child: Text(
                                        "Cancel",
                                        style: GoogleFonts.manrope(
                                          color: Colors.red,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {});
                                      },
                                      icon: Icon(HugeIcons.strokeRoundedFilter, color: Colors.grey[600], size: 18),
                                    )
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Request title
                            Text(
                              "REQUEST ID: ${widget.request.id ?? 'Unknown'}",
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Constants.ftaColorLight,
                              ),
                            ),
                            SizedBox(height: 8),
                            // Description label
                            Container(
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: Colors.orange, width: 3)),
                              ),
                              padding: EdgeInsets.only(left: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Description -",
                                        style: GoogleFonts.manrope(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: (){},
                                        child: Text(
                                          "View Details",
                                          style: GoogleFonts.manrope(
                                            color: Color(0xFF2B3A5C),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _getRequestDescription(widget.request, widget.rimTyre),
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    widget.request.category ?? "Unknown Category",
                                    style: GoogleFonts.manrope(
                                      color: Colors.orange[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            // Status dots - showing elapsed time
                            Row(
                              children: [
                                Spacer(),
                                _buildStatusDot("D", _getElapsedTime(widget.request.createdAt, 'days')),
                                SizedBox(width: 8),
                                _buildStatusDot("H", _getElapsedTime(widget.request.createdAt, 'hours')),
                                SizedBox(width: 8),
                                _buildStatusDot("M", _getElapsedTime(widget.request.createdAt, 'minutes')),
                                SizedBox(width: 8),
                                _buildStatusDot("S", _getElapsedTime(widget.request.createdAt, 'seconds')),
                                Spacer(),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: 1400),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Details Card
                            Expanded(
                              child: _buildDetailCard(
                                "Product Details",
                                Constants.ctaColorLight,
                                [
                                  _buildDetailItem("Tyre Width (mm)", widget.rimTyre.productDetails.tyreWidthMm.toString()),
                                  _buildDetailItem("Sidewall Profile", widget.rimTyre.productDetails.sidewallProfile),
                                  _buildDetailItem("Wheel Rim Diameter (inches)", widget.rimTyre.productDetails.wheelRimDiameterInches),
                                  _buildDetailItem("Tyre Type", widget.rimTyre.productDetails.tyreType),
                                  _buildDetailItem("Quantity", widget.rimTyre.productDetails.quantity.toString()),
                                  _buildDetailItem("Urgency", widget.rimTyre.productDetails.urgency),
                                  _buildDetailItem(
                                    "Tyre Size",
                                    "${widget.rimTyre.productDetails.tyreWidthMm}/${widget.rimTyre.productDetails.sidewallProfile}R${widget.rimTyre.productDetails.wheelRimDiameterInches}",
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
// Vehicle & Brand Details Card
                            Expanded(
                              child: _buildDetailCard(
                                "Vehicle & Brand Details",
                                Colors.orange,
                                [
                                  _buildDetailItem("Vehicle Type", widget.rimTyre.moreFields.vehicleType),
                                  _buildDetailItem("Preferred Brand", widget.rimTyre.moreFields.preferredBrand),
                                  _buildDetailItem("Pitch Circle Diameter", widget.rimTyre.moreFields.pitchCircleDiameter),
                                  _buildDetailItem("Tyre Construction Type", widget.rimTyre.moreFields.tyreConstructionType),
                                  _buildDetailItem("Description", widget.rimTyre.moreFields.description),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildDetailCard(
                                "Service Requirements",
                                Colors.orange,
                                [
                                  _buildDetailItem("Fitment Required", widget.rimTyre.moreFields.fitmentRequired ? "Yes" : "No"),
                                  _buildDetailItem("Balancing Required", widget.rimTyre.moreFields.balancingRequired ? "Yes" : "No"),
                                  _buildDetailItem("Tyre Rotation Required", widget.rimTyre.moreFields.tyreRotationRequired ? "Yes" : "No"),
                                  _buildDetailItem(
                                    "Product Images",
                                    "",
                                    isProductImages: true,
                                    imageList: widget.rimTyre.moreFields.imageUrls,
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    FooterSection(logo: "lib/assets/images/bidr_logo2.png")
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _getRequestDescription(dynamic request, dynamic item) {
    try {
      if (request?.category == null) return "No description available";

      switch (request.category) {
        case "Vehicle Spares":
          if (item?.partDetails?.partName != null &&
              item?.vehicleDetails?.makeModel != null &&
              item?.vehicleDetails?.year != null) {
            return "${item.partDetails.partName}, ${item.vehicleDetails.makeModel}, ${item.vehicleDetails.year}";
          }
          return "Vehicle Spares Request";

        case "Vehicle Tyres and Rims":
          if (item?.productDetails != null) {
            final typeOfElectronics = item.productDetails.typeOfElectronics ?? "Electronics";
            final brandPreference = item.productDetails.brandPreference ?? "Various Brands";
            final modelSeries = item.productDetails.modelSeries;
            return "$typeOfElectronics, $brandPreference${modelSeries != null ? ', $modelSeries' : ''}";
          }
          return "Electronics Request";

        case "Consumer Electronics":
          if (item?.productDetails != null) {
            final tyreType = item.productDetails.tyreType ?? "Tyres";
            final tyreWidth = item.productDetails.tyreWidthMm ?? 0;
            final sidewall = item.productDetails.sidewallProfile ?? "";
            final rimDiameter = item.productDetails.wheelRimDiameterInches ?? "";
            final brand = item.moreFields?.preferredBrand ?? "Various Brands";
            return "$tyreType, $tyreWidth/$sidewall" + "R$rimDiameter, $brand";
          }
          return "Tyre/Rim Request";

        default:
          return "Request #${request.id ?? 'Unknown'}";
      }
    } catch (e) {
      print('Error getting description: $e');
      return "Request information unavailable";
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Date unavailable";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _getElapsedTime(DateTime? createdAt, String unit) {
    if (createdAt == null) return "0";

    final difference = DateTime.now().difference(createdAt);

    switch (unit) {
      case 'days':
        return difference.inDays.toString();
      case 'hours':
        return difference.inHours.toString();
      case 'minutes':
        return difference.inMinutes.toString();
      case 'seconds':
        return difference.inSeconds.toString();
      default:
        return "0";
    }
  }

  Widget _buildStatusDot(String letter, String time) {
    return Column(
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: GradientGlowBorder.normalGradient(
            borderRadius: BorderRadius.circular(360),
            blurRadius: 1,
            spreadRadius: 1,
            colors: [Colors.transparent, Constants.ftaColorLight.withOpacity(0.4)],
            glowOpacity: 1,
            duration: Duration(milliseconds: 800),
            thickness: 2,
            child: Center(
              child: Text(
                time,
                style: GoogleFonts.manrope(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Text(
          letter.toString(),
          style: GoogleFonts.manrope(
            color: Constants.ftaColorLight,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(String title, Color borderColor, List<Widget> children) {
    return CustomCard(
      elevation: 3,
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with colored border
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: borderColor,
              ),
            ),
            // Content
            SizedBox(height: 16,),
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    color: borderColor,
                  ),
                  SizedBox(width: 16,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
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

  Widget _buildDetailItem(String label, String value, {bool showImage = false, bool isProductImages = false, List<String>? imageList}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          if (showImage) ...[
            // Show placeholder image
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFE0E0E0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/mechanic_working.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 6),
          ],
          if (isProductImages) ...[
            if (imageList != null && imageList.isNotEmpty) ...[
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageList.first, // Show first image
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.tire_repair,
                                color: Colors.grey[400],
                                size: 30,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Navigation arrows
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: (){
                                setState(() {

                                });
                              },
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: (){
                                setState(() {

                                });
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Image counter
                    if (imageList.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "1/${imageList.length}",
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              // No images available
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    // Navigation arrows
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: (){
                                setState(() {

                                });
                              },
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: (){
                                setState(() {

                                });
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (!showImage) ...[
            Text(
              value.isEmpty ? "-" : value,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Constants.ftaColorLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (showImage && value.isNotEmpty) ...[
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}