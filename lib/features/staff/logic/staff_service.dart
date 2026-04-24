import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/staff_model.dart';

class StaffService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Add Staff
  Future<void> addStaff(String businessId, StaffModel staff) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('staff')
        .add(staff.toMap());
  }

  // 2. Update Staff
  Future<void> updateStaff(String businessId, StaffModel staff) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('staff')
        .doc(staff.id)
        .update(staff.toMap());
  }

  // 3. Get Staff List
  Stream<List<StaffModel>> getStaffList(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('staff')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // 4. Mark Attendance
  Future<void> markAttendance(
    String businessId,
    String staffId,
    String date,
    String status,
  ) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('staff')
        .doc(staffId)
        .collection('attendance')
        .doc(date)
        .set({'status': status});
  }

  // 5. Get Attendance for a Month
  Future<Map<String, String>> getAttendanceForMonth(
    String businessId,
    String staffId,
    int month,
    int year,
  ) async {
    final start = "$year-${month.toString().padLeft(2, '0')}-01";
    final end = "$year-${month.toString().padLeft(2, '0')}-31";

    final snapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('staff')
        .doc(staffId)
        .collection('attendance')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: start)
        .where(FieldPath.documentId, isLessThanOrEqualTo: end)
        .get();

    Map<String, String> records = {};
    for (var doc in snapshot.docs) {
      records[doc.id] = doc.data()['status'];
    }
    return records;
  }

  // 6. Calculate and Update Salary Record
  Future<SalaryRecord> calculateSalary(
    String businessId,
    StaffModel staff,
    int month,
    int year,
  ) async {
    final monthYear = "${month.toString().padLeft(2, '0')}_$year";

    // Check if a record already exists
    final existingDoc = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('staff')
        .doc(staff.id)
        .collection('salary_records')
        .doc(monthYear)
        .get();

    if (existingDoc.exists) {
      final data = existingDoc.data()!;
      return SalaryRecord(
        monthYear: monthYear,
        presentDays: (data['presentDays'] ?? 0.0).toDouble(),
        totalWorkingDays: data['totalWorkingDays'] ?? 0,
        calculatedSalary: (data['calculatedSalary'] ?? 0.0).toDouble(),
        bonus: (data['bonus'] ?? 0.0).toDouble(),
        status: data['status'] ?? 'Unpaid',
        paymentDate: data['paymentDate'] != null
            ? (data['paymentDate'] as Timestamp).toDate()
            : null,
      );
    }

    final attendance = await getAttendanceForMonth(
      businessId,
      staff.id,
      month,
      year,
    );

    double presentDaysCount = 0;
    int markedDaysCount = 0;

    attendance.forEach((date, status) {
      markedDaysCount++;
      if (status == 'Present') {
        presentDaysCount += 1.0;
      } else if (status == 'Half-Day') {
        presentDaysCount += 0.5;
      }
    });

    double calculatedSalary = 0;
    if (markedDaysCount > 0) {
      calculatedSalary =
          (presentDaysCount / markedDaysCount) * staff.salaryPerMonth;
    }

    return SalaryRecord(
      monthYear: monthYear,
      presentDays: presentDaysCount,
      totalWorkingDays: markedDaysCount,
      calculatedSalary: calculatedSalary,
      status: 'Unpaid',
    );
  }

  Future<void> saveSalaryRecord(
    String businessId,
    String staffId,
    SalaryRecord record,
  ) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('staff')
        .doc(staffId)
        .collection('salary_records')
        .doc(record.monthYear)
        .set(record.toMap());
  }

  // 7. Get Salary Records
  Stream<List<SalaryRecord>> getSalaryRecords(
    String businessId,
    String staffId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('staff')
        .doc(staffId)
        .collection('salary_records')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return SalaryRecord(
              monthYear: doc.id,
              presentDays: (data['presentDays'] ?? 0.0).toDouble(),
              totalWorkingDays: data['totalWorkingDays'] ?? 0,
              calculatedSalary: (data['calculatedSalary'] ?? 0.0).toDouble(),
              bonus: (data['bonus'] ?? 0.0).toDouble(),
              status: data['status'] ?? 'Unpaid',
              paymentDate: data['paymentDate'] != null
                  ? (data['paymentDate'] as Timestamp).toDate()
                  : null,
            );
          }).toList(),
        );
  }
}
