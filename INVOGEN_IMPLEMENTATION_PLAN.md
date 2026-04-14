# InvoGen -- Production Implementation Plan

## 1. Executive Summary

InvoGen is a production-quality Flutter invoice generator application targeting Indian freelancers, small businesses, and sole proprietors who need to create GST-compliant tax invoices, manage clients, track payment statuses, and send professional invoices via email -- all without cloud dependency.

**What makes it production-quality:**
- Offline-first architecture using Hive for all persistent data -- zero server dependency for core functionality
- GST-compliant invoicing with CGST/SGST (intra-state) and IGST (inter-state) breakdowns at standard Indian tax slabs (0%, 5%, 12%, 18%, 28%)
- Indian number formatting (1,00,000.00) and number-to-words conversion ("Indian Rupee Four Thousand Only")
- Professional PDF generation matching real-world tax invoice standards
- Guided onboarding and tutorial overlay for first-time users
- AI-powered chatbot assistant via Gemini API for invoice/business queries
- Dev-mode autofill on every form for rapid testing

**Target users:** Indian freelancers, consultants, small shop owners, service providers who issue fewer than 500 invoices/month and want a free, offline-capable mobile invoicing tool.

**Platform:** Android-first, Flutter multi-platform. Primary testing on Android physical devices.

---

## 2. Architecture Overview

### 2.1 State Management: GetX (Mandatory)

Every screen uses the GetX pattern exclusively. No `setState`, no Provider, no Riverpod, no BLoC anywhere in the codebase.

**Pattern per module:**
```
module/
  controller.dart    -> extends GetxController, all .obs variables + business logic
  binding.dart       -> extends Bindings, calls Get.lazyPut(() => Controller())
  screen.dart        -> extends GetView<Controller>, uses Obx() for reactive UI
  widgets/           -> stateless widgets receiving data via constructor or Get.find()
```

**Reactive variable conventions:**
- Primitives: `final count = 0.obs;` accessed via `count.value`
- Lists: `final items = <Model>[].obs;` accessed directly (RxList)
- Objects: `final client = Rxn<ClientModel>();` accessed via `client.value`
- All UI rebuilds use `Obx(() => ...)` wrapper -- never `GetBuilder` unless explicitly needed for performance on large lists

**Controller lifecycle:**
- `onInit()` -- load data from Hive, set up reactive listeners (e.g., `ever()`, `debounce()`)
- `onReady()` -- post-frame operations like showing tutorial overlay
- `onClose()` -- dispose TextEditingControllers, close streams

### 2.2 Local Database: Hive

**Box topology (4 boxes):**

| Box Name | Type | Purpose |
|----------|------|---------|
| `clients` | `Box<ClientModel>` | All client records, keyed by UUID |
| `invoices` | `Box<InvoiceModel>` | All invoice records, keyed by UUID |
| `userProfile` | `Box<UserProfileModel>` | Single record (key: `'profile'`) for business info |
| `appSettings` | `Box` | Dynamic key-value: `invoiceCounter` (int), plus any future settings |

**GetStorage (separate, for flags only):**

| Key | Type | Purpose |
|-----|------|---------|
| `isLoggedIn` | bool | Skip login on subsequent launches |
| `isFirstLaunch` | bool | Show onboarding only once |
| `tutorialShown` | bool | Show dashboard tutorial only once |

**Why both Hive and GetStorage:** Hive handles structured data with TypeAdapters and indexed boxes. GetStorage is a thin key-value wrapper for boolean flags that do not need schema -- keeping them separate avoids polluting Hive boxes with untyped data.

### 2.3 Navigation: GetX Named Routes

```
Splash ──> Onboarding ──> Login ──> MainShell (BottomNav)
                                        |
                            +-----------+-----------+-----------+
                            |           |           |           |
                        Dashboard   ClientList  InvoiceList   Profile
                            |           |           |
                         (FAB->      AddClient   CreateInvoice
                          Gemini)    EditClient   InvoicePreview
                                    ClientDetail
                                                  Reports
```

**MainShell pattern:** A single `MainShellScreen` holds a `BottomNavigationBar` with 4 tabs. Each tab shows its respective screen. The shell uses `IndexedStack` (or `Offstage` widgets) to preserve state across tab switches. Navigation to sub-screens (AddClient, CreateInvoice, InvoicePreview, ClientDetail, Reports) uses `Get.toNamed()` which pushes on top of the shell.

**Route guards:** The `SplashController` acts as the only guard -- it checks `isLoggedIn` and `isFirstLaunch` via GetStorage and routes accordingly using `Get.offAllNamed()`.

### 2.4 Dependency Injection: Bindings

```
InitialBinding (app-level, in GetMaterialApp initialBinding):
  - Get.lazyPut(() => HiveService())       // singleton
  - Get.lazyPut(() => AuthController())     // persists across app

Per-route bindings (in app_pages.dart GetPage):
  - SplashBinding      -> SplashController
  - OnboardingBinding  -> OnboardingController
  - AuthBinding        -> AuthController
  - DashboardBinding   -> DashboardController, TutorialController
  - ClientBinding      -> ClientController
  - InvoiceBinding     -> InvoiceController
  - ProfileBinding     -> ProfileController
```

### 2.5 Service Layer

Services are plain Dart classes (not controllers) registered as singletons via `Get.put()` in InitialBinding:

- **HiveService** -- CRUD operations on all boxes, box lifecycle management
- **PdfService** -- PDF document generation, returns `File`
- **EmailService** -- Compose and send email with PDF attachment
- **GeminiService** -- HTTP calls to Gemini API, message history management

---

## 3. Phase 1: Foundation (T1-T3)

### T1: Project Setup, Dependencies, Hive Models, Code Generation

**Step 1: Update `pubspec.yaml`**

Replace the current dependencies block entirely. The final dependencies section must include:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  get: ^4.6.6
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  google_sign_in: ^6.2.1
  pdf: ^3.10.8
  printing: ^5.12.0
  path_provider: ^2.1.2
  flutter_email_sender: ^6.0.3
  lottie: ^3.1.0
  image_picker: ^1.0.7
  permission_handler: ^11.3.0
  intl: ^0.19.0
  uuid: ^4.3.3
  http: ^1.2.1
  share_plus: ^7.2.2
  open_file: ^3.3.2
  get_storage: ^2.1.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
```

Add assets section:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/animations/
    - assets/fonts/
```

**Step 2: Create folder structure**

Create every directory listed below (empty directories need a `.gitkeep`):

```
lib/
  app/
    bindings/
    core/
      constants/
      theme/
      utils/
    data/
      models/
      services/
    modules/
      splash/
      onboarding/
      auth/
      dashboard/
        widgets/
      clients/
      invoices/
      profile/
      reports/
      tutorial/
    routes/
assets/
  animations/
  fonts/
```

**Step 3: Create Hive models**

Each model file must have `@HiveType` and `@HiveField` annotations. The generated adapter files will be created by `build_runner`.

**`lib/app/data/models/client_model.dart`:**

```dart
import 'package:hive/hive.dart';

part 'client_model.g.dart';

@HiveType(typeId: 0)
class ClientModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String address;

  @HiveField(5)
  String? gstin;

  @HiveField(6)
  DateTime createdAt;

  ClientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.gstin,
    required this.createdAt,
  });
}
```

**`lib/app/data/models/invoice_item_model.dart`:**

```dart
import 'package:hive/hive.dart';

part 'invoice_item_model.g.dart';

@HiveType(typeId: 1)
class InvoiceItemModel extends HiveObject {
  @HiveField(0)
  String description;

  @HiveField(1)
  double quantity;

  @HiveField(2)
  double rate;

  InvoiceItemModel({
    required this.description,
    required this.quantity,
    required this.rate,
  });

  double get amount => quantity * rate;
}
```

**`lib/app/data/models/invoice_model.dart`:**

```dart
import 'package:hive/hive.dart';
import 'invoice_item_model.dart';

part 'invoice_model.g.dart';

@HiveType(typeId: 2)
class InvoiceModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String invoiceNumber; // INV-000001

  @HiveField(2)
  String clientId;

  @HiveField(3)
  DateTime invoiceDate;

  @HiveField(4)
  DateTime dueDate;

  @HiveField(5)
  List<InvoiceItemModel> items;

  @HiveField(6)
  bool applyGst;

  @HiveField(7)
  double gstPercent; // default 18.0

  @HiveField(8)
  String status; // 'draft' | 'sent' | 'paid' | 'overdue'

  @HiveField(9)
  String notes;

  @HiveField(10)
  double paymentMade;

  @HiveField(11)
  String terms;

  @HiveField(12)
  DateTime createdAt;

  @HiveField(13)
  bool isInterState; // true = IGST, false = CGST+SGST

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.invoiceDate,
    required this.dueDate,
    required this.items,
    this.applyGst = false,
    this.gstPercent = 18.0,
    this.status = 'draft',
    this.notes = '',
    this.paymentMade = 0.0,
    this.terms = 'Due on Receipt',
    required this.createdAt,
    this.isInterState = false,
  });

  double get subTotal => items.fold(0.0, (sum, item) => sum + item.amount);
  double get gstAmount => applyGst ? subTotal * gstPercent / 100 : 0.0;
  double get total => subTotal + gstAmount;
  double get balanceDue => total - paymentMade;

  // For CGST+SGST split (intra-state): each is half of gstAmount
  double get cgstAmount => applyGst && !isInterState ? gstAmount / 2 : 0.0;
  double get sgstAmount => applyGst && !isInterState ? gstAmount / 2 : 0.0;
  // For IGST (inter-state): full gstAmount
  double get igstAmount => applyGst && isInterState ? gstAmount : 0.0;
}
```

**`lib/app/data/models/user_profile_model.dart`:**

```dart
import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 3)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  String businessName;

  @HiveField(1)
  String address;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String? gstin;

  @HiveField(5)
  String? logoPath;

  @HiveField(6)
  double defaultGstRate;

  @HiveField(7)
  String defaultTerms;

  @HiveField(8)
  String defaultNotes;

  @HiveField(9)
  String? displayName; // from Google Sign-In

  @HiveField(10)
  String? photoUrl; // from Google Sign-In

  UserProfileModel({
    this.businessName = '',
    this.address = '',
    this.email = '',
    this.phone = '',
    this.gstin,
    this.logoPath,
    this.defaultGstRate = 18.0,
    this.defaultTerms = 'Due on Receipt',
    this.defaultNotes = 'Thanks for your business.',
    this.displayName,
    this.photoUrl,
  });
}
```

**Step 4: Run code generation**

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

This generates `client_model.g.dart`, `invoice_item_model.g.dart`, `invoice_model.g.dart`, `user_profile_model.g.dart` with TypeAdapter classes.

**Step 5: Create HiveService**

`lib/app/data/services/hive_service.dart` -- a singleton service class:

```
class HiveService {
  static late Box<ClientModel> clientsBox;
  static late Box<InvoiceModel> invoicesBox;
  static late Box<UserProfileModel> userProfileBox;
  static late Box appSettingsBox;

  static Future<void> init() async {
    // Register all adapters
    Hive.registerAdapter(ClientModelAdapter());
    Hive.registerAdapter(InvoiceItemModelAdapter());
    Hive.registerAdapter(InvoiceModelAdapter());
    Hive.registerAdapter(UserProfileModelAdapter());

    // Open all boxes
    clientsBox = await Hive.openBox<ClientModel>('clients');
    invoicesBox = await Hive.openBox<InvoiceModel>('invoices');
    userProfileBox = await Hive.openBox<UserProfileModel>('userProfile');
    appSettingsBox = await Hive.openBox('appSettings');
  }

  // --- Client CRUD ---
  static Future<void> addClient(ClientModel client) async =>
      await clientsBox.put(client.id, client);
  static Future<void> updateClient(ClientModel client) async =>
      await client.save();
  static Future<void> deleteClient(String id) async =>
      await clientsBox.delete(id);
  static List<ClientModel> getAllClients() => clientsBox.values.toList();
  static ClientModel? getClient(String id) => clientsBox.get(id);

  // --- Invoice CRUD ---
  static Future<void> addInvoice(InvoiceModel invoice) async =>
      await invoicesBox.put(invoice.id, invoice);
  static Future<void> updateInvoice(InvoiceModel invoice) async =>
      await invoice.save();
  static Future<void> deleteInvoice(String id) async =>
      await invoicesBox.delete(id);
  static List<InvoiceModel> getAllInvoices() => invoicesBox.values.toList();
  static InvoiceModel? getInvoice(String id) => invoicesBox.get(id);
  static List<InvoiceModel> getInvoicesByClient(String clientId) =>
      invoicesBox.values.where((inv) => inv.clientId == clientId).toList();

  // --- User Profile ---
  static Future<void> saveUserProfile(UserProfileModel profile) async =>
      await userProfileBox.put('profile', profile);
  static UserProfileModel? getUserProfile() => userProfileBox.get('profile');

  // --- Invoice Counter ---
  static String generateInvoiceNumber() {
    int counter = appSettingsBox.get('invoiceCounter', defaultValue: 0) as int;
    counter++;
    appSettingsBox.put('invoiceCounter', counter);
    return 'INV-${counter.toString().padLeft(6, '0')}';
  }
}
```

**Step 6: Create `main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await HiveService.init();
  await GetStorage.init();
  runApp(const InvoGenApp());
}

class InvoGenApp extends StatelessWidget {
  const InvoGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'InvoGen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),
    );
  }
}
```

### T2: Routes and Bindings

**`lib/app/routes/app_routes.dart`:**

```dart
abstract class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const main = '/main';           // MainShell with BottomNav
  static const addClient = '/clients/add';
  static const editClient = '/clients/edit';
  static const clientDetail = '/clients/detail';
  static const createInvoice = '/invoices/create';
  static const editInvoice = '/invoices/edit';
  static const invoicePreview = '/invoices/preview';
  static const reports = '/reports';
}
```

**`lib/app/routes/app_pages.dart`:**

Each `GetPage` wires route string to screen widget and binding. The `main` route uses `MainShellScreen` and `MainShellBinding` which lazy-puts DashboardController, ClientController, InvoiceController, and ProfileController.

**`lib/app/bindings/app_bindings.dart`:**

`InitialBinding` registers HiveService. Per-module bindings are separate files inside each module folder or can be defined inline in `app_pages.dart`.

**Important navigation decisions:**
- `Get.offAllNamed(AppRoutes.main)` from login -- clears the back stack so users cannot go back to login
- `Get.toNamed(AppRoutes.createInvoice)` from dashboard/invoice list -- pushes on top, back button returns
- `Get.back(result: true)` from add/edit screens -- returns result to trigger list refresh
- `Get.toNamed(AppRoutes.invoicePreview, arguments: invoiceId)` -- pass invoice ID via arguments

### T3: Theme and Design System

**`lib/app/core/constants/app_colors.dart`:**

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#1A73E8` | Buttons, AppBar, links, active tab |
| `primaryDark` | `#1557B0` | Pressed button state, AppBar on status bar |
| `primaryLight` | `#E8F0FE` | Selected tab background, light highlights |
| `accent` | `#00BFA5` | Secondary actions, teal highlights |
| `success` / `statusPaid` | `#34A853` | Paid status chip, success snackbars |
| `warning` / `statusPending` | `#FBBC04` | Warning status, pending chips |
| `danger` / `statusOverdue` | `#EA4335` | Overdue status, error states, delete actions |
| `statusDraft` | `#9AA0A6` | Draft status chip |
| `statusSent` | `#1A73E8` | Sent status chip (same as primary) |
| `background` | `#F8F9FA` | Scaffold background, light grey |
| `surface` | `#FFFFFF` | Card background, white |
| `textPrimary` | `#202124` | Headings, primary text |
| `textSecondary` | `#5F6368` | Subtitles, secondary text |
| `textHint` | `#9AA0A6` | Placeholder text |
| `divider` | `#E0E0E0` | Horizontal dividers, borders |
| `cardShadow` | `#14000000` | Box shadow color (8% opacity black) |
| `devFill` | `#FF9800` | Dev autofill button (orange) |

**`lib/app/core/constants/app_text_styles.dart`:**

| Style Name | Size | Weight | Color | Usage |
|------------|------|--------|-------|-------|
| `heading1` | 24sp | w700 (Bold) | textPrimary | Screen titles |
| `heading2` | 20sp | w600 (SemiBold) | textPrimary | Section headers |
| `heading3` | 16sp | w600 | textPrimary | Card titles |
| `bodyLarge` | 16sp | w400 (Regular) | textPrimary | Primary body text |
| `bodyMedium` | 14sp | w400 | textPrimary | Default body text |
| `bodySmall` | 12sp | w400 | textSecondary | Captions, timestamps |
| `labelLarge` | 14sp | w600 | primary | Form labels (blue) |
| `labelSmall` | 10sp | w500 | textSecondary | Chip text, badges |
| `amountLarge` | 28sp | w700 | textPrimary | Large currency displays |
| `amountMedium` | 18sp | w600 | textPrimary | Invoice totals |

Font family: System default (Roboto on Android). No custom fonts needed unless the user explicitly requests them later.

**`lib/app/core/theme/app_theme.dart`:**

Build a `ThemeData` with:
- `colorScheme` seeded from `#1A73E8`
- `scaffoldBackgroundColor`: `#F8F9FA`
- `cardTheme`: elevation 0, shape with borderRadius 12, color white, with outer `BoxDecoration` for subtle shadow
- `appBarTheme`: backgroundColor white, foregroundColor textPrimary, elevation 0, centerTitle false
- `elevatedButtonTheme`: borderRadius 8, primary background, white text, height 48
- `outlinedButtonTheme`: borderRadius 8, primary border, primary text, height 48
- `inputDecorationTheme`: underline border style (matching Zoho screenshots), label style in primary blue, hint style in textHint, focused border in primary
- `bottomNavigationBarTheme`: selectedItemColor primary, unselectedItemColor textSecondary, backgroundColor white, type fixed
- `chipTheme`: borderRadius 20, label style 12sp w600
- `dividerTheme`: color divider, thickness 1, space 0
- `snackBarTheme`: behavior floating, shape roundedRectangle 8

**`lib/app/core/utils/currency_formatter.dart`:**

Indian number formatting function:
- Input: `double` value
- Output: String like `"4,000.00"` or `"1,00,000.00"`
- Algorithm: Split at decimal, format the integer part with Indian grouping (last 3 digits, then groups of 2), append decimal part with 2 decimal places
- Provide both `formatIndianCurrency(double)` returning `"1,00,000.00"` and `formatIndianCurrencyWithSymbol(double)` returning `"Rs. 1,00,000.00"`
- Use `NumberFormat` from `intl` package with locale `'en_IN'` pattern: `#,##,##0.00`

**`lib/app/core/utils/date_formatter.dart`:**

- `formatDate(DateTime)` -> `"14/04/2026"` using `DateFormat('dd/MM/yyyy')`
- `formatDateLong(DateTime)` -> `"Tue, Apr 14 2026"` using `DateFormat('EEE, MMM d yyyy')`
- `getGreeting()` -> `"Good Morning"` / `"Good Afternoon"` / `"Good Evening"` based on `DateTime.now().hour`

**`lib/app/core/utils/number_to_words.dart`:**

Converts a double amount to Indian English words for PDF:
- Input: `4000.0`
- Output: `"Indian Rupee Four Thousand Only"`
- Input: `1,23,456.78`
- Output: `"Indian Rupee One Lakh Twenty Three Thousand Four Hundred Fifty Six and Paise Seventy Eight Only"`

Algorithm:
1. Split into rupees (integer) and paise (decimal * 100, rounded)
2. Convert rupees integer to words using Indian place values (Crore, Lakh, Thousand, Hundred)
3. If paise > 0, append "and Paise [words] Only", else just "Only"
4. Capitalize first letter of each word

**`lib/app/core/constants/app_strings.dart`:**

All user-facing strings centralized here:
- App name: `"InvoGen"`
- Onboarding titles/descriptions
- Form labels and validation messages
- Greeting templates
- Email template strings
- Gemini API key placeholder: `const geminiApiKey = 'YOUR_API_KEY_HERE';`
- Default terms: `"Due on Receipt"`
- Default notes: `"Thanks for your business."`

---

## 4. Phase 2: Authentication Flow (T4-T6)

### T4: Splash Screen

**File: `lib/app/modules/splash/splash_screen.dart`**

**Visual layout:**
- Full-screen container with gradient background: linear gradient from `primary` (#1A73E8) at top to `primaryDark` (#1557B0) at bottom
- Center column:
  1. Lottie animation (invoice/document icon animation) -- 200x200 size. Use a free Lottie file from LottieFiles (e.g., a document/invoice writing animation). Place the JSON file at `assets/animations/splash_animation.json`
  2. SizedBox(height: 24)
  3. Text "InvoGen" in white, 32sp, bold
  4. SizedBox(height: 8)
  5. Text "Professional Invoice Generator" in white70, 14sp, regular

**Controller: `splash_controller.dart`**

```
onInit():
  Future.delayed(Duration(milliseconds: 2500), _navigate);

_navigate():
  final storage = GetStorage();
  if (storage.read('isLoggedIn') == true) {
    Get.offAllNamed(AppRoutes.main);
  } else if (storage.read('isFirstLaunch') != false) {
    Get.offAllNamed(AppRoutes.onboarding);
  } else {
    Get.offAllNamed(AppRoutes.login);
  }
```

**Key detail:** `isFirstLaunch` defaults to `null` on first install, so `!= false` covers both `null` and `true` cases. After onboarding completes, it is set to `false`.

### T5: Onboarding Screen

**File: `lib/app/modules/onboarding/onboarding_screen.dart`**

**Visual layout:**
- White background
- `PageView` with 3 pages, controlled by `PageController`
- Each page layout (centered column):
  1. Lottie animation (280x280) -- different animation per page
  2. SizedBox(height: 40)
  3. Title text: 22sp, bold, textPrimary, center-aligned
  4. SizedBox(height: 16)
  5. Subtitle text: 14sp, regular, textSecondary, center-aligned, horizontal padding 40

**Page content:**

| Page | Animation File | Title | Subtitle |
|------|---------------|-------|----------|
| 1 | `onboarding_invoice.json` | "Create Professional Invoices" | "Generate GST-compliant tax invoices with your business branding in seconds" |
| 2 | `onboarding_clients.json` | "Manage Your Clients" | "Keep all your client details organized and create invoices for them instantly" |
| 3 | `onboarding_analytics.json` | "Track Payments & Revenue" | "Monitor your business performance with real-time payment tracking and analytics" |

**Bottom section (fixed, not in PageView):**
- Row of 3 dot indicators: active dot = primary blue 10x10 rounded, inactive = grey 8x8 rounded
- SizedBox(height: 24)
- Row:
  - Pages 0-1: TextButton "Skip" (textSecondary) on left, ElevatedButton "Next" (primary) on right
  - Page 2: Full-width ElevatedButton "Get Started" (primary)

**Controller: `onboarding_controller.dart`**

```
final pageController = PageController();
final currentPage = 0.obs;

void nextPage() {
  if (currentPage.value < 2) {
    pageController.nextPage(duration: 300ms, curve: Curves.easeInOut);
  } else {
    completeOnboarding();
  }
}

void skip() => completeOnboarding();

void completeOnboarding() {
  GetStorage().write('isFirstLaunch', false);
  Get.offAllNamed(AppRoutes.login);
}

@override
void onClose() {
  pageController.dispose();
  super.onClose();
}
```

**Lottie animation files:** Download 3 free Lottie JSON files from lottiefiles.com. If download is not possible at build time, create placeholder `Container` widgets with `Icon` + colored background as fallback. The animations can be added later. Use `Lottie.asset()` with `errorBuilder` fallback.

### T6: Login Screen

**File: `lib/app/modules/auth/login_screen.dart`**

**Visual layout:**
- Scaffold with background color `#F8F9FA`
- Center column:
  1. SizedBox(height: 80) -- top spacing
  2. Icon: `Icons.receipt_long`, size 80, color primary -- app logo placeholder
  3. SizedBox(height: 24)
  4. Text "Welcome to InvoGen" in 24sp bold textPrimary
  5. SizedBox(height: 8)
  6. Text "Create professional invoices in minutes" in 14sp textSecondary
  7. SizedBox(height: 48)
  8. White card (borderRadius 12, padding 32, shadow) containing:
     - Google Sign-In button: outlined button with Google "G" logo icon + "Sign in with Google" text
     - Height 52, full width, borderRadius 8
     - Border: 1px `#E0E0E0`, text color `#202124`
  9. SizedBox(height: 16)
  10. Text "By signing in, you agree to our Terms of Service" in 12sp textSecondary center

**Controller: `auth_controller.dart`**

```
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
final isLoading = false.obs;

Future<void> signInWithGoogle() async {
  try {
    isLoading.value = true;
    final account = await _googleSignIn.signIn();
    if (account != null) {
      // Save user profile to Hive
      final profile = UserProfileModel(
        displayName: account.displayName ?? 'User',
        email: account.email,
        photoUrl: account.photoUrl,
        businessName: '',  // will be filled in Profile screen
      );
      await HiveService.saveUserProfile(profile);

      // Seed mock data
      await _seedMockData(account.displayName ?? 'User');

      // Mark as logged in
      GetStorage().write('isLoggedIn', true);

      // Navigate to main
      Get.offAllNamed(AppRoutes.main);
    }
  } catch (e) {
    Get.snackbar(
      'Sign-In Failed',
      'Could not sign in with Google. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.danger,
      colorText: Colors.white,
    );
  } finally {
    isLoading.value = false;
  }
}
```

**Mock data seeding strategy (`_seedMockData`):**

This method is called exactly once on first Google Sign-In. It creates:

**2 mock clients:**
1. Sanjay Hooda -- sanjay.hooda@example.com, +91 98765 43210, B-42 Sector 18 Gurugram Haryana 122001, GSTIN: 06AABCU9603R1ZX
2. Priya Sharma -- priya.sharma@example.com, +91 87654 32109, A-12 Connaught Place New Delhi 110001, GSTIN: 07AADCS0472N1ZK

**3 mock invoices:**
1. INV-000001 -- client: Sanjay Hooda, items: [Printer x1 @ 4000], status: 'paid', paymentMade: 4000, invoiceDate: 7 days ago, dueDate: 7 days ago, notes: "Thanks for your business."
2. INV-000002 -- client: Priya Sharma, items: [Web Development x1 @ 25000, Hosting Setup x1 @ 5000], status: 'sent', paymentMade: 0, invoiceDate: 3 days ago, dueDate: 12 days from now, notes: "Payment due within 15 days."
3. INV-000003 -- client: Sanjay Hooda, items: [Logo Design x1 @ 8000], status: 'draft', paymentMade: 0, invoiceDate: today, dueDate: 30 days from now, notes: "Draft -- pending client approval."

The invoice counter in appSettings must be set to 3 after seeding so the next auto-generated number is INV-000004.

**Google Sign-In mock handling:** On emulators or devices without Google Play Services, the `signIn()` call will throw. The catch block shows a snackbar. For development, add a "Dev Login" button (visible only in `kDebugMode`) that bypasses Google Sign-In entirely, creating a mock profile with name "Manan Rohilla", email "manan@test.com", and proceeding to seed data and navigate.

---

## 5. Phase 3: Core Dashboard (T7)

### T7: Dashboard Screen -- The Central Hub

**File: `lib/app/modules/dashboard/dashboard_screen.dart`**

This screen lives inside the `MainShellScreen` as tab index 0.

**MainShellScreen architecture:**

```dart
class MainShellScreen extends GetView<MainShellController> {
  // BottomNavigationBar with 4 tabs
  // Body: IndexedStack with 4 children:
  //   0: DashboardScreen
  //   1: ClientListScreen
  //   2: InvoiceListScreen
  //   3: ProfileScreen

  // BottomNav items:
  //   Dashboard (Icons.dashboard_outlined / Icons.dashboard)
  //   Clients (Icons.people_outline / Icons.people)
  //   Invoices (Icons.receipt_long_outlined / Icons.receipt_long)
  //   Profile (Icons.person_outline / Icons.person)
}
```

**MainShellController:**
```
final currentIndex = 0.obs;
void changeTab(int index) => currentIndex.value = index;
```

**Dashboard layout (top to bottom, scrollable via SingleChildScrollView):**

**Section 1: AppBar**
- Not a standard AppBar -- use a custom header inside the body
- Left side: Column with greeting text
  - "Good Morning, Manan" (or Afternoon/Evening based on hour) in 20sp w600 textPrimary. The name comes from `UserProfileModel.displayName`
- Right side: Row of
  - CircleAvatar (40x40) showing user photo from `photoUrl` or initials fallback
  - (No notification icon needed -- keep it clean)
- Background: white, bottom border 1px divider color
- Padding: horizontal 16, vertical 12

**Section 2: Stat Cards (horizontal scroll)**
- Container with height 120
- `ListView.builder` with `scrollDirection: Axis.horizontal`, padding horizontal 16
- 4 cards, each:
  - Width: 160
  - Margin: right 12
  - Padding: 16
  - White card, borderRadius 12, subtle shadow
  - Column(crossAxisAlignment: start):
    - Row: colored icon (40x40 circle with icon) + Spacer
    - SizedBox(height: 12)
    - Value text: 20sp bold (e.g., "Rs. 4,000" or "2" or "Rs. 25,000")
    - Label text: 12sp textSecondary (e.g., "Total Revenue")

| Card | Icon | Icon BG Color | Label | Value Source |
|------|------|---------------|-------|-------------|
| 1 | Icons.account_balance_wallet | success (green) light | "Total Revenue" | Sum of `total` for all invoices where status == 'paid' |
| 2 | Icons.people | primary (blue) light | "Total Clients" | `clientsBox.length` |
| 3 | Icons.pending_actions | warning (yellow) light | "Pending" | Sum of `balanceDue` for all invoices where status == 'sent' |
| 4 | Icons.warning_amber | danger (red) light | "Overdue" | Count of invoices where status == 'overdue' |

All values are reactive via `Obx()`. The controller computes them from Hive data in `onInit()` and whenever data changes (using `ever()` on the reactive lists or by calling `refreshStats()` in `onReady()` and after returning from create/edit screens).

**Section 3: Quick Actions (2x2 grid)**
- Section header: "Quick Actions" in 18sp w600, padding horizontal 16, top 24
- Padding: horizontal 16, top 12
- `GridView.count(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.5)`
- 4 action cards, each:
  - White card, borderRadius 12, subtle shadow
  - `InkWell` with splash
  - Row: colored icon (in circle) + SizedBox(8) + Column(title text 14sp w500)

| Action | Icon | Color | Route |
|--------|------|-------|-------|
| "New Invoice" | Icons.add_circle_outline | primary | AppRoutes.createInvoice |
| "Add Client" | Icons.person_add_outlined | accent | AppRoutes.addClient |
| "All Invoices" | Icons.receipt_long_outlined | warning | Switch to Invoices tab (index 2) |
| "Reports" | Icons.bar_chart_outlined | success | AppRoutes.reports |

**Section 4: Recent Invoices**
- Section header: Row("Recent Invoices" 18sp w600 + Spacer + TextButton "View All" primary) padding horizontal 16, top 24
- "View All" taps -> switch to Invoices tab
- `ListView.builder` with `shrinkWrap: true, physics: NeverScrollableScrollPhysics()`
- Shows last 5 invoices sorted by createdAt descending
- Each tile is a white card (margin horizontal 16 vertical 4, borderRadius 12, padding 16):
  - Row:
    - Column(crossAxisAlignment: start):
      - Text invoiceNumber 14sp w600 textPrimary
      - SizedBox(4)
      - Text clientName 12sp textSecondary (look up client by clientId)
      - SizedBox(4)
      - Text formatted date 12sp textSecondary
    - Spacer
    - Column(crossAxisAlignment: end):
      - Text formatted total amount 16sp w600 textPrimary
      - SizedBox(8)
      - Status chip (see chip design in Section 12)
  - `InkWell` onTap -> `Get.toNamed(AppRoutes.invoicePreview, arguments: invoice.id)`
- Empty state (if no invoices): centered illustration/icon + "No invoices yet" + "Create your first invoice" button

**Section 5: Gemini AI FAB**
- `FloatingActionButton` at `bottomRight` (standard FAB position)
- Icon: `Icons.smart_toy` or `Icons.chat`
- Color: accent teal (`#00BFA5`)
- OnTap: opens Gemini chatbot bottom sheet (see Phase 8)
- This FAB must have a `GlobalKey` assigned for the tutorial overlay

**DashboardController reactive variables:**

```
final totalRevenue = 0.0.obs;
final totalClients = 0.obs;
final pendingAmount = 0.0.obs;
final overdueCount = 0.obs;
final recentInvoices = <InvoiceModel>[].obs;

// GlobalKeys for tutorial spotlight
static final statsKey = GlobalKey();
static final quickActionsKey = GlobalKey();
static final recentInvoicesKey = GlobalKey();
static final fabKey = GlobalKey();

void refreshStats() {
  final invoices = HiveService.getAllInvoices();
  final clients = HiveService.getAllClients();

  totalRevenue.value = invoices
      .where((i) => i.status == 'paid')
      .fold(0.0, (sum, i) => sum + i.total);

  totalClients.value = clients.length;

  pendingAmount.value = invoices
      .where((i) => i.status == 'sent')
      .fold(0.0, (sum, i) => sum + i.balanceDue);

  overdueCount.value = invoices
      .where((i) => i.status == 'overdue')
      .length;

  recentInvoices.assignAll(
    (invoices..sort((a, b) => b.createdAt.compareTo(a.createdAt))).take(5),
  );
}
```

Call `refreshStats()` in `onInit()` and again whenever returning from sub-screens (use `Get.toNamed(...).then((_) => refreshStats())` pattern or call it in `onReady()` of screens that modify data).

### Tutorial Overlay Implementation

**Trigger:** In `DashboardController.onReady()`, check `GetStorage().read('tutorialShown') != true`. If not shown, call `TutorialController.startTutorial()` after a 500ms delay (to let the dashboard render first).

**Implementation approach: Custom Overlay with ClipPath**

The tutorial uses Flutter's `Overlay` system, not a separate screen. It consists of:

1. A full-screen `OverlayEntry` that paints a semi-transparent black layer (`Colors.black.withOpacity(0.7)`)
2. A "cutout" region around the target widget, achieved using `CustomClipper<Path>` with `Path.combine(PathOperation.difference, ...)` -- the full-screen rect minus the target widget's rect (obtained via `GlobalKey.currentContext.findRenderObject().localToGlobal()`)
3. A tooltip card positioned relative to the cutout (above or below, depending on available space)

**TutorialController:**

```
final currentStep = 0.obs;
OverlayEntry? _overlayEntry;

final steps = [
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
```

**Tooltip card design:**
- White card, borderRadius 12, padding 16, shadow
- Small arrow/triangle pointing to the highlighted widget (optional -- can omit for simplicity)
- Title: 16sp w600 textPrimary
- Description: 14sp regular textSecondary
- SizedBox(12)
- Row: step indicator "1/4" in 12sp textSecondary + Spacer + TextButton "Skip" + SizedBox(8) + ElevatedButton "Next" (or "Done" on last step)

**Spotlight cutout calculation:**

```dart
Rect _getTargetRect(GlobalKey key) {
  final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
  final position = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;
  // Add 8px padding around the target
  return Rect.fromLTWH(
    position.dx - 8,
    position.dy - 8,
    size.width + 16,
    size.height + 16,
  );
}
```

The custom painter draws the full-screen dark overlay and uses `canvas.clipPath` with a `Path` that has the target rect subtracted (using `Path.combine(PathOperation.difference, fullScreenPath, targetRectPath)`), then fills with the semi-transparent color. The cutout area has rounded corners (RRect).

---

## 6. Phase 4: Client Management (T8)

### Client List Screen

**File: `lib/app/modules/clients/client_list_screen.dart`**

Lives inside MainShellScreen as tab index 1.

**Layout:**
- AppBar: Title "Clients", trailing IconButton search icon
- When search tapped: AppBar transforms to show a TextField with autofocus and clear button. The search query filters the displayed list in real-time via `Obx`. Filter matches on name, email, or phone (case-insensitive contains).
- Body: `Obx(() => ListView.builder(...))`
- Each client tile: white card, margin horizontal 16 vertical 4, borderRadius 12, padding 16
  - Row:
    - CircleAvatar (48x48) with initials of client name, background color derived from name hash (pick from a preset palette of 6 colors)
    - SizedBox(12)
    - Expanded Column(crossAxisAlignment: start):
      - Text name 16sp w600 textPrimary
      - SizedBox(4)
      - Text email 13sp textSecondary
      - SizedBox(2)
      - Text phone 13sp textSecondary
    - Column(crossAxisAlignment: end):
      - Badge showing invoice count for this client (small pill: "3 invoices" in 11sp)
      - Icon chevron_right textSecondary
  - `InkWell` onTap -> `Get.toNamed(AppRoutes.clientDetail, arguments: client.id)`
  - Swipe-to-delete using `Dismissible`:
    - Background: red with trash icon
    - `confirmDismiss`: show `Get.defaultDialog` with "Delete Client?" confirmation
    - On confirm: delete client from Hive, remove from list, show undo snackbar

- FAB: CircularFAB with `+` icon, primary color, onTap -> `Get.toNamed(AppRoutes.addClient)`
- Empty state: Column centered with `Icons.people_outline` size 80 grey, "No clients yet" 18sp, "Add your first client to get started" 14sp, ElevatedButton "Add Client"

**ClientController:**

```
final clients = <ClientModel>[].obs;
final searchQuery = ''.obs;
final isSearching = false.obs;

List<ClientModel> get filteredClients {
  if (searchQuery.value.isEmpty) return clients;
  final q = searchQuery.value.toLowerCase();
  return clients.where((c) =>
    c.name.toLowerCase().contains(q) ||
    c.email.toLowerCase().contains(q) ||
    c.phone.contains(q)
  ).toList();
}

void loadClients() {
  clients.assignAll(HiveService.getAllClients()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
}

Future<void> deleteClient(String id) async {
  // Check if client has invoices
  final clientInvoices = HiveService.getInvoicesByClient(id);
  if (clientInvoices.isNotEmpty) {
    Get.snackbar('Cannot Delete',
      'This client has ${clientInvoices.length} invoice(s). Delete them first.');
    return;
  }
  await HiveService.deleteClient(id);
  loadClients();
}
```

### Add/Edit Client Screen

**File: `lib/app/modules/clients/add_client_screen.dart`**

**Layout:**
- AppBar: "Add Client" or "Edit Client" (determined by argument), trailing SAVE text button
- Body: SingleChildScrollView, padding 16
- White card, borderRadius 12, padding 20

**Dev Autofill Button (conditional):**
- Positioned at the very top of the body, ABOVE the card
- Visible only when `kDebugMode == true`
- Styled: orange (#FF9800) ElevatedButton.icon with wrench icon and "Dev Fill" text, compact size
- OnTap: fills all controllers with mock data

**Form fields (inside card, each with blue label text above the underline input):**

| Field | Label | Keyboard Type | Validation | Required |
|-------|-------|--------------|------------|----------|
| `nameController` | "Client Name" | text | Non-empty, min 2 chars | Yes |
| `emailController` | "Email Address" | emailAddress | Valid email regex | Yes |
| `phoneController` | "Phone Number" | phone | Non-empty, 10+ digits | Yes |
| `addressController` | "Billing Address" | multiline | Non-empty | No (but recommended) |
| `gstinController` | "GSTIN / Tax Number" | text | 15-char alphanumeric if provided | No |

**Form styling (matching Zoho screenshots):**
- Each field: Column with blue label text (14sp w500 primary color) at top, SizedBox(4), TextFormField with underline border, hint text in grey
- Vertical spacing between fields: SizedBox(20)
- GSTIN field has a helper text: "15-digit GST Identification Number" in 11sp textHint

**Dev autofill data:**
```
nameController.text = 'Sanjay Hooda';
emailController.text = 'sanjay.hooda@example.com';
phoneController.text = '+91 98765 43210';
addressController.text = 'B-42, Sector 18\nGurugram, Haryana 122001';
gstinController.text = '06AABCU9603R1ZX';
```

**Save logic:**
1. Validate form with `_formKey.currentState!.validate()`
2. If editing: update existing ClientModel fields, call `HiveService.updateClient()`
3. If adding: create new ClientModel with `Uuid().v4()` as id, `DateTime.now()` as createdAt, call `HiveService.addClient()`
4. Show success snackbar: "Client saved successfully"
5. `Get.back(result: true)` -- the result triggers list refresh on the previous screen

### Client Detail Screen

**File: `lib/app/modules/clients/client_detail_screen.dart`**

**Layout:**
- AppBar: client name as title, trailing PopupMenuButton with "Edit" and "Delete" options
- Body: SingleChildScrollView

**Section 1: Client Info Header**
- White card, full width, padding 20, borderRadius 12
- Row:
  - Large CircleAvatar (64x64) with initials
  - SizedBox(16)
  - Column:
    - Name 20sp w600
    - Email 14sp textSecondary (with mail icon)
    - Phone 14sp textSecondary (with phone icon)
- Below row: full address text, 14sp, padding top 12
- If GSTIN present: "GSTIN: 06AABCU9603R1ZX" in 13sp textSecondary

**Section 2: Financial Summary**
- Row of 3 mini stat cards (equal width):
  - "Total Billed": sum of all invoice totals for this client
  - "Received": sum of paymentMade for this client's invoices
  - "Outstanding": total billed minus received
- Each card: colored top border (2px), value in 18sp w600, label in 12sp textSecondary

**Section 3: Invoice History**
- Section header: "Invoices" + count badge
- ListView of invoice tiles for this client (same tile design as dashboard recent invoices)
- Sorted by createdAt descending
- Empty state if no invoices: "No invoices for this client" + "Create Invoice" button

**Section 4: Action Buttons (bottom)**
- Row of 2 buttons, padding 16:
  - OutlinedButton "Edit Client" -> `Get.toNamed(AppRoutes.editClient, arguments: client)`
  - ElevatedButton "Create Invoice" -> `Get.toNamed(AppRoutes.createInvoice, arguments: {'clientId': client.id})`

---

## 7. Phase 5: Invoice Engine (T9-T11)

### T9: Invoice List Screen

**File: `lib/app/modules/invoices/invoice_list_screen.dart`**

Lives inside MainShellScreen as tab index 2.

**Layout:**
- AppBar: "Invoices", trailing search icon (same expanding search pattern as Client List)
- Below AppBar: horizontal tab bar with 5 filter tabs

**Filter tabs:**
- Implemented as a `SingleChildScrollView` with `Row` of `ChoiceChip` or custom tab buttons
- Tabs: "All", "Draft", "Sent", "Paid", "Overdue"
- Active tab: primary color background with white text
- Inactive tab: white background with textSecondary, border 1px divider
- Tab state is reactive: `final selectedTab = 'All'.obs;`

**Filtered list logic:**
```
List<InvoiceModel> get filteredInvoices {
  var list = allInvoices.toList();

  // Apply status filter
  if (selectedTab.value != 'All') {
    list = list.where((i) => i.status == selectedTab.value.toLowerCase()).toList();
  }

  // Apply search filter
  if (searchQuery.value.isNotEmpty) {
    final q = searchQuery.value.toLowerCase();
    list = list.where((i) =>
      i.invoiceNumber.toLowerCase().contains(q) ||
      _getClientName(i.clientId).toLowerCase().contains(q)
    ).toList();
  }

  return list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
```

**Invoice tile design:**
- White card, margin horizontal 16 vertical 4, borderRadius 12, padding 16
- Row:
  - Expanded Column(crossAxisAlignment: start):
    - Row: Text invoiceNumber 15sp w600 + SizedBox(8) + StatusChip
    - SizedBox(6)
    - Text clientName 13sp textSecondary
    - SizedBox(4)
    - Text "Due: dd/MM/yyyy" 12sp textSecondary
  - Column(crossAxisAlignment: end):
    - Text formatted total 16sp w700 textPrimary (Indian format with Rs.)
    - SizedBox(4)
    - If balanceDue > 0 and status != 'draft': Text "Due: Rs. X" 12sp danger
- `InkWell` onTap -> `Get.toNamed(AppRoutes.invoicePreview, arguments: invoice.id)`
- `Dismissible` for swipe-to-delete with confirmation

**FAB:** Primary color, `+` icon, onTap -> `Get.toNamed(AppRoutes.createInvoice)`

**Empty state per tab:**
- All: "No invoices yet. Create your first invoice!"
- Draft: "No draft invoices"
- Sent: "No sent invoices"
- Paid: "No paid invoices"
- Overdue: "No overdue invoices"

**Tab counts:** Each tab shows a count badge: "All (5)", "Draft (1)", "Sent (1)", etc. These counts are computed reactively.

### T10: Create Invoice Screen (Most Complex Screen)

**File: `lib/app/modules/invoices/create_invoice_screen.dart`**

This is a full-screen pushed route, NOT inside the bottom nav shell.

**AppBar:**
- Title: "New Invoice" (or "Edit Invoice" if editing)
- Trailing: TextButton "SAVE AS DRAFT" + PopupMenuButton with "..." for more options
- Leading: back arrow

**Dev Autofill Button:**
- Same pattern as client form: orange button at top, `kDebugMode` only
- Fills: first client selected, today's date, "Due on Receipt" terms, 1 line item (Printer x1 @ 4000), GST off, notes "Thanks for your business."

**Body: SingleChildScrollView with Column of white cards**

#### Card 1: Invoice Header

| Field | Widget | Default Value |
|-------|--------|---------------|
| Invoice Number | Read-only TextField | Auto-generated "INV-000004" (next available). Non-editable. Grey background. |
| Invoice Date | DatePicker TextField (tap to open `showDatePicker`) | Today's date, formatted dd/MM/yyyy |
| Due Date | DatePicker TextField | Today's date (changes based on terms selection) |
| Payment Terms | Dropdown: "Due on Receipt", "Net 15", "Net 30", "Net 45", "Custom" | "Due on Receipt" |

**Terms-to-DueDate auto-calculation:**
```
When terms changes:
  "Due on Receipt" -> dueDate = invoiceDate
  "Net 15" -> dueDate = invoiceDate + 15 days
  "Net 30" -> dueDate = invoiceDate + 30 days
  "Net 45" -> dueDate = invoiceDate + 45 days
  "Custom" -> user picks manually
```

#### Card 2: Bill To (Client Selection)

- Dropdown showing all clients from Hive, displaying client name
- Below dropdown: if client selected, show client details card:
  - Name in 16sp w600
  - Email, Phone in 13sp textSecondary
  - Address in 13sp textSecondary
  - GSTIN if present
- Last dropdown item: "+ Add New Client" -- opens Add Client screen, on return refreshes dropdown and auto-selects the new client

**Controller variable:** `final selectedClient = Rxn<ClientModel>();`

#### Card 3: Line Items (Itemized Billing)

**This is the most complex widget on this screen.**

Header: "Items" section title + "Add Line Item" button (blue text with + icon)

Each line item is rendered as a sub-card within this section:

```
+--------------------------------------------------+
| Item 1                                     [X]   |
| Description: [_____________________________]     |
| Qty: [_1.00_]    Rate: [_4000.00_]   = 4,000.00  |
+--------------------------------------------------+
```

- Description: TextFormField, full width, validation required non-empty
- Qty: TextFormField, width 80, keyboardType numberWithOptions(decimal), default "1.00"
- Rate: TextFormField, width 120, keyboardType numberWithOptions(decimal), default "0.00"
- Amount: computed Text (read-only), right-aligned, 14sp w600
- [X] button: IconButton to remove item (with confirmation if > 1 item)

**"+ Add Line Item" button:** OutlinedButton full width, dashed border style, primary blue text. Appends a new empty InvoiceItemModel to the reactive list.

**Reactive calculation chain:**

```dart
// In CreateInvoiceController:
final items = <InvoiceItemModel>[].obs;
final applyGst = false.obs;
final gstPercent = 18.0.obs;
final isInterState = false.obs;
final paymentMade = 0.0.obs;

// Each item has its own TextEditingControllers stored in parallel lists:
final descControllers = <TextEditingController>[].obs;
final qtyControllers = <TextEditingController>[].obs;
final rateControllers = <TextEditingController>[].obs;

// Computed values (these are Rx so UI rebuilds):
double get subTotal => items.fold(0.0, (sum, item) => sum + item.amount);
double get gstAmount => applyGst.value ? subTotal * gstPercent.value / 100 : 0.0;
double get cgstAmount => applyGst.value && !isInterState.value ? gstAmount / 2 : 0.0;
double get sgstAmount => applyGst.value && !isInterState.value ? gstAmount / 2 : 0.0;
double get igstAmount => applyGst.value && isInterState.value ? gstAmount : 0.0;
double get total => subTotal + gstAmount;
double get balanceDue => total - paymentMade.value;
```

**Important:** Because computed getters on non-Rx objects do not trigger Obx rebuilds, the controller must use a `final _recalcTrigger = 0.obs;` that is incremented every time a qty or rate text field changes. The `subTotal` etc. are then accessed inside `Obx` that also references `_recalcTrigger.value` to ensure rebuild. Alternatively, store subTotal/total/etc. as `.obs` variables and update them via an explicit `recalculate()` method called from text field `onChanged`.

**Recommended approach (explicit recalculate):**

```dart
final subTotal = 0.0.obs;
final gstAmount = 0.0.obs;
final totalAmount = 0.0.obs;
final balanceDue = 0.0.obs;

void recalculate() {
  // Sync items list from controllers
  for (int i = 0; i < items.length; i++) {
    items[i].quantity = double.tryParse(qtyControllers[i].text) ?? 0;
    items[i].rate = double.tryParse(rateControllers[i].text) ?? 0;
  }

  subTotal.value = items.fold(0.0, (sum, item) => sum + item.amount);
  gstAmount.value = applyGst.value ? subTotal.value * gstPercent.value / 100 : 0.0;
  totalAmount.value = subTotal.value + gstAmount.value;
  balanceDue.value = totalAmount.value - paymentMade.value;
}
```

Call `recalculate()` from every qty/rate `onChanged`, from the GST toggle, from GST percent dropdown change, and from payment made field change. Add listeners to text controllers in `addItem()`.

#### Card 4: Tax / GST Configuration

```
+--------------------------------------------------+
| Apply GST                          [Toggle]       |
|                                                   |
| (visible when GST enabled:)                       |
| GST Rate    [18% dropdown: 0/5/12/18/28]          |
| Tax Type    ( ) Intra-State (CGST+SGST)           |
|             ( ) Inter-State (IGST)                |
+--------------------------------------------------+
```

- Toggle: `Switch` widget bound to `applyGst.obs`
- GST Rate Dropdown: `DropdownButtonFormField<double>` with items [0, 5, 12, 18, 28]. Each displayed as "X%". Default 18.
- Tax Type: `RadioListTile` group with two options. Bound to `isInterState.obs`.
- All changes call `recalculate()`

#### Card 5: Summary (Always Visible)

This card shows the running totals. All values formatted in Indian number system.

```
+--------------------------------------------------+
| Sub Total                           Rs. 4,000.00  |
|                                                   |
| (if GST enabled and intra-state:)                 |
| CGST (9%)                              Rs. 360.00 |
| SGST (9%)                              Rs. 360.00 |
|                                                   |
| (if GST enabled and inter-state:)                 |
| IGST (18%)                             Rs. 720.00 |
|                                                   |
| ------------------------------------------------- |
| Total                              Rs. 4,720.00   |
| Payment Received                   Rs. 0.00       |
| Balance Due                        Rs. 4,720.00   |
+--------------------------------------------------+
```

- Each row: Row with label (left) and value (right), padding vertical 6
- Divider before Total row
- Total row: 16sp w700
- Balance Due row: 16sp w700, color danger if > 0

"Payment Received" is an editable TextFormField (inline, right-aligned) for partial payment recording. Calls `recalculate()` on change.

#### Card 6: Notes & Terms

```
+--------------------------------------------------+
| Customer Notes                                    |
| [Thanks for your business.               ]        |
|                                                   |
| Terms & Conditions                                |
| [Due on Receipt                          ]        |
+--------------------------------------------------+
```

- Notes: multiline TextFormField, max lines 3, prefilled from profile defaults
- Terms: TextFormField, single line, prefilled from profile defaults

#### Bottom Action Bar (Sticky)

Fixed at the bottom of the screen (not scrollable), Row with padding 16:

```
[  Save as Draft  ]    [  Preview Invoice  ]
(outlined, full-width)  (elevated, primary)
```

- "Save as Draft": OutlinedButton, saves invoice with status = 'draft'
- "Preview Invoice": ElevatedButton primary, validates form first, saves invoice (status = 'draft' if new), navigates to InvoicePreview with the invoice ID

**Save logic:**

```
void saveInvoice({String status = 'draft'}) {
  // Validate
  if (selectedClient.value == null) {
    Get.snackbar('Error', 'Please select a client');
    return;
  }
  if (items.isEmpty) {
    Get.snackbar('Error', 'Add at least one line item');
    return;
  }
  for (final item in items) {
    if (item.description.isEmpty || item.rate <= 0) {
      Get.snackbar('Error', 'Fill in all item details');
      return;
    }
  }

  // Build model
  final invoice = InvoiceModel(
    id: isEditing ? existingInvoice.id : Uuid().v4(),
    invoiceNumber: isEditing ? existingInvoice.invoiceNumber : HiveService.generateInvoiceNumber(),
    clientId: selectedClient.value!.id,
    invoiceDate: invoiceDate.value,
    dueDate: dueDate.value,
    items: items.toList(),
    applyGst: applyGst.value,
    gstPercent: gstPercent.value,
    isInterState: isInterState.value,
    status: status,
    notes: notesController.text,
    paymentMade: paymentMade.value,
    terms: termsController.text,
    createdAt: isEditing ? existingInvoice.createdAt : DateTime.now(),
  );

  if (isEditing) {
    HiveService.updateInvoice(invoice);
  } else {
    HiveService.addInvoice(invoice);
  }

  Get.back(result: true);
  Get.snackbar('Success', 'Invoice ${status == "draft" ? "saved as draft" : "saved"}');
}
```

### T11: Invoice Preview Screen

**File: `lib/app/modules/invoices/invoice_preview_screen.dart`**

**Receives:** invoice ID via `Get.arguments`

**Layout:**
- AppBar: "Invoice Preview", no trailing actions (actions are in the bottom bar)
- Body: SingleChildScrollView, padding 16
- Renders the invoice as it would appear on paper, inside a white card with shadow

**Invoice preview card layout (matches the PDF layout):**

```
+--------------------------------------------------+
|  BUSINESS NAME (bold 20sp)        TAX INVOICE     |
|  Business Address                 (bold 18sp blue) |
|  Business Email | Phone                           |
|  GSTIN: XXXXXXXXX                                 |
|--------------------------------------------------|
|  Invoice #: INV-000001                            |
|  Invoice Date: 14/04/2026                         |
|  Terms: Due on Receipt                            |
|  Due Date: 14/04/2026                             |
|--------------------------------------------------|
|  Bill To                                          |
|  CLIENT NAME (bold)                               |
|  Client Address                                   |
|  Client Email | Phone                             |
|  GSTIN: XXXXXXXXX (if present)                    |
|--------------------------------------------------|
|  #  | Item & Description | Qty  | Rate   | Amount|
|  ---|-------------------|------|--------|-------|
|  1  | Printer           | 1.00 | 4,000  | 4,000 |
|--------------------------------------------------|
|                                                   |
|  Total In Words:                                  |
|  Indian Rupee Four Thousand Only                  |
|                                                   |
|  Notes: Thanks for your business.                 |
|                                                   |
|                    Sub Total      Rs. 4,000.00    |
|                    CGST (9%)         Rs. 360.00   |
|                    SGST (9%)         Rs. 360.00   |
|                    -------------------------      |
|                    Total          Rs. 4,720.00    |
|                    Payment Made (-) Rs. 4,000.00  |
|                    Balance Due    Rs. 720.00      |
|                                                   |
|                         Authorized Signature      |
|                         ____________________      |
|                         [Business Name]           |
+--------------------------------------------------+
```

**Table implementation:** Use `Table` widget with `TableRow` children. Header row has a grey (#F0F0F0) background. Column widths: `#` = fixed 30, `Item` = flex, `Qty` = fixed 60, `Rate` = fixed 80, `Amount` = fixed 90. Cell text: 13sp. Header text: 13sp w600.

**"Total In Words" line:** Uses the `numberToWords()` utility function.

**Bottom Action Bar:**
- Horizontal scrollable Row of action buttons, or a fixed Row with 4-5 compact buttons:

```
[Generate PDF]  [Send Email]  [Share]  [Edit]  [Mark as Paid]
```

| Button | Icon | Style | Action |
|--------|------|-------|--------|
| Generate PDF | Icons.picture_as_pdf | Outlined | Calls PdfService, opens/saves PDF |
| Send Email | Icons.email | Outlined | Generates PDF, then calls EmailService |
| Share | Icons.share | Outlined | Generates PDF, then uses share_plus |
| Edit | Icons.edit | Outlined | `Get.toNamed(AppRoutes.editInvoice, arguments: invoice)` |
| Mark as Paid | Icons.check_circle | Elevated (green) | Updates status to 'paid', paymentMade = total, saves, refreshes UI |

"Mark as Paid" only shows if status is not already 'paid'. When invoice is already paid, show a green chip "PAID" instead.

Status change buttons (contextual):
- If draft: show "Send Invoice" (changes status to 'sent' + triggers email)
- If sent: show "Mark as Paid"
- If paid: show "Paid" chip (non-interactive)
- If overdue: show "Mark as Paid"

---

## 8. Phase 6: PDF & Email (T12-T13)

### T12: PDF Generation

**File: `lib/app/data/services/pdf_service.dart`**

Uses the `pdf` package (`pw` prefix for `pdf/widgets.dart`).

**Method signature:**
```dart
static Future<File> generateInvoicePdf({
  required InvoiceModel invoice,
  required ClientModel client,
  required UserProfileModel business,
}) async
```

**PDF layout specification (A4 page, margins 40):**

**Header section:**
- Left column (60% width):
  - Business name: bold 22pt, dark color
  - Business address: regular 10pt, grey
  - Email / Phone: regular 10pt, grey
  - GSTIN: regular 10pt, grey (if present)
  - If business has a logo (logoPath), show logo image (60x60) to the left of business name
- Right column (40% width), right-aligned:
  - "TAX INVOICE": bold 20pt, primary blue color
  - Or "INVOICE" if GST is not applied

**Divider:** Full-width horizontal line, 1pt, grey

**Invoice meta section (two-column layout):**
- Left column:
  - "Invoice #:" label + value in bold
  - "Invoice Date:" + formatted date
  - "Terms:" + terms string
  - "Due Date:" + formatted date
- Right column: empty or status badge

**Divider**

**Bill To section:**
- "Bill To" label in 10pt grey
- Client name: bold 12pt
- Client address: regular 10pt
- Client email, phone: regular 10pt
- Client GSTIN: regular 10pt (if present)

**Divider**

**Items table:**
- Table header row: grey (#F0F0F0) background
  - Columns: "#" (30pt fixed), "Item & Description" (flex), "Qty" (60pt), "Rate" (80pt), "Amount" (90pt)
  - Header text: bold 10pt, dark color
- Data rows: each item with serial number
  - Text: regular 10pt
  - Amount: right-aligned, Indian formatted
  - Alternate row shading (optional, very subtle #FAFAFA)

**Below table, left side:**
- "Total In Words:" label in bold italic 10pt
- Amount in words: italic 10pt (e.g., "Indian Rupee Four Thousand Only")
- SizedBox(10)
- "Notes:" label in bold 9pt
- Notes text in regular 9pt

**Below table, right side (right-aligned summary):**

```
Sub Total          4,000.00
CGST (9%)            360.00
SGST (9%)            360.00
─────────────────────────
Total             Rs. 4,720.00
Payment Made (-)     4,000.00
Balance Due       Rs. 720.00
```

- Use a `pw.Table` or `pw.Column` of `pw.Row` widgets
- Total row: bold, larger font
- Balance Due: bold, colored (blue or red depending on amount)
- All amounts in Indian number format

**Footer (bottom of page):**
- Right-aligned block:
  - SizedBox(40)
  - "Authorized Signature" in 10pt grey
  - Horizontal line (100pt wide)
  - Business name in 10pt below the line

**File saving:**
```dart
final dir = await getApplicationDocumentsDirectory();
final file = File('${dir.path}/${invoice.invoiceNumber}.pdf');
await file.writeAsBytes(await pdf.save());
return file;
```

**PDF viewing:** Use the `printing` package's `Printing.layoutPdf()` for print dialog, or `open_file` package to open the saved PDF in the system viewer.

### T13: Email Service

**File: `lib/app/data/services/email_service.dart`**

**Method signature:**
```dart
static Future<void> sendInvoiceEmail({
  required InvoiceModel invoice,
  required ClientModel client,
  required UserProfileModel business,
  required File pdfFile,
}) async
```

**Email composition:**

```
Subject: Invoice ${invoice.invoiceNumber} from ${business.businessName}

Body:
Dear ${client.name},

Thank you for your business. Your invoice can be viewed, printed and downloaded as PDF from the attachment.

INVOICE DETAILS
Invoice No: ${invoice.invoiceNumber}
Invoice Date: ${formatDate(invoice.invoiceDate)}
Due Date: ${formatDate(invoice.dueDate)}
Amount Due: Rs. ${formatIndianCurrency(invoice.balanceDue)}

${invoice.notes}

Regards,
${business.displayName ?? business.businessName}
${business.businessName}

Recipients: [client.email]
Attachments: [pdfFile.path]
isHTML: false
```

Uses `flutter_email_sender`:
```dart
final email = Email(
  body: bodyText,
  subject: subjectText,
  recipients: [client.email],
  attachmentPaths: [pdfFile.path],
  isHTML: false,
);
await FlutterEmailSender.send(email);
```

**Error handling:** Wrap in try-catch. If no email client is installed, show a snackbar: "No email app found. Please install an email client." Use `share_plus` as fallback to share the PDF.

**Invoice status update:** After email send is initiated (even if user cancels from email client, we cannot detect that), update invoice status from 'draft' to 'sent' and save to Hive.

---

## 9. Phase 7: Profile & Analytics (T14-T15)

### T14: Profile / Business Settings Screen

Lives inside MainShellScreen as tab index 3.

**File: `lib/app/modules/profile/profile_screen.dart`**

**Layout:**
- No AppBar (or minimal AppBar with just "Profile")
- Body: SingleChildScrollView

**Section 1: User Card**
- White card at top, padding 20
- Row: CircleAvatar (64x64 from photoUrl or initials) + Column(displayName 20sp w600, email 14sp textSecondary)
- Below: business name if set, 14sp textSecondary

**Section 2: Business Information Form**

**Dev Autofill Button** at top of form section:
```
businessNameController.text = 'Cabiverse';
addressController.text = 'B-42, Sector 18\nGurugram, Haryana 122001\nIndia';
emailController.text = 'billing@cabiverse.com';
phoneController.text = '+91 98765 43210';
gstinController.text = '06AABCU9603R1ZX';
defaultTermsController.text = 'Due on Receipt';
defaultNotesController.text = 'Thanks for your business.';
defaultGstRate.value = 18.0;
```

**Form fields (in white cards):**

Card: "Business Details"
- Business Name *
- Business Address (multiline)
- Email *
- Phone

Card: "Tax Information"
- GSTIN
- Default GST Rate (dropdown: 0%, 5%, 12%, 18%, 28%)

Card: "Invoice Defaults"
- Default Payment Terms (dropdown)
- Default Notes (multiline)

Card: "Business Logo"
- Current logo preview (or placeholder icon)
- "Change Logo" button -> `image_picker` to pick from gallery
- "Remove Logo" button (if logo exists)
- Logo is saved to app documents directory, path stored in UserProfileModel

**Save button:** Full-width ElevatedButton "Save Profile" at bottom. Updates `UserProfileModel` in Hive.

**Section 3: App Actions**
- ListTile "About InvoGen" with info icon -> shows About dialog with app version
- ListTile "Sign Out" with logout icon, red text -> confirmation dialog -> clears `isLoggedIn` from GetStorage, navigates to Login with `Get.offAllNamed(AppRoutes.login)`

**ProfileController:**
```
final profile = Rxn<UserProfileModel>();
// TextEditingControllers for each field
// Load from Hive in onInit, save to Hive on save
```

### T15: Reports / Analytics Screen

**File: `lib/app/modules/reports/reports_screen.dart`**

Pushed route from Dashboard Quick Actions.

**Layout:**
- AppBar: "Reports & Analytics"
- Body: SingleChildScrollView

**Section 1: Period Selector**
- Row of ChoiceChips: "This Month", "Last 3 Months", "This Year", "All Time"
- Default: "All Time"

**Section 2: Revenue Summary Cards**
- Row of 2 cards:
  - "Total Invoiced": sum of all invoice totals (formatted Indian)
  - "Total Collected": sum of all paymentMade (formatted Indian)
- Below: progress bar showing collection rate (collected/invoiced * 100)%

**Section 3: Invoice Status Distribution**
- Simple custom-painted horizontal stacked bar chart (or use Container widths proportionally):
  - Green segment: paid count
  - Blue segment: sent count
  - Grey segment: draft count
  - Red segment: overdue count
- Legend below with color dots + labels + counts

**Section 4: Monthly Revenue (Bar Chart)**
- Simple bar chart using `CustomPaint` or a column of horizontal bars
- Last 6 months of revenue data
- Each bar: month label (Jan, Feb...) + horizontal bar (width proportional to revenue) + amount label
- No external chart library needed -- build with Containers and proportional widths

**Section 5: Top Clients**
- "Top Clients by Revenue" section header
- List of top 5 clients sorted by total invoice amount
- Each row: rank number + avatar + name + total amount

**ReportsController:**
- Computes all analytics from Hive data in `onInit()`
- Filters data based on selected period
- All values are `.obs` for reactivity

---

## 10. Phase 8: AI Chatbot (T16)

### Gemini Integration

**File: `lib/app/data/services/gemini_service.dart`**

**API endpoint:** `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent`

**Request format:**
```dart
static Future<String> sendMessage(String message, List<Map<String, String>> history) async {
  final url = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$geminiApiKey'
  );

  final contents = history.map((msg) => {
    'role': msg['role'], // 'user' or 'model'
    'parts': [{'text': msg['text']}],
  }).toList();

  // Add current message
  contents.add({
    'role': 'user',
    'parts': [{'text': message}],
  });

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': contents,
      'systemInstruction': {
        'parts': [{'text': _systemPrompt}],
      },
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'];
  } else {
    throw Exception('Gemini API error: ${response.statusCode}');
  }
}

static const _systemPrompt = '''
You are InvoBot, a helpful AI assistant for the InvoGen invoice app.
You help users with:
- Creating and managing invoices
- Understanding GST/tax calculations
- Managing client information
- Business invoicing best practices
- Indian tax compliance basics

Keep responses concise and practical. You are embedded in a mobile app,
so keep answers under 200 words when possible.
''';
```

### Chat UI: DraggableScrollableSheet

**File: `lib/app/modules/dashboard/widgets/gemini_chatbot_sheet.dart`**

Opened from the Dashboard FAB.

**Implementation:**

```dart
void openChatbot() {
  Get.bottomSheet(
    DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => GeminiChatSheet(scrollController),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}
```

**Chat sheet layout:**
- Container with white background, top borderRadius 20
- Header bar: drag handle (small grey pill 40x4), title "InvoGen AI Assistant", close button
- Divider
- Messages list: `ListView.builder` with `scrollController`, shows chat bubbles
  - User messages: right-aligned, primary blue background, white text, borderRadius 12 (top-right square)
  - Bot messages: left-aligned, grey (#F0F0F0) background, dark text, borderRadius 12 (top-left square)
  - Bot avatar: small robot icon circle on left of bot messages
  - Typing indicator: three animated dots in a grey bubble (when waiting for response)
- Bottom input bar: Row of TextField (expanded, borderRadius 24, grey background) + CircularIconButton send (primary)

**ChatController (or included in DashboardController):**
```
final messages = <ChatMessage>[].obs;
final isTyping = false.obs;
final textController = TextEditingController();

void sendMessage() async {
  final text = textController.text.trim();
  if (text.isEmpty) return;

  textController.clear();
  messages.add(ChatMessage(text: text, isUser: true));
  isTyping.value = true;

  try {
    final history = messages.map((m) => {
      'role': m.isUser ? 'user' : 'model',
      'text': m.text,
    }).toList();

    final response = await GeminiService.sendMessage(text, history);
    messages.add(ChatMessage(text: response, isUser: false));
  } catch (e) {
    messages.add(ChatMessage(
      text: 'Sorry, I could not process your request. Please try again.',
      isUser: false,
    ));
  } finally {
    isTyping.value = false;
  }
}
```

**ChatMessage model (simple, not Hive-persisted):**
```dart
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isUser})
    : timestamp = DateTime.now();
}
```

**Welcome message:** On first open, show a pre-populated bot message: "Hi! I'm InvoBot, your invoice assistant. Ask me anything about creating invoices, managing clients, or understanding GST calculations."

---

## 11. Dev Experience

### Dev Autofill Strategy

**Universal pattern for all form screens:**

```dart
// At the top of the form body, before the first card:
if (kDebugMode)
  Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: controller.devAutofill,
        icon: const Icon(Icons.build, size: 16),
        label: const Text('Dev Fill'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.devFill, // #FF9800 orange
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 36),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  ),
```

**Screens with Dev Fill:**

| Screen | File | Data Filled |
|--------|------|------------|
| Login | login_screen.dart | "Dev Login" button bypasses Google Sign-In, creates mock profile |
| Add Client | add_client_screen.dart | Sanjay Hooda, full address, GSTIN |
| Create Invoice | create_invoice_screen.dart | First client, today's date, Printer item, notes, terms |
| Profile | profile_screen.dart | Cabiverse business, Haryana address, GSTIN |

**Debug vs Release behavior:**
- `kDebugMode` is from `package:flutter/foundation.dart` -- it is `true` in debug builds and `false` in release builds
- All dev fill buttons are wrapped in `if (kDebugMode)` -- they are tree-shaken out of release builds entirely
- No `#ifdef` or flavor-based toggling needed -- `kDebugMode` is the standard approach

### Hot Reload Considerations

- All `GetxController` instances survive hot reload because they are `Get.put`/`Get.lazyPut` singletons
- Hive boxes remain open across hot reload -- no need to re-initialize
- If a Hive TypeAdapter changes (field added/removed), a full app restart is required AND the old box data may be incompatible -- during development, call `Hive.deleteBoxFromDisk()` in `main.dart` if migration is too complex
- Lottie animations cache their composition -- hot reload preserves them

---

## 12. UI/UX Design Tokens

### Color Tokens (Complete)

```dart
class AppColors {
  // Primary palette
  static const primary         = Color(0xFF1A73E8);
  static const primaryDark     = Color(0xFF1557B0);
  static const primaryLight    = Color(0xFFE8F0FE);

  // Accent
  static const accent          = Color(0xFF00BFA5);
  static const accentLight     = Color(0xFFE0F7FA);

  // Semantic
  static const success         = Color(0xFF34A853);
  static const successLight    = Color(0xFFE6F4EA);
  static const warning         = Color(0xFFFBBC04);
  static const warningLight    = Color(0xFFFEF7E0);
  static const danger          = Color(0xFFEA4335);
  static const dangerLight     = Color(0xFFFCE8E6);

  // Neutrals
  static const background      = Color(0xFFF8F9FA);
  static const surface         = Color(0xFFFFFFFF);
  static const textPrimary     = Color(0xFF202124);
  static const textSecondary   = Color(0xFF5F6368);
  static const textHint        = Color(0xFF9AA0A6);
  static const divider         = Color(0xFFE0E0E0);
  static const cardShadow      = Color(0x14000000);
  static const disabled        = Color(0xFFBDBDBD);

  // Status chips
  static const statusDraft     = Color(0xFF9AA0A6);
  static const statusSent      = Color(0xFF1A73E8);
  static const statusPaid      = Color(0xFF34A853);
  static const statusOverdue   = Color(0xFFEA4335);

  // Dev
  static const devFill         = Color(0xFFFF9800);
}
```

### Typography Scale

| Token | Size | Weight | LetterSpacing |
|-------|------|--------|---------------|
| displayLarge | 28sp | w700 | -0.5 |
| headlineLarge | 24sp | w700 | -0.25 |
| headlineMedium | 20sp | w600 | 0 |
| titleLarge | 18sp | w600 | 0 |
| titleMedium | 16sp | w600 | 0.15 |
| bodyLarge | 16sp | w400 | 0.15 |
| bodyMedium | 14sp | w400 | 0.25 |
| bodySmall | 12sp | w400 | 0.4 |
| labelLarge | 14sp | w600 | 0.1 |
| labelMedium | 12sp | w500 | 0.5 |
| labelSmall | 10sp | w500 | 0.5 |

### Spacing Constants

```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const section = 40.0;

  // Standard paddings
  static const screenHorizontal = 16.0;
  static const screenVertical = 16.0;
  static const cardPadding = 16.0;
  static const cardMarginVertical = 4.0;
  static const cardMarginHorizontal = 16.0;
}
```

### Component Standards

**Card:**
```dart
Container(
  margin: EdgeInsets.symmetric(
    horizontal: AppSpacing.cardMarginHorizontal,
    vertical: AppSpacing.cardMarginVertical,
  ),
  padding: EdgeInsets.all(AppSpacing.cardPadding),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: AppColors.cardShadow,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
)
```

**Status Chip:**
```dart
Widget buildStatusChip(String status) {
  final color = _statusColor(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.capitalize!,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Color _statusColor(String status) {
  switch (status) {
    case 'draft':   return AppColors.statusDraft;
    case 'sent':    return AppColors.statusSent;
    case 'paid':    return AppColors.statusPaid;
    case 'overdue': return AppColors.statusOverdue;
    default:        return AppColors.statusDraft;
  }
}
```

**Form Field (Zoho style -- blue label above underline input):**
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(label, style: TextStyle(
      color: AppColors.primary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    )),
    const SizedBox(height: 4),
    TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textHint),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      validator: validator,
    ),
  ],
)
```

**Primary Button:**
```dart
SizedBox(
  width: double.infinity,
  height: 48,
  child: ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    child: Text(label),
  ),
)
```

**Avatar with Initials:**
```dart
CircleAvatar(
  radius: radius,
  backgroundColor: _avatarColor(name), // deterministic color from name
  child: Text(
    _initials(name), // first letter of first + last name, uppercase
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
  ),
)
```

**Avatar color palette** (deterministic from name hash):
```dart
static const _avatarColors = [
  Color(0xFF1A73E8), // blue
  Color(0xFF34A853), // green
  Color(0xFFEA4335), // red
  Color(0xFFFBBC04), // yellow
  Color(0xFF00BFA5), // teal
  Color(0xFF9C27B0), // purple
  Color(0xFFFF5722), // deep orange
  Color(0xFF607D8B), // blue grey
];

static Color _avatarColor(String name) =>
    _avatarColors[name.hashCode.abs() % _avatarColors.length];
```

---

## 13. Android Manifest and Permissions

**File: `android/app/src/main/AndroidManifest.xml`**

Add these permissions BEFORE the `<application>` tag:

```xml
<!-- Internet access for Gemini API calls and Google Sign-In -->
<uses-permission android:name="android.permission.INTERNET"/>

<!-- Network state check before API calls -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- Storage for PDF save/read on older Android versions -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29"/>

<!-- Scoped storage for Android 13+ (image picker for logo) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

Add to `<application>` tag:
```xml
android:requestLegacyExternalStorage="true"
```

**Add to `<queries>` section (for email intent and file opening):**
```xml
<queries>
    <intent>
        <action android:name="android.intent.action.SENDTO"/>
        <data android:scheme="mailto"/>
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <data android:mimeType="application/pdf"/>
    </intent>
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
</queries>
```

**Why each permission:**
- `INTERNET` -- Gemini API HTTP calls, Google Sign-In OAuth flow
- `ACCESS_NETWORK_STATE` -- Check connectivity before API calls, show offline message
- `READ/WRITE_EXTERNAL_STORAGE` -- Saving generated PDFs to Downloads folder on Android <= 10. On Android 11+, `getApplicationDocumentsDirectory()` does not need these permissions
- `READ_MEDIA_IMAGES` -- `image_picker` on Android 13+ for selecting business logo
- `requestLegacyExternalStorage` -- Android 10 compatibility for file access

**No permission_handler runtime requests needed for:**
- PDF saving to app-private directory (`getApplicationDocumentsDirectory()`) -- no permission needed
- Email sending via intent -- no permission needed
- Sharing via share_plus -- no permission needed

**Permission_handler is only needed for:**
- Camera permission if you add camera option to image_picker (not required, gallery-only is fine)
- Storage permission on Android <= 10 if saving to public Downloads folder (use app-private directory instead to avoid this)

**Recommendation:** Save PDFs to `getApplicationDocumentsDirectory()` (private, no permission needed) and use `share_plus` or `printing` package to let users save/share externally. This avoids all storage permission complexity.

---

## 14. Potential Pitfalls and Solutions

### Pitfall 1: Hive Code Generation Fails

**Problem:** Running `dart run build_runner build` fails with "Could not generate TypeAdapter" or "unresolved reference".

**Solutions:**
- Ensure every model file has `part 'filename.g.dart';` at the top (after imports)
- Ensure `@HiveType(typeId: N)` uses unique typeIds across ALL models (0, 1, 2, 3)
- The `InvoiceItemModel` is embedded inside `InvoiceModel.items` list -- Hive handles `List<HiveObject>` natively as long as both adapters are registered
- Run with `--delete-conflicting-outputs` flag: `dart run build_runner build --delete-conflicting-outputs`
- If `.g.dart` files exist but are stale, delete them manually before regenerating

### Pitfall 2: Hive Computed Getters in Model

**Problem:** Hive does not serialize computed getters (`get subTotal`, `get amount`). They are computed at runtime, which is correct. But if you add a `@HiveField` to a getter, code gen will fail.

**Solution:** Never annotate getters with `@HiveField`. Only annotate stored fields. Computed properties are regular Dart getters derived from stored fields.

### Pitfall 3: GetX Navigation Stack Confusion

**Problem:** Using `Get.toNamed()` from a screen inside `IndexedStack` (bottom nav) creates a weird back-stack where pressing back returns to the bottom nav but the wrong tab.

**Solutions:**
- Sub-screens (AddClient, CreateInvoice, InvoicePreview, ClientDetail, Reports) are PUSHED on top of the MainShell, not inside it. They have their own Scaffold and AppBar with back button.
- Use `Get.toNamed()` (not `Get.offNamed()`) so the main shell stays in the stack
- Use `Get.back()` to return to the main shell
- Never use `Get.offAllNamed()` except from Splash/Login (to clear auth stack)

### Pitfall 4: Obx Not Rebuilding

**Problem:** Changing a property on an object inside an RxList does not trigger Obx rebuild because the list reference has not changed.

**Solutions:**
- After modifying an object property inside `items.obs`, call `items.refresh()` to force notification
- For invoice item qty/rate changes, use the explicit `recalculate()` pattern described in T10 -- update `.obs` variables directly rather than relying on computed getters
- Test reactive chains: change a value, verify the UI updates. If not, add `.refresh()` calls

### Pitfall 5: PDF Rendering Issues on Android

**Problem:** `pdf` package text rendering may have font issues (missing glyphs for Rs. symbol, Hindi text).

**Solutions:**
- Use `pw.Text('Rs. ')` instead of the actual Rupee symbol `'₹'` if font does not support it -- OR load a TTF font that includes the Rupee symbol:
  ```dart
  final font = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  final ttf = pw.Font.ttf(font);
  ```
  Then use `style: pw.TextStyle(font: ttf)` throughout the PDF
- Bundle `Roboto-Regular.ttf` and `Roboto-Bold.ttf` in `assets/fonts/`
- The Rupee symbol `₹` (U+20B9) is supported by Roboto
- Always test PDF generation on a real Android device -- emulator rendering may differ

### Pitfall 6: Google Sign-In Setup

**Problem:** Google Sign-In requires SHA-1 fingerprint registered in Google Cloud Console and a proper `google-services.json` for Android.

**Solutions for mock/demo approach:**
- For genuine Google Sign-In: configure a Google Cloud project, enable Google Sign-In API, add SHA-1 from `keytool -list -v -keystore ~/.android/debug.keystore`, download `google-services.json` to `android/app/`
- For mock approach: wrap the sign-in in try-catch, provide the "Dev Login" button as fallback
- The `google_sign_in` package will throw `PlatformException` if not configured -- the catch block handles this gracefully

### Pitfall 7: flutter_email_sender on Emulator

**Problem:** `flutter_email_sender` requires an email client app installed. Emulators typically don't have one.

**Solution:** Always test email on a physical device. On emulators, the `send()` call will throw -- catch it and show a snackbar. Consider offering `share_plus` as an alternative distribution method.

### Pitfall 8: Hive Box Already Open

**Problem:** Calling `Hive.openBox()` for a box that is already open throws an error on hot restart.

**Solution:** Check if box is already open before opening:
```dart
if (!Hive.isBoxOpen('clients')) {
  clientsBox = await Hive.openBox<ClientModel>('clients');
} else {
  clientsBox = Hive.box<ClientModel>('clients');
}
```

### Pitfall 9: IndexedStack Memory

**Problem:** `IndexedStack` keeps all 4 tab screens in memory simultaneously.

**Solution:** This is acceptable for 4 screens. If memory is a concern, use `Offstage` or lazy-load tabs on first visit. For InvoGen's scale, `IndexedStack` is the correct choice as it preserves scroll positions and state.

### Pitfall 10: Invoice Number Collision

**Problem:** If the app crashes between generating an invoice number and saving the invoice, the counter has incremented but no invoice exists with that number, leaving a gap.

**Solution:** Gaps are acceptable and standard in invoice numbering. Do NOT try to fill gaps -- sequential numbering with gaps is normal business practice. The counter only increments in `generateInvoiceNumber()` which is called at save time, not at form open time. Display the "next" number in the Create Invoice form as a preview, but only persist the counter increment when actually saving.

**Revised approach:** Show a preview number in the form (read from counter + 1 without incrementing), and only call `generateInvoiceNumber()` (which increments) at actual save time. This minimizes gaps.

---

## 15. Execution Checklist

This is the ordered task list for Claude Code to follow during implementation. Each task should be completed and verified before moving to the next.

### Foundation

- [ ] **T1.1** -- Update `pubspec.yaml` with all dependencies. Run `flutter pub get`. Verify no resolution errors.
- [ ] **T1.2** -- Create the complete folder structure under `lib/app/`.
- [ ] **T1.3** -- Create `client_model.dart` with HiveType(typeId: 0) and all HiveField annotations.
- [ ] **T1.4** -- Create `invoice_item_model.dart` with HiveType(typeId: 1).
- [ ] **T1.5** -- Create `invoice_model.dart` with HiveType(typeId: 2), including `isInterState` field and all computed getters.
- [ ] **T1.6** -- Create `user_profile_model.dart` with HiveType(typeId: 3).
- [ ] **T1.7** -- Run `dart run build_runner build --delete-conflicting-outputs`. Verify all `.g.dart` files generated.
- [ ] **T1.8** -- Create `hive_service.dart` with init(), all CRUD methods, and `generateInvoiceNumber()`.
- [ ] **T1.9** -- Create `main.dart` with Hive init, GetStorage init, GetMaterialApp.

### Routes and Theme

- [ ] **T2.1** -- Create `app_routes.dart` with all route constants.
- [ ] **T2.2** -- Create `app_pages.dart` with GetPage list (screens can be placeholder widgets initially).
- [ ] **T2.3** -- Create `app_bindings.dart` with InitialBinding.
- [ ] **T3.1** -- Create `app_colors.dart` with complete color palette.
- [ ] **T3.2** -- Create `app_text_styles.dart` with typography scale.
- [ ] **T3.3** -- Create `app_theme.dart` with full ThemeData.
- [ ] **T3.4** -- Create `currency_formatter.dart` with Indian number formatting.
- [ ] **T3.5** -- Create `date_formatter.dart` with date formatting and greeting utilities.
- [ ] **T3.6** -- Create `number_to_words.dart` with Indian English number-to-words conversion.
- [ ] **T3.7** -- Create `app_strings.dart` with all string constants.
- [ ] **T3.8** -- Verify app builds and shows a blank screen with correct theme. Run `flutter run`.

### Authentication Flow

- [ ] **T4.1** -- Create `splash_controller.dart` with navigation logic.
- [ ] **T4.2** -- Create `splash_screen.dart` with gradient background, icon/animation, app name.
- [ ] **T4.3** -- Download or create placeholder Lottie animation files in `assets/animations/`.
- [ ] **T5.1** -- Create `onboarding_controller.dart` with PageController and navigation.
- [ ] **T5.2** -- Create `onboarding_screen.dart` with 3-page PageView, dot indicators, Next/Skip/Get Started buttons.
- [ ] **T6.1** -- Create `auth_controller.dart` with Google Sign-In, mock data seeding, dev login.
- [ ] **T6.2** -- Create `login_screen.dart` with Google button and Dev Login button.
- [ ] **T6.3** -- Implement `_seedMockData()` in auth_controller with 2 clients + 3 invoices.
- [ ] **T6.4** -- Test full auth flow: Splash -> Onboarding -> Login -> Dashboard. Verify mock data in Hive.

### Dashboard

- [ ] **T7.1** -- Create `MainShellScreen` with BottomNavigationBar and IndexedStack (4 tabs, placeholder screens for tabs 1-3).
- [ ] **T7.2** -- Create `dashboard_controller.dart` with reactive stats computation and GlobalKeys.
- [ ] **T7.3** -- Create `dashboard_screen.dart` with greeting header.
- [ ] **T7.4** -- Build stat cards horizontal scroll widget.
- [ ] **T7.5** -- Build quick actions 2x2 grid.
- [ ] **T7.6** -- Build recent invoices list with status chips.
- [ ] **T7.7** -- Add Gemini FAB (placeholder -- just the button, chatbot comes in T16).
- [ ] **T7.8** -- Create `tutorial_controller.dart` with step management.
- [ ] **T7.9** -- Create tutorial overlay widget with spotlight cutout and tooltip cards.
- [ ] **T7.10** -- Test dashboard: verify stats calculate correctly from mock data, tutorial shows on first visit.

### Client Management

- [ ] **T8.1** -- Create `client_controller.dart` with CRUD operations, search, and filtered list.
- [ ] **T8.2** -- Create `client_list_screen.dart` with search, list tiles, swipe-to-delete, FAB, empty state.
- [ ] **T8.3** -- Create `add_client_screen.dart` with form, validation, dev autofill, save logic.
- [ ] **T8.4** -- Create `client_detail_screen.dart` with info header, financial summary, invoice history.
- [ ] **T8.5** -- Wire edit client (reuse add_client_screen with pre-filled data from arguments).
- [ ] **T8.6** -- Test: add client, edit client, view detail, delete client, search.

### Invoice Engine

- [ ] **T9.1** -- Create `invoice_controller.dart` with filtered list, status tabs, search.
- [ ] **T9.2** -- Create `invoice_list_screen.dart` with filter tabs, invoice tiles, status chips, FAB, empty states.
- [ ] **T10.1** -- Create `create_invoice_controller.dart` with all reactive variables, item management, recalculate logic.
- [ ] **T10.2** -- Build Invoice Header card (invoice number, dates, terms dropdown with auto due-date).
- [ ] **T10.3** -- Build Bill To card (client dropdown with detail display).
- [ ] **T10.4** -- Build Line Items card (dynamic item rows with add/remove, reactive amount calculation).
- [ ] **T10.5** -- Build Tax/GST card (toggle, rate dropdown, intra/inter-state radio).
- [ ] **T10.6** -- Build Summary card (sub total, CGST/SGST or IGST breakdown, total, payment, balance due).
- [ ] **T10.7** -- Build Notes & Terms card.
- [ ] **T10.8** -- Build bottom action bar (Save as Draft, Preview Invoice).
- [ ] **T10.9** -- Add dev autofill button with complete mock data fill.
- [ ] **T10.10** -- Implement save logic with validation, Hive persistence, invoice number generation.
- [ ] **T10.11** -- Test: create invoice with multiple items, toggle GST on/off, change rates, verify all calculations match expected values.
- [ ] **T11.1** -- Create `invoice_preview_screen.dart` with full invoice render matching the PDF layout.
- [ ] **T11.2** -- Build bottom action bar (PDF, Email, Share, Edit, Mark as Paid).
- [ ] **T11.3** -- Implement status change actions (mark as paid, send).
- [ ] **T11.4** -- Test: preview invoice, verify layout matches spec, test status changes.

### PDF and Email

- [ ] **T12.1** -- Bundle Roboto TTF fonts in `assets/fonts/`.
- [ ] **T12.2** -- Create `pdf_service.dart` with complete PDF generation matching the layout spec.
- [ ] **T12.3** -- Implement PDF header (business info + TAX INVOICE).
- [ ] **T12.4** -- Implement invoice meta section.
- [ ] **T12.5** -- Implement Bill To section.
- [ ] **T12.6** -- Implement items table with header styling.
- [ ] **T12.7** -- Implement totals summary with GST breakdown and Indian formatting.
- [ ] **T12.8** -- Implement Total In Words using number_to_words utility.
- [ ] **T12.9** -- Implement notes, authorized signature, footer.
- [ ] **T12.10** -- Test: generate PDF, open it, verify layout matches the spec and sample screenshots.
- [ ] **T13.1** -- Create `email_service.dart` with email composition.
- [ ] **T13.2** -- Wire "Send Email" button in preview screen to generate PDF then send email.
- [ ] **T13.3** -- Wire "Share" button to use share_plus with PDF file.
- [ ] **T13.4** -- Test on physical device: send invoice email, verify PDF attachment.

### Profile and Analytics

- [ ] **T14.1** -- Create `profile_controller.dart` with profile load/save, sign out.
- [ ] **T14.2** -- Create `profile_screen.dart` with user card, business form, logo picker, sign out.
- [ ] **T14.3** -- Add dev autofill button for profile.
- [ ] **T14.4** -- Test: fill profile, save, verify PDF uses profile data, test sign out flow.
- [ ] **T15.1** -- Create `reports_controller.dart` with analytics computation.
- [ ] **T15.2** -- Create `reports_screen.dart` with period selector, revenue cards, status distribution, monthly chart, top clients.
- [ ] **T15.3** -- Test: verify analytics match actual data in Hive.

### AI Chatbot

- [ ] **T16.1** -- Create `gemini_service.dart` with API call and system prompt.
- [ ] **T16.2** -- Create `gemini_chatbot_sheet.dart` with DraggableScrollableSheet chat UI.
- [ ] **T16.3** -- Wire FAB on dashboard to open chatbot sheet.
- [ ] **T16.4** -- Test: send message, receive response, verify chat history.

### Android Configuration

- [ ] **T17.1** -- Update `AndroidManifest.xml` with all required permissions and queries.
- [ ] **T17.2** -- Verify Google Sign-In configuration (or confirm mock/dev approach).

### Final Verification

- [ ] **T18.1** -- Full flow test: Splash -> Onboarding -> Login -> Dashboard (with tutorial) -> Create Client -> Create Invoice -> Preview -> Generate PDF -> Send Email
- [ ] **T18.2** -- Verify all dev autofill buttons work on every form screen.
- [ ] **T18.3** -- Verify Indian number formatting throughout (stat cards, invoice summary, PDF, preview).
- [ ] **T18.4** -- Verify invoice number auto-increments correctly across multiple invoices.
- [ ] **T18.5** -- Verify GST calculations: toggle on/off, change rates, switch CGST+SGST vs IGST.
- [ ] **T18.6** -- Verify data persists across app restarts (kill and relaunch).
- [ ] **T18.7** -- Run `flutter analyze` and fix any warnings.
- [ ] **T18.8** -- Run `dart format lib/` to ensure consistent formatting.
