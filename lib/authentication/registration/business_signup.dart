import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';

import '../../constants/Constants.dart';
import '../../customWdget/customCard.dart';
import '../../customWdget/custom_input2.dart';
import 'complete_business_registration.dart';

class BusinessSignUpPage extends StatefulWidget {
  const BusinessSignUpPage({Key? key}) : super(key: key);

  @override
  State<BusinessSignUpPage> createState() => _BusinessSignUpPageState();
}

class _BusinessSignUpPageState extends State<BusinessSignUpPage> {
  int currentStep = 0;
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  bool _isLoadingLocation = false;
  PageController pageController = PageController();

  // Step 0 - User Information Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _userPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Focus nodes for user information
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _userEmailFocusNode = FocusNode();
  final FocusNode _userPhoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // Step 1 - Company Details Controllers
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _tradingNameController = TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _vatNumberController = TextEditingController();
  final TextEditingController _websiteUrlController = TextEditingController();

  // Step 2 - Company Address Controllers
  final TextEditingController _postalAddressController =
      TextEditingController();
  final TextEditingController _physicalAddressController =
      TextEditingController();
  final TextEditingController _contactPersonNameController =
      TextEditingController();
  final TextEditingController _contactPersonTelephoneController =
      TextEditingController();
  final TextEditingController _contactPersonEmailController =
      TextEditingController();
  final TextEditingController _platformWorkflowEmailController =
      TextEditingController();

  // Step 3 - Bank Account Controllers
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _branchCodeController = TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();

  // Step 4 - Product Categories 'Oil & Fluids'
  List<String> selectedCategories = [];
  final List<String> availableCategories = [
    'Engines Parts',
    'Batteries',
    'Transmission Parts',
    'Body Parts',
    'Suspension Parts',
  ];

  // Step 5 - Display on Platform
  final TextEditingController _tradingDisplayNameController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Step 6 - Authorization
  final TextEditingController _authPersonNameController =
      TextEditingController();
  final TextEditingController _authPersonEmailController =
      TextEditingController();
  final TextEditingController _authPersonPhoneController =
      TextEditingController();

  // Focus Nodes
  final Map<String, FocusNode> focusNodes = {};

  File? _uploadedDocument;
  String? _selectedLocationText;
  bool _isLoading = false;
  bool _isRegisteredNameSelected = false;
  bool isApproval = false;

  final List<StepInfo> steps = [
    StepInfo(
      title: 'User Information',
      subtitle: 'Enter Your Personal Details',
      isCompleted: false,
    ),
    StepInfo(
      title: 'OTP Verification',
      subtitle: 'Verify Your Email Address',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Company Details',
      subtitle: 'Setup Your Company Details',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Company Address',
      subtitle: 'Setup Your Company Address',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Company Bank Account',
      subtitle: 'Setup Your Bank Account',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Product Categories',
      subtitle: 'Select Your Product Categories',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Display On Platform',
      subtitle: 'Enter Name of Trading Name',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Authorization For Company',
      subtitle: 'Enter Company Authorization',
      isCompleted: false,
    ),
  ];
  Timer? _addressValidationTimer;

  void _debounceAddressValidation() {
    // Cancel previous timer if it exists
    _addressValidationTimer?.cancel();

    // Set a new timer for 1.5 seconds after user stops typing
    _addressValidationTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_physicalAddressController.text.isNotEmpty) {
        _validatePhysicalAddress();
      }
    });
  }

  void _validatePhysicalAddress() {
    // Add your address validation logic here
    String address = _physicalAddressController.text.trim();

    if (address.length < 10) {
      // Address might be too short
      print('Address might be incomplete: $address');
      return;
    }

    print('Validating address: $address');
  }

  @override
  void initState() {
    super.initState();
    _initializeFocusNodes();
    _physicalAddressController.addListener(() {
      if (_selectedLocationText != null &&
          _physicalAddressController.text.isNotEmpty) {
        setState(() {
          // Reset location selection when address changes
          _selectedLocationText = null;
        });
      }

      // If address is cleared completely, also clear the location
      if (_physicalAddressController.text.isEmpty &&
          _selectedLocationText != null) {
        setState(() {
          _selectedLocationText = null;
        });
      }

      // Optional: Auto-debounced address validation
      _debounceAddressValidation();
    });
  }

  void _initializeFocusNodes() {
    List<String> fieldNames = [
      'companyName',
      'tradingName',
      'registrationNumber',
      'vatNumber',
      'websiteUrl',
      'postalAddress',
      'physicalAddress',
      'contactPersonName',
      'contactPersonTelephone',
      'contactPersonEmail',
      'platformWorkflowEmail',
      'bankName',
      'accountNumber',
      'branchCode',
      'accountHolder',
      'tradingDisplayName',
      'description',
      'authPersonName',
      'authPersonEmail',
      'authPersonPhone',
    ];

    for (String name in fieldNames) {
      focusNodes[name] = FocusNode();
    }
  }

  @override
  void dispose() {
    focusNodes.values.forEach((node) => node.dispose());
    _postalAddressController.dispose();
    _physicalAddressController.dispose();
    _contactPersonNameController.dispose();
    _contactPersonTelephoneController.dispose();
    _contactPersonEmailController.dispose();
    _platformWorkflowEmailController.dispose();
    pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() {
        steps[currentStep].isCompleted = true;
      });

      if (currentStep < steps.length - 1) {
        setState(() {
          currentStep++;
        });

        // Animate to next page with a smooth transition
        pageController.animateToPage(
          currentStep,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        // Handle final submission
        _handleFinalSubmission();
      }
    } else {
      _showValidationError();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });

      // Animate to previous page
      pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleFinalSubmission() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API submission
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // Show success message or navigate to next screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Business registration submitted successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showValidationError() {
    String errorMessage = '';

    switch (currentStep) {
      case 0:
        errorMessage =
            'Please fill in Company Name, Trading Name, and Registration Number';
        break;
      case 1:
        errorMessage = 'Please fill in Street Address, City, and Postal Code';
        break;
      case 2:
        errorMessage = 'Please fill in Bank Name and Account Number';
        break;
      case 3:
        errorMessage = 'Please select at least one product category';
        break;
      case 4:
        errorMessage = 'Please enter a Trading Display Name';
        break;
      case 5:
        errorMessage = 'Please grant approval';
        break;
      default:
        errorMessage = 'Please complete all required fields';
    }

    _showErrorSnackBar(errorMessage);
  }

  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        return _companyNameController.text.isNotEmpty &&
            _tradingNameController.text.isNotEmpty &&
            _registrationNumberController.text.isNotEmpty;
      case 1:
        return _postalAddressController.text.isNotEmpty &&
            _physicalAddressController.text.isNotEmpty &&
            _contactPersonNameController.text.isNotEmpty &&
            _contactPersonTelephoneController.text.isNotEmpty &&
            _contactPersonEmailController.text.isNotEmpty &&
            _platformWorkflowEmailController.text.isNotEmpty;
      case 2:
        return _bankNameController.text.isNotEmpty &&
            _accountNumberController.text.isNotEmpty;
      case 3:
        return selectedCategories.isNotEmpty;
      case 4:
        return _tradingNameController.text.isNotEmpty;
      case 5:
        return true;
      default:
        return true;
    }
  }

  Future<void> _getCoordinatesFromAddress([StateSetter? setDialogState]) async {
    if (_physicalAddressController.text.isEmpty) return;

    final address = _physicalAddressController.text.trim();

    // Validate address format before geocoding
    if (address.length < 5) {
      _showLocationError('Please enter a more complete address');
      return;
    }

    try {
      if (setDialogState != null) {
        setDialogState(() {
          _isLoadingLocation = true;
        });
      } else {
        setState(() {
          _isLoadingLocation = true;
        });
      }

      print('🔍 Attempting to geocode address: "$address"');

      // Try multiple geocoding approaches
      List<Location>? locations;

      // Method 1: Direct geocoding
      try {
        locations = await locationFromAddress(address);
        print('📍 Found ${locations.length} locations using direct geocoding');
      } catch (e) {
        print('❌ Direct geocoding failed: $e');

        // Method 2: Try with formatted address variations
        final addressVariations = _generateAddressVariations(address);

        for (String variation in addressVariations) {
          try {
            print('🔄 Trying variation: "$variation"');
            locations = await locationFromAddress(variation);
            if (locations.isNotEmpty) {
              print('✅ Success with variation: "$variation"');
              break;
            }
          } catch (variationError) {
            print('❌ Variation failed: $variationError');
            continue;
          }
        }
      }

      if (locations != null && locations.isNotEmpty) {
        final location = locations.first;
        final newLocation = LatLng(location.latitude, location.longitude);

        print('✅ Geocoding successful:');
        print('   Latitude: ${location.latitude}');
        print('   Longitude: ${location.longitude}');

        if (setDialogState != null) {
          setDialogState(() {
            _currentLocation = newLocation;
            _isLoadingLocation = false;
          });
        } else {
          setState(() {
            _currentLocation = newLocation;
            _isLoadingLocation = false;
          });
        }

        _updateMarker();

        // Move camera to new location if map controller is available
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: newLocation,
                zoom: 16, // Slightly closer zoom
              ),
            ),
          );
        }

        // Show success message
        _showLocationSuccess('Location found successfully!');
      } else {
        print('❌ No locations found for address: "$address"');
        _showLocationError(
          'Could not find location for "$address". Please try:\n'
          '• Adding more details (street number, city, country)\n'
          '• Checking spelling\n'
          '• Using a different format',
        );
      }
    } on PlatformException catch (e) {
      print('❌ Platform exception during geocoding: ${e.message}');
      if (e.code == 'PERMISSION_DENIED') {
        _showLocationError(
          'Location permission denied. Please enable location services.',
        );
      } else if (e.code == 'NETWORK_ERROR') {
        _showLocationError(
          'Network error. Please check your internet connection.',
        );
      } else {
        _showLocationError('Platform error: ${e.message}');
      }
    } catch (e) {
      print('❌ Unexpected error during geocoding: $e');
      _showLocationError('Unexpected error occurred. Please try again.');
    } finally {
      if (setDialogState != null) {
        setDialogState(() {
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Generate address variations to improve geocoding success rate
  List<String> _generateAddressVariations(String originalAddress) {
    List<String> variations = [];

    // Add country if missing (adjust based on your target region)
    if (!originalAddress.toLowerCase().contains('south africa') &&
        !originalAddress.toLowerCase().contains('sa')) {
      variations.add('$originalAddress, South Africa');
      variations.add('$originalAddress, SA');
    }

    // Add common city if it seems incomplete
    if (originalAddress.split(',').length < 2) {
      variations.add('$originalAddress, Johannesburg, South Africa');
      variations.add('$originalAddress, Cape Town, South Africa');
      variations.add('$originalAddress, Durban, South Africa');
    }

    // Try with postal code format adjustments
    final cleanAddress = originalAddress.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanAddress != originalAddress) {
      variations.add(cleanAddress);
    }

    return variations;
  }

  // Show success message
  void _showLocationSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Enhanced error message function
  void _showLocationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: () {
              _getCoordinatesFromAddress();
            },
          ),
        ),
      );
    }
  }

  // Get address from coordinates (reverse geocoding)
  Future<void> _getAddressFromCoordinates(LatLng coordinates) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address =
            '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';

        // Optionally update the physical address controller with the new address
        // _physicalAddressController.text = address;

        print('Address for coordinates: $address');
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
  }

  // Update marker on map
  void _updateMarker() {
    if (_currentLocation != null) {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _currentLocation!,
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: _physicalAddressController.text.isNotEmpty
                ? _physicalAddressController.text
                : 'Custom location',
          ),
        ),
      };
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,

                child: Row(
                  children: [
                    // Left Side - Stepper
                    Expanded(
                      flex: 2,
                      child: Container(
                        width: 350,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(0),
                            bottomLeft: Radius.circular(0),
                          ),
                          color: const Color(0xFF1B365D),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 24,
                                top: 32,
                                right: 24,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Seller Sign Up',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 24.0,
                                ),
                                child: Column(
                                  children: steps.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    return _buildStepItem(index);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right Side - Form
                    Expanded(
                      flex: 5,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.all(32),
                        constraints: BoxConstraints(
                          maxWidth: 850,
                          maxHeight: 1200,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Header
                            currentStep == steps.length - 1 && isApproval
                                ? SizedBox.shrink()
                                : SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.4,
                                    child: Row(
                                      children: [
                                        currentStep > 0
                                            ? IconButton(
                                                onPressed: currentStep > 0
                                                    ? _previousStep
                                                    : null,
                                                style: IconButton.styleFrom(
                                                  backgroundColor:
                                                      Constants.ftaColorLight,
                                                  foregroundColor:
                                                      Constants.ctaColorLight,
                                                  elevation: 5,
                                                  shadowColor: Colors.black54,
                                                ),
                                                icon: Icon(
                                                  CupertinoIcons.back,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : SizedBox.shrink(),
                                        currentStep > 0
                                            ? const SizedBox(width: 20)
                                            : SizedBox.shrink(),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Application to Register a Business',
                                              style: GoogleFonts.manrope(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Constants.ftaColorLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                            currentStep == steps.length - 1 && isApproval
                                ? SizedBox.shrink()
                                : (currentStep > 0
                                      ? SizedBox.shrink()
                                      : const SizedBox(height: 16)),

                            // Description
                            currentStep == steps.length - 1 && isApproval
                                ? SizedBox.shrink()
                                : (currentStep > 0
                                      ? SizedBox.shrink()
                                      : SizedBox(
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.4,
                                          child: Text(
                                            'This page will allow you to register a business in a few easy steps. Please provide all the required information. Once the application has been received, the information will be vetted and we will inform you of the status thereof. If successful, the business will be added to our database and you will immediately be eligible to receive requests as per the selections in this application.',
                                            textAlign: TextAlign.justify,
                                            style: GoogleFonts.manrope(
                                              fontSize: 16,
                                              color: Colors.grey.shade500,
                                              height: 1.5,
                                            ),
                                          ),
                                        )),

                            currentStep == steps.length - 1 && isApproval
                                ? SizedBox.shrink()
                                : const SizedBox(height: 24),

                            // Form Content
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 800),
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      return SlideTransition(
                                        position:
                                            Tween<Offset>(
                                              begin: const Offset(0.1, 0),
                                              end: Offset.zero,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeInOutCubic,
                                              ),
                                            ),
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.4,
                                  child: Center(
                                    child: PageView(
                                      controller: pageController,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      children: [
                                        _buildUserInformationForm(),
                                        _buildOTPVerificationForm(),
                                        _buildCompanyDetailsForm(),
                                        _buildCompanyAddressForm(),
                                        _buildBankAccountForm(),
                                        _buildProductCategoriesForm(),
                                        _buildDisplayOnPlatformForm(),
                                        currentStep == steps.length - 1 &&
                                                isApproval
                                            ? BusinessRegistrationCompleteWidget()
                                            : _buildAuthorizationForm(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Navigation Button
                            const SizedBox(height: 24),
                            currentStep == steps.length - 1 && isApproval
                                ? Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.4,
                                      height: 45,
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Constants.ctaColorLight,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          elevation: _isLoading ? 0 : 2,
                                          shadowColor: Constants.ctaColorLight
                                              .withOpacity(0.3),
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 600,
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  key: ValueKey('loading'),
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : Text(
                                                  'Enter BIDR Word',
                                                  key: ValueKey(
                                                    'text_${currentStep}',
                                                  ),
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.4,
                                      height: 45,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _nextStep,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Constants.ctaColorLight,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          elevation: _isLoading ? 0 : 2,
                                          shadowColor: Constants.ctaColorLight
                                              .withOpacity(0.3),
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 600,
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  key: ValueKey('loading'),
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : Text(
                                                  currentStep ==
                                                          steps.length - 1
                                                      ? 'Submit Application'
                                                      : 'Next',
                                                  key: ValueKey(
                                                    'text_${currentStep}',
                                                  ),
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int index) {
    bool isActive = index == currentStep;
    bool isCompleted = steps[index].isCompleted;
    bool isLastStep = index == steps.length - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical line and circle container
          SizedBox(
            width: 35,
            child: Column(
              children: [
                // Circle with number or checkmark
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Constants.ctaColorLight
                        : isActive
                        ? Constants.ctaColorLight
                        : Colors.grey[300],
                    boxShadow: isActive || isCompleted
                        ? [
                            BoxShadow(
                              color: Constants.ctaColorLight.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                              key: ValueKey('check'),
                            )
                          : Text(
                              '${index + 1}',
                              key: ValueKey('number_$index'),
                              style: GoogleFonts.manrope(
                                color: isActive
                                    ? Colors.white
                                    : Constants.ftaColorLight,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),

                // Vertical line (only if not last step)
                if (!isLastStep)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 2,
                    height: 50,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: (isCompleted || index < currentStep)
                          ? Constants.ctaColorLight
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Step info
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 0, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 600),
                    style: GoogleFonts.manrope(
                      color: isActive ? Constants.ctaColorLight : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    child: Text(steps[index].title),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[index].subtitle,
                    style: GoogleFonts.manrope(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInformationForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your personal details to get started',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'First Name',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomInputTransparent4(
                      hintText: 'Enter first name',
                      controller: _firstNameController,
                      focusNode: _firstNameFocusNode,
                      textInputAction: TextInputAction.next,
                      isPasswordField: false,
                      onChanged: (value) {},
                      onSubmitted: (value) {
                        _lastNameFocusNode.requestFocus();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Name',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomInputTransparent4(
                      hintText: 'Enter last name',
                      controller: _lastNameController,
                      focusNode: _lastNameFocusNode,
                      textInputAction: TextInputAction.next,
                      isPasswordField: false,
                      onChanged: (value) {},
                      onSubmitted: (value) {
                        _userEmailFocusNode.requestFocus();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Email Address',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          CustomInputTransparent4(
            hintText: 'Enter email address',
            controller: _userEmailController,
            focusNode: _userEmailFocusNode,
            textInputAction: TextInputAction.next,
            isPasswordField: false,
            onChanged: (value) {},
            onSubmitted: (value) {
              _userPhoneFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Phone Number',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          CustomInputTransparent4(
            hintText: 'Enter phone number',
            controller: _userPhoneController,
            focusNode: _userPhoneFocusNode,
            textInputAction: TextInputAction.next,
            isPasswordField: false,
            onChanged: (value) {},
            onSubmitted: (value) {
              _passwordFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Password',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          CustomInputTransparent4(
            hintText: 'Enter password',
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            textInputAction: TextInputAction.next,
            isPasswordField: true,
            onChanged: (value) {},
            onSubmitted: (value) {
              _confirmPasswordFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Confirm Password',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          CustomInputTransparent4(
            hintText: 'Confirm password',
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            textInputAction: TextInputAction.done,
            isPasswordField: true,
            onChanged: (value) {},
            onSubmitted: (value) {},
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildOTPVerificationForm() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email Verification',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We have sent a verification code to \${_userEmailController.text}',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Enter Verification Code',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'OTP verification will be implemented here',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              // Resend OTP logic
            },
            child: Text(
              'Resend Code',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Constants.ctaColorLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDetailsForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField(
            'Registered Company Name (CIPC)',
            'Enter Registered Company Name',
            _companyNameController,
            focusNodes['companyName']!,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'Trading Name',
            'Enter Company Trading Name',
            _tradingNameController,
            focusNodes['tradingName']!,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'Registration Number',
            'Enter Registration Number',
            _registrationNumberController,
            focusNodes['registrationNumber']!,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'VAT Number',
            'Enter VAT Number',
            _vatNumberController,
            focusNodes['vatNumber']!,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'Website URL',
            'Enter Company Website URL',
            _websiteUrlController,
            focusNodes['websiteUrl']!,
          ),
          const SizedBox(height: 24),
          _buildFileUploadField(),
        ],
      ),
    );
  }

  Widget _buildCompanyAddressForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField(
            'Postal Address',
            'Enter Postal Address',
            _postalAddressController,
            focusNodes['postalAddress']!,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'Physical Address',
            'Enter Physical Address',
            _physicalAddressController,
            focusNodes['physicalAddress']!,
          ),
          const SizedBox(height: 24),
          _buildLocationDropdown(),
          const SizedBox(height: 24),
          _buildInputField(
            'Contact Person Name',
            'Enter Contact Person Name',
            _contactPersonNameController,
            focusNodes['contactPersonName']!,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'Contact Person Telephone',
            'Enter Contact Person Telephone',
            _contactPersonTelephoneController,
            focusNodes['contactPersonTelephone']!,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'Contact Person Email Address',
            'Enter Contact Person Email Address',
            _contactPersonEmailController,
            focusNodes['contactPersonEmail']!,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'Platform Workflow Email Address',
            'Enter Contact Person Email Address',
            _platformWorkflowEmailController,
            focusNodes['platformWorkflowEmail']!,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showLocationPickerDialog,
            icon: Icon(
              Icons.location_on_outlined,
              color: _selectedLocationText != null
                  ? Colors.white
                  : Colors.grey[600],
              size: 20,
            ),
            label: Text(
              _selectedLocationText ?? 'Select Location',
              style: GoogleFonts.manrope(
                color: _selectedLocationText != null
                    ? Colors.white
                    : Colors.grey[600],
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedLocationText != null
                  ? const Color(0xFFF5A623)
                  : Colors.grey[100],
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
      ],
    );
  }

  void _showLocationPickerDialog() {
    // Initialize location when dialog opens
    _initializeLocationFromAddress();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.6,
                constraints: BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Location',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Map Container
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Search/Address input with refresh button
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.search, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _physicalAddressController.text.isEmpty
                                          ? 'Enter physical address above to show location'
                                          : _physicalAddressController.text,
                                      style: GoogleFonts.manrope(
                                        color:
                                            _physicalAddressController
                                                .text
                                                .isEmpty
                                            ? Colors.grey[600]
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (_physicalAddressController
                                      .text
                                      .isNotEmpty)
                                    IconButton(
                                      onPressed: () {
                                        _getCoordinatesFromAddress(
                                          setDialogState,
                                        );
                                      },
                                      icon: _isLoadingLocation
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.grey[600]!),
                                              ),
                                            )
                                          : Icon(
                                              Icons.refresh,
                                              color: Colors.grey[600],
                                            ),
                                      tooltip: 'Refresh location',
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Google Maps
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _currentLocation != null
                                      ? GoogleMap(
                                          initialCameraPosition: CameraPosition(
                                            target: _currentLocation!,
                                            zoom: 15,
                                          ),
                                          markers: _markers,
                                          onMapCreated:
                                              (GoogleMapController controller) {
                                                _mapController = controller;
                                              },
                                          onTap: (LatLng tappedLocation) {
                                            setDialogState(() {
                                              _currentLocation = tappedLocation;
                                              _updateMarker();
                                            });
                                            _getAddressFromCoordinates(
                                              tappedLocation,
                                            );
                                          },
                                          myLocationEnabled: true,
                                          myLocationButtonEnabled: true,
                                          mapType: MapType.normal,
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (_isLoadingLocation)
                                                  const CircularProgressIndicator()
                                                else ...[
                                                  Icon(
                                                    Icons.map_outlined,
                                                    size: 48,
                                                    color: Colors.grey[400],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    _physicalAddressController
                                                            .text
                                                            .isEmpty
                                                        ? 'Enter physical address to show location'
                                                        : 'Tap refresh to load location',
                                                    style: GoogleFonts.manrope(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Footer buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _currentLocation != null
                                  ? () {
                                      setState(() {
                                        _selectedLocationText =
                                            _physicalAddressController
                                                .text
                                                .isEmpty
                                            ? 'Custom Location Selected'
                                            : _physicalAddressController.text;
                                      });
                                      Navigator.of(context).pop();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5A623),
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                              child: Text(
                                'Confirm Location',
                                style: GoogleFonts.manrope(color: Colors.white),
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
          },
        );
      },
    );
  }

  // Initialize location when dialog opens
  void _initializeLocationFromAddress() {
    if (_physicalAddressController.text.isNotEmpty) {
      _getCoordinatesFromAddress(null);
    }
  }

  // Get coordinates from physical address

  Widget _buildBankAccountForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField(
            'Bank Name',
            'Enter Bank Name',
            _bankNameController,
            focusNodes['bankName']!,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'Account Number',
            'Enter Account Number',
            _accountNumberController,
            focusNodes['accountNumber']!,
            integersOnly: true,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'Branch Code',
            'Enter Branch Code',
            _branchCodeController,
            focusNodes['branchCode']!,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'Account Holder Name',
            'Enter Account Holder Name',
            _accountHolderController,
            focusNodes['accountHolder']!,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCategoriesForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Product Categories',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose the categories that best describe your products:',
            style: GoogleFonts.manrope(fontSize: 13, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: availableCategories.map((category) {
              bool isSelected = selectedCategories.contains(category);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedCategories.remove(category);
                    } else {
                      selectedCategories.add(category);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Constants.ctaColorLight
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? Constants.ctaColorLight
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.manrope(
                      color: isSelected ? Colors.white : Color(0xFF666666),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayOnPlatformForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Registered Name with Checkbox
          _buildRegisteredNameWithCheckbox("Registered name"),
          const SizedBox(height: 24),
          // Trading Name
          _buildInputField(
            'Trading Name',
            'Enter Trading Name',
            _tradingNameController,
            focusNodes['tradingName']!,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredNameWithCheckbox(String desName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Constants.ftaColorLight),
            borderRadius: BorderRadius.circular(360),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  desName,
                  style: GoogleFonts.manrope(color: Colors.black, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isRegisteredNameSelected = !_isRegisteredNameSelected;
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _isRegisteredNameSelected
                        ? Constants.ctaColorLight
                        : Colors.transparent,
                    border: Border.all(
                      color: _isRegisteredNameSelected
                          ? Constants.ctaColorLight
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(360),
                  ),
                  child: _isRegisteredNameSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalNameWithCheckbox(String desName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Constants.ftaColorLight),
            borderRadius: BorderRadius.circular(360),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  desName,
                  style: GoogleFonts.manrope(color: Colors.black, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isApproval = !isApproval;
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isApproval
                        ? Constants.ctaColorLight
                        : Colors.transparent,
                    border: Border.all(
                      color: isApproval
                          ? Constants.ctaColorLight
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(360),
                  ),
                  child: isApproval
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorizationForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildApprovalNameWithCheckbox("Grant Approval")],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    FocusNode focusNode, {
    bool integersOnly = false,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 8),
        CustomInputTransparent4(
          hintText: hint,
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.next,
          isPasswordField: false,
          integersOnly: integersOnly,
          maxLines: maxLines,
          onChanged: (value) {},
          onSubmitted: (value) {},
        ),
      ],
    );
  }

  Widget _buildFileUploadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload CIPC Documents',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // Handle file upload
            print('Upload CIPC documents');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
              color: const Color(0xFFF8F9FA),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  color: Color(0xFF999999),
                ),
                const SizedBox(width: 12),
                Text(
                  _uploadedDocument != null
                      ? 'Document uploaded'
                      : 'Upload CIPC Documents',
                  style: GoogleFonts.manrope(
                    color: Color(0xFF999999),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class StepInfo {
  final String title;
  final String subtitle;
  bool isCompleted;

  StepInfo({
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
  });
}
