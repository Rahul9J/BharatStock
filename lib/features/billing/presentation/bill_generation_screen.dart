import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/tax_calculator.dart';
import '../../../core/constants/gst_constants.dart';
import '../../auth/logic/user_service.dart';
import '../../accounting/data/party_model.dart';
import '../../inventory/data/stock_model.dart';
import '../../auth/presentation/widgets/auth_widgets.dart';
import '../../billing/data/bill_model.dart';
import '../../billing/services/pdf_invoice_service.dart';
import 'package:intl/intl.dart';

class BillGenerationScreen extends StatefulWidget {
  const BillGenerationScreen({super.key});

  @override
  State<BillGenerationScreen> createState() => _BillGenerationScreenState();
}

class _BillGenerationScreenState extends State<BillGenerationScreen> {
  final FirestoreService _service = FirestoreService();
  final UserService _userService = UserService();

  // Party Selection
  final String _partyType = 'customer';
  String _billType = 'B2C'; // 'B2C' or 'B2B'
  PartyModel? _selectedParty;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _partyController = TextEditingController();
  final TextEditingController _billingAddressController =
      TextEditingController();
  final TextEditingController _shippingAddressController =
      TextEditingController();

  // Item Entry
  StockModel? _selectedStock;
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Bill Cart
  final List<Map<String, dynamic>> _billItems = [];
  bool _isConfirmed = false;

  // Payment Tracking
  String _paymentMode = 'paid';
  String _creditDuration = '1week';

  // GST State
  String _businessStateCode = '';
  String _selectedPlaceOfSupply = ''; // State Code
  bool _isInterState = false;
  bool _reverseCharge = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessState();
  }

  @override
  void dispose() {
    _partyController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _billingAddressController.dispose();
    _shippingAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessState() async {
    final user = await _userService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _businessStateCode = user.businessStateCode;
        _selectedPlaceOfSupply =
            user.businessStateCode; // Default POS is own state
      });
    }
  }

  void _updateInterState() {
    final pos = _selectedPlaceOfSupply.isNotEmpty
        ? _selectedPlaceOfSupply
        : (_selectedParty?.stateCode ?? _businessStateCode);
    final isInter =
        _businessStateCode.isNotEmpty &&
        pos.isNotEmpty &&
        TaxCalculator.isInterState(_businessStateCode, pos);
    if (isInter != _isInterState) {
      setState(() => _isInterState = isInter);
    }
  }

  void _addItem() {
    if (_selectedStock == null) {
      showTopToast(context, "Please select an item", isError: true);
      return;
    }

    final qty = double.tryParse(_qtyController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (qty <= 0) {
      showTopToast(context, "Quantity must be > 0", isError: true);
      return;
    }

    final stock = _selectedStock!;

    if (qty > stock.quantity) {
      showTopToast(
        context,
        "Cannot add more than available stock (${stock.quantity} left)",
        isError: true,
      );
      return;
    }

    final gstRate = stock.gstRate;
    final isTaxInclusive = stock.isTaxInclusive;

    final lineItemTax = TaxCalculator.calculateLineItem(
      unitPrice: price,
      qty: qty,
      gstRate: gstRate,
      isTaxInclusive: isTaxInclusive,
      interState: _isInterState,
    );

    setState(() {
      _billItems.add({
        'stockId': stock.id,
        'name': stock.name,
        'qty': qty,
        'price': price,
        'costPrice': stock.costPrice,
        'hsnCode': stock.hsnCode,
        'gstRate': gstRate,
        'isTaxInclusive': isTaxInclusive,
        'taxableValue': lineItemTax.taxableValue,
        'taxAmount': lineItemTax.taxAmount,
        'cgst': lineItemTax.cgst,
        'sgst': lineItemTax.sgst,
        'igst': lineItemTax.igst,
        'total': lineItemTax.grandTotal,
      });

      _selectedStock = null;
      _qtyController.clear();
      _priceController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() => _billItems.removeAt(index));
  }

  Future<void> _generateBill() async {
    final partyName = _selectedParty?.name ?? _partyController.text.trim();
    if (_billType == 'B2B' &&
        (_selectedParty == null || _selectedParty!.gstin.isEmpty)) {
      showTopToast(
        context,
        "B2B Invoice requires a Customer with GSTIN",
        isError: true,
      );
      return;
    }

    if (partyName.isEmpty) {
      showTopToast(
        context,
        "Please enter or select a Party name",
        isError: true,
      );
      return;
    }
    if (_billItems.isEmpty) {
      showTopToast(context, "Add at least one item", isError: true);
      return;
    }
    if (!_isConfirmed) {
      showTopToast(context, "Please confirm the details", isError: true);
      return;
    }

    final billNumber =
        "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

    DateTime? dueDate;
    if (_paymentMode == 'credit') {
      switch (_creditDuration) {
        case '1week':
          dueDate = _selectedDate.add(const Duration(days: 7));
          break;
        case '15days':
          dueDate = _selectedDate.add(const Duration(days: 15));
          break;
        case '1month':
          dueDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + 1,
            _selectedDate.day,
          );
          break;
        case '2months':
          dueDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + 2,
            _selectedDate.day,
          );
          break;
        case '3months':
          dueDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + 3,
            _selectedDate.day,
          );
          break;
      }
    }

    final BillTaxSummary billSummary = TaxCalculator.aggregateBill(
      _billItems
          .map(
            (item) => LineItemTax(
              taxableValue: (item['taxableValue'] as num).toDouble(),
              taxAmount: (item['taxAmount'] as num).toDouble(),
              cgst: (item['cgst'] as num).toDouble(),
              sgst: (item['sgst'] as num).toDouble(),
              igst: (item['igst'] as num).toDouble(),
              grandTotal: (item['total'] as num).toDouble(),
            ),
          )
          .toList(),
    );

    final hsnSummary = TaxCalculator.buildHsnSummary(_billItems);

    final newBill = BillModel(
      id: '',
      billNumber: billNumber,
      partyId: _selectedParty?.id ?? '',
      partyName: partyName,
      partyMobile: _selectedParty?.mobile ?? '',
      date: _selectedDate,
      items: _billItems,
      totalAmount: billSummary.grandTotal,
      createdAt: DateTime.now(),
      paymentStatus: _paymentMode,
      dueDate: dueDate,
      partyType: _partyType,
      billType: _billType,
      customerGstin: _selectedParty?.gstin ?? '',
      placeOfSupply: GstConstants.getStateName(_selectedPlaceOfSupply),
      taxType: _isInterState ? 'inter' : 'intra',
      totalTaxableValue: billSummary.totalTaxableValue,
      totalCgst: billSummary.totalCgst,
      totalSgst: billSummary.totalSgst,
      totalIgst: billSummary.totalIgst,
      hsnSummary: hsnSummary,
      billingAddress: _billingAddressController.text.trim(),
      shippingAddress: _shippingAddressController.text.trim(),
      reverseCharge: _reverseCharge,
    );

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      await _service.saveBill(newBill);

      for (var item in _billItems) {
        if (item['stockId'] != null) {
          await _service.updateStockQuantity(
            item['stockId'],
            -(item['qty'] as double),
          );
        }
      }

      final userModel = await _userService.getCurrentUser();
      if (userModel == null) {
        if (!mounted) return;
        Navigator.pop(context);
        showTopToast(context, "Error fetching user profile", isError: true);
        return;
      }

      final pdfService = PdfInvoiceService();
      final pdfBytes = await pdfService.generateInvoice(newBill, userModel);

      if (!mounted) return;
      Navigator.pop(context);

      _showSuccessDialog(billNumber, billSummary, pdfService, pdfBytes);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      showTopToast(context, "Error: $e", isError: true);
    }
  }

  void _showSuccessDialog(
    String billNumber,
    BillTaxSummary billSummary,
    PdfInvoiceService pdfService,
    dynamic pdfBytes,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Bill Generated!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Invoice #$billNumber created successfully."),
            const SizedBox(height: 10),
            Text(
              "Total: ₹${billSummary.grandTotal.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (billSummary.totalTax > 0) ...[
              const SizedBox(height: 4),
              Text(
                "GST: ₹${billSummary.totalTax.toStringAsFixed(2)} (${_isInterState ? 'IGST' : 'CGST+SGST'})",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.share),
            label: const Text("Share / Print"),
            onPressed: () async =>
                await pdfService.shareOrPrint(pdfBytes, "Invoice_$billNumber"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFF2F4F8);
    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: Text(AppStrings.get('newBill')),
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
            // --- SECTION 1: PARTY & BILL TYPE ---
            ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(AppStrings.get('billTypeAndParty')),
                  RadioGroup<String>(
                    groupValue: _billType,
                    onChanged: (v) => setState(() => _billType = v!),
                    child: Row(
                      children: [
                        _buildTypeRadio(
                          "B2C",
                          'B2C',
                          Colors.blue,
                        ),
                        _buildTypeRadio(
                          "B2B",
                          'B2B',
                          Colors.indigo,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPartyAutocomplete(),

                  if (_selectedParty != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      "GSTIN: ${_selectedParty!.gstin.isEmpty ? 'N/A' : _selectedParty!.gstin}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.get('billingAddress'),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    ClayInput(
                      hint: AppStrings.get('billingAddress'),
                      controller: _billingAddressController,
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.get('shippingAddress'),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    ClayInput(
                      hint: AppStrings.get('shippingAddress'),
                      controller: _shippingAddressController,
                      icon: Icons.local_shipping_outlined,
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  _buildPlaceOfSupplyDropdown(baseColor),
                  const SizedBox(height: 12),
                  _buildDateSelector(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- SECTION 2: PAYMENT & REVERSE CHARGE ---
            ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(AppStrings.get('paymentAndOptions')),
                  RadioGroup<String>(
                    groupValue: _paymentMode,
                    onChanged: (v) => setState(() => _paymentMode = v!),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPaymentRadio(
                            AppStrings.get('cash'),
                            'cash',
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildPaymentRadio(
                            AppStrings.get('online'),
                            'online',
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildPaymentRadio(
                            AppStrings.get('credit'),
                            'credit',
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_paymentMode == 'credit') _buildCreditDurationDropdown(),
                  const Divider(height: 24),
                  SwitchListTile(
                    title: const Text(
                      "Reverse Charge (RCM)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      "Is tax payable by buyer?",
                      style: TextStyle(fontSize: 11),
                    ),
                    value: _reverseCharge,
                    onChanged: (v) => setState(() => _reverseCharge = v),
                    activeThumbColor: Colors.deepOrange,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- SECTION 3: ADD ITEMS ---
            ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(AppStrings.get('addItemsToBill')),
                  _buildStockDropdown(),
                  if (_selectedStock != null) ...[
                    const SizedBox(height: 12),
                    _buildSelectedStockInfo(),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.get('quantity'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClayInput(
                              hint: "0",
                              controller: _qtyController,
                              isNumeric: true,
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
                              AppStrings.get('unitPrice'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClayInput(
                              hint: "0.00",
                              controller: _priceController,
                              isNumeric: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClayButton(
                    text: AppStrings.get('addToBill'),
                    onTap: _addItem,
                    icon: Icons.add_shopping_cart,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- SECTION 4: BILL SUMMARY ---
            if (_billItems.isNotEmpty) _buildBillSummary(baseColor),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

  Widget _buildTypeRadio(
    String label,
    String value,
    Color activeColor,
  ) {
    return Expanded(
      child: RadioListTile<String>(
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        value: value,
        contentPadding: EdgeInsets.zero,
        activeColor: activeColor,
      ),
    );
  }

  Widget _buildPartyAutocomplete() {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.getPartiesStream(type: _partyType),
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
              _selectedParty = selection;
              _billingAddressController.text = selection.billingAddress;
              _shippingAddressController.text = selection.isShippingSame
                  ? selection.billingAddress
                  : selection.shippingAddress;
              _selectedPlaceOfSupply = selection.stateCode.isNotEmpty
                  ? selection.stateCode
                  : _businessStateCode;
              if (selection.registrationType != 'unregistered') {
                _billType = 'B2B';
              }
            });
            _updateInterState();
          },
          fieldViewBuilder: (ctx, ctrl, focus, onSub) {
            if (_partyController.text != ctrl.text && _selectedParty == null) {
              _partyController.text = ctrl.text;
            }
            return TextField(
              controller: ctrl,
              focusNode: focus,
              decoration: const InputDecoration(
                hintText: "Search Party Name...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaceOfSupplyDropdown(Color baseColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Place of Supply (POS):",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 5),
        ClayContainer(
          color: baseColor,
          borderRadius: 10,
          depth: -10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPlaceOfSupply.isEmpty
                    ? null
                    : _selectedPlaceOfSupply,
                isExpanded: true,
                items: GstConstants.sortedStates
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          e.value,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedPlaceOfSupply = v!);
                  _updateInterState();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          "Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: const Text("Change"),
        ),
      ],
    );
  }

  Widget _buildPaymentRadio(String label, String value, Color activeColor) {
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(fontSize: 12)),
      value: value,
      contentPadding: EdgeInsets.zero,
      activeColor: activeColor,
    );
  }

  Widget _buildCreditDurationDropdown() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DropdownButtonFormField<String>(
        initialValue: _creditDuration,
        decoration: const InputDecoration(
          labelText: "Credit Period",
          border: OutlineInputBorder(),
        ),
        items: [
          {'label': '1 Week', 'val': '1week'},
          {'label': '15 Days', 'val': '15days'},
          {'label': '1 Month', 'val': '1month'},
          {'label': '2 Months', 'val': '2months'},
          {'label': '3 Months', 'val': '3months'},
        ]
            .map(
              (e) => DropdownMenuItem(
                value: e['val'],
                child: Text(e['label']!),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _creditDuration = v!),
      ),
    );
  }

  Widget _buildStockDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.getStocksStream(),
      builder: (context, snapshot) {
        final stocks = snapshot.hasData
            ? snapshot.data!.docs
                .map((d) => StockModel.fromSnapshot(d))
                .toList()
            : <StockModel>[];
        return DropdownButtonFormField<StockModel>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Select Product",
          ),
          isExpanded: true,
          items: stocks
              .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
              .toList(),
          onChanged: (v) {
            if (v != null && v.quantity <= v.lowStockNotify) {
              showTopToast(
                context,
                "Low Stock Warning: Only ${v.quantity} units left for ${v.name}",
                isError: true,
              );
            }
            setState(() {
              _selectedStock = v;
              _priceController.text = v?.price.toString() ?? '';
            });
          },
          initialValue: _selectedStock,
        );
      },
    );
  }

  Widget _buildSelectedStockInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        "GST: ${_selectedStock!.gstRate.toInt()}% | HSN: ${_selectedStock!.hsnCode} | ${_selectedStock!.isTaxInclusive ? 'Inclusive' : 'Exclusive'}",
        style: const TextStyle(fontSize: 11, color: Colors.blue),
      ),
    );
  }

  Widget _buildBillSummary(Color baseColor) {
    final subtotal = _billItems.fold(
      0.0,
      (acc, item) => acc + (item['taxableValue'] as double),
    );
    final totalTax = _billItems.fold(
      0.0,
      (acc, item) => acc + (item['taxAmount'] as double),
    );
    final grandTotal = _billItems.fold(
      0.0,
      (acc, item) => acc + (item['total'] as double),
    );

    return _billItems.isEmpty
        ? const SizedBox.shrink()
        : ClayCard(
            depth: 15,
            child: Column(
              children: [
                Text(
                  AppStrings.get('billSummary').toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                ..._billItems.asMap().entries.map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(128),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "${entry.value['qty']} x ₹${entry.value['price']}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹${entry.value['total'].toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeItem(entry.key),
                              child: const Text(
                                "REMOVE",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                _buildSummaryRow("Subtotal", subtotal),
                if (!_isInterState) ...[
                  _buildSummaryRow("CGST", totalTax / 2),
                  _buildSummaryRow("SGST", totalTax / 2),
                ] else ...[
                  _buildSummaryRow("IGST", totalTax),
                ],
                const SizedBox(height: 8),
                _buildSummaryRow("Grand Total", grandTotal, isBold: true),
                const SizedBox(height: 16),
                _buildGstBreakdown(),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isConfirmed,
                        onChanged: (v) => setState(() => _isConfirmed = v!),
                        activeColor: Colors.blue,
                      ),
                      Expanded(
                        child: Text(
                          AppStrings.get('confirmDetails'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ClayButton(
                  text: AppStrings.get('generateBill'),
                  onTap: _generateBill,
                  icon: Icons.check_circle_outline,
                  color: Colors.green.shade600,
                ),
              ],
            ),
          );
  }

  Widget _buildSummaryRow(String label, double val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
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
      ),
    );
  }

  Widget _buildGstBreakdown() {
    final Map<double, Map<String, double>> slabs = {};
    for (var item in _billItems) {
      final rate = item['gstRate'] as double;
      if (!slabs.containsKey(rate)) slabs[rate] = {'taxable': 0, 'tax': 0};
      slabs[rate]!['taxable'] =
          slabs[rate]!['taxable']! + (item['taxableValue'] as double);
      slabs[rate]!['tax'] =
          slabs[rate]!['tax']! + (item['taxAmount'] as double);
    }
    return Column(
      children: slabs.entries
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${e.key.toInt()}% GST Breakdown:",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    "Taxable: ₹${e.value['taxable']!.toStringAsFixed(2)} | Tax: ₹${e.value['tax']!.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
