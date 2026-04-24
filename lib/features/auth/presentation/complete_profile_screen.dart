import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bharatstock/features/auth/logic/user_service.dart';
import 'package:bharatstock/core/constants/gst_constants.dart';
import 'package:bharatstock/core/utils/tax_calculator.dart';
import 'package:bharatstock/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:bharatstock/core/services/firestore_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _legalNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  // Address
  final TextEditingController _flatShopController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  // GST & Tax
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _panController = TextEditingController();

  // Bank
  final TextEditingController _bankAccController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();

  String _selectedStateCode = '';
  String? _userImageUrl;
  String? _signatureImageUrl;

  bool _isLoading = false;
  bool _isUploadingImage = false;

  void _pickAndUploadImage({required bool isSignature}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final File file = File(image.path);
      final folder = isSignature ? 'signatures' : 'profiles';
      final downloadUrl = await _userService.uploadImage(file, folder);

      setState(() {
        if (isSignature) {
          _signatureImageUrl = downloadUrl;
        } else {
          _userImageUrl = downloadUrl;
        }
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload Failed: $e")));
      }
    }
  }

  void _saveProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _legalNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Name and Legal Business Name are required."),
        ),
      );
      return;
    }

    // Validate GSTIN & State Code Logic
    final gstin = _gstinController.text.trim().toUpperCase();
    if (gstin.isNotEmpty) {
      if (!TaxCalculator.validateGstin(gstin)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid GSTIN format.")));
        return;
      }

      // Auto-Match / Validation: First 2 digits must match selected state code
      if (_selectedStateCode.isNotEmpty) {
        final gstinStateCode = gstin.substring(0, 2);
        if (gstinStateCode != _selectedStateCode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "GSTIN prefix ($gstinStateCode) doesn't match selected state.",
              ),
            ),
          );
          return;
        }
      } else {
        final gstinStateCode = gstin.substring(0, 2);
        if (GstConstants.stateCodes.containsKey(gstinStateCode)) {
          setState(() => _selectedStateCode = gstinStateCode);
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      // Role is always admin as per user request (no role selection)
      const role = 'admin';
      const businessId = ''; // Will be generated in UserService

      await _userService.saveUserProfile(
        fullName: _nameController.text.trim(),
        legalBusinessName: _legalNameController.text.trim(),
        flatShopNo: _flatShopController.text.trim(),
        area: _areaController.text.trim(),
        city: _cityController.text.trim(),
        pincode: _pincodeController.text.trim(),
        gstin: gstin,
        businessStateCode: _selectedStateCode,
        pan: _panController.text.trim(),
        bankAccountNo: _bankAccController.text.trim(),
        bankIfsc: _ifscController.text.trim(),
        phoneNumber: _mobileController.text.trim(),
        userImageUrl: _userImageUrl ?? '',
        signatureImageUrl: _signatureImageUrl ?? '',
        role: role,
        businessId: businessId,
      );

      // Initialize FirestoreService with the new businessId
      final newUser = await _userService.getCurrentUser();
      if (newUser != null && newUser.businessId.isNotEmpty) {
        FirestoreService().setBusinessId(newUser.businessId);
      }

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFF2F4F8);

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: const Text(
          "Setup Your Business",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        centerTitle: true,
        backgroundColor: baseColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Welcome to BharatStock",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Complete your profile for GST compliance",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // --- User Image ---
            GestureDetector(
              onTap: () => _pickAndUploadImage(isSignature: false),
              child: ClayContainer(
                borderRadius: 75,
                depth: 20,
                color: baseColor,
                height: 120,
                width: 120,
                child: _userImageUrl != null && _userImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(75),
                        child: _buildImageWidget(_userImageUrl!),
                      )
                    : const Icon(
                        Icons.add_a_photo,
                        size: 50,
                        color: Colors.grey,
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Basic Info ---
            ClayContainer(
              color: baseColor,
              borderRadius: 20,
              depth: 10,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTextField(
                      _nameController,
                      "Your Full Name",
                      Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _legalNameController,
                      "Legal Business Name",
                      Icons.store,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _mobileController,
                      "Mobile Number",
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Address ---
            ClayContainer(
              color: baseColor,
              borderRadius: 20,
              depth: 10,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTextField(
                      _flatShopController,
                      "Flat / Shop No.",
                      Icons.home,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _areaController,
                      "Area / Street",
                      Icons.map,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _cityController,
                            "City",
                            Icons.location_city,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            _pincodeController,
                            "Pincode",
                            Icons.pin_drop,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- GST State Dropdown ---
            ClayContainer(
              color: baseColor,
              borderRadius: 20,
              depth: 10,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "GST DETAILS (Mandatory)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStateDropdown(baseColor),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _gstinController,
                      "GSTIN (If Registered)",
                      Icons.badge,
                      isAllCaps: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _panController,
                      "PAN Number (Optional)",
                      Icons.credit_card,
                      isAllCaps: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Bank & Signature ---
            ClayContainer(
              color: baseColor,
              borderRadius: 20,
              depth: 10,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTextField(
                      _bankAccController,
                      "Bank Account No. (Optional)",
                      Icons.account_balance,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _ifscController,
                      "IFSC Code",
                      Icons.code,
                      isAllCaps: true,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => _pickAndUploadImage(isSignature: true),
                      child: ClayContainer(
                        depth: -10,
                        color: baseColor,
                        borderRadius: 10,
                        height: 60,
                        child: Center(
                          child: _signatureImageUrl != null
                              ? const Text(
                                  "Signature Uploaded!",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.upload_file, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text(
                                      "Upload Signature",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            _isLoading || _isUploadingImage
                ? const CircularProgressIndicator()
                : ClayPrimaryButton(
                    text: "SAVE & CONTINUE",
                    onTap: _saveProfile,
                  ),
          ],
        ),
      ),
    );
  }

  /// Builds an image widget that handles both Base64 data URIs and network URLs
  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Extract Base64 data from data URI
      final base64Data = imageUrl.split(',').last;
      final bytes = base64Decode(base64Data);
      return Image.memory(bytes, fit: BoxFit.cover, width: 120, height: 120);
    } else {
      return Image.network(imageUrl, fit: BoxFit.cover, width: 120, height: 120);
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool isAllCaps = false,
  }) {
    return ClayContainer(
      depth: -15,
      color: const Color(0xFFF2F4F8),
      borderRadius: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: isAllCaps
              ? TextCapitalization.characters
              : TextCapitalization.words,
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: Icon(icon, size: 20, color: Colors.grey),
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildStateDropdown(Color baseColor) {
    return ClayContainer(
      depth: -15,
      color: baseColor,
      borderRadius: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedStateCode.isEmpty ? null : _selectedStateCode,
            hint: const Text(
              "Select Business State",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _selectedStateCode = newValue);
              }
            },
            items: GstConstants.sortedStates.map<DropdownMenuItem<String>>((
              entry,
            ) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
