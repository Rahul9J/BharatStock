import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/gst_constants.dart';
import '../../../core/widgets/clay_widgets.dart';
import '../data/party_model.dart';

class AddPartyScreen extends StatefulWidget {
  final PartyModel? party; // If null, Add Mode
  final bool? isCustomer; // Optional: Pre-select type

  const AddPartyScreen({super.key, this.party, this.isCustomer});

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();

  // Bank Controllers
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();

  // Address Controllers
  final _billingFlatShopController = TextEditingController();
  final _billingAreaController = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingPincodeController = TextEditingController();

  final _shippingFlatShopController = TextEditingController();
  final _shippingAreaController = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingPincodeController = TextEditingController();

  final FirestoreService _service = FirestoreService();

  String _selectedType = 'customer';
  String _registrationType = 'unregistered';
  String _selectedStateCode = '';
  bool _isShippingSame = true;
  bool _isLoading = false;

  // B2B Search Fields
  bool _isRegisteredOnApp = false;
  String? _linkedBusinessId;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.party != null) {
      _nameController.text = widget.party!.name;
      _mobileController.text = widget.party!.mobile;
      _gstinController.text = widget.party!.gstin;
      _panController.text = widget.party!.pan;
      _selectedType = widget.party!.type;
      _registrationType = widget.party!.registrationType;
      _selectedStateCode = widget.party!.stateCode;
      _isRegisteredOnApp = widget.party!.isRegisteredOnApp;
      _linkedBusinessId = widget.party!.linkedBusinessId;

      _bankAccountController.text = widget.party!.bankAccount;
      _ifscController.text = widget.party!.ifscCode;

      _billingFlatShopController.text = widget.party!.billingFlatShopNo;
      _billingAreaController.text = widget.party!.billingArea;
      _billingCityController.text = widget.party!.billingCity;
      _billingPincodeController.text = widget.party!.billingPincode;

      _isShippingSame = widget.party!.isShippingSame;
      if (!_isShippingSame) {
        _shippingFlatShopController.text = widget.party!.shippingFlatShopNo;
        _shippingAreaController.text = widget.party!.shippingArea;
        _shippingCityController.text = widget.party!.shippingCity;
        _shippingPincodeController.text = widget.party!.shippingPincode;
      }
    } else if (widget.isCustomer != null) {
      _selectedType = widget.isCustomer! ? 'customer' : 'supplier';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    _billingFlatShopController.dispose();
    _billingAreaController.dispose();
    _billingCityController.dispose();
    _billingPincodeController.dispose();
    _shippingFlatShopController.dispose();
    _shippingAreaController.dispose();
    _shippingCityController.dispose();
    _shippingPincodeController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await _service.searchPublicBusiness(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _selectBusiness(Map<String, dynamic> biz) {
    setState(() {
      _nameController.text = biz['businessName'] ?? '';
      _mobileController.text = biz['businessMobile'] ?? '';
      _gstinController.text = biz['gstin'] ?? '';
      _registrationType = (biz['gstin'] != null && biz['gstin'] != '')
          ? 'regular'
          : 'unregistered';
      _selectedStateCode = biz['stateCode'] ?? '';
      _billingFlatShopController.text = biz['address'] ?? '';

      _isRegisteredOnApp = true;
      _linkedBusinessId = biz['businessId'];
      _searchResults = [];
    });
  }

  Future<void> _saveParty() async {
    if (_nameController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Mobile are required")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> data = {
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'mobile': _mobileController.text.trim(),
        'registrationType': _registrationType,
        'gstin': _gstinController.text.trim().toUpperCase(),
        'pan': _panController.text.trim().toUpperCase(),
        'stateCode': _selectedStateCode,
        'isRegisteredOnApp': _isRegisteredOnApp,
        'linkedBusinessId': _linkedBusinessId,
        'bankAccount': _selectedType == 'supplier'
            ? _bankAccountController.text.trim()
            : '',
        'ifscCode': _selectedType == 'supplier'
            ? _ifscController.text.trim()
            : '',
        'billingFlatShopNo': _billingFlatShopController.text.trim(),
        'billingArea': _billingAreaController.text.trim(),
        'billingCity': _billingCityController.text.trim(),
        'billingPincode': _billingPincodeController.text.trim(),
        'isShippingSame': _isShippingSame,
        'shippingFlatShopNo': _isShippingSame
            ? ''
            : _shippingFlatShopController.text.trim(),
        'shippingArea': _isShippingSame
            ? ''
            : _shippingAreaController.text.trim(),
        'shippingCity': _isShippingSame
            ? ''
            : _shippingCityController.text.trim(),
        'shippingPincode': _isShippingSame
            ? ''
            : _shippingPincodeController.text.trim(),
      };

      if (widget.party == null) {
        await _service.addParty(
          name: data['name'],
          type: data['type'],
          mobile: data['mobile'],
          registrationType: data['registrationType'],
          gstin: data['gstin'],
          pan: data['pan'],
          stateCode: data['stateCode'],
          isRegisteredOnApp: data['isRegisteredOnApp'],
          linkedBusinessId: data['linkedBusinessId'],
          bankAccount: data['bankAccount'],
          ifscCode: data['ifscCode'],
          billingFlatShopNo: data['billingFlatShopNo'],
          billingArea: data['billingArea'],
          billingCity: data['billingCity'],
          billingPincode: data['billingPincode'],
          isShippingSame: data['isShippingSame'],
          shippingFlatShopNo: data['shippingFlatShopNo'],
          shippingArea: data['shippingArea'],
          shippingCity: data['shippingCity'],
          shippingPincode: data['shippingPincode'],
        );
      } else {
        await _service.updateParty(widget.party!.id, data);
      }

      if (mounted) {
        Navigator.pop(context);
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
    final title = widget.party == null
        ? "Add ${_selectedType.capitalize()}"
        : "Edit ${_selectedType.capitalize()}";

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: baseColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search Section
            if (widget.party == null) ...[
              const Text(
                "Search existing business to link (Optional)",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ClayInput(
                hint: "Enter Name or GSTIN...",
                icon: Icons.search,
                onChanged: _onSearchChanged,
              ),
              if (_isSearching) const LinearProgressIndicator(),
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 5),
                    ],
                  ),
                  child: Column(
                    children: _searchResults
                        .map(
                          (biz) => ListTile(
                            leading: const Icon(
                              Icons.business,
                              color: Colors.blue,
                            ),
                            title: Text(biz['businessName'] ?? ''),
                            subtitle: Text(biz['businessMobile'] ?? ''),
                            trailing: const Icon(
                              Icons.add_link,
                              color: Colors.green,
                            ),
                            onTap: () => _selectBusiness(biz),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 30),
            ],

            ClayCard(
              borderRadius: 20,
              depth: 10,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Party Details"),
                  if (_isRegisteredOnApp)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Verified BharatStock User",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Type Selection (Simplified for view)
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'customer',
                        label: Text('Customer'),
                        icon: Icon(Icons.person),
                      ),
                      ButtonSegment(
                        value: 'supplier',
                        label: Text('Supplier'),
                        icon: Icon(Icons.local_shipping),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _selectedType = newSelection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: _selectedType == 'customer'
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      selectedForegroundColor: _selectedType == 'customer'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ClayInput(
                    controller: _nameController,
                    hint: "Party Name",
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 15),
                  ClayInput(
                    controller: _mobileController,
                    hint: "Mobile Number",
                    icon: Icons.phone,
                    isNumeric: true,
                  ),
                  const SizedBox(height: 15),
                  ClayInput(
                    controller: _panController,
                    hint: "PAN Number",
                    icon: Icons.credit_card,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 25),

                  _buildSectionTitle("GST & Address"),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'unregistered',
                        label: Text('Unreg'),
                      ),
                      ButtonSegment(value: 'regular', label: Text('Regular')),
                      ButtonSegment(value: 'composition', label: Text('Comp')),
                    ],
                    selected: {_registrationType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _registrationType = newSelection.first);
                    },
                  ),
                  const SizedBox(height: 15),
                  if (_registrationType != 'unregistered')
                    ClayInput(
                      controller: _gstinController,
                      hint: "GSTIN",
                      icon: Icons.badge,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  const SizedBox(height: 15),
                  _buildStateDropdown(baseColor),
                  const SizedBox(height: 25),

                  _buildSectionTitle("Billing Address"),
                  _buildAddressFields(
                    flatShop: _billingFlatShopController,
                    area: _billingAreaController,
                    city: _billingCityController,
                    pincode: _billingPincodeController,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: _isShippingSame,
                        onChanged: (v) => setState(() => _isShippingSame = v!),
                        activeColor: Colors.indigo,
                      ),
                      const Text(
                        "Shipping same as Billing",
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),

                  if (!_isShippingSame) ...[
                    _buildSectionTitle("Shipping Address"),
                    _buildAddressFields(
                      flatShop: _shippingFlatShopController,
                      area: _shippingAreaController,
                      city: _shippingCityController,
                      pincode: _shippingPincodeController,
                    ),
                  ],

                  const SizedBox(height: 40),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ClayButton(text: "SAVE PARTY", onTap: _saveParty),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildAddressFields({
    required TextEditingController flatShop,
    required TextEditingController area,
    required TextEditingController city,
    required TextEditingController pincode,
  }) {
    return Column(
      children: [
        ClayInput(
          controller: flatShop,
          hint: "Flat / Shop No.",
          icon: Icons.home,
        ),
        const SizedBox(height: 12),
        ClayInput(controller: area, hint: "Area / Street", icon: Icons.map),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ClayInput(
                controller: city,
                hint: "City",
                icon: Icons.location_city,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClayInput(
                controller: pincode,
                hint: "Pincode",
                icon: Icons.pin_drop,
                isNumeric: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStateDropdown(Color baseColor) {
    return ClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 12,
      depth: 6,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedStateCode.isEmpty ? null : _selectedStateCode,
        decoration: const InputDecoration(
          border: InputBorder.none,
          icon: Icon(Icons.public, color: Colors.grey, size: 20),
          labelText: "State",
        ),
        items: GstConstants.sortedStates
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value, style: const TextStyle(fontSize: 14)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _selectedStateCode = v!),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}
