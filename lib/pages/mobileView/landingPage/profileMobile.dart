import 'package:bidr/constants/Constants.dart';
import 'package:bidr/pages/mobileView/landingPage/blogcardMobileView.dart';
import 'package:bidr/pages/mobileView/landingPage/faqMobileView.dart';
import 'package:bidr/pages/mobileView/landingPage/policiesMobileView.dart';
import 'package:bidr/pages/mobileView/landingPage/supportMobileView.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../customWdget/appbar.dart';
import '../../../customWdget/custom_input2.dart';
import '../../../customWdget/mobileBottomNavBar.dart';
import '../../../services/auth_api_service.dart';
import '../../../services/shared_preferences.dart';
import '../../buyer_home.dart';
import 'contactUsMobileView.dart';
import 'landingMobileController.dart';
import 'landingMobileViewPage.dart';


class ProfileMobilePage extends StatefulWidget {
  @override
  _ProfileMobilePageState createState() => _ProfileMobilePageState();
}
 bool isBackButtonDisplayed = false;
class _ProfileMobilePageState extends State<ProfileMobilePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<ProfileMenuItem> menuItems = [
    ProfileMenuItem(
      title: 'Edit Profile',
      icon: Icons.edit,
      route: '/edit-profile',
    ),
    ProfileMenuItem(
      title: 'Change Password',
      icon: Icons.lock,
      route: '/change-password',
    ),
    ProfileMenuItem(
      title: 'FAQs',
      icon: Icons.help_outline,
      route: '/faqs',
    ),
    ProfileMenuItem(
      title: 'Policies',
      icon: Icons.policy,
      route: '/policies',
    ),
    ProfileMenuItem(
      title: 'Blogs',
      icon: Icons.article,
      route: '/blogs',
    ),
    ProfileMenuItem(
      title: 'Get Quote',
      icon: Icons.request_quote,
      route: '/get-quote',
    ),
    ProfileMenuItem(
      title: 'Message Board',
      icon: Icons.message,
      route: '/message-board',
    ),
    ProfileMenuItem(
      title: 'Contact Us',
      icon: Icons.contact_support,
      route: '/contact-us',
    ),
    ProfileMenuItem(
      title: 'Sign Out',
      icon: Icons.logout,
      route: '/sign-out',
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();//BlogCardsMobileScreen
    super.dispose();
  }

  void _navigateToPage(String route, String title) {
    // Navigate to specific pages based on title
    Widget page;
    switch (title) {
      case 'Edit Profile':
        page = EditProfileMobilePage();
        break;
      case 'Change Password':
        page = ChangePasswordPage();
        break;
      case "FAQs":
        page = FAQMobileScreen();
        break;
      case 'Policies':
        page = PoliciesMobileScreen();
        break;
      case 'Blogs':
        page = BlogCardsMobileScreen();
        break;
      case 'Get Quote':
        page = GetQuotePage();
        break;
      case 'Message Board':
        page = MessageBoardPage();
        break;
      case 'Contact Us':
        page = ContactFormMobileScreen();
        break;
      case 'Sign Out':
        page = SignOutPage();
        break;
      default:
        page = DetailPage(title: title);
        break;
    }
    isBackButtonDisplayed = true;
    Navigator.push(
      context,
      SlidePageRoute(page: page),
    );
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading:isFromDashboard?
        IconButton(
          onPressed:(){
            Constants.buyerAppBarValue = 6;
            appBarValueNotifier.value++;
            buyerHomeValueNotifier.value++;
            buyerHomeMobileValueNotifier.value++;
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
          "Profile",
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
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListView.builder(
                    itemCount: menuItems.length,
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.only(bottom: 12),
                        child: ProfileMenuTile(
                          menuItem: menuItems[index],
                          onTap: () => _navigateToPage(
                            menuItems[index].route,
                            menuItems[index].title,
                          ),
                          animationDelay: index * 100,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  _buildDeleteAccountButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: () {
          _showDeleteAccountDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[400],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
          ),
          elevation: 4,
        ),
        child: Text(
          'Delete Account',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Account',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          content: Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
            style: GoogleFonts.manrope(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Account deletion cancelled'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.manrope(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom Page Route for smooth animations
class SlidePageRoute extends PageRouteBuilder {
  final Widget page;

  SlidePageRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
    transitionDuration: Duration(milliseconds: 400),
  );
}

class ProfileMenuItem {
  final String title;
  final IconData icon;
  final String route;

  ProfileMenuItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class ProfileMenuTile extends StatefulWidget {
  final ProfileMenuItem menuItem;
  final VoidCallback onTap;
  final int animationDelay;

  const ProfileMenuTile({
    Key? key,
    required this.menuItem,
    required this.onTap,
    required this.animationDelay,
  }) : super(key: key);

  @override
  _ProfileMenuTileState createState() => _ProfileMenuTileState();
}

class _ProfileMenuTileState extends State<ProfileMenuTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        onTap: () {
          _scaleController.forward().then((_) {
            _scaleController.reverse();
            widget.onTap();
          });
        },
        onTapDown: (_) => _scaleController.forward(),
        onTapCancel: () => _scaleController.reverse(),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 50,
          child: Row(
            children: [

              Expanded(
                child: Text(
                  widget.menuItem.title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.black87),
                  shape: BoxShape.circle
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black87,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Edit Profile Page
class EditProfileMobilePage extends StatefulWidget {
  @override
  _EditProfileMobilePageState createState() => _EditProfileMobilePageState();
}

class _EditProfileMobilePageState extends State<EditProfileMobilePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,//BlogCardsMobileScreen
    ));
    _fadeController.forward();

    // Load sample data
    _firstNameController.text = Constants.myDisplayname;
    _lastNameController.text = Constants.myDisplayname;
    _mobileController.text = Constants.myCell;
    _emailController.text = Constants.myEmail;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _mobileFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _saveProfile() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    });
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
          "Edit Profile",
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
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Update your personal information',
                style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[600]),
              ),
              SizedBox(height: 32),

              _buildMobileInputField(
                'First Name',
                'Enter First Name',
                _firstNameController,
                _firstNameFocusNode,
                TextInputAction.next,
                onSubmitted: (value) => _lastNameFocusNode.requestFocus(),
              ),
              SizedBox(height: 24),

              _buildMobileInputField(
                'Last Name',
                'Enter Last Name',
                _lastNameController,
                _lastNameFocusNode,
                TextInputAction.next,
                onSubmitted: (value) => _mobileFocusNode.requestFocus(),
              ),
              SizedBox(height: 24),

              _buildMobileInputField(
                'Mobile Number',
                'Enter Mobile Number',
                _mobileController,
                _mobileFocusNode,
                TextInputAction.next,
                onSubmitted: (value) => _emailFocusNode.requestFocus(),
              ),
              SizedBox(height: 24),

              _buildMobileInputField(
                'Email',
                'Enter Email',
                _emailController,
                _emailFocusNode,
                TextInputAction.done,
              ),
              SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ftaColorLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'Save Changes',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileInputField(
    String label,
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    TextInputAction textInputAction, {
    bool isPassword = false,
    int maxLines = 1,
    final void Function(String)? onSubmitted,
  }) {
    return SizedBox(
      width: double.infinity,
      child: CustomInputTransparent4(
        hintText: hintText.replaceAll('*', ''),
        labelText: hintText,
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        isPasswordField: isPassword,
        onChanged: (value) {},
        onSubmitted: onSubmitted ?? (value) {},
        maxLines: maxLines,
      ),
    );
  }
}

// Change Password Page
class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _currentPasswordFocusNode = FocusNode();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _changePassword() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
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
          "Edit Password",
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
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Password',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Update your account password',
                style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[600]),
              ),
              SizedBox(height: 32),

              _buildMobileInputField(
                'Current Password',
                'Enter current password',
                _currentPasswordController,
                _currentPasswordFocusNode,
                TextInputAction.next,
                isPassword: true,
                onSubmitted: (value) => _newPasswordFocusNode.requestFocus(),
              ),
              SizedBox(height: 24),

              _buildMobileInputField(
                'New Password',
                'Enter new password',
                _newPasswordController,
                _newPasswordFocusNode,
                TextInputAction.next,
                isPassword: true,
                onSubmitted: (value) => _confirmPasswordFocusNode.requestFocus(),
              ),
              SizedBox(height: 24),

              _buildMobileInputField(
                'Confirm New Password',
                'Confirm your new password',
                _confirmPasswordController,
                _confirmPasswordFocusNode,
                TextInputAction.done,
                isPassword: true,
              ),
              SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ftaColorLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'Change Password',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileInputField(
    String label,
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    TextInputAction textInputAction, {
    bool isPassword = false,
    int maxLines = 1,
    final void Function(String)? onSubmitted,
  }) {
    return SizedBox(
      width: double.infinity,
      child: CustomInputTransparent4(
        hintText: hintText.replaceAll('*', ''),
        labelText: hintText,
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        isPasswordField: isPassword,
        onChanged: (value) {},
        onSubmitted: onSubmitted ?? (value) {},
        maxLines: maxLines,
      ),
    );
  }
}

// Get Quote Page
class GetQuotePage extends StatefulWidget {
  @override
  _GetQuotePageState createState() => _GetQuotePageState();
}

class _GetQuotePageState extends State<GetQuotePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _projectDetailsController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _companyFocusNode = FocusNode();
  final FocusNode _projectDetailsFocusNode = FocusNode();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _projectDetailsController.dispose();
    _emailFocusNode.dispose();
    _companyFocusNode.dispose();
    _projectDetailsFocusNode.dispose();
    super.dispose();
  }

  void _requestQuote() {
    if (_emailController.text.isEmpty || _companyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quote request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _emailController.clear();
      _companyController.clear();
      _projectDetailsController.clear();
    });
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
              borderRadius: BorderRadius.circular(36),
            ),
          ),
          icon: Icon(
            CupertinoIcons.back,
            color: Constants.ftaColorLight,
          ),
        ),
        title: Text(
          "Get Quote",
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
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get Quotes',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Request quotes for your projects',
                style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[600]),
              ),
              SizedBox(height: 32),

              _buildMobileInputField(
                'Email',
                'Enter your email',
                _emailController,
                _emailFocusNode,
                TextInputAction.next,
                onSubmitted: (value) => _companyFocusNode.requestFocus(),
              ),
              SizedBox(height: 24),

              _buildMobileInputField(
                'Company Name*',
                'Enter company name',
                _companyController,
                _companyFocusNode,
                TextInputAction.next,
                onSubmitted: (value) => _projectDetailsFocusNode.requestFocus(),
              ),
              SizedBox(height: 24),

              _buildMobileInputField(
                'Project Details',
                'Describe your project requirements',
                _projectDetailsController,
                _projectDetailsFocusNode,
                TextInputAction.done,
                maxLines: 5,
              ),
              SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ftaColorLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'Request Quote',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileInputField(
    String label,
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    TextInputAction textInputAction, {
    bool isPassword = false,
    int maxLines = 1,
    final void Function(String)? onSubmitted,
  }) {
    return SizedBox(
      width: double.infinity,
      child: CustomInputTransparent4(
        hintText: hintText.replaceAll('*', ''),
        labelText: hintText,
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        isPasswordField: isPassword,
        onChanged: (value) {},
        onSubmitted: onSubmitted ?? (value) {},
        maxLines: maxLines,
      ),
    );
  }
}

// Message Board Page
class MessageBoardPage extends StatefulWidget {
  @override
  _MessageBoardPageState createState() => _MessageBoardPageState();
}

class _MessageBoardPageState extends State<MessageBoardPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final FocusNode _subjectFocusNode = FocusNode();
  final FocusNode _messageFocusNode = FocusNode();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _subjectFocusNode.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide both subject and message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _subjectController.clear();
      _messageController.clear();
    });
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
              borderRadius: BorderRadius.circular(36),
            ),
          ),
          icon: Icon(
            CupertinoIcons.back,
            color: Constants.ftaColorLight,
          ),
        ),
        title: Text(
          "Message Board",
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
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Text(
                'Send us a message or feedback',
                style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[600]),
              ),
              SizedBox(height: 32),

              _buildMobileInputField(
                'Subject',
                'Enter message subject',
                _subjectController,
                _subjectFocusNode,
                TextInputAction.next,
                onSubmitted: (value) => _messageFocusNode.requestFocus(),
              ),
              SizedBox(height: 24),

              _buildMobileInputField(
                'Message',
                'Type your message here',
                _messageController,
                _messageFocusNode,
                TextInputAction.done,
                maxLines: 6,
              ),
              SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ftaColorLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(360),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'Send Message',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileInputField(
      String label,
      String hintText,
      TextEditingController controller,
      FocusNode focusNode,
      TextInputAction textInputAction, {
        bool isPassword = false,
        int maxLines = 1,
        final void Function(String)? onSubmitted,
      }) {
    return SizedBox(
      width: double.infinity,
      child: CustomInputTransparent4(
        hintText: hintText.replaceAll('*', ''),
        labelText: hintText,
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        isPasswordField: isPassword,
        onChanged: (value) {},
        onSubmitted: onSubmitted ?? (value) {},
        maxLines: maxLines,
      ),
    );
  }
}

// Sign Out Page
class SignOutPage extends StatefulWidget {
  @override
  _SignOutPageState createState() => _SignOutPageState();
}

class _SignOutPageState extends State<SignOutPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isPasswordLoading =false;
  final AuthApiService _authService = AuthApiService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildSignOutContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign Out',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign out from your account',
          style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    HugeIcons.strokeRoundedInformationCircle,
                    color: Colors.orange[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Are you sure you want to sign out?',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'You will be redirected to the login screen and will need to enter your credentials to access your account again.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Constants.ftaColorLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(360),
                  ),
                  side: BorderSide(color: Constants.ftaColorLight),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(360),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
            setState(() {});
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
          "Sign Out",
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildSignOutContent(),
        ),
      ),
    );
  }
  void _signOut() async {
    setState(() {
      _isPasswordLoading = true;
    });

    try {
      final accessToken =
      await Sharedprefs.getUserAccessTokenSharedPreference();
      final refreshToken =
      await Sharedprefs.getUserRefreshTokenSharedPreference();

      if (accessToken != null && refreshToken != null) {
        await _authService.signOut(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      await _clearAllUserData();
      _showSuccessMessage('Signed out successfully');
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          context.go('/getstarted');
        }
      });
    } catch (e) {
      await _clearAllUserData();
      if (mounted) {
        context.go('/getstarted');
      }
    } finally {
      setState(() {
        _isPasswordLoading = false;
      });
    }
  }

  Future<void> _clearAllUserData() async {
    await Sharedprefs.saveUserLoggedInSharedPreference(false);
    await Sharedprefs.saveUserAccessTokenSharedPreference('');
    await Sharedprefs.saveUserRefreshTokenSharedPreference('');
    await Sharedprefs.saveUserIdSharedPreference(-1);
    await Sharedprefs.saveUserUidSharedPreference('');
    await Sharedprefs.saveUserEmailSharedPreference('');
    await Sharedprefs.saveUserNameSharedPreference('');
    await Sharedprefs.saveUserRoleSharedPreference('');
    await Sharedprefs.saveUserCellSharedPreference('');
    await Sharedprefs.saveBusinessIdSharedPreference(-1);
    await Sharedprefs.saveBusinessUidSharedPreference('');
    await Sharedprefs.saveBusinessNameSharedPreference('');
    await Sharedprefs.saveBusinessEmailSharedPreference('');
    await Sharedprefs.saveBusinessPhoneNumberSharedPreference('');

    Constants.myUid = '';
    Constants.userId = -1;
    Constants.myCell = '';
    Constants.myDisplayname = '';
    Constants.myCategoryRole = '';
    Constants.myUsername = '';
    Constants.myEmail = '';
    Constants.business_name = '';
    Constants.business_email = '';
    Constants.business_phone_number = '';
    Constants.business_id = -1;
    Constants.business_uid = '';
  }

  // Helper methods for showing messages
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// Default Detail Page for other menu items
class DetailPage extends StatefulWidget {
  final String title;

  const DetailPage({Key? key, required this.title}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _bounceController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bounceController.dispose();
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
              borderRadius: BorderRadius.circular(36),
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ScaleTransition(
            scale: _bounceAnimation,
            child: Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 80,
                  ),
                  SizedBox(height: 20),
                  Text(
                    '${widget.title} Page',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'This is the ${widget.title.toLowerCase()} page content. You can add your specific content here.',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ftaColorLight,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Go Back',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}