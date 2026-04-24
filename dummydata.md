this is a project i recently build based on a old project ("C:\Users\rahul\OneDrive\Desktop\SEM 6 PROJECT\bvm1") which was also a flutter project . i leaved it and started to make a new project beacuse there were many problems comming up. so i want you to make the dashboard of the current project and change it into an full functoinal, proffesional like, you can also take reference from the older project. also there is coming errors when i try to run the flutter app. first tell me how you are going to do it. if you have any questions then please ask me. [Dashboard] [HomeScreen UI Upgrade] 
[NEW] 
home_drawer.dart
Create a professional sidebar drawer with navigation links to all main modules (Billing, Inventory, Staff, Analytics, Settings).
Include user profile section at the top.
[MODIFY] 
home_screen.dart
Integrate the new 
HomeDrawer
.
Replace the "Coming Soon" placeholder with a grid of Premium Feature Cards.
Implement sections for "Inventory Summary", "Recent Transactions", and "Quick Analytics".
Use vibrant color palettes and modern glassmorphism effects.
[Localization] [Keys Restoration]
[MODIFY] 
app_localizations.dart
Restore all missing keys used in Analytics and Dashboard:
Analytics: 
addExpense
, expenseTitle, amountLabel, category, selectPeriod, reportsToInclude, salesRegisterDesc, purchaseRegisterDesc, taxSummaryPdfDesc, expenseManager, totalSpending, allCategories, 
deleteExpense
, confirmDeleteExpense, cancel, 
delete
, profitLossAnalysis, today, thisWeek, thisMonth, allTime, manageExpenses, netLoss, grossProfit, margin, financialPerformance, revenueVsExpenses, revenue, inventoryCost, operatingExpenses, itemsSold, recentExpenses, viewAll.
Dashboard: taxLedger, stockSubtitle, analytics, hello, businessHubSubtitle.
[MODIFY] [Language Files]
Ensure 
app_localizations_en.dart
, 
app_localizations_hi.dart
, and 
app_localizations_gu.dart
 all implement these keys consistently.
Fix any broken or incomplete translations in the Gujarati file. if some things are already done no problem. solve the errors and make sure that the all screens of the app support multi language localization.

 User Profiles (Multi-User Testing)
Feature	User 1 (Local Retail)	User 2 (Wholesaler)	User 3 (Service/Consult)	User 4 (Large Enterprise)
Legal Name	Aarav Electronics	Global Traders Hub	TechSol Services	Bharat Mega Mart
GSTIN	24AAACB1111A1Z1	27BBBCB2222B1Z2	07CCCCB3333C1Z3	09DDDDB4444D1Z4
State	Gujarat (24)	Maharashtra (27)	Delhi (07)	Uttar Pradesh (09)
Mobile	98765 00001	98765 00002	98765 00003	98765 00004
Bank Name	State Bank of India	HDFC Bank	ICICI Bank	Punjab National Bank
Account No	100020003000	501001002003	000405060708	300100200300
BharatStock Manual Testing Dummy Data
User Profiles for Testing
Use these details to create different user profiles and test the app's business logic.

Field	User 1 (Retailer)	User 2 (Wholesaler)	User 3 (Service Provider)	User 4 (Distributor)
Business Name	Sharma Electronics	Gupta Traders	Tech Hub Solutions	Metro Distribution
Owner Name	Rajesh Sharma	Amit Gupta	Suman Patel	Vikram Singh
Email	
user1@test.com
user2@test.com
user3@test.com
user4@test.com
Mobile	+91 98765 43210	+91 87654 32109	+91 76543 21098	+91 65432 10987
GSTIN	07AAAAA0000A1Z5	24BBBBB1111B1Z2	27CCCCC2222C1Z9	19DDDDD3333D1Z4
Bank Name	SBI	HDFC	ICICI	Axis Bank
Account No	1234567890	9876543210	1122334455	6677889900
IFSC Code	SBIN0001234	HDFC0004321	ICIC0005678	UTIB0009876
Address	Shop 12, Main Market, Delhi	Plot 45, GIDC, Ahmedabad	Office 302, BKC, Mumbai	Warehouse 5, Kolkata
Sample Inventory Data
Item Name	Category	SKU	Price (Base)	GST Rate
LED Bulb 9W	Electronics	ELE-LED-09	₹80	12%
Ceiling Fan	Appliances	APP-FAN-01	₹1,200	18%
Copper Wire 1m	Hardware	HRD-WIR-CU	₹45	18%
Smart Plug	Electronics	ELE-PLG-01	₹450	18%
Sample Staff Data
Name	Role	Daily Wage	Mobile
Rahul Verma	Salesman	₹500	99999 88888
Sunita Das	Accountant	₹800	77777 66666
Amit K.	Helper	₹350	55555 44444
🤝 Parties (Customers & Suppliers)
Name	Type	GST Type	Location	Notes
Shree Krishna Kirana	Customer	Unregistered	Intra-state (Local)	Tests CGST/SGST
Mumbai Steel Wholesalers	Supplier	Registered	Inter-state (MH)	Tests IGST
💸 Expenses
Rent: ₹15,000 (Category: Rent)
Electricity Bill: ₹1,200 (Category: Utilities)
Packaging Materials: ₹3,500 (Category: Consumables)
🧪 Recommended Test Scenarios
1. The P&L Test
Add Premium Basmati Rice (100 units) at ₹80 cost.
Sell 20 units to a customer at ₹120.
Check Profit & Loss Screen:
Revenue should show ₹2,400.
COGS (Cost of Goods Sold) should show ₹1,600.
Gross Profit should show ₹800.
2. The GST Inter-state Test
Create a bill for Mumbai Steel Wholesalers (Registered, Outside State).
Add an item with 18% GST.
Verify that the bill totals show IGST (18%) instead of CGST/SGST.
3. The Staff Salary Test (As requested earlier)
Mark Suresh Patel (₹500/day wage) as "Present" for 20 days and "Half-Day" for 4 days.
Calculated Salary should be: 
(20 * 500) + (4 * 250) = ₹11,000
.
Mark other days as "Holiday" by leaving them blank.

///////////////////
Walkthrough - Logout Relocation & Firebase Storage Bypass
I have successfully completed the tasks to move the logout functionality and resolve the Firebase Storage upload issue by bypassing Storage entirely.

Changes Made
1. Logout Functionality
Relocated the logout button from the 
HomeScreen
 AppBar to the bottom of the 
HomeDrawer
.
Integrated Firebase sign-out and SharedPreferences cleanup directly into the drawer for a cleaner UI.
2. Firebase Storage Bypass (Base64 Implementation)
Problem: Firebase Storage required a Blaze (Paid) plan for new projects, which caused the "object-not-found" error.
Solution: Modified UserService.uploadImage to convert image files into Base64 encoded data URIs. These are stored directly in Firestore, staying within the free Spark plan limits.
Optimization: Implemented a 500KB file size limit to prevent bloated Firestore documents.
Consistency: Standardized the user image field name to userImageUrl across 
CompleteProfileScreen
, 
HomeScreen
, and 
HomeDrawer
.
3. UI Updates
CompleteProfileScreen: Updated to display Base64 images using Image.memory via a new helper widget.
HomeScreen: Updated the profile header CircleAvatar to support both Base64 strings and legacy network URLs.
HomeDrawer: Updated the header CircleAvatar to correctly fetch userImageUrl and render Base64 data.
Verification Results
Automated Tests
Ran dart analyze on all modified files.
Result: No errors. The project compiles cleanly.
Manual Verification Required
 Upload Test: Go to the Profile Setup screen and try uploading a small profile picture and signature. They should now save and display immediately without errors.
 Logout Test: Open the side drawer on the dashboard and click "Logout" at the bottom to verify it returns you to the login screen.
NOTE

Storing images in Firestore is a great solution for small images (profile pics, signatures) on free plans. For high-resolution images, Firebase Storage on the Blaze plan would be the standard approach, but this fix ensures your project works without cost requirements.

