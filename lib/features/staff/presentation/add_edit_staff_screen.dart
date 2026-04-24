import 'package:flutter/material.dart';
import '../data/staff_model.dart';
import '../logic/staff_service.dart';
import 'package:bharatstock/features/auth/presentation/widgets/auth_widgets.dart';

class AddEditStaffScreen extends StatefulWidget {
  final String businessId;
  final StaffModel? staff;

  const AddEditStaffScreen({super.key, required this.businessId, this.staff});

  @override
  State<AddEditStaffScreen> createState() => _AddEditStaffScreenState();
}

class _AddEditStaffScreenState extends State<AddEditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _accountController;
  late TextEditingController _salaryController;

  bool _isLoading = false;
  final StaffService _staffService = StaffService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff?.name ?? '');
    _mobileController = TextEditingController(
      text: widget.staff?.mobileNo ?? '',
    );
    _accountController = TextEditingController(
      text: widget.staff?.accountNo ?? '',
    );
    _salaryController = TextEditingController(
      text: widget.staff?.salaryPerMonth.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _accountController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final staff = StaffModel(
      id: widget.staff?.id ?? '',
      name: _nameController.text.trim(),
      mobileNo: _mobileController.text.trim(),
      accountNo: _accountController.text.trim(),
      salaryPerMonth: double.tryParse(_salaryController.text.trim()) ?? 0,
      joinDate: widget.staff?.joinDate ?? DateTime.now(),
    );

    try {
      if (widget.staff == null) {
        await _staffService.addStaff(widget.businessId, staff);
      } else {
        await _staffService.updateStaff(widget.businessId, staff);
      }
      if (mounted) Navigator.pop(context);
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
        title: Text(widget.staff == null ? "Add Staff" : "Edit Staff"),
        backgroundColor: baseColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ClayContainer(
                color: baseColor,
                borderRadius: 20,
                depth: 12,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildField(
                        controller: _nameController,
                        hint: "Full Name",
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 15),
                      _buildField(
                        controller: _mobileController,
                        hint: "Mobile Number",
                        icon: Icons.phone,
                        keyboard: TextInputType.phone,
                      ),
                      const SizedBox(height: 15),
                      _buildField(
                        controller: _accountController,
                        hint: "Bank Account No.",
                        icon: Icons.account_balance,
                        keyboard: TextInputType.number,
                      ),
                      const SizedBox(height: 15),
                      _buildField(
                        controller: _salaryController,
                        hint: "Monthly Salary (₹)",
                        icon: Icons.currency_rupee,
                        keyboard: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ClayPrimaryButton(
                      text: "SAVE STAFF DETAILS",
                      onTap: _saveStaff,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return ClayContainer(
      depth: -15,
      color: const Color(0xFFF2F4F8),
      borderRadius: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          validator: (val) => val == null || val.isEmpty ? "Required" : null,
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: Icon(icon, size: 20, color: Colors.grey),
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
