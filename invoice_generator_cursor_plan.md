# 📱 Invoice Generator App — Cursor Build Plan
### Flutter + GetX + Hive | Android-First | Full-Featured

---

## 📌 Overview

Build a **production-ready Invoice Generator & Maker App** for Android using Flutter. This document is the **single source of truth for Cursor** to generate all code, screens, logic, and configurations with minimal manual intervention. Follow the task order strictly.

**Tech Stack:**
- Flutter (Android-first, iOS optional)
- State Management: **GetX** (mandatory everywhere)
- Local DB: **Hive**
- Auth: **Google Sign-In** (mock/dummy — extract user name and show mock data)
- PDF Generation: `pdf` + `printing` packages
- Email: `flutter_email_sender`
- AI Chatbot: **Gemini API** (light feature on Dashboard)
- Animations: `lottie`

---

## 🗂️ Folder Structure

```
lib/
├── main.dart
├── app/
│   ├── bindings/
│   │   └── app_bindings.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   └── app_text_styles.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── utils/
│   │       ├── currency_formatter.dart
│   │       ├── date_formatter.dart
│   │       └── number_to_words.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── client_model.dart        (HiveObject)
│   │   │   ├── invoice_model.dart       (HiveObject)
│   │   │   ├── invoice_item_model.dart  (HiveObject)
│   │   │   └── user_profile_model.dart
│   │   └── services/
│   │       ├── hive_service.dart
│   │       ├── pdf_service.dart
│   │       ├── email_service.dart
│   │       └── gemini_service.dart
│   ├── modules/
│   │   ├── splash/
│   │   │   ├── splash_screen.dart
│   │   │   └── splash_controller.dart
│   │   ├── onboarding/
│   │   │   ├── onboarding_screen.dart
│   │   │   └── onboarding_controller.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── auth_controller.dart
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── dashboard_controller.dart
│   │   │   └── widgets/
│   │   │       ├── stat_card_widget.dart
│   │   │       ├── quick_action_widget.dart
│   │   │       ├── recent_invoice_tile.dart
│   │   │       └── gemini_chatbot_sheet.dart
│   │   ├── clients/
│   │   │   ├── client_list_screen.dart
│   │   │   ├── add_client_screen.dart
│   │   │   ├── client_detail_screen.dart
│   │   │   └── client_controller.dart
│   │   ├── invoices/
│   │   │   ├── invoice_list_screen.dart
│   │   │   ├── create_invoice_screen.dart
│   │   │   ├── invoice_preview_screen.dart
│   │   │   └── invoice_controller.dart
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   └── profile_controller.dart
│   │   └── tutorial/
│   │       ├── tutorial_overlay.dart
│   │       └── tutorial_controller.dart
│   └── routes/
│       ├── app_routes.dart
│       └── app_pages.dart
├── Screenshots/           ← reference UI screenshots (already in project)
└── assets/
    ├── animations/        ← Lottie JSON files
    └── fonts/
```

---

## 📦 pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  get: ^4.6.6

  # Local DB
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Auth
  google_sign_in: ^6.2.1

  # PDF
  pdf: ^3.10.8
  printing: ^5.12.0
  path_provider: ^2.1.2

  # Email
  flutter_email_sender: ^6.0.3

  # Animations
  lottie: ^3.1.0

  # Image Picker (for business logo)
  image_picker: ^1.0.7

  # Permissions
  permission_handler: ^11.3.0

  # Number formatting
  intl: ^0.19.0

  # UUID generation
  uuid: ^4.3.3

  # HTTP (Gemini API)
  http: ^1.2.1

  # Share Plus
  share_plus: ^7.2.2

  # Open File
  open_file: ^3.3.2

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
```

---

## 🔐 Android Manifest Permissions

**File: `android/app/src/main/AndroidManifest.xml`**

Add ALL of the following permissions:

```xml
<!-- Internet (Gemini API, Google Sign-In) -->
<uses-permission android:name="android.permission.INTERNET"/>

<!-- Storage - Read/Write for PDF saving -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29"/>

<!-- For Android 13+ scoped storage -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>

<!-- Email -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- Vibration for feedback -->
<uses-permission android:name="android.permission.VIBRATE"/>
```

Also add `android:requestLegacyExternalStorage="true"` to `<application>` tag for Android 10 compatibility.

---

## 🎯 Task 1: Project Setup & Hive Configuration

### 1.1 — Initialize Hive Models

Create the following Hive models with `@HiveType` annotations:

**`client_model.dart`**
```dart
@HiveType(typeId: 0)
class ClientModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String email;
  @HiveField(3) String phone;
  @HiveField(4) String address;
  @HiveField(5) String? gstin;
  @HiveField(6) DateTime createdAt;
}
```

**`invoice_item_model.dart`**
```dart
@HiveType(typeId: 1)
class InvoiceItemModel extends HiveObject {
  @HiveField(0) String description;
  @HiveField(1) double quantity;
  @HiveField(2) double rate;
  @HiveField(3) double get amount => quantity * rate;
}
```

**`invoice_model.dart`**
```dart
@HiveType(typeId: 2)
class InvoiceModel extends HiveObject {
  @HiveField(0)  String id;
  @HiveField(1)  String invoiceNumber;   // e.g. INV-000001
  @HiveField(2)  String clientId;
  @HiveField(3)  DateTime invoiceDate;
  @HiveField(4)  DateTime dueDate;
  @HiveField(5)  List<InvoiceItemModel> items;
  @HiveField(6)  bool applyGst;
  @HiveField(7)  double gstPercent;      // default 18.0
  @HiveField(8)  String status;          // 'draft' | 'sent' | 'paid' | 'overdue'
  @HiveField(9)  String notes;
  @HiveField(10) double paymentMade;
  @HiveField(11) String terms;           // e.g. "Due on Receipt"
  @HiveField(12) DateTime createdAt;
  
  double get subTotal => items.fold(0, (sum, i) => sum + i.amount);
  double get gstAmount => applyGst ? subTotal * gstPercent / 100 : 0;
  double get total => subTotal + gstAmount;
  double get balanceDue => total - paymentMade;
}
```

### 1.2 — Hive Service

**`hive_service.dart`** — singleton service opened in `main.dart`:
- Open boxes: `clients`, `invoices`, `userProfile`, `appSettings`
- Register all adapters
- Provide CRUD helpers: `addClient()`, `updateClient()`, `deleteClient()`, `addInvoice()`, `updateInvoice()`, `deleteInvoice()`, `getInvoicesByClient()`

### 1.3 — main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Register adapters
  await HiveService.init();
  runApp(MyApp());
}
```

---

## 🎯 Task 2: Routes & Bindings

**`app_routes.dart`**
```dart
abstract class AppRoutes {
  static const splash       = '/splash';
  static const onboarding   = '/onboarding';
  static const login        = '/login';
  static const dashboard    = '/dashboard';
  static const clientList   = '/clients';
  static const addClient    = '/clients/add';
  static const clientDetail = '/clients/detail';
  static const invoiceList  = '/invoices';
  static const createInvoice = '/invoices/create';
  static const invoicePreview = '/invoices/preview';
  static const profile      = '/profile';
}
```

**`app_pages.dart`** — Wire each route to screen + binding using `GetPage`.

**`app_bindings.dart`** — `InitialBinding` that lazy-puts all controllers.

---

## 🎯 Task 3: Theme & Design System

### UI Color Palette (match screenshots — Zoho Invoice style, clean white + blue)

```dart
// app_colors.dart
class AppColors {
  static const primary        = Color(0xFF1A73E8);   // Blue
  static const primaryDark    = Color(0xFF1557B0);
  static const accent         = Color(0xFF00BFA5);   // Teal accent
  static const success        = Color(0xFF34A853);
  static const warning        = Color(0xFFFBBC04);
  static const danger         = Color(0xFFEA4335);
  static const background     = Color(0xFFF8F9FA);
  static const surface        = Color(0xFFFFFFFF);
  static const textPrimary    = Color(0xFF202124);
  static const textSecondary  = Color(0xFF5F6368);
  static const divider        = Color(0xFFE0E0E0);
  static const cardShadow     = Color(0x14000000);
  static const statusPaid     = Color(0xFF34A853);
  static const statusPending  = Color(0xFFFBBC04);
  static const statusOverdue  = Color(0xFFEA4335);
  static const statusDraft    = Color(0xFF9AA0A6);
}
```

Define `ThemeData` with card elevation, border radius `12`, inter/Roboto font.

---

## 🎯 Task 4: Splash Screen ⭐ HIGH PRIORITY

**Reference screenshot:** `lib/Screenshots/Screenshot_20260413-223434_Zoho Invoice.jpg`

- Full-screen with brand gradient (primary blue)
- Center: App Logo (invoice icon) + App Name "InvoGen"
- Use **Lottie animation** (invoice writing / document animation)
- Duration: 2.5s → check if user is logged in
  - If logged in → Navigate to Dashboard
  - If first launch → Navigate to Onboarding
  - Else → Navigate to Login
- `SplashController` uses `GetStorage` to check `isLoggedIn` & `isFirstLaunch`

```dart
class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    Future.delayed(2500.milliseconds, _navigate);
  }
  
  void _navigate() {
    final box = GetStorage();
    if (box.read('isLoggedIn') == true) {
      Get.offNamed(AppRoutes.dashboard);
    } else if (box.read('isFirstLaunch') != false) {
      Get.offNamed(AppRoutes.onboarding);
    } else {
      Get.offNamed(AppRoutes.login);
    }
  }
}
```

---

## 🎯 Task 5: Onboarding Screen

**Reference screenshots:** `lib/Screenshots/Screenshot_20260413-231744_Zoho Invoice.jpg`, `Screenshot_20260413-231805_Zoho Invoice.jpg`

3-page onboarding using `PageView`:
1. **"Create Professional Invoices"** — Invoice icon + description
2. **"Manage Your Clients"** — People icon + description
3. **"Track Payments & Revenue"** — Chart icon + description

Each page: large centered Lottie animation, title, subtitle text.

Bottom: Dot indicators + Next/Skip button. On last page: **"Get Started"** → Login.

Store `isFirstLaunch = false` in GetStorage on completion.

---

## 🎯 Task 6: Login Screen

**Reference screenshot:** `lib/Screenshots/Screenshot_20260413-231810_Zoho Invoice.jpg`

- Clean centered card layout
- App logo + "Welcome to InvoGen" title
- **Google Sign-In button** (standard Google branded button)
- On sign-in success:
  - Extract `displayName` from GoogleSignInAccount
  - Store name, email, photoUrl in Hive `userProfile` box
  - Pre-populate mock dashboard data (3 mock invoices, 2 mock clients using the user's name)
  - Navigate to Dashboard

**Mock data autofill:** On successful Google login, call `_seedMockData(userName)` which creates:
- 2 mock clients
- 3 mock invoices (one paid, one pending, one draft)

```dart
class AuthController extends GetxController {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  
  Future<void> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await HiveService.saveUserProfile(account.displayName, account.email, account.photoUrl);
        await _seedMockData(account.displayName ?? 'User');
        GetStorage().write('isLoggedIn', true);
        Get.offNamed(AppRoutes.dashboard);
      }
    } catch (e) {
      Get.snackbar('Error', 'Sign-in failed: $e');
    }
  }
}
```

---

## 🎯 Task 7: Dashboard Screen ⭐⭐ HIGHEST PRIORITY

**Reference screenshots:** 
- `lib/Screenshots/Screenshot_20260413-233234_Zoho Invoice.jpg`
- `lib/Screenshots/Screenshot_20260413-233248_Zoho Invoice.jpg`
- `lib/Screenshots/Screenshot_20260413-235124_Zoho Invoice.jpg`

### Layout

```
AppBar: "Good Morning, [Name] 👋"  |  Avatar + Notification icon
─────────────────────────────────────────────────────
STATS ROW (horizontal scroll cards):
  [Total Revenue ₹]  [Clients]  [Pending]  [Overdue]
─────────────────────────────────────────────────────
QUICK ACTIONS (2x2 grid):
  [+ New Invoice]   [+ Add Client]
  [📄 View All]     [📊 Reports]
─────────────────────────────────────────────────────
RECENT INVOICES (ListView):
  Invoice tile: #INV-XXXX | Client | Amount | Status chip
─────────────────────────────────────────────────────
FAB: 💬 (opens Gemini AI chatbot bottom sheet) 
```

### Stat Cards Widget
Each card: icon + label + value. Use `Obx` for reactivity.
- **Total Revenue**: Sum of all paid invoice totals
- **Total Clients**: Count from Hive clients box
- **Pending Amount**: Sum of balanceDue on sent invoices
- **Overdue Count**: Count of overdue invoices

### Quick Actions
Tappable cards with icon + label with ripple effect:
- `+ New Invoice` → `AppRoutes.createInvoice`
- `+ Add Client` → `AppRoutes.addClient`
- `View Invoices` → `AppRoutes.invoiceList`
- `View Clients` → `AppRoutes.clientList`

### Tutorial Overlay (first-time only)
On first dashboard visit, show a **guided step-by-step tutorial overlay**:

```dart
class TutorialStep {
  final String title;
  final String description;
  final GlobalKey targetKey;
  final TutorialPosition position;
}
```

Steps:
1. Highlight stat cards → "See your revenue at a glance"
2. Highlight Quick Actions → "Quickly create invoices or add clients"
3. Highlight Recent Invoices → "Track your latest invoices here"
4. Highlight FAB → "Ask AI for help anytime"

Use a semi-transparent overlay with a cutout (spotlight effect) around each target widget. Show "Next" / "Skip" / "Done" buttons. Store `tutorialShown = true` in GetStorage after completion.

### Gemini AI Chatbot (FAB → Bottom Sheet) — Lower Priority
- Floating action button (chat icon) at bottom right
- Opens a `DraggableScrollableSheet` chatbot UI
- Simple chat UI: messages list + text input
- System prompt: "You are a helpful assistant for the InvoGen invoice app. Answer questions about creating invoices, managing clients, and tracking payments."
- Uses `http` package to call Gemini API: `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent`
- Store API key in `app_strings.dart` as `geminiApiKey`

---

## 🎯 Task 8: Client Management ⭐⭐ HIGH PRIORITY

### Client List Screen
**Reference screenshots:**
- `lib/Screenshots/Screenshot_20260414-000835_Zoho Invoice.jpg`
- `lib/Screenshots/Screenshot_20260414-000844_Zoho Invoice.jpg`

- `AppBar`: "Clients" + search icon
- `SearchBar` (collapsible) — filter clients by name/email in real-time using `Obx`
- Client cards: Avatar (initials), Name, Email, Phone, invoice count badge
- Swipe-to-delete with confirmation dialog
- FAB: `+` → Add Client
- Empty state: illustration + "No clients yet. Add your first client!"

### Add/Edit Client Screen ⭐ DEV AUTOFILL BUTTON REQUIRED
**Reference screenshots:**
- `lib/Screenshots/Screenshot_20260414-001246_Zoho Invoice.jpg`
- `lib/Screenshots/Screenshot_20260414-001638_Zoho Invoice.jpg`

Form fields:
- Client Name *
- Email Address *
- Phone Number *
- Billing Address (multiline)
- GSTIN / Tax Number (optional)

**🛠️ DEV AUTOFILL BUTTON** — Visible orange `[🔧 Dev Fill]` button at top of form (can be toggled off with a const flag `kDebugMode`). On tap, fills all fields with:
```dart
void devAutofill() {
  nameController.text = 'Sanjay Hooda';
  emailController.text = 'sanjay.hooda@example.com';
  phoneController.text = '+91 98765 43210';
  addressController.text = 'B-42, Sector 18, Gurugram, Haryana 122001';
  gstinController.text = '06AABCU9603R1ZX';
}
```

Save → HiveService → Navigate back with success snackbar.

### Client Detail Screen
- Client info header (name, email, phone, address)
- Invoice history list for this client
- Totals: total billed, total paid, outstanding
- Action buttons: Edit, Delete, Create Invoice for this client

---

## 🎯 Task 9: Invoice Management ⭐⭐ HIGHEST PRIORITY

### Invoice List Screen
**Reference screenshots:**
- `lib/Screenshots/Screenshot_20260414-002209_Zoho Invoice.jpg`
- `lib/Screenshots/Screenshot_20260414-002212_Zoho Invoice.jpg`
- `lib/Screenshots/Screenshot_20260414-002214_Zoho Invoice.jpg`

- Filter tabs: **All | Draft | Sent | Paid | Overdue**
- Each tile: Invoice number, client name, date, amount, status chip
- Status chip colors: Draft=grey, Sent=blue, Paid=green, Overdue=red
- Tap → Invoice Preview
- Long press or swipe → Delete/Edit options
- FAB: Create new invoice
- Search bar

### Create Invoice Screen ⭐⭐ HIGHEST PRIORITY + DEV AUTOFILL
**Reference screenshots:**
- `lib/Screenshots/Screenshot_20260414-002228_Zoho Invoice.jpg`
- `lib/Screenshots/Screenshot_20260414-002320_Zoho Invoice.jpg`
- `lib/Screenshots/Screenshot_20260414-002345_Zoho Invoice.jpg`
- `lib/Screenshots/Screenshot_20260414-002400_Zoho Invoice.jpg`

**🛠️ DEV AUTOFILL BUTTON** — Orange button to fill entire form:
```dart
void devAutofill() {
  selectedClient.value = clientController.clients.first;
  invoiceDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  dueDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  termsController.text = 'Due on Receipt';
  notesController.text = 'Thanks for your business.';
  items.assignAll([
    InvoiceItemModel(description: 'Printer', quantity: 1, rate: 4000),
  ]);
  applyGst.value = false;
}
```

#### Section 1: Invoice Header
- Invoice Number (auto-generated: INV-000001, INV-000002...)
- Invoice Date (DatePicker)
- Due Date (DatePicker)
- Payment Terms dropdown: "Due on Receipt", "Net 15", "Net 30", "Net 45"

#### Section 2: Bill To
- Client selector (Dropdown showing all clients from Hive)
- "Add New Client" option inline
- Shows selected client's name, email, address below

#### Section 3: Line Items ⭐⭐ ITEMIZED BILLING
Dynamic list of items:

```
┌─────────────────────────────────────────┐
│ Item Description          Qty  Rate  Amt│
│ [___________________]  [1.0] [0.00] auto│
│ [+ Add Item]                            │
└─────────────────────────────────────────┘
```

- Each item row: description TextField, qty (number), rate (number), amount (auto-calculated, read-only)
- Add item: adds new row
- Delete item: swipe or X button
- Auto-calculates amount on qty/rate change using `GetX` reactive variables

#### Section 4: Tax/GST ⭐⭐ HIGH PRIORITY
```
Apply GST     [Toggle]
GST Rate      [18%  ▼]  (dropdown: 0%, 5%, 12%, 18%, 28%)
```
When GST enabled:
- Shows GST breakdown: Subtotal + CGST (9%) + SGST (9%) = Total
  - OR: Subtotal + IGST (18%) = Total
- Toggle between CGST/SGST (intra-state) and IGST (inter-state)

#### Section 5: Summary
```
Subtotal:           ₹4,000.00
CGST (9%):             ₹360.00
SGST (9%):             ₹360.00
──────────────────────────────
Total:              ₹4,720.00
Payment Received:   ₹0.00
Balance Due:        ₹4,720.00
```
All calculated reactively using `Obx`.

#### Section 6: Notes & Terms
- Notes multiline field
- Authorized signature placeholder

#### Action Buttons
- `[Save as Draft]` → saves with status='draft'
- `[Preview Invoice]` → navigates to preview
- `[Send Invoice]` → saves with status='sent' + triggers email

---

### Invoice Preview Screen ⭐⭐ HIGH PRIORITY
**Reference screenshots:**
- `lib/Screenshots/Screenshot_20260414-002404_Zoho Invoice.jpg`
- `lib/Screenshots/Screenshot_20260414-002411_Zoho Invoice.jpg`

Match the **sample PDF exactly** (`lib/INV-000001.pdf` or attached PDF):

```
┌─────────────────────────────────────────┐
│  [Business Name]            TAX INVOICE │
│  Address                                │
│  Email                                  │
│─────────────────────────────────────────│
│  # : INV-000001                         │
│  Invoice Date : 14/04/2026              │
│  Terms : Due on Receipt                 │
│  Due Date : 14/04/2026                  │
│─────────────────────────────────────────│
│  Bill To                                │
│  [Client Name]                          │
│─────────────────────────────────────────│
│  # │ Item & Description │ Qty│Rate │Amt │
│  1 │ Printer            │1.00│4000 │4000│
│─────────────────────────────────────────│
│  Total In Words: Indian Rupee Four...   │
│  Notes: Thanks for your business.       │
│              Sub Total    4,000.00      │
│              Total       ₹4,000.00      │
│              Payment Made (-) 4,000.00  │
│              Balance Due     ₹0.00      │
│                  Authorized Signature   │
└─────────────────────────────────────────┘
```

Action bar (bottom):
- `[📄 Generate PDF]`
- `[📧 Send Email]`
- `[📤 Share]`
- `[✏️ Edit]`
- `[✅ Mark as Paid]`

---

## 🎯 Task 10: PDF Generation ⭐⭐ HIGH PRIORITY

**File: `pdf_service.dart`**

Match the attached sample invoice PDF exactly (`lib/Screenshots/` → reference `INV-000001.pdf`).

```dart
class PdfService {
  static Future<File> generateInvoicePdf(InvoiceModel invoice, ClientModel client, UserProfileModel business) async {
    final pdf = pw.Document();
    
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(children: [
        // Header: Business Name + TAX INVOICE
        _buildHeader(business),
        // Invoice meta: #, Date, Terms, Due Date
        _buildInvoiceMeta(invoice),
        // Bill To section
        _buildBillTo(client),
        // Items table
        _buildItemsTable(invoice),
        // Totals + Notes + Signature
        _buildTotalsSection(invoice),
        // Footer
        _buildFooter(),
      ])
    ));
    
    // Save to app documents directory
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
```

Key PDF elements (replicate from sample):
- Business name bold, left-aligned
- "TAX INVOICE" large text, right-aligned
- Horizontal dividers between sections
- Items table with header row (shaded)
- "Total In Words" in bold italic
- Balance Due row in bold with ₹ symbol
- Authorized Signature line at bottom right
- Amount in Indian number format (1,00,000.00)

---

## 🎯 Task 11: Auto Email ⭐⭐ HIGH PRIORITY

**File: `email_service.dart`**

Triggered automatically when "Send Invoice" is tapped OR can be sent from Preview screen.

```dart
class EmailService {
  static Future<void> sendInvoiceEmail({
    required InvoiceModel invoice,
    required ClientModel client,
    required File pdfFile,
  }) async {
    final email = Email(
      body: '''Dear ${client.name},

Please find attached your invoice ${invoice.invoiceNumber} for ₹${invoice.total.toStringAsFixed(2)}.

Invoice Date: ${DateFormat('dd/MM/yyyy').format(invoice.invoiceDate)}
Due Date: ${DateFormat('dd/MM/yyyy').format(invoice.dueDate)}
Amount Due: ₹${invoice.balanceDue.toStringAsFixed(2)}

${invoice.notes}

Thank you for your business!''',
      subject: 'Invoice ${invoice.invoiceNumber} from [Business Name]',
      recipients: [client.email],
      attachmentPaths: [pdfFile.path],
      isHTML: false,
    );
    
    await FlutterEmailSender.send(email);
  }
}
```

---

## 🎯 Task 12: Profile / Business Settings Screen

**Reference screenshots:**
- `lib/Screenshots/Screenshot_20260414-003055_Zoho Invoice.jpg`
- `lib/Screenshots/Screenshot_20260414-003100_Zoho Invoice.jpg`

**🛠️ DEV AUTOFILL BUTTON** fills all profile fields.

Fields:
- Business Name *
- Business Address
- Email *
- Phone
- GSTIN
- Business Logo (image picker)
- Default GST Rate (dropdown)
- Default Payment Terms
- Default Notes template

This data is stored in Hive `userProfile` box and used in PDF generation header.

**Sign Out** button at bottom → clears GetStorage `isLoggedIn` → navigates to Login.

---

## 🎯 Task 13: Invoice Number Auto-Generation

```dart
String generateInvoiceNumber() {
  final box = Hive.box('appSettings');
  int counter = box.get('invoiceCounter', defaultValue: 0) + 1;
  box.put('invoiceCounter', counter);
  return 'INV-${counter.toString().padLeft(6, '0')}'; // INV-000001
}
```

---

## 🎯 Task 14: Dashboard Tutorial Overlay

**Trigger:** First time user reaches Dashboard (`tutorialShown != true` in GetStorage).

Implementation using `OverlayEntry` + `GlobalKey`:

```dart
class TutorialController extends GetxController {
  final steps = <TutorialStep>[
    TutorialStep(
      title: 'Your Revenue Overview',
      description: 'See your total revenue, clients, and pending payments at a glance.',
      targetKey: DashboardController.statsKey,
    ),
    TutorialStep(
      title: 'Quick Actions',
      description: 'Tap here to quickly create invoices or add new clients.',
      targetKey: DashboardController.quickActionsKey,
    ),
    TutorialStep(
      title: 'Recent Activity',
      description: 'Your latest invoices appear here for quick access.',
      targetKey: DashboardController.recentInvoicesKey,
    ),
    TutorialStep(
      title: 'AI Assistant',
      description: 'Tap the chat button to ask questions about your invoices.',
      targetKey: DashboardController.fabKey,
    ),
  ];
  
  final currentStep = 0.obs;
  
  void nextStep() {
    if (currentStep.value < steps.length - 1) {
      currentStep.value++;
    } else {
      completeTutorial();
    }
  }
  
  void completeTutorial() {
    GetStorage().write('tutorialShown', true);
    // Remove overlay
  }
}
```

Overlay UI: Semi-transparent black overlay (opacity 0.7) with a circular/rectangular cutout revealing the target widget. Show tooltip card below/above target with title, description, step indicator (1/4), and Next/Skip buttons.

---

## 🎯 Task 15: Reports / Analytics (Bonus Screen)

**Reference screenshots:**
- `lib/Screenshots/Screenshot_20260414-003104_Zoho Invoice.jpg`
- `lib/Screenshots/Screenshot_20260414-003137_Zoho Invoice.jpg`
- `lib/Screenshots/Screenshot_20260414-003154_Zoho Invoice.jpg`

Simple analytics screen:
- Monthly revenue bar chart (use `fl_chart` or simple custom painter)
- Invoice status pie chart (Paid / Pending / Draft / Overdue)
- Top clients by revenue list
- Total invoiced vs total collected

---

## 🛠️ Dev Autofill Summary

**IMPORTANT:** Every screen with a form MUST have a `[🔧 Dev Fill]` button visible only in `kDebugMode`. The button should be styled distinctly (orange, elevated, small) and positioned at the top of the form.

| Screen | Dev Fill Data |
|--------|--------------|
| Login | Auto-triggers Google Sign-In mock |
| Add Client | Name, Email, Phone, Address, GSTIN |
| Create Invoice | Client, Date, Items (Printer ₹4000), Notes |
| Profile/Settings | Business: Cabiverse, Haryana, India |

---

## 📋 Screen Inventory (11 Screens)

| # | Screen | Priority | Reference Screenshot |
|---|--------|----------|---------------------|
| 1 | Splash | High | Screenshot_20260413-223434 |
| 2 | Onboarding (3 pages) | Medium | Screenshot_20260413-2317xx |
| 3 | Login (Google) | High | Screenshot_20260413-231810 |
| 4 | Dashboard | ⭐⭐ Highest | Screenshot_20260413-2332xx |
| 5 | Client List | High | Screenshot_20260414-0008xx |
| 6 | Add/Edit Client | High | Screenshot_20260414-0012xx |
| 7 | Client Detail | Medium | — |
| 8 | Invoice List | High | Screenshot_20260414-0022xx |
| 9 | Create Invoice | ⭐⭐ Highest | Screenshot_20260414-002228 |
| 10 | Invoice Preview | ⭐⭐ Highest | Screenshot_20260414-002404 |
| 11 | Profile/Settings | Medium | Screenshot_20260414-003055 |
| 12 | Reports | Low | Screenshot_20260414-003104 |

---

## 📱 UI/UX Standards

### Card Component Standard
```dart
Container(
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0,2))],
  ),
)
```

### Status Chip Standard
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: statusColor.withOpacity(0.12),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
)
```

### Responsive Layout
- Use `MediaQuery` for screen-size-aware padding
- Cards: max width 600 on tablets
- Font scaling: use `textScaleFactor` clamping to prevent overflow
- Bottom nav: `BottomNavigationBar` with 4 tabs (Dashboard, Clients, Invoices, Profile)

---

## 🔧 GetX Controller Patterns

### Always use `Obx` for reactive UI:
```dart
Obx(() => Text('Total: ₹${controller.totalRevenue.value}'))
```

### Reactive invoice items list:
```dart
final items = <InvoiceItemModel>[].obs;
final subTotal = 0.0.obs;

void recalculate() {
  subTotal.value = items.fold(0, (sum, item) => sum + item.amount);
}
```

### Named bindings for lazy loading:
```dart
Get.lazyPut(() => InvoiceController());
Get.lazyPut(() => ClientController());
```

---

## 📸 Screenshot References for Cursor

All screenshots are located at: `lib/Screenshots/`

When building each screen, Cursor should:
1. Open the corresponding screenshot(s) listed in the screen table above
2. Match layout, spacing, colors, typography, and component arrangement pixel-perfectly
3. The app UI should mirror Zoho Invoice's clean, professional aesthetic

**Key design patterns from screenshots:**
- White cards on light grey (#F8F9FA) background
- Blue primary actions (#1A73E8)
- Clean table layout for line items
- Status chips with colored backgrounds
- Bottom navigation bar (4 items)
- Header with greeting + avatar
- Horizontal scrollable stat cards

---

## 📄 PDF Reference

The sample invoice PDF is located at: `lib/INV-000001.pdf` (or attached in project root)

**Key PDF layout elements to replicate exactly:**
- Business name (Cabiverse) top-left, bold
- "TAX INVOICE" header, top-right, large
- Two-column meta section: fields left, values right
- "Bill To" section with client name in bold
- Items table: `#`, `Item & Description`, `Qty`, `Rate`, `Amount` columns
- Subtotal / Total / Payment Made / Balance Due summary, right-aligned
- "Total In Words" in bold italic
- "Authorized Signature" line, bottom-right
- Footer: small grey text

---

## ✅ Build Checklist for Cursor

Execute tasks in this exact order:

- [ ] **T1** — pubspec.yaml, folder structure, Hive models + adapters, `main.dart`
- [ ] **T2** — Routes, Pages, Bindings
- [ ] **T3** — Theme, Colors, Text Styles
- [ ] **T4** — Splash Screen (Lottie animation)
- [ ] **T5** — Onboarding Screen
- [ ] **T6** — Login Screen (Google Sign-In + mock data seed)
- [ ] **T7** — Dashboard Screen (stats, quick actions, recent invoices, tutorial overlay)
- [ ] **T8** — Client List + Add Client + Client Detail
- [ ] **T9** — Invoice List Screen
- [ ] **T10** — Create Invoice Screen (itemized billing + GST)
- [ ] **T11** — Invoice Preview Screen
- [ ] **T12** — PDF Generation (match sample PDF)
- [ ] **T13** — Auto Email (flutter_email_sender)
- [ ] **T14** — Profile/Settings Screen
- [ ] **T15** — Android Manifest permissions
- [ ] **T16** — Gemini AI Chatbot (bottom sheet)
- [ ] **T17** — Reports Screen (optional/bonus)
- [ ] **T18** — Final testing: hot reload, Hive CRUD, PDF generation, email

---

## ⚠️ Critical Notes for Cursor

1. **GetX is mandatory** — Do NOT use Provider, Riverpod, Bloc, or setState anywhere.
2. **Hive is the only database** — No SQLite, SharedPreferences for data (GetStorage only for simple flags).
3. **Dev autofill buttons** must appear on EVERY form screen, wrapped in `if (kDebugMode)`.
4. **Invoice number** must auto-increment and persist across app restarts.
5. **GST/Tax** must show CGST + SGST breakdown for intra-state and IGST for inter-state.
6. **PDF layout** must match the attached sample invoice exactly — pay close attention to formatting.
7. **Tutorial overlay** is mandatory on first dashboard visit — do not skip this.
8. All **currency values** must be formatted in Indian number system (1,00,000.00) using `intl` package.
9. **Bottom navigation** should be persistent across Dashboard, Clients, Invoices, and Profile screens.
10. **Gemini chatbot** is lower priority — implement last, keep UI minimal.
