/// GST 2.0 Constants — India (2026)
class GstConstants {
  /// GST Rate Slabs (GST 2.0 — 2026)
  static const List<double> gstSlabs = [0, 5, 12, 18, 28];

  /// Indian State Codes (ISO 3166-2:IN) - Strictly as per strict 2026 guidelines
  static const Map<String, String> stateCodes = {
    "01": "Jammu and Kashmir",
    "02": "Himachal Pradesh",
    "03": "Punjab",
    "04": "Chandigarh",
    "05": "Uttarakhand",
    "06": "Haryana",
    "07": "Delhi",
    "08": "Rajasthan",
    "09": "Uttar Pradesh",
    "10": "Bihar",
    "11": "Sikkim",
    "12": "Arunachal Pradesh",
    "13": "Nagaland",
    "14": "Manipur",
    "15": "Mizoram",
    "16": "Tripura",
    "17": "Meghalaya",
    "18": "Assam",
    "19": "West Bengal",
    "20": "Jharkhand",
    "21": "Odisha",
    "22": "Chhattisgarh",
    "23": "Madhya Pradesh",
    "24": "Gujarat",
    "26": "Dadra & Nagar Haveli and Daman & Diu",
    "27": "Maharashtra",
    "29": "Karnataka",
    "30": "Goa",
    "31": "Lakshadweep",
    "32": "Kerala",
    "33": "Tamil Nadu",
    "34": "Puducherry",
    "35": "Andaman and Nicobar Islands",
    "36": "Telangana",
    "37": "Andhra Pradesh",
    "38": "Ladakh",
    "97": "Other Territory",
    "99": "Centre Jurisdiction",
  };

  /// Get state name from code
  static String getStateName(String code) {
    return stateCodes[code] ?? 'Unknown State';
  }

  /// Get state code from name
  static String? getStateCode(String name) {
    for (final entry in stateCodes.entries) {
      if (entry.value == name) return entry.key;
    }
    return null;
  }

  /// Sorted list of state entries for dropdowns
  static List<MapEntry<String, String>> get sortedStates {
    final entries = stateCodes.entries.toList();
    entries.sort((a, b) => a.value.compareTo(b.value));
    return entries;
  }
}
