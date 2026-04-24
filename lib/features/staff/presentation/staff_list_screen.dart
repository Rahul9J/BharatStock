import 'package:flutter/material.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logic/staff_service.dart';
import '../data/staff_model.dart';
import 'add_edit_staff_screen.dart';
import 'attendance_screen.dart';
import 'payroll_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final StaffService _staffService = StaffService();
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
  }

  void _loadBusinessId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _businessId = doc.data()?['businessId'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFF2F4F8);

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: const Text(
          "Manage Staff",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: baseColor,
        elevation: 0,
      ),
      body: _businessId == null
          ? _buildNoBusinessState()
          : StreamBuilder<List<StaffModel>>(
              stream: _staffService.getStaffList(_businessId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(context, baseColor);
                }

                final staffList = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: staffList.length,
                  itemBuilder: (context, index) {
                    return _buildStaffCard(
                      context,
                      staffList[index],
                      baseColor,
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: () {
          if (_businessId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditStaffScreen(businessId: _businessId!),
              ),
            );
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color baseColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClayContainer(
            color: baseColor,
            borderRadius: 50,
            depth: 20,
            height: 100,
            width: 100,
            child: const Icon(
              Icons.people_outline,
              size: 50,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No staff added yet.",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Add your workers to manage attendance and payroll.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(
    BuildContext context,
    StaffModel staff,
    Color baseColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ClayContainer(
        color: baseColor,
        borderRadius: 20,
        depth: 12,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Text(
                      staff.name[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          staff.mobileNo,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹${staff.salaryPerMonth.toInt()}/mo",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionIcon(
                    icon: Icons.calendar_today,
                    label: "Attendance",
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttendanceScreen(
                          businessId: _businessId!,
                          staff: staff,
                        ),
                      ),
                    ),
                  ),
                  _buildActionIcon(
                    icon: Icons.payments_outlined,
                    label: "Payroll",
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PayrollScreen(
                          businessId: _businessId!,
                          staff: staff,
                        ),
                      ),
                    ),
                  ),
                  _buildActionIcon(
                    icon: Icons.edit_outlined,
                    label: "Edit",
                    color: Colors.blueGrey,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditStaffScreen(
                          businessId: _businessId!,
                          staff: staff,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBusinessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business_center_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Business Profile Required",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Please complete your business profile setup to manage staff and payroll.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/complete-profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Complete Setup", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
