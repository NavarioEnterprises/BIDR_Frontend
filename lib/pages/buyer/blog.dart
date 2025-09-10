import 'package:bidr/pages/buyer/support.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../constants/Constants.dart';
import '../../customWdget/appbar.dart';
import '../../customWdget/customCard.dart';
import '../../global_values.dart';
import '../../models/blog.dart';
import '../../services/blog_api_service.dart';
import '../buyer_home.dart';
import '../mobileView/breakpoints.dart';

import 'package:google_fonts/google_fonts.dart';

class BlogCardsScreen extends StatefulWidget {
  @override
  _BlogCardsScreenState createState() => _BlogCardsScreenState();
}

class _BlogCardsScreenState extends State<BlogCardsScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final BlogApiService _blogApiService = BlogApiService();
  List<BlogItem> blogItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _loadBlogs();
    _controller.forward();
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
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBlogContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Constants.ctaColorLight,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading blog posts...',
              style: GoogleFonts.manrope(
                fontSize: Breakpoints.isTablet(context)
                    ? ResponsiveTypography.getTypography(context).normal
                    : 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              'Failed to load blog posts',
              style: GoogleFonts.manrope(
                fontSize: Breakpoints.isTablet(context)
                    ? ResponsiveTypography.getTypography(context).medium
                    : 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error!.replaceAll('Exception: ', ''),
              style: GoogleFonts.manrope(
                fontSize: Breakpoints.isTablet(context)
                    ? ResponsiveTypography.getTypography(context).normal
                    : 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
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
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.manrope(
                  fontSize: Breakpoints.isTablet(context)
                      ? ResponsiveTypography.getTypography(context).normal
                      : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (blogItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              HugeIcons.strokeRoundedFileNotFound,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No blog posts available',
              style: GoogleFonts.manrope(
                fontSize: Breakpoints.isTablet(context)
                    ? ResponsiveTypography.getTypography(context).medium
                    : 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later for new content!',
              style: GoogleFonts.manrope(
                fontSize: Breakpoints.isTablet(context)
                    ? ResponsiveTypography.getTypography(context).normal
                    : 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        //childAspectRatio: 0.4,
      ),
      itemCount: blogItems.length,
      padding: Breakpoints.isTablet(context)
          ? EdgeInsets.all(ResponsiveSpacing.getSpacing(context).paddingLarge)
          : EdgeInsets.all(24),
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 800 + (index * 200)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: BlogCard(
                    blogItem: blogItems[index],
                    onTap: () {
                      // Increment view count when opening blog
                      _blogApiService.incrementBlogViews(blogItems[index].id);

                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  BlogDetailScreen(
                                    blogItem: blogItems[index],
                                    relatedItems: blogItems
                                        .where(
                                          (item) => item != blogItems[index],
                                        )
                                        .toList(),
                                  ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return SlideTransition(
                                  position:
                                      Tween<Offset>(
                                        begin: Offset(1.0, 0.0),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeInOut,
                                        ),
                                      ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: BuyerDashboardHeader(headerName: 'Buyer Dashboard'),
                ),
              );
            },
          ),
          SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: Breakpoints.isTablet(context)
                        ? EdgeInsets.only(
                            left: ResponsiveSpacing.getSpacing(
                              context,
                            ).paddingLarge,
                            right: ResponsiveSpacing.getSpacing(
                              context,
                            ).paddingLarge,
                          )
                        : const EdgeInsets.only(left: 45, right: 45),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 400,
                      constraints: BoxConstraints(maxWidth: 1600),
                      child: _buildBlogContent(),
                    ),
                  ),
                  SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 1000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: FooterSection(
                            logo: "lib/assets/images/bidr_logo2.png",
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BlogCard extends StatefulWidget {
  final BlogItem blogItem;
  final VoidCallback onTap;

  const BlogCard({Key? key, required this.blogItem, required this.onTap})
    : super(key: key);

  @override
  _BlogCardState createState() => _BlogCardState();
}

class _BlogCardState extends State<BlogCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _elevationAnimation = Tween<double>(begin: 3.0, end: 8.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: CustomCard(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image section with animation
                      Expanded(
                        flex: 3,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),

                            color: Colors.grey[300],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: widget.blogItem.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (context, url) => Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                      color: Colors.grey.shade100,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.black54,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                          color: Colors.grey.shade100,
                                        ),
                                        child: const Icon(
                                          HugeIcons
                                              .strokeRoundedShoppingBasket01,
                                          color: Colors.grey,
                                          size: 32,
                                        ),
                                      ),
                                ),
                                // Hover overlay
                                AnimatedOpacity(
                                  duration: Duration(milliseconds: 200),
                                  opacity: _isHovered ? 0.1 : 0.0,
                                  child: Container(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Content section with animations
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 600),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Text(
                                      widget.blogItem.title,
                                      style: GoogleFonts.manrope(
                                        fontSize: Breakpoints.isTablet(context)
                                            ? ResponsiveTypography.getTypography(
                                                context,
                                              ).normal
                                            : 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 6),
                              Expanded(
                                child: TweenAnimationBuilder<double>(
                                  duration: Duration(milliseconds: 800),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Text(
                                        widget.blogItem.description,
                                        textAlign: TextAlign.justify,
                                        style: GoogleFonts.manrope(
                                          fontSize:
                                              Breakpoints.isTablet(context)
                                              ? ResponsiveTypography.getTypography(
                                                      context,
                                                    ).normal -
                                                    4
                                              : 12,
                                          color: Colors.grey[600],
                                          height: 1.3,
                                        ),
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 8),
                              TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 1000),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: Colors.grey[600],
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          DateFormat("yyyy-MM-dd HH:mm").format(
                                            DateTime.parse(
                                              widget.blogItem.date,
                                            ),
                                          ),
                                          style: GoogleFonts.manrope(
                                            fontSize:
                                                Breakpoints.isTablet(context)
                                                ? ResponsiveTypography.getTypography(
                                                        context,
                                                      ).normal -
                                                      5
                                                : 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 6),
                              TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 1200),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Row(
                                      children: [
                                        _buildAnimatedStatItem(
                                          Icons.favorite,
                                          widget.blogItem.likes,
                                          Colors.orange,
                                          value,
                                        ),
                                        SizedBox(width: 12),
                                        _buildAnimatedStatItem(
                                          Icons.chat_bubble_outline,
                                          widget.blogItem.commentsCount,
                                          Colors.orange,
                                          value,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
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
      ),
    );
  }

  Widget _buildAnimatedStatItem(
    IconData icon,
    int count,
    Color color,
    double animationValue,
  ) {
    return Transform.scale(
      scale: animationValue,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          TweenAnimationBuilder<int>(
            duration: Duration(milliseconds: 800),
            tween: IntTween(begin: 0, end: count),
            builder: (context, value, child) {
              return Text(
                '$value',
                style: GoogleFonts.manrope(
                  fontSize: Breakpoints.isTablet(context)
                      ? ResponsiveTypography.getTypography(context).normal - 5
                      : 11,
                  color: Colors.grey[600],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _getImageWidget() {
    return Container(
      decoration: BoxDecoration(color: _getBackgroundColor()),
      child: Center(
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: HugeIcon(
                icon: _getIcon(),
                color: Colors.white70,
                size: 40,
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    Map<String, Color> colorMap = {
      'Auto Spares': Colors.grey[700]!,
      'Tyres and Rims': Colors.black87,
      'Consumer Electronics': Colors.blue[400]!,
      'Complains': Colors.red[400]!,
      'Issues': Colors.orange[600]!,
    };
    return colorMap[widget.blogItem.title] ?? Colors.grey;
  }

  IconData _getIcon() {
    Map<String, IconData> iconMap = {
      'Auto Spares': HugeIcons.strokeRoundedSettings01,
      'Tyres and Rims': HugeIcons.strokeRoundedTire,
      'Consumer Electronics': HugeIcons.strokeRoundedSmartPhone01,
      'Complains': HugeIcons.strokeRoundedComplaint,
      'Issues': HugeIcons.strokeRoundedAlert02,
    };
    return iconMap[widget.blogItem.title] ?? HugeIcons.strokeRoundedImage01;
  }
}

class BlogDetailScreen extends StatefulWidget {
  final BlogItem blogItem;
  final List<BlogItem> relatedItems;

  const BlogDetailScreen({
    Key? key,
    required this.blogItem,
    required this.relatedItems,
  }) : super(key: key);

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<BlogComment> blogComments = [
    BlogComment(
      id: 1,
      user: {'username': 'user1', 'first_name': 'John', 'last_name': 'Smith'},
      content:
          "Great article! Very informative about auto spares. This really helped me understand the importance of quality parts.",
      isApproved: true,
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
    ),
    BlogComment(
      id: 2,
      user: {
        'username': 'user2',
        'first_name': 'Sarah',
        'last_name': 'Johnson',
      },
      content:
          "I've been looking for reliable auto spares for months. This guide is exactly what I needed. Thanks for sharing!",
      isApproved: true,
      createdAt: DateTime.now().subtract(Duration(hours: 5)),
    ),
    BlogComment(
      id: 3,
      user: {'username': 'user3', 'first_name': 'Mike', 'last_name': 'Wilson'},
      content:
          "The section about brake pads was particularly helpful. Keep up the good work with these detailed posts.",
      isApproved: true,
      createdAt: DateTime.now().subtract(Duration(days: 1)),
    ),
  ];

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24),
                    child: HeaderSection(),
                  ),
                  SizedBox(height: 24),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 60,
                    width: MediaQuery.of(context).size.width,
                    color: Constants.ctaColorLight,
                    padding: Breakpoints.isTablet(context)
                        ? EdgeInsets.only(
                            left: ResponsiveSpacing.getSpacing(
                              context,
                            ).paddingLarge,
                            right: ResponsiveSpacing.getSpacing(
                              context,
                            ).paddingLarge,
                            top: ResponsiveSpacing.getSpacing(
                              context,
                            ).paddingSmall,
                            bottom: ResponsiveSpacing.getSpacing(
                              context,
                            ).paddingSmall,
                          )
                        : EdgeInsets.only(
                            left: 40,
                            right: 24,
                            top: 8,
                            bottom: 8,
                          ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: 1.0,
                          duration: Duration(milliseconds: 200),
                          child: IconButton(
                            onPressed: () {
                              // Navigate back to the first page (remove all routes until first)
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            },
                            icon: Icon(CupertinoIcons.back),
                            splashRadius: 20,
                          ),
                        ),
                        SizedBox(width: 22),
                        Text(
                          'Buyer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Breakpoints.isTablet(context)
                                ? ResponsiveTypography.getTypography(
                                    context,
                                  ).normal
                                : 16,
                            fontFamily: 'YuGothic',
                          ),
                        ),
                        Text(
                          ' Dashboard',
                          style: TextStyle(
                            color: Constants.ftaColorLight,
                            fontSize: Breakpoints.isTablet(context)
                                ? ResponsiveTypography.getTypography(
                                    context,
                                  ).normal
                                : 16,
                            fontFamily: 'YuGothic',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Center(
                    child: Padding(
                      padding: Breakpoints.isTablet(context)
                          ? EdgeInsets.only(
                              left: ResponsiveSpacing.getSpacing(
                                context,
                              ).paddingLarge,
                              right: ResponsiveSpacing.getSpacing(
                                context,
                              ).paddingLarge,
                            )
                          : const EdgeInsets.only(left: 55, right: 55),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height + 400,
                        constraints: BoxConstraints(maxWidth: 1600),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Content (Left Side)
                            Expanded(
                              flex: 2,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Hero Image with animation
                                      AnimatedContainer(
                                        duration: Duration(milliseconds: 600),
                                        width: double.infinity,
                                        height: 300,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              widget.blogItem.imageUrl,
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 24),

                                      // Title with fade animation
                                      TweenAnimationBuilder<double>(
                                        duration: Duration(milliseconds: 800),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                20 * (1 - value),
                                              ),
                                              child: Text(
                                                widget.blogItem.title,
                                                style: GoogleFonts.manrope(
                                                  fontSize:
                                                      Breakpoints.isTablet(
                                                        context,
                                                      )
                                                      ? ResponsiveTypography.getTypography(
                                                          context,
                                                        ).heading
                                                      : 32,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      Constants.ftaColorLight,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(height: 16),

                                      // Description with delayed animation
                                      TweenAnimationBuilder<double>(
                                        duration: Duration(milliseconds: 1000),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                15 * (1 - value),
                                              ),
                                              child: Text(
                                                widget.blogItem.description,
                                                style: GoogleFonts.manrope(
                                                  fontSize:
                                                      Breakpoints.isTablet(
                                                        context,
                                                      )
                                                      ? ResponsiveTypography.getTypography(
                                                          context,
                                                        ).normal
                                                      : 14,
                                                  color: Colors.black,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(height: 24),

                                      // Date and Stats with staggered animation
                                      TweenAnimationBuilder<double>(
                                        duration: Duration(milliseconds: 1200),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      HugeIcons
                                                          .strokeRoundedCalendar01,
                                                      size: 24,
                                                      color: Constants
                                                          .ftaColorLight,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      widget.blogItem.date,
                                                      style: GoogleFonts.manrope(
                                                        fontSize:
                                                            Breakpoints.isTablet(
                                                              context,
                                                            )
                                                            ? ResponsiveTypography.getTypography(
                                                                context,
                                                              ).normal
                                                            : 14,
                                                        color: Constants
                                                            .ftaColorLight,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    _buildAnimatedStatItem(
                                                      CupertinoIcons.heart_fill,
                                                      widget.blogItem.likes,
                                                      Colors.red,
                                                    ),
                                                    SizedBox(width: 16),
                                                    _buildAnimatedStatItem(
                                                      HugeIcons
                                                          .strokeRoundedMessage01,
                                                      widget
                                                          .blogItem
                                                          .commentsCount,
                                                      Colors.orange,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(height: 16),
                                      Divider(),
                                      SizedBox(height: 8),

                                      // Content with fade animation
                                      TweenAnimationBuilder<double>(
                                        duration: Duration(milliseconds: 1400),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Text(
                                              widget.blogItem.detailContent,
                                              style: GoogleFonts.manrope(
                                                fontSize:
                                                    Breakpoints.isTablet(
                                                      context,
                                                    )
                                                    ? ResponsiveTypography.getTypography(
                                                        context,
                                                      ).normal
                                                    : 14,
                                                height: 1.6,
                                                color: Colors.black,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(height: 8),
                                      Divider(),
                                      SizedBox(height: 16),

                                      Text(
                                        'Comments (${blogComments.length})',
                                        style: GoogleFonts.manrope(
                                          fontSize:
                                              Breakpoints.isTablet(context)
                                              ? ResponsiveTypography.getTypography(
                                                  context,
                                                ).large
                                              : 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 16),

                                      // Comments List with staggered animations
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: [
                                              ...blogComments.asMap().entries.map((
                                                entry,
                                              ) {
                                                int index = entry.key;
                                                BlogComment comment =
                                                    entry.value;
                                                return TweenAnimationBuilder<
                                                  double
                                                >(
                                                  duration: Duration(
                                                    milliseconds:
                                                        600 + (index * 200),
                                                  ),
                                                  tween: Tween(
                                                    begin: 0.0,
                                                    end: 1.0,
                                                  ),
                                                  builder: (context, value, child) {
                                                    return Opacity(
                                                      opacity: value,
                                                      child: Transform.translate(
                                                        offset: Offset(
                                                          30 * (1 - value),
                                                          0,
                                                        ),
                                                        child:
                                                            _buildCommentItem(
                                                              comment,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 24),

                            // Related Articles (Right Side) with slide animation
                            SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _slideController,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                              child: Container(
                                width: 350,
                                height: MediaQuery.of(context).size.height,
                                color: Colors.white,
                                //padding: EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Related Articles',
                                      style: GoogleFonts.manrope(
                                        fontSize: Breakpoints.isTablet(context)
                                            ? ResponsiveTypography.getTypography(
                                                context,
                                              ).medium
                                            : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: widget.relatedItems.length,
                                        itemBuilder: (context, index) {
                                          return TweenAnimationBuilder<double>(
                                            duration: Duration(
                                              milliseconds: 800 + (index * 150),
                                            ),
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            builder: (context, value, child) {
                                              return Opacity(
                                                opacity: value,
                                                child: Transform.translate(
                                                  offset: Offset(
                                                    20 * (1 - value),
                                                    0,
                                                  ),
                                                  child:
                                                      _buildAnimatedRelatedItem(
                                                        context,
                                                        widget
                                                            .relatedItems[index],
                                                      ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  FooterSection(logo: "lib/assets/images/bidr_logo2.png"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStatItem(IconData icon, int count, Color color) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 4),
              Text(
                '$count',
                style: GoogleFonts.manrope(
                  fontSize: Breakpoints.isTablet(context)
                      ? ResponsiveTypography.getTypography(context).normal
                      : 14,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentItem(BlogComment comment) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                child: Text(
                  comment.userName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: GoogleFonts.manrope(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.userName ?? 'Anonymous User',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _formatDate(comment.createdAt),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            comment.content,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedRelatedItem(BuildContext context, BlogItem item) {
    return GestureDetector(
      onTap: () {
        // Use pushAndRemoveUntil to go back to article section
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                BlogDetailScreen(
                  blogItem: item,
                  relatedItems: widget.relatedItems
                      .where((i) => i != item)
                      .toList(),
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          ),
                        ),
                    child: child,
                  );
                },
            transitionDuration: Duration(milliseconds: 300),
          ),
          (route) => route.settings.name == '/articles' || route.isFirst,
        );
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      BlogDetailScreen(
                        blogItem: item,
                        relatedItems: widget.relatedItems
                            .where((i) => i != item)
                            .toList(),
                      ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                          child: child,
                        );
                      },
                  transitionDuration: Duration(milliseconds: 300),
                ),
                (route) => route.settings.name == '/articles' || route.isFirst,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(item.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Text(
                        item.description,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4),
                          Text(
                            item.date,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.favorite, size: 12, color: Colors.orange),
                          SizedBox(width: 2),
                          Text(
                            '${item.likes}',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 12,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '${item.commentsCount}',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
