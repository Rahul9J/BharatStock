class ValidationService {
  // Mobile: 10 digits starting with 6-9
  static bool validateMobile(String mobile) {
    final regex = RegExp(r'^[6-9]\d{9}$');
    return regex.hasMatch(mobile);
  }

  // GSTIN: 15 characters standard format
  static bool validateGstin(String gstin) {
    final regex = RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
    );
    return regex.hasMatch(gstin);
  }

  // HSN: 4 to 8 digits
  static bool validateHsn(String hsn) {
    final regex = RegExp(r'^\d{4,8}$');
    return regex.hasMatch(hsn);
  }

  // PAN: 10 chars (5 letters, 4 digits, 1 letter)
  static bool validatePan(String pan) {
    final regex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    return regex.hasMatch(pan);
  }

  // Pincode: 6 digits
  static bool validatePincode(String pincode) {
    final regex = RegExp(r'^[1-9][0-9]{5}$');
    return regex.hasMatch(pincode);
  }

  // State Code Match (First 2 digits of GSTIN)
  static bool validateGstinState(String gstin, String stateCode) {
    if (gstin.length < 2) return false;
    return gstin.substring(0, 2) == stateCode;
  }
}
