import 'package:bidr/pages/mobileView/landingPage/profileMobile.dart';
import 'package:bidr/pages/mobileView/landingPage/supportMobileView.dart';
import 'package:flutter/material.dart';

import '../../../constants/Constants.dart';
import '../../../customWdget/mobileBottomNavBar.dart';
import '../../../notifier/my_notifier.dart';
import '../../seller/seller_home_dashboard.dart' hide notifications;
import '../SellerDashboard/notificationMobile.dart';
import '../SellerDashboard/sellerMobileDashboard.dart' hide notifications;
import '../buyerDashboard/buyerMobileDashboard.dart';
import 'categories.dart';
import 'landingMobileViewPage.dart';

class LandingMobileController extends StatefulWidget {
  @override
  _LandingMobileControllerState createState() => _LandingMobileControllerState();
}

MyNotifier? currentControllerNotifier;
final currentControllerValueNotifier = ValueNotifier<int>(0);

class _LandingMobileControllerState extends State<LandingMobileController> {

  final List<Widget> _pages = [
    BuyerHomeMobilePage(),
    CategoriesWidget(),
    NotificationMobile(notifications: notifications,),
    SupportMobile(),
    ProfileMobilePage(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    currentControllerNotifier = MyNotifier(currentControllerValueNotifier, context);
    currentControllerValueNotifier.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return  Constants.buyerAppBarValue == 6
    ? MaterialApp(
        debugShowCheckedModeBanner: false,
        home:Scaffold(
          backgroundColor: Colors.white,
          body: BuyerMobileDashboard(),
        ) )
        : Constants.buyerAppBarValue == 7
    ? SellerMobileDashboard():
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: _pages[currentIndex],
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 310,
                child: BottomMobileBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}