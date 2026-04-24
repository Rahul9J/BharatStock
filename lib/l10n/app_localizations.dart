import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
  ];

  /// No description provided for @smartStock.
  ///
  /// In en, this message translates to:
  /// **'Smart Stock'**
  String get smartStock;

  /// No description provided for @smartStockDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your stocks effortlessly with our real-time tracking.'**
  String get smartStockDesc;

  /// No description provided for @workEasy.
  ///
  /// In en, this message translates to:
  /// **'Work Easy'**
  String get workEasy;

  /// No description provided for @workEasyDesc.
  ///
  /// In en, this message translates to:
  /// **'Simplify your daily operations and focus on growth.'**
  String get workEasyDesc;

  /// No description provided for @fullToolkit.
  ///
  /// In en, this message translates to:
  /// **'Full Toolkit'**
  String get fullToolkit;

  /// No description provided for @fullToolkitDesc.
  ///
  /// In en, this message translates to:
  /// **'Powerful tools like GST billing and cash flow management at your fingertips.'**
  String get fullToolkitDesc;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @manageShop.
  ///
  /// In en, this message translates to:
  /// **'Manage your shop with ease'**
  String get manageShop;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'SHOP NAME'**
  String get shopName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'PHONE NUMBER'**
  String get phone;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'New shop owner? Register Shop'**
  String get register;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get usernameHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM PASSWORD'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinNetwork.
  ///
  /// In en, this message translates to:
  /// **'Join the leading network for Indian businesses'**
  String get joinNetwork;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'SIGN UP'**
  String get signUp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New user? '**
  String get newUser;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpLink;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Namaste,'**
  String get welcome;

  /// No description provided for @manageStore.
  ///
  /// In en, this message translates to:
  /// **'Manage Store'**
  String get manageStore;

  /// No description provided for @manageWorkers.
  ///
  /// In en, this message translates to:
  /// **'Manage Workers'**
  String get manageWorkers;

  /// No description provided for @manageStocks.
  ///
  /// In en, this message translates to:
  /// **'Manage Stocks'**
  String get manageStocks;

  /// No description provided for @myCustomers.
  ///
  /// In en, this message translates to:
  /// **'My Customers'**
  String get myCustomers;

  /// No description provided for @mySuppliers.
  ///
  /// In en, this message translates to:
  /// **'My Suppliers'**
  String get mySuppliers;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @lowItems.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowItems;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @pendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Pending Payment'**
  String get pendingPayment;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @stockList.
  ///
  /// In en, this message translates to:
  /// **'Stock List'**
  String get stockList;

  /// No description provided for @addNewItem.
  ///
  /// In en, this message translates to:
  /// **'Add New Item'**
  String get addNewItem;

  /// No description provided for @searchStock.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchStock;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @workerList.
  ///
  /// In en, this message translates to:
  /// **'Staff List'**
  String get workerList;

  /// No description provided for @salaryDue.
  ///
  /// In en, this message translates to:
  /// **'Salary Due'**
  String get salaryDue;

  /// No description provided for @markAttendance.
  ///
  /// In en, this message translates to:
  /// **'Mark Attendance'**
  String get markAttendance;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @salesSummary.
  ///
  /// In en, this message translates to:
  /// **'Sales Summary'**
  String get salesSummary;

  /// No description provided for @todaySales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get todaySales;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @profitLoss.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get profitLoss;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @newBill.
  ///
  /// In en, this message translates to:
  /// **'New Bill'**
  String get newBill;

  /// No description provided for @billTypeAndParty.
  ///
  /// In en, this message translates to:
  /// **'Bill Type & Party'**
  String get billTypeAndParty;

  /// No description provided for @billingAddress.
  ///
  /// In en, this message translates to:
  /// **'Billing Address'**
  String get billingAddress;

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get shippingAddress;

  /// No description provided for @paymentAndOptions.
  ///
  /// In en, this message translates to:
  /// **'Payment & Options'**
  String get paymentAndOptions;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @reverseChargeRCM.
  ///
  /// In en, this message translates to:
  /// **'Reverse Charge (RCM)'**
  String get reverseChargeRCM;

  /// No description provided for @isTaxPayableByBuyer.
  ///
  /// In en, this message translates to:
  /// **'Is tax payable by buyer?'**
  String get isTaxPayableByBuyer;

  /// No description provided for @addItemsToBill.
  ///
  /// In en, this message translates to:
  /// **'Add Items to Bill'**
  String get addItemsToBill;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price (₹)'**
  String get unitPrice;

  /// No description provided for @addToBill.
  ///
  /// In en, this message translates to:
  /// **'Add to Bill'**
  String get addToBill;

  /// No description provided for @billSummary.
  ///
  /// In en, this message translates to:
  /// **'Bill Summary'**
  String get billSummary;

  /// No description provided for @generateBill.
  ///
  /// In en, this message translates to:
  /// **'GENERATE BILL'**
  String get generateBill;

  /// No description provided for @confirmDetails.
  ///
  /// In en, this message translates to:
  /// **'I confirm the details are correct'**
  String get confirmDetails;

  /// No description provided for @billGenerated.
  ///
  /// In en, this message translates to:
  /// **'Bill Generated!'**
  String get billGenerated;

  /// No description provided for @invoiceCreated.
  ///
  /// In en, this message translates to:
  /// **'Invoice created successfully.'**
  String get invoiceCreated;

  /// No description provided for @sharePrint.
  ///
  /// In en, this message translates to:
  /// **'Share / Print'**
  String get sharePrint;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @placeOfSupply.
  ///
  /// In en, this message translates to:
  /// **'Place of Supply'**
  String get placeOfSupply;

  /// No description provided for @billDate.
  ///
  /// In en, this message translates to:
  /// **'Bill Date'**
  String get billDate;

  /// No description provided for @selectItem.
  ///
  /// In en, this message translates to:
  /// **'Select Item'**
  String get selectItem;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @taxableValue.
  ///
  /// In en, this message translates to:
  /// **'Taxable Value'**
  String get taxableValue;

  /// No description provided for @taxAmount.
  ///
  /// In en, this message translates to:
  /// **'Tax Amount'**
  String get taxAmount;

  /// No description provided for @gstr1Report.
  ///
  /// In en, this message translates to:
  /// **'GSTR-1 Report'**
  String get gstr1Report;

  /// No description provided for @b2bInvoices.
  ///
  /// In en, this message translates to:
  /// **'B2B Invoices'**
  String get b2bInvoices;

  /// No description provided for @b2cInvoices.
  ///
  /// In en, this message translates to:
  /// **'B2C Invoices'**
  String get b2cInvoices;

  /// No description provided for @hsnSummary.
  ///
  /// In en, this message translates to:
  /// **'HSN Summary'**
  String get hsnSummary;

  /// No description provided for @exportCSV.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCSV;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @totalInvoices.
  ///
  /// In en, this message translates to:
  /// **'Total Invoices'**
  String get totalInvoices;

  /// No description provided for @totalTaxable.
  ///
  /// In en, this message translates to:
  /// **'Total Taxable'**
  String get totalTaxable;

  /// No description provided for @totalTax.
  ///
  /// In en, this message translates to:
  /// **'Total Tax'**
  String get totalTax;

  /// No description provided for @noInvoicesFound.
  ///
  /// In en, this message translates to:
  /// **'No invoices found for this period'**
  String get noInvoicesFound;

  /// No description provided for @gstr3bReport.
  ///
  /// In en, this message translates to:
  /// **'GSTR-3B Report'**
  String get gstr3bReport;

  /// No description provided for @outwardSupplies.
  ///
  /// In en, this message translates to:
  /// **'Outward Supplies'**
  String get outwardSupplies;

  /// No description provided for @eligibleITC.
  ///
  /// In en, this message translates to:
  /// **'Eligible ITC'**
  String get eligibleITC;

  /// No description provided for @netTaxPayable.
  ///
  /// In en, this message translates to:
  /// **'Net Tax Payable'**
  String get netTaxPayable;

  /// No description provided for @outputTax.
  ///
  /// In en, this message translates to:
  /// **'Output Tax'**
  String get outputTax;

  /// No description provided for @inputTaxCredit.
  ///
  /// In en, this message translates to:
  /// **'Input Tax Credit'**
  String get inputTaxCredit;

  /// No description provided for @netPayable.
  ///
  /// In en, this message translates to:
  /// **'Net Payable'**
  String get netPayable;

  /// No description provided for @caExport.
  ///
  /// In en, this message translates to:
  /// **'CA Export'**
  String get caExport;

  /// No description provided for @exportReportsForCA.
  ///
  /// In en, this message translates to:
  /// **'Export reports for your CA'**
  String get exportReportsForCA;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @salesRegister.
  ///
  /// In en, this message translates to:
  /// **'Sales Register'**
  String get salesRegister;

  /// No description provided for @purchaseRegister.
  ///
  /// In en, this message translates to:
  /// **'Purchase Register'**
  String get purchaseRegister;

  /// No description provided for @taxSummaryPDF.
  ///
  /// In en, this message translates to:
  /// **'Tax Summary PDF'**
  String get taxSummaryPDF;

  /// No description provided for @generateAndShare.
  ///
  /// In en, this message translates to:
  /// **'GENERATE & SHARE'**
  String get generateAndShare;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'GENERATING...'**
  String get generating;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Smart Stock Management'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Track your inventory in real-time. Never run out of stock again.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Work Smart, Work Easy'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Simplify daily operations, generate invoices, and manage your team from one place.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Your Complete Business Toolkit'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'GST billing, cash flow, analytics and much more — all at your fingertips.'**
  String get onboardingDesc3;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'BharatStock'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@business.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get passwordLabel;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get loginButton;

  /// No description provided for @newUserText.
  ///
  /// In en, this message translates to:
  /// **'New user? '**
  String get newUserText;

  /// No description provided for @signUpLinkText.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpLinkText;

  /// No description provided for @welcomeBackToast.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBackToast;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check credentials.'**
  String get loginFailed;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get fillAllFields;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join the leading network for Indian businesses'**
  String get signupSubtitle;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM PASSWORD'**
  String get confirmPasswordLabel;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'SIGN UP'**
  String get signupButton;

  /// No description provided for @alreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyAccount;

  /// No description provided for @loginLinkText.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginLinkText;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match!'**
  String get passwordMismatch;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Password must be >6 chars, with Letter, Number & Special Char'**
  String get passwordWeak;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created!'**
  String get accountCreated;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'FULL NAME'**
  String get fullNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Recovery'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset link.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendLinkButton.
  ///
  /// In en, this message translates to:
  /// **'SEND RESET LINK'**
  String get sendLinkButton;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent! Check your email.'**
  String get resetLinkSent;

  /// No description provided for @roleSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BharatStock'**
  String get roleSelectionTitle;

  /// No description provided for @roleSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your role to continue'**
  String get roleSelectionSubtitle;

  /// No description provided for @ownerTitle.
  ///
  /// In en, this message translates to:
  /// **'I am a Business Owner'**
  String get ownerTitle;

  /// No description provided for @ownerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new business, manage inventory and tax.'**
  String get ownerSubtitle;

  /// No description provided for @staffTitle.
  ///
  /// In en, this message translates to:
  /// **'I am a Staff Member'**
  String get staffTitle;

  /// No description provided for @staffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join an existing business using shop code.'**
  String get staffSubtitle;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @expenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Title'**
  String get expenseTitle;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @selectPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Period'**
  String get selectPeriod;

  /// No description provided for @reportsToInclude.
  ///
  /// In en, this message translates to:
  /// **'Reports to Include'**
  String get reportsToInclude;

  /// No description provided for @salesRegisterDesc.
  ///
  /// In en, this message translates to:
  /// **'Detailed record of all sales'**
  String get salesRegisterDesc;

  /// No description provided for @purchaseRegisterDesc.
  ///
  /// In en, this message translates to:
  /// **'Detailed record of all purchases'**
  String get purchaseRegisterDesc;

  /// No description provided for @taxSummaryPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'Consolidated tax summary'**
  String get taxSummaryPdfDesc;

  /// No description provided for @expenseManager.
  ///
  /// In en, this message translates to:
  /// **'Expense Manager'**
  String get expenseManager;

  /// No description provided for @totalSpending.
  ///
  /// In en, this message translates to:
  /// **'Total Spending'**
  String get totalSpending;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get deleteExpense;

  /// No description provided for @confirmDeleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get confirmDeleteExpense;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @profitLossAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss Analysis'**
  String get profitLossAnalysis;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @manageExpenses.
  ///
  /// In en, this message translates to:
  /// **'Manage Expenses'**
  String get manageExpenses;

  /// No description provided for @netLoss.
  ///
  /// In en, this message translates to:
  /// **'Net Loss'**
  String get netLoss;

  /// No description provided for @grossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit'**
  String get grossProfit;

  /// No description provided for @margin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get margin;

  /// No description provided for @financialPerformance.
  ///
  /// In en, this message translates to:
  /// **'Financial Performance'**
  String get financialPerformance;

  /// No description provided for @revenueVsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Revenue vs Expenses'**
  String get revenueVsExpenses;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @inventoryCost.
  ///
  /// In en, this message translates to:
  /// **'Inventory Cost'**
  String get inventoryCost;

  /// No description provided for @operatingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Operating Expenses'**
  String get operatingExpenses;

  /// No description provided for @itemsSold.
  ///
  /// In en, this message translates to:
  /// **'Items Sold'**
  String get itemsSold;

  /// No description provided for @recentExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recent Expenses'**
  String get recentExpenses;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @taxLedger.
  ///
  /// In en, this message translates to:
  /// **'Tax Ledger'**
  String get taxLedger;

  /// No description provided for @stockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory Management'**
  String get stockSubtitle;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @businessHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Network & B2B Trading'**
  String get businessHubSubtitle;

  /// No description provided for @waitersStaff.
  ///
  /// In en, this message translates to:
  /// **'Waiters/Staff'**
  String get waitersStaff;

  /// No description provided for @viewWorkers.
  ///
  /// In en, this message translates to:
  /// **'View Workers'**
  String get viewWorkers;

  /// No description provided for @viewItems.
  ///
  /// In en, this message translates to:
  /// **'View Items'**
  String get viewItems;

  /// No description provided for @manageCustomers.
  ///
  /// In en, this message translates to:
  /// **'Manage Customers'**
  String get manageCustomers;

  /// No description provided for @manageSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Manage Suppliers'**
  String get manageSuppliers;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @salesReport.
  ///
  /// In en, this message translates to:
  /// **'Sales Report'**
  String get salesReport;

  /// No description provided for @taxSummary.
  ///
  /// In en, this message translates to:
  /// **'Tax Summary'**
  String get taxSummary;

  /// No description provided for @salesRevenue.
  ///
  /// In en, this message translates to:
  /// **'Sales/Revenue'**
  String get salesRevenue;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @businessHub.
  ///
  /// In en, this message translates to:
  /// **'Business Hub'**
  String get businessHub;

  /// No description provided for @csvPdf.
  ///
  /// In en, this message translates to:
  /// **'CSV + PDF'**
  String get csvPdf;

  /// No description provided for @billingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Billing & Invoices'**
  String get billingInvoices;

  /// No description provided for @staffManagement.
  ///
  /// In en, this message translates to:
  /// **'Staff Management'**
  String get staffManagement;

  /// No description provided for @partiesLedgers.
  ///
  /// In en, this message translates to:
  /// **'Parties & Ledgers'**
  String get partiesLedgers;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @supportHelp.
  ///
  /// In en, this message translates to:
  /// **'Support & Help'**
  String get supportHelp;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @yourShop.
  ///
  /// In en, this message translates to:
  /// **'Your Shop'**
  String get yourShop;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup >'**
  String get completeSetup;

  /// No description provided for @overdueBills.
  ///
  /// In en, this message translates to:
  /// **'You have {count} bills overdue'**
  String overdueBills(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
