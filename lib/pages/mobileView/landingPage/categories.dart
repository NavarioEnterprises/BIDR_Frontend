import 'dart:math';
import 'package:bidr/customWdget/mobileBottomNavBar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/Constants.dart';
import 'landingMobileController.dart';
import 'landingMobileViewPage.dart';

class CategoriesWidget extends StatefulWidget {
  const CategoriesWidget({super.key});

  @override
  State<CategoriesWidget> createState() => _CategoriesWidgetState();
}

class _CategoriesWidgetState extends State<CategoriesWidget> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  List<Animation<Offset>> _slideAnimations = [];
  List<Animation<double>> _scaleAnimations = [];
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _staggerController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    // Create staggered animations for each category button
    for (int i = 0; i < 3; i++) {
      final start = i * 0.2;
      final end = start + 0.6;
      
      _slideAnimations.add(
        Tween<Offset>(
          begin: Offset(0, 0.5),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
      );
      
      _scaleAnimations.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(start, end, curve: Curves.elasticOut),
          ),
        ),
      );
    }
    
    _fadeController.forward();
    _staggerController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading:IconButton(
          onPressed:(){
            currentIndex =0;
            currentControllerValueNotifier.value++;
            setState(() {

            });
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
          'Categories',
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              SlideTransition(
                position: _slideAnimations[0],
                child: ScaleTransition(
                  scale: _scaleAnimations[0],
                  child: CategoryButton(
                    imagePath: 'lib/assets/images/auto_spares.png',
                    title: 'Vehicle Spares',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => 
                            const SwitchCategories(title: 'Vehicle Spares'),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            );
                          },
                        ),
                      );
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SlideTransition(
                position: _slideAnimations[1],
                child: ScaleTransition(
                  scale: _scaleAnimations[1],
                  child: CategoryButton(
                    imagePath: 'lib/assets/images/rims_and_tyre.png',
                    title: 'Vehicle Tyres and Rims',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => 
                            const SwitchCategories(title: 'Vehicle Tyres and Rims'),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            );
                          },
                        ),
                      );
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SlideTransition(
                position: _slideAnimations[2],
                child: ScaleTransition(
                  scale: _scaleAnimations[2],
                  child: CategoryButton(
                    imagePath: 'lib/assets/images/electronics_com.png',
                    title: 'Consumer Electronics',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => 
                            const SwitchCategories(title: 'Consumer Electronics'),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            );
                          },
                        ),
                      );
                      setState(() {});
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryButton extends StatefulWidget {
  final String imagePath;
  final String title;
  final VoidCallback onTap;

  const CategoryButton({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.onTap,
  }) : super(key: key);
  
  @override
  State<CategoryButton> createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<CategoryButton> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _bounceController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _bounceController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _bounceController.reverse();
      },
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 150),
              height: 80,
              decoration: BoxDecoration(
                color: _isPressed ? Constants.ctaColorLight.withOpacity(0.9) : Constants.ctaColorLight,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isPressed ? 0.15 : 0.08),
                    blurRadius: _isPressed ? 8 : 5,
                    offset: Offset(0, _isPressed ? 4 : 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Icon/Image with rotation animation
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 0.1,
                          child: Transform.scale(
                            scale: 0.9 + (0.1 * value),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                widget.imagePath,
                                color: Colors.white,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    // Title with fade animation
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(20 * (1 - value), 0),
                              child: Text(
                                widget.title,
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Arrow icon with pulse animation
                    TweenAnimationBuilder<double>(
                      duration: Duration(seconds: 2),
                      tween: Tween(begin: 0.0, end: 1.0),
                      onEnd: () {},
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 1.0 + (0.1 * sin(value * 2 * 3.14159)),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: _isPressed ? Constants.ctaColorLight.withOpacity(0.8) : Color(0xFFFF9F40),
                              size: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SwitchCategories extends StatefulWidget {
  final String title;
  const SwitchCategories({super.key, required this.title});

  @override
  State<SwitchCategories> createState() => _SwitchCategoriesState();
}

class _SwitchCategoriesState extends State<SwitchCategories> with SingleTickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  
  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    ));
    
    _contentSlideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));
    
    _contentController.forward();
  }
  
  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading:IconButton(
          onPressed:(){
            currentIndex =0;
            Navigator.pop(context);
            setState(() {

            });
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
          widget.title,
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SlideTransition(
        position: _contentSlideAnimation,
        child: FadeTransition(
          opacity: _contentFadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                if(widget.title == "Vehicle Spares")...[
                  VehicleDetailsQuoteMobileForm()
                ]else if(widget.title == "Vehicle Tyres and Rims")...[
                  TireProductQuoteMobileForm()
                ]else...[
                  ProductQuoteMobileForm()
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}