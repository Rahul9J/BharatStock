## 🏢 User Profiles (Multi-User Testing)

| Feature | User 1 (Local Retail) | User 2 (Wholesaler) | User 3 (Service/Consult) | User 4 (Large Enterprise) |
| :--- | :--- | :--- | :--- | :--- |
| **Legal Name** | Aarav Electronics | Global Traders Hub | TechSol Services | Bharat Mega Mart |
| **GSTIN** | 24AAACB1111A1Z1 | 27BBBCB2222B1Z2 | 07CCCCB3333C1Z3 | 09DDDDB4444D1Z4 |
| **State** | Gujarat (24) | Maharashtra (27) | Delhi (07) | Uttar Pradesh (09) |
| **Mobile** | 98765 00001 | 98765 00002 | 98765 00003 | 98765 00004 |
| **Bank Name** | State Bank of India | HDFC Bank | ICICI Bank | Punjab National Bank |
| **Account No** | 100020003000 | 501001002003 | 000405060708 | 300100200300 |
# BharatStock Manual Testing Dummy Data

## User Profiles for Testing
Use these details to create different user profiles and test the app's business logic.

| Field | User 1 (Retailer) | User 2 (Wholesaler) | User 3 (Service Provider) | User 4 (Distributor) |
| :--- | :--- | :--- | :--- | :--- |
| **Business Name** | Sharma Electronics | Gupta Traders | Tech Hub Solutions | Metro Distribution |
| **Owner Name** | Rajesh Sharma | Amit Gupta | Suman Patel | Vikram Singh |
| **Email** | user1@test.com | user2@test.com | user3@test.com | user4@test.com |
| **Mobile** | +91 98765 43210 | +91 87654 32109 | +91 76543 21098 | +91 65432 10987 |
| **GSTIN** | 07AAAAA0000A1Z5 | 24BBBBB1111B1Z2 | 27CCCCC2222C1Z9 | 19DDDDD3333D1Z4 |
| **Bank Name** | SBI | HDFC | ICICI | Axis Bank |
| **Account No** | 1234567890 | 9876543210 | 1122334455 | 6677889900 |
| **IFSC Code** | SBIN0001234 | HDFC0004321 | ICIC0005678 | UTIB0009876 |
| **Address** | Shop 12, Main Market, Delhi | Plot 45, GIDC, Ahmedabad | Office 302, BKC, Mumbai | Warehouse 5, Kolkata |

## Sample Inventory Data
| Item Name | Category | SKU | Price (Base) | GST Rate |
| :--- | :--- | :--- | :--- | :--- |
| LED Bulb 9W | Electronics | ELE-LED-09 | ₹80 | 12% |
| Ceiling Fan | Appliances | APP-FAN-01 | ₹1,200 | 18% |
| Copper Wire 1m | Hardware | HRD-WIR-CU | ₹45 | 18% |
| Smart Plug | Electronics | ELE-PLG-01 | ₹450 | 18% |

## Sample Staff Data
| Name | Role | Daily Wage | Mobile |
| :--- | :--- | :--- | :--- |
| Rahul Verma | Salesman | ₹500 | 99999 88888 |
| Sunita Das | Accountant | ₹800 | 77777 66666 |
| Amit K. | Helper | ₹350 | 55555 44444 |

---

## 🤝 Parties (Customers & Suppliers)
| Name | Type | GST Type | Location | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Shree Krishna Kirana** | Customer | Unregistered | Intra-state (Local) | Tests CGST/SGST |
| **Mumbai Steel Wholesalers**| Supplier | Registered | Inter-state (MH) | Tests IGST |

---

## 💸 Expenses
- **Rent:** ₹15,000 (Category: Rent)
- **Electricity Bill:** ₹1,200 (Category: Utilities)
- **Packaging Materials:** ₹3,500 (Category: Consumables)

---

## 🧪 Recommended Test Scenarios

### 1. The P&L Test
1. Add **Premium Basmati Rice** (100 units) at ₹80 cost.
2. Sell **20 units** to a customer at ₹120.
3. Check **Profit & Loss Screen**:
   - Revenue should show ₹2,400.
   - COGS (Cost of Goods Sold) should show ₹1,600.
   - Gross Profit should show ₹800.

### 2. The GST Inter-state Test
1. Create a bill for **Mumbai Steel Wholesalers** (Registered, Outside State).
2. Add an item with 18% GST.
3. Verify that the bill totals show **IGST (18%)** instead of CGST/SGST.

### 3. The Staff Salary Test (As requested earlier)
1. Mark **Suresh Patel** (₹500/day wage) as "Present" for 20 days and "Half-Day" for 4 days.
2. Calculated Salary should be: [(20 * 500) + (4 * 250) = ₹11,000](file:///c:/Users/rahul/OneDrive/Desktop/SEM%206%20PROJECT/bharatstock/lib/l10n/app_localizations.dart#71-74).
3. Mark other days as "Holiday" by leaving them blank.
