import 'package:cloud_firestore/cloud_firestore.dart';

class StaffModel {
  final String id;
  final String name;
  final String mobileNo;
  final String accountNo;
  final double salaryPerMonth;
  final DateTime joinDate;

  StaffModel({
    required this.id,
    required this.name,
    required this.mobileNo,
    this.accountNo = '',
    required this.salaryPerMonth,
    required this.joinDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobileNo': mobileNo,
      'accountNo': accountNo,
      'salaryPerMonth': salaryPerMonth,
      'joinDate': Timestamp.fromDate(joinDate),
    };
  }

  factory StaffModel.fromMap(Map<String, dynamic> map, String id) {
    return StaffModel(
      id: id,
      name: map['name'] ?? '',
      mobileNo: map['mobileNo'] ?? '',
      accountNo: map['accountNo'] ?? '',
      salaryPerMonth: (map['salaryPerMonth'] ?? 0.0).toDouble(),
      joinDate: (map['joinDate'] as Timestamp).toDate(),
    );
  }
}

class AttendanceRecord {
  final String date; // YYYY-MM-DD
  final String status; // Present, Absent, Half-Day

  AttendanceRecord({required this.date, required this.status});

  Map<String, dynamic> toMap() {
    return {'status': status};
  }
}

class SalaryRecord {
  final String monthYear; // MM_YYYY
  final double presentDays;
  final int totalWorkingDays;
  final double calculatedSalary;
  final double bonus;
  final String status; // Paid, Unpaid
  final DateTime? paymentDate;

  SalaryRecord({
    required this.monthYear,
    required this.presentDays,
    required this.totalWorkingDays,
    required this.calculatedSalary,
    this.bonus = 0.0,
    required this.status,
    this.paymentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'presentDays': presentDays,
      'totalWorkingDays': totalWorkingDays,
      'calculatedSalary': calculatedSalary,
      'bonus': bonus,
      'status': status,
      'paymentDate': paymentDate != null
          ? Timestamp.fromDate(paymentDate!)
          : null,
    };
  }
}
