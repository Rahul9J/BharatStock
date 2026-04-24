# BharatStock Technical Reference Manual
## Codebase Logic & Architectural Breakdown

This document provides a detailed explanation of every Dart file in the BharatStock project, describing its internal logic, primary classes, and the widgets utilized.

---

## 🏗️ 01. Core Architecture Layer
The core layer contains the foundation of the app, including shared utilities, database services, and the global design system.

### 📍 Localization & Strings
- **`lib/core/localization/app_strings.dart`**
    - **Purpose**: Acts as the central gateway for retrieving translated text.
    - **Logic**: It uses a static `get(key)` method. It checks the current system language (LanguageProvider) and fetches the value from the `languages.dart` map.
    - **Class**: `AppStrings`
- **`lib/core/localization/languages.dart`**
    - **Purpose**: The database of all UI strings.
    - **Logic**: A large nested `Map<String, Map<String, String>>` containing translations for 'en' (English), 'hi' (Hindi), and 'gu' (Gujarati).

### ⚙️ Services & Providers
- **`lib/core/services/firestore_service.dart`**
    - **Purpose**: Wrapper for all Google Cloud Firestore interactions.
    - **Logic**: Implements CRUD (Create, Read, Update, Delete) operations. It ensures that every query is strictly filtered by the user's `businessId` to prevent data leaks.
    - **Class**: `FirestoreService`
- **`lib/core/services/business_service.dart`**
    - **Purpose**: Manages business-specific metadata.
    - **Logic**: Handles the registration of new shop profiles and updates global business settings (like address or GSTIN).
    - **Class**: `BusinessService`
- **`lib/core/providers/language_provider.dart`**
    - **Purpose**: Global state management for the app's language.
    - **Logic**: Uses Flutter's `ChangeNotifier`. When a user selects a new language, it notifies the entire UI to re-render without a restart.
    - **Class**: `LanguageProvider`

### 🛠️ Computational Utilities
- **`lib/core/utils/tax_calculator.dart`**
    - **Purpose**: The "Brain" of the GST engine.
    - **Logic**: Pure Dart logic for calculating taxes. It handles:
        - *Inclusive math*: (Total / (1 + Rate)) to find the taxable value.
        - *State Logic*: Compares the `businessState` with the `partyState`. If they match, it splits tax into 50/50 CGST and SGST. If they differ, it applies 100% IGST.
    - **Class**: `TaxCalculator`
- **`lib/core/utils/validation_utils.dart`**
    - **Purpose**: Input sanitation.
    - **Logic**: Uses Regular Expressions (RegEx) to validate Indian GSTINs (must be 15 chars), PAN cards, and Mobile numbers.

### 🎨 Visual Design System
- **`lib/core/widgets/clay_widgets.dart`**
    - **Purpose**: Defines the custom "Claymorphic" design identity.
    - **Classes**:
        - `ClayCard`: Provides a 3D elevated surface for sections.
        - `ClayInput`: A recessed text field that looks "pressed into" the screen.
        - `ClayButton`: A tactile 3D button that reacts to taps with shadow changes.

-------------------------------------------------------------------------

## 🔐 02. Authentication & Onboarding
This layer handles the "Entry Point" of the application.

- **`lib/features/auth/data/user_model.dart`**
    - **Purpose**: Data structure for user profiles.
    - **Logic**: maps Firestore JSON data to Dart objects. Includes fields for `role` (owner/staff) and `businessId`.
- **`lib/features/auth/logic/auth_service.dart`**
    - **Purpose**: Integration with Firebase Authentication.
    - **Logic**: Manages Firebase Login, Signup, and Password resets. 
- **`lib/features/auth/presentation/login_screen.dart`**
    - **Purpose**: The primary login gateway.
    - **Widgets**: `ClayInput` for credentials, `ClayButton` for submission.
- **`lib/features/auth/presentation/signup_screen.dart`**
    - **Purpose**: New user registration.
    - **Logic**: Collects email/password and then pushes the user to the "Role Selection" flow.
- **`lib/features/auth/presentation/role_selection_screen.dart`**
    - **Purpose**: Splits the user flow.
    - **Logic**: Asks "Are you a Shop Owner or Staff?". This choice determines whether they create a new business or join an existing one via a Secret ID.

---------------------------------------------------

## 📈 03. Billing & Accounting Feature

- **`lib/features/billing/presentation/bill_generation_screen.dart`**
    - **Purpose**: The most complex screen in the app.
    - **Logic**:
        - Users add multiple items to a "Bill Cart".
        - The `TaxCalculator` runs in the background for every item added.
        - Real-time aggregation of the Grand Total happens via a persistent `BillModel`.
    - **Widgets**: Uses a `ListView` for line items and a floating `ClayCard` for the final bill total.
- **`lib/features/billing/data/bill_model.dart`**
    - **Purpose**: Defines what a "Bill" looks like.
    - **Logic**: Stores customer name, list of items, HSN summaries, and tax breakdown.
- **`lib/features/billing/services/pdf_invoice_service.dart`**
    - **Purpose**: Converts digital bills into physical-ready PDFs.
    - **Logic**: Uses the `pdf/widgets.dart` library to draw a professional invoice layout including columns for HSN, Rate, and Tax splits.
- **`lib/features/accounting/presentation/party_list_screen.dart`**
    - **Purpose**: CRM (Customer Relationship Management).
    - **Logic**: Lists all customers and suppliers. Tracks the "Balance" (money owed or receivable).

## 📊 04. Analytics & GST Reporting

- **`lib/features/analytics/presentation/gstr1_report_screen.dart`**
    - **Purpose**: Generates the GSTR-1 (Outward Supplies) summary.
    - **Logic**: It streams all bills for the selected month and uses a `Map<double, double>` to aggregate sales by GST Rate (e.g., how many ₹5% vs ₹18% sales were made).
- **`lib/features/analytics/presentation/tax_ledger_screen.dart`**
    - **Purpose**: A real-time ledger of GST liabilities.
    - **Logic**: Compares "Output Tax" (from sales) vs "Input Tax Credit" (from purchases) to show the net payable amount to the government.
- **`lib/features/analytics/services/excel_service.dart`**
    - **Purpose**: Data portability.
    - **Logic**: Uses the `excel` package to create `.xlsx` files. It loops through the Firestore bill collection and creates rows for Date, Party Name, GSTIN, and Taxable Value.

---

## 📦 05. Inventory & Stock Management

- **`lib/features/inventory/data/product_model.dart`**
    - **Purpose**: Core data entity for items.
    - **Logic**: Contains validation for HSN codes and handles `toJson()`/`fromJson()` for Firestore syncing.
- **`lib/features/inventory/logic/inventory_service.dart`**
    - **Purpose**: The bridge between UI and Database for stock.
    - **Logic**: Implements "Stock Auditing." When a sale is made, it performs a Firestore `Transaction` to atomically decrement the `quantity` field to prevent race conditions.
- **`lib/features/inventory/presentation/product_list_screen.dart`**
    - **Purpose**: Real-time stock dashboard.
    - **Widgets**: Uses `StreamBuilder` to reactively update the UI whenever a sale happens on another device (e.g., if a staff member generates a bill).

---

## 🤝 06. Interaction Hub (B2B Networking)

- **`lib/features/interactions/logic/interaction_service.dart`**
    - **Purpose**: Powers the "Social Network" side of the app.
    - **Logic**: Uses a "Public Directory" collection. When Business A wants to send a bill to Business B, this service finds Business B's `shopId` and creates a message entry in their secure inbox.
- **`lib/features/interactions/presentation/interaction_hub_screen.dart`**
    - **Purpose**: List of connected business partners.
    - **Logic**: Sorts partners by "Last Transaction Date."
- **`lib/features/interactions/presentation/interaction_chat_screen.dart`**
    - **Purpose**: Interface for bill approval.
    - **Widgets**: Uses custom `MessageBubble` widgets built with `ClayContainer` to display shared bills.

---

## 🏁 Summary of Architectural Workflow
When a user performs a Sale:
1. **Selection**: User picks a product in `bill_generation_screen.dart`.
2. **Calculation**: `TaxCalculator` determines the CGST/SGST split.
3. **Storage**: `FirestoreService` saves the bill.
4. **Automation**: `InventoryService` reduces stock levels.
5. **Notification**: If the customer is another BharatStock business, `InteractionService` pushes the bill to their "Interactions Hub".

---
**DOCUMENTATION COMPLETE**

