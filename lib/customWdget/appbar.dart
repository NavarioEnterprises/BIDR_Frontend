import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/Constants.dart';
import '../notifier/my_notifier.dart';
import '../pages/buyer_home.dart';

class HeaderSection extends StatefulWidget {
  const HeaderSection({Key? key}) : super(key: key);

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

MyNotifier? myNotifier1;
final appBarValueNotifier = ValueNotifier<int>(0);
class _HeaderSectionState extends State<HeaderSection> {

  void initState() {
    myNotifier1 = MyNotifier(appBarValueNotifier, context);
    appBarValueNotifier.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(360),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.55),
            blurRadius: 4,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(
            "lib/assets/images/bidr_logo1.png",
            fit: BoxFit.contain,
            height: 50,
            width: 80,
          ),
          Expanded(
            child: Row(
              children: [
                Wrap(
                  runSpacing: 16,
                  children: [
                    _navButton('Home',0,()=>setState(() {
                      Constants.buyerAppBarValue =0;
                      appBarValueNotifier.value++;
                      buyerHomeValueNotifier.value++;
                    })),
                    _navButton('Support',1,()=>setState(() {
                      Constants.buyerAppBarValue =1;
                      appBarValueNotifier.value++;
                      buyerHomeValueNotifier.value++;
                    })),
                    _navButton('FAQs',2,()=>setState(() {
                      Constants.buyerAppBarValue =2;
                      appBarValueNotifier.value++;
                      buyerHomeValueNotifier.value++;
                    })),
                    _navButton('Policies',3,()=>setState(() {
                      Constants.buyerAppBarValue =3;
                      appBarValueNotifier.value++;
                      buyerHomeValueNotifier.value++;
                    })),
                    _navButton('Blogs',4,()=>setState(() {
                      Constants.buyerAppBarValue =4;
                      appBarValueNotifier.value++;
                      buyerHomeValueNotifier.value++;
                    })),
                    _navButton('Contact Us',5,()=>setState(() {
                      Constants.buyerAppBarValue =5;
                      appBarValueNotifier.value++;
                      buyerHomeValueNotifier.value++;
                    })),

                  ],
                ),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: ()=>setState(() {
              Constants.buyerAppBarValue =7;
              appBarValueNotifier.value++;
              sellerHomeValueNotifier.value++;
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: Constants.ftaColorLight,width: 1.4),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Seller Dashboard',
              style: GoogleFonts.manrope(color: Constants.ftaColorLight),
            ),
          ),
          SizedBox(width:12),
          ElevatedButton(
            onPressed: ()=>setState(() {
              Constants.buyerAppBarValue =6;
              appBarValueNotifier.value++;
              buyerHomeValueNotifier.value++;
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: Constants.ftaColorLight,width: 1.4),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Buyer Dashboard',
              style: GoogleFonts.manrope(color: Constants.ftaColorLight),
            ),
          ),
          SizedBox(width:12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.ctaColorLight,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Login',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(String text,int index, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IntrinsicWidth(
            child: Column(
              children: [
                TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(minimumSize: Size(105, 45)),
                  child: Text(
                    text,
                    style: GoogleFonts.manrope(
                      color:index == Constants.buyerAppBarValue?Constants.ftaColorLight: Colors.black45,
                      fontSize: 14,
                      fontWeight: index == Constants.buyerAppBarValue?FontWeight.bold:FontWeight.w300,
                    ),
                  ),
                ),
                index == Constants.buyerAppBarValue?SizedBox(height: 8,):SizedBox.shrink(),
                index == Constants.buyerAppBarValue?Padding(
                  padding: const EdgeInsets.only(left: 12,right: 12),
                  child: Container(
                    height: 2,
                    color: Constants.ctaColorLight,
                  ),
                ):SizedBox.shrink(),

              ],
            ),
          ),
        ],
      ),
    );
  }
}