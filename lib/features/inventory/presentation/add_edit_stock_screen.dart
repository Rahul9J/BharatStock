import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/gst_constants.dart';
import '../../auth/presentation/widgets/auth_widgets.dart';
import '../../auth/logic/user_service.dart';
import '../../accounting/data/party_model.dart';
import '../../../core/utils/tax_calculator.dart';
import '../data/stock_model.dart';

class AddEditStockScreen extends StatefulWidget {
  final StockModel? stock;

  const AddEditStockScreen({super.key, this.stock});

  @override
  State<AddEditStockScreen> createState() => _AddEditStockScreenState();
}

class _AddEditStockScreenState extends State<AddEditStockScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _hsnController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _supplierInvoiceController = TextEditingController();
  final _lowStockNotifyController = TextEditingController(text: "5");

  final FirestoreService _service = FirestoreService();
  final UserService _userService = UserService();

  PartyModel? _selectedSupplier;
  final TextEditingController _supplierController = TextEditingController();
  String _businessStateCode = '';
  bool _isInterState = false;

  double _selectedGstRate = 0.0;
  double _purchaseGstRate = 0.0;
  bool _isTaxInclusive = false;
  bool _itcEligible = true;
  bool _isVerifiedGstr2b = false;
  DateTime? _invoiceDate;
  bool _isLoading = false;

  final List<String> _commonHsn = [
    "8536 (Switches/Plugs)",
    "8544 (Wires)",
    "9405 (LED)",
    "8539 (Bulbs)",
    "8537 (Boards)",
    "8414 (Fans)",
    "3917 (PVC Pipes)",
    "7307 (Pipes)",
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessState();
    if (widget.stock != null) {
      _nameController.text = widget.stock!.name;
      _quantityController.text = widget.stock!.quantity.toString();
      _priceController.text = widget.stock!.price.toString();
      _hsnController.text = widget.stock!.hsnCode;
      _costPriceController.text = widget.stock!.costPrice.toString();
      _supplierInvoiceController.text = widget.stock!.supplierInvoiceNo;
      _lowStockNotifyController.text = widget.stock!.lowStockNotify.toString();
      _selectedGstRate = widget.stock!.gstRate;
      _purchaseGstRate = widget.stock!.purchaseGstRate;
      _isTaxInclusive = widget.stock!.isTaxInclusive;
      _itcEligible = widget.stock!.itcEligible;
      _isVerifiedGstr2b = widget.stock!.isVerifiedGstr2b;
      _invoiceDate = widget.stock!.invoiceDate;
    }

    _quantityController.addListener(_updateCalcValues);
    _costPriceController.addListener(_updateCalcValues);
  }

  Future<void> _loadBusinessState() async {
    final user = await _userService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _businessStateCode = user.businessStateCode;
      });
    }
  }

  void _updateCalcValues() {
    setState(() {});
  }

  void _updateInterState() {
    final supplierState = _selectedSupplier?.stateCode ?? '';
    final isInter =
        _businessStateCode.isNotEmpty &&
        supplierState.isNotEmpty &&
        TaxCalculator.isInterState(_businessStateCode, supplierState);
    if (isInter != _isInterState) {
      setState(() => _isInterState = isInter);
    }
  }

  @override
  void dispose() {
    _quantityController.removeListener(_updateCalcValues);
    _costPriceController.removeListener(_updateCalcValues);
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _hsnController.dispose();
    _costPriceController.dispose();
    _supplierInvoiceController.dispose();
    _lowStockNotifyController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _invoiceDate = picked);
  }

  Future<void> _saveStock() async {
    if (_nameController.text.trim().isEmpty ||
        _quantityController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      showTopToast(context, "Please fill Name, Qty and Price", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
      final price = double.tryParse(_priceController.text.trim()) ?? 0;
      final costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0;
      final lowStockNotify =
          double.tryParse(_lowStockNotifyController.text.trim()) ?? 5.0;
      final hsn = _hsnController.text.trim().split(' ').first;

      final purchaseTaxable = quantity * costPrice;
      final itcAmount = purchaseTaxable * (_purchaseGstRate / 100);

      if (widget.stock == null) {
        await _service.addStock(
          name: name,
          quantity: quantity,
          price: price,
          costPrice: costPrice,
          hsnCode: hsn,
          gstRate: _selectedGstRate,
          isTaxInclusive: _isTaxInclusive,
          lowStockNotify: lowStockNotify,
          supplierInvoiceNo: _supplierInvoiceController.text.trim(),
          invoiceDate: _invoiceDate,
          itcEligible: _itcEligible,
          purchaseGstRate: _purchaseGstRate,
          itcAmount: itcAmount,
          isVerifiedGstr2b: _isVerifiedGstr2b,
        );
      } else {
        await _service.updateStock(widget.stock!.id, {
          'name': name,
          'quantity': quantity,
          'price': price,
          'costPrice': costPrice,
          'hsnCode': hsn,
          'gstRate': _selectedGstRate,
          'isTaxInclusive': _isTaxInclusive,
          'lowStockNotify': lowStockNotify,
          'supplierInvoiceNo': _supplierInvoiceController.text.trim(),
          'invoiceDate': _invoiceDate != null
              ? Timestamp.fromDate(_invoiceDate!)
              : null,
          'itcEligible': _itcEligible,
          'purchaseGstRate': _purchaseGstRate,
          'itcAmount': itcAmount,
          'isVerifiedGstr2b': _isVerifiedGstr2b,
        });
      }

      if (mounted) {
        showTopToast(context, "Stock Saved Successfully!");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showTopToast(context, "Error: $e", isError: true);
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
        title: Text(
          widget.stock == null ? "Add Stock (Purchase)" : "Edit Stock",
        ),
        backgroundColor: baseColor,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClayCard(
              borderRadius: 20,
              depth: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Purchase / Invoice Details"),
                  _buildSupplierAutocomplete(),
                  if (_selectedSupplier?.registrationType == 'unregistered')
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Note: Unregistered; no ITC available.",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ClayTextField(
                    controller: _supplierInvoiceController,
                    hint: "Supplier Invoice No.",
                    icon: Icons.receipt_long,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _selectDate,
                    child: ClayCard(
                      depth: -10,
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 15),
                          Text(
                            _invoiceDate == null
                                ? "Select Invoice Date"
                                : DateFormat(
                                    'dd MMM yyyy',
                                  ).format(_invoiceDate!),
                            style: TextStyle(
                              color: _invoiceDate == null
                                  ? Colors.grey
                                  : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  _buildSectionHeader("Product Info"),
                  ClayTextField(
                    controller: _nameController,
                    hint: "Item Name",
                    icon: Icons.inventory_2,
                  ),
                  const SizedBox(height: 12),
                  _buildHsnField(baseColor),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClayTextField(
                          controller: _quantityController,
                          hint: "Qty",
                          icon: Icons.numbers,
                          isNumeric: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClayTextField(
                          controller: _costPriceController,
                          hint: "Purchase Price",
                          icon: Icons.calculate,
                          isNumeric: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClayTextField(
                    controller: _priceController,
                    hint: "Selling Price (per unit)",
                    icon: Icons.sell,
                    isNumeric: true,
                  ),
                  const SizedBox(height: 25),

                  _buildSectionHeader("Taxation (ITC Logic)"),
                  _buildGstRateDropdown(
                    "Purchase GST Rate",
                    _purchaseGstRate,
                    (v) => setState(() => _purchaseGstRate = v!),
                    baseColor,
                  ),
                  const SizedBox(height: 12),
                  _buildToggleTile("Eligible for ITC?", _itcEligible, (v) {
                    if (_selectedSupplier?.registrationType == 'unregistered') {
                      showTopToast(
                        context,
                        "No ITC for Unregistered",
                        isError: true,
                      );
                      return;
                    }
                    setState(() => _itcEligible = v);
                  }, baseColor),
                  const SizedBox(height: 12),
                  _buildGstRateDropdown(
                    "Selling GST Rate",
                    _selectedGstRate,
                    (v) => setState(() => _selectedGstRate = v!),
                    baseColor,
                  ),
                  const SizedBox(height: 12),
                  _buildToggleTile(
                    "Selling Price includes GST?",
                    _isTaxInclusive,
                    (v) => setState(() => _isTaxInclusive = v),
                    baseColor,
                  ),
                  const SizedBox(height: 25),

                  _buildSectionHeader("Alert Settings"),
                  ClayTextField(
                    controller: _lowStockNotifyController,
                    hint: "Low Stock Alert Threshold",
                    icon: Icons.warning_amber_rounded,
                    isNumeric: true,
                  ),
                  const SizedBox(height: 30),

                  _buildTaxSummary(baseColor),
                  const SizedBox(height: 40),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ClayPrimaryButton(
                          text: "SAVE STOCK",
                          onTap: _saveStock,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Colors.indigo,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildHsnField(Color baseColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClayTextField(
          controller: _hsnController,
          hint: "HSN Code",
          icon: Icons.qr_code,
          isNumeric: true,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 35,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _commonHsn.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _hsnController.text = _commonHsn[i]),
                  child: Chip(
                    label: Text(
                      _commonHsn[i],
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGstRateDropdown(
    String label,
    double currentVal,
    ValueChanged<double?> onChanged,
    Color baseColor,
  ) {
    return ClayCard(
      depth: -5,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: 12,
      child: DropdownButtonFormField<double>(
        initialValue: currentVal,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.percent, color: Colors.grey, size: 18),
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
        ),
        items: GstConstants.gstSlabs
            .map(
              (rate) => DropdownMenuItem(
                value: rate,
                child: Text(
                  "${rate.toInt()}% GST",
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildToggleTile(
    String title,
    bool val,
    ValueChanged<bool> onChanged,
    Color baseColor,
  ) {
    return ClayCard(
      depth: -5,
      padding: EdgeInsets.zero,
      borderRadius: 12,
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        value: val,
        onChanged: onChanged,
        activeThumbColor: Colors.indigo,
      ),
    );
  }

  Widget _buildSupplierAutocomplete() {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.getPartiesStream(type: 'supplier'),
      builder: (context, snapshot) {
        final List<PartyModel> partiesList = snapshot.hasData
            ? snapshot.data!.docs
                  .map((d) => PartyModel.fromSnapshot(d))
                  .toList()
            : [];
        return Autocomplete<PartyModel>(
          displayStringForOption: (option) => option.name,
          optionsBuilder: (textVal) => textVal.text.isEmpty
              ? const Iterable<PartyModel>.empty()
              : partiesList.where(
                  (p) =>
                      p.name.toLowerCase().contains(textVal.text.toLowerCase()),
                ),
          onSelected: (selection) {
            setState(() {
              _selectedSupplier = selection;
              if (selection.registrationType == 'unregistered') {
                _itcEligible = false;
              }
            });
            _updateInterState();
            _updateCalcValues();
          },
          fieldViewBuilder: (ctx, ctrl, focus, onSub) {
            return TextField(
              controller: ctrl,
              focusNode: focus,
              onSubmitted: (_) => onSub(),
              decoration: InputDecoration(
                hintText: "Search Supplier Name...",
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTaxSummary(Color baseColor) {
    if (_quantityController.text.isEmpty || _costPriceController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final costPrice = double.tryParse(_costPriceController.text) ?? 0;
    final taxableValue = quantity * costPrice;
    final taxAmount = taxableValue * (_purchaseGstRate / 100);
    final totalAmount = taxableValue + taxAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _summaryRow("Taxable Value", taxableValue),
          const SizedBox(height: 5),
          _summaryRow("Tax Amount ($_purchaseGstRate%)", taxAmount),
          const Divider(height: 20),
          _summaryRow("Total Purchase", totalAmount, isBold: true),
          if (_itcEligible)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Claimable ITC",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "₹${taxAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double val, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.black : Colors.grey,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          "₹${val.toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
