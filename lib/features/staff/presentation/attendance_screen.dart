import 'package:flutter/material.dart';
import '../../../core/widgets/clay_widgets.dart';
import 'package:intl/intl.dart';
import '../data/staff_model.dart';
import '../logic/staff_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String businessId;
  final StaffModel staff;

  const AttendanceScreen({
    super.key,
    required this.businessId,
    required this.staff,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final StaffService _staffService = StaffService();
  DateTime _selectedMonth = DateTime.now();
  Map<String, String> _attendanceRecords = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  void _loadAttendance() async {
    setState(() => _isLoading = true);
    final records = await _staffService.getAttendanceForMonth(
      widget.businessId,
      widget.staff.id,
      _selectedMonth.month,
      _selectedMonth.year,
    );
    if (mounted) {
      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
    }
  }

  void _markAttendance(int day, String status) async {
    final dateKey =
        "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

    // Toggle off if same status selected
    final newStatus = _attendanceRecords[dateKey] == status ? null : status;

    if (newStatus == null) {
      // Logic for deleting or "unmarking" as holiday isn't explicitly in service yet,
      // but we can set to empty or just leave it.
      // Per user request: "if the owner does not press any option... it should be taken as holiday."
      // So let's just delete the doc if they unselect.
      // For now, let's keep it simple: just overwrite.
    }

    try {
      await _staffService.markAttendance(
        widget.businessId,
        widget.staff.id,
        dateKey,
        status,
      );
      _loadAttendance(); // Refresh
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFF2F4F8);
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: Text("Attendance: ${widget.staff.name}"),
        backgroundColor: baseColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(
                () => _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                ),
              );
              _loadAttendance();
            },
          ),
          Text(
            DateFormat('MMM yyyy').format(_selectedMonth),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(
                () => _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                ),
              );
              _loadAttendance();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final dateKey =
                    "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
                final status = _attendanceRecords[dateKey];
                final isToday =
                    day == DateTime.now().day &&
                    _selectedMonth.month == DateTime.now().month &&
                    _selectedMonth.year == DateTime.now().year;

                return _buildDayCard(day, status, isToday, baseColor);
              },
            ),
    );
  }

  Widget _buildDayCard(int day, String? status, bool isToday, Color baseColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: ClayContainer(
        color: baseColor,
        borderRadius: 15,
        depth: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isToday ? Colors.deepOrange : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    "$day",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.white : Colors.blueGrey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: status == null
                    ? const Text(
                        "Holiday",
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(
                        status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: status == 'Present'
                              ? Colors.green
                              : (status == 'Absent'
                                    ? Colors.red
                                    : Colors.orange),
                        ),
                      ),
              ),
              Row(
                children: [
                  _buildStatusBtn(
                    day,
                    'P',
                    'Present',
                    Colors.green,
                    status == 'Present',
                  ),
                  _buildStatusBtn(
                    day,
                    'H',
                    'Half-Day',
                    Colors.orange,
                    status == 'Half-Day',
                  ),
                  _buildStatusBtn(
                    day,
                    'A',
                    'Absent',
                    Colors.red,
                    status == 'Absent',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBtn(
    int day,
    String label,
    String status,
    Color color,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _markAttendance(day, status),
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
