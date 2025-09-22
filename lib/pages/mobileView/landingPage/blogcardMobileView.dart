import 'package:bidr/pages/buyer/support.dart';
import 'package:bidr/pages/mobileView/landingPage/profileMobile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../constants/Constants.dart';
import '../../../customWdget/appbar.dart';
import '../../../customWdget/customCard.dart';
import '../../../customWdget/mobileBottomNavBar.dart';
import '../../../global_values.dart';
import '../../../models/blog.dart';
import '../../../services/blog_api_service.dart';
import '../../buyer_home.dart';
import '../breakpoints.dart';
import 'landingMobileController.dart';
import 'landingMobileViewPage.dart';

class BlogCardsMobileScreen extends StatefulWidget {
  const BlogCardsMobileScreen({super.key});

  @override
  _BlogCardsMobileScreenState createState() => _BlogCardsMobileScreenState();
}

class _BlogCardsMobileScreenState extends State<BlogCardsMobileScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final BlogApiService _blogApiService = BlogApiService();
  List<BlogItem> blogItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _loadBlogs();
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadBlogs() async {
    try {
      final blogs = await _blogApiService.fetchBlogs();
      setState(() {
        blogItems = blogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Widget _buildMobileBlogContent() {
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);
    
    if (_isLoading) {
      return Container(
        height: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Constants.ctaColorLight,
              strokeWidth: 3,
            ),
            SizedBox(height: spacing.spacingMedium),
            Text(
              'Loading blog posts...',
              style: GoogleFonts.manrope(
                fontSize: typography.medium,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              HugeIcons.strokeRoundedAlert02,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: spacing.spacingMedium),
            Text(
              'Failed to load blog posts',
              style: GoogleFonts.manrope(
                fontSize: typography.subHeading,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: spacing.spacingSmall),
            Text(
              _error!.replaceAll('Exception: ', ''),
              style: GoogleFonts.manrope(
                fontSize: typography.normal,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.spacingLarge),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadBlogs();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.paddingLarge,
                  vertical: spacing.paddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              icon: Icon(HugeIcons.strokeRoundedRefresh),
              label: Text(
                'Retry',
                style: GoogleFonts.manrope(
                  fontSize: typography.normal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (blogItems.isEmpty) {
      return Container(
        height: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              HugeIcons.strokeRoundedFileNotFound,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: spacing.spacingMedium),
            Text(
              'No blog posts available',
              style: GoogleFonts.manrope(
                fontSize: typography.subHeading,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: spacing.spacingSmall),
            Text(
              'Check back later for new content!',
              style: GoogleFonts.manrope(
                fontSize: typography.normal,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    // Mobile-only single column layout
    return Column(
      children: List.generate(blogItems.length, (index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 150)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Container(
                  margin: EdgeInsets.only(bottom: spacing.spacingLarge),
                  child: MobileBlogCard(
                    blogItem: blogItems[index],
                    typography: typography,
                    spacing: spacing,
                    onTap: () {
                      // Increment view count when opening blog
                      _blogApiService.incrementBlogViews(blogItems[index].id);

                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => MobileBlogDetailScreen(
                            blogItem: blogItems[index],
                            relatedItems: blogItems.where((item) => item != blogItems[index]).toList(),
                          ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              )),
                              child: child,
                            );
                          },
                          transitionDuration: Duration(milliseconds: 400),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);
    
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading:isBackButtonDisplayed?
          IconButton(
            onPressed:(){
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
          ):
          IconButton(
            onPressed:(){
              currentIndex =0;
              selectedTitle = "";
              Constants.buyerAppBarValue =0;
              currentControllerValueNotifier.value++;
              buyerBackMobileButtonValueNotifier.value++;
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
            "Blogs",
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.all(spacing.paddingMedium),
          child: SingleChildScrollView(child: _buildMobileBlogContent()),
        ),
      ),
    );

  }
}

class MobileBlogCard extends StatefulWidget {
  final BlogItem blogItem;
  final TypographyConfig typography;
  final SpacingConfig spacing;
  final VoidCallback onTap;

  const MobileBlogCard({
    Key? key,
    required this.blogItem,
    required this.typography,
    required this.spacing,
    required this.onTap,
  }) : super(key: key);

  @override
  _MobileBlogCardState createState() => _MobileBlogCardState();
}

class _MobileBlogCardState extends State<MobileBlogCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 3.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade500)
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Image section

                    Container(
                      width: 140,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: widget.blogItem.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Constants.ctaColorLight,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  HugeIcons.strokeRoundedImage01,
                                  color: Colors.grey[400],
                                  size: 40,
                                ),
                                SizedBox(height: widget.spacing.spacingSmall),
                                Text(
                                  'Image not available',
                                  style: GoogleFonts.manrope(
                                    color: Colors.grey[500],
                                    fontSize: widget.typography.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Content section
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(widget.spacing.paddingMedium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              widget.blogItem.title,
                              style: GoogleFonts.manrope(
                                fontSize: widget.typography.subHeading,
                                fontWeight: FontWeight.bold,
                                color: Constants.ftaColorLight,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: widget.spacing.spacingMedium),

                            // Description
                            Text(
                              widget.blogItem.description,

                              style: GoogleFonts.manrope(
                                fontSize: widget.typography.normal,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: widget.spacing.spacingMedium),

                            // Date and stats
                            Row(
                              children: [
                                Icon(
                                  HugeIcons.strokeRoundedCalendar01,
                                  size: widget.typography.normal,
                                  color: Colors.black87,
                                ),
                                SizedBox(width: widget.spacing.spacingSmall / 2),
                                Text(
                                  DateFormat("dd MMM yyyy").format(DateTime.parse(widget.blogItem.date)),
                                  style: GoogleFonts.manrope(
                                    fontSize: widget.typography.normal,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: widget.spacing.spacingMedium),
                            Row(
                              children: [
                                _buildStatItem(
                                  CupertinoIcons.heart_fill,
                                  widget.blogItem.likes,
                                  Constants.ctaColorLight,
                                ),
                                SizedBox(width: widget.spacing.spacingMedium),
                                _buildStatItem(
                                  HugeIcons.strokeRoundedMessage01,
                                  widget.blogItem.commentsCount,
                                    Constants.ctaColorLight,
                                ),
                              ],
                            ),

                            SizedBox(height: widget.spacing.spacingSmall),
                          ],
                        ),
                      ),
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

  Widget _buildStatItem(IconData icon, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: widget.typography.medium, color: color),
        SizedBox(width: widget.spacing.spacingSmall / 2),
        Text(
          '$count',
          style: GoogleFonts.manrope(
            fontSize: widget.typography.medium,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Mobile-only Blog Detail Screen
class MobileBlogDetailScreen extends StatefulWidget {
  final BlogItem blogItem;
  final List<BlogItem> relatedItems;

  const MobileBlogDetailScreen({
    Key? key,
    required this.blogItem,
    required this.relatedItems,
  }) : super(key: key);

  @override
  State<MobileBlogDetailScreen> createState() => _MobileBlogDetailScreenState();
}

class _MobileBlogDetailScreenState extends State<MobileBlogDetailScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading:IconButton(
            onPressed:(){
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
            widget.blogItem.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,

            ),
          ),
          centerTitle: true,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: spacing.spacingLarge),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: spacing.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero image
                      Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: widget.blogItem.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[100],
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Constants.ctaColorLight,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[100],
                              child: Center(
                                child: Icon(
                                  HugeIcons.strokeRoundedImage01,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: spacing.spacingLarge),
                      
                      // Title
                      Text(
                        widget.blogItem.title,
                        style: GoogleFonts.manrope(
                          fontSize: typography.heading,
                          fontWeight: FontWeight.bold,
                          color: Constants.ftaColorLight,
                          height: 1.3,
                        ),
                      ),
                      
                      SizedBox(height: spacing.spacingMedium),
                      
                      // Date and stats
                      Row(
                        children: [
                          Icon(
                            HugeIcons.strokeRoundedCalendar01,
                            size: typography.medium,
                            color: Constants.ctaColorLight,
                          ),
                          SizedBox(width: spacing.spacingSmall),
                          Text(
                            DateFormat("dd MMM yyyy").format(DateTime.parse(widget.blogItem.date)),
                            style: GoogleFonts.manrope(
                              fontSize: typography.normal,
                              color: Constants.ctaColorLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          Icon(CupertinoIcons.heart_fill,
                               size: typography.medium, 
                               color: Colors.red[400]),
                          SizedBox(width: spacing.spacingSmall / 2),
                          Text('${widget.blogItem.likes}',
                               style: GoogleFonts.manrope(
                                 fontSize: typography.normal,
                                 color: Colors.red[400],
                                 fontWeight: FontWeight.w600,
                               )),
                          SizedBox(width: spacing.spacingMedium),
                          Icon(HugeIcons.strokeRoundedMessage01,
                               size: typography.medium, 
                               color: Colors.blue[400]),
                          SizedBox(width: spacing.spacingSmall / 2),
                          Text('${widget.blogItem.commentsCount}',
                               style: GoogleFonts.manrope(
                                 fontSize: typography.normal,
                                 color: Colors.blue[400],
                                 fontWeight: FontWeight.w600,
                               )),
                        ],
                      ),
                      
                      SizedBox(height: spacing.spacingLarge),
                      
                      // Content
                      Text(
                        widget.blogItem.description,
                        style: GoogleFonts.manrope(
                          fontSize: typography.normal,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      
                      SizedBox(height: spacing.spacingMedium),
                      
                      Text(
                        widget.blogItem.detailContent,
                        style: GoogleFonts.manrope(
                          fontSize: typography.normal,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      
                      SizedBox(height: spacing.spacingLarge * 2),
                      
                      // Related articles section
                      if (widget.relatedItems.isNotEmpty) ...[
                        Text(
                          'Related Articles',
                          style: GoogleFonts.manrope(
                            fontSize: typography.subHeading,
                            fontWeight: FontWeight.bold,
                            color: Constants.ftaColorLight,
                          ),
                        ),
                        SizedBox(height: spacing.spacingMedium),
                        ...widget.relatedItems.take(3).map((item) => Container(
                          margin: EdgeInsets.only(bottom: spacing.spacingMedium),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => MobileBlogDetailScreen(
                                    blogItem: item,
                                    relatedItems: widget.relatedItems.where((i) => i != item).toList(),
                                  ),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: Offset(1.0, 0.0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            child: CustomCard(
                              elevation: 2,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(spacing.paddingMedium),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: item.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey[200],
                                            child: Icon(
                                              HugeIcons.strokeRoundedImage01,
                                              color: Colors.grey[400],
                                              size: 20,
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.grey[200],
                                            child: Icon(
                                              HugeIcons.strokeRoundedImage01,
                                              color: Colors.grey[400],
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: spacing.spacingMedium),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: GoogleFonts.manrope(
                                              fontSize: typography.normal,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: spacing.spacingSmall / 2),
                                          Text(
                                            DateFormat("dd MMM yyyy").format(DateTime.parse(item.date)),
                                            style: GoogleFonts.manrope(
                                              fontSize: typography.normal,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      HugeIcons.strokeRoundedArrowRight01,
                                      color: Constants.ctaColorLight,
                                      size: typography.medium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )),
                      ],
                      
                      SizedBox(height: spacing.spacingLarge * 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}