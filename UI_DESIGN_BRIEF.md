# InvoGen — UI Design Brief for Stitch

## 1. App Overview

**App Name:** InvoGen  
**Platform:** Flutter (Android-first, portrait orientation)  
**Purpose:** Offline-first GST invoice generator for Indian small businesses and freelancers. Users create professional invoices, manage clients, track payments, and generate PDFs — all without an internet connection.  
**Audience:** Small business owners, freelancers, consultants in India.  
**Tone:** Professional, clean, trustworthy. Not playful or informal.

---

## 2. Design System

### 2.1 Color Palette

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#7C3AED` | Brand color, buttons, active states, accents |
| `primaryDark` | `#5B21B6` | Pressed states, dark gradients |
| `primaryLight` | `#F5F3FF` | Chips, icon backgrounds, subtle highlights |
| `accent` | `#00BFA5` | Secondary accents, teal cards |
| `accentLight` | `#E0F7FA` | Teal card backgrounds |
| `success` | `#34A853` | Paid status, positive stats |
| `warning` | `#FBBC04` | Pending amount, overdue warnings |
| `danger` | `#EA4335` | Overdue status, destructive actions |
| `draft` | `#9AA0A6` | Draft status, disabled states |
| `textPrimary` | `#202124` | Headings, important text |
| `textSecondary` | `#5F6368` | Subtitles, helper text |
| `textHint` | `#9AA0A6` | Placeholder text |
| `surface` | `#FFFFFF` | Cards, form backgrounds |
| `background` | `#F8F9FA` | Page background |

**Gradient Pairs (for stat cards):**
- Purple: `#9333EA` → `#7C3AED`
- Teal: `#00BFA5` → `#00897B`
- Green: `#34A853` → `#1E8E3E`
- Orange: `#F9AB00` → `#E37400`
- Red: `#EA4335` → `#C62828`

### 2.2 Typography

Font family: **Noto Sans** (Regular, Bold, Italic)

| Style | Size | Weight | Usage |
|---|---|---|---|
| Display | 34px | Bold | Hero numbers, large amounts |
| H1 | 28px | Bold | Page titles |
| H2 | 22px | Bold | Section titles |
| H3 | 18px | SemiBold | Card titles |
| H4 | 16px | SemiBold | Subtitles |
| Body1 | 16px | Regular | Primary body text |
| Body2 | 14px | Regular | Secondary text |
| Caption | 12px | Regular | Labels, timestamps |
| Button | 14px | SemiBold | Buttons |
| AmountLarge | 24px | Bold | Invoice totals |
| AmountMedium | 18px | Bold | Card amounts |

### 2.3 Spacing & Shape

- Base unit: 8px
- Card border radius: 16px (standard), 24px (large/hero cards)
- Button height: 52px
- Icon size: 24px (standard), 32px (avatars), 44–48px (hero icons)
- Input field border radius: 12px
- Chip border radius: 8px

### 2.4 Status Color Mapping

| Status | Background | Text | Label |
|---|---|---|---|
| Paid | `#E6F4EA` | `#34A853` | PAID |
| Sent | `#F5F3FF` | `#7C3AED` | SENT |
| Overdue | `#FCE8E6` | `#EA4335` | OVERDUE |
| Draft | `#F1F3F4` | `#9AA0A6` | DRAFT |

---

## 3. Screen-by-Screen Specification

### Screen 1: Splash Screen

**Route:** `/splash`  
**Layout:** Full-screen, centered content, gradient background

**Elements:**
- Full-screen background: vertical linear gradient from `#7C3AED` (top) to white (bottom)
- Centered logo: 108×108 rounded container (white, soft shadow) with receipt/invoice icon in primary color
- App name "InvoGen" below logo: H1, white, letter-spacing 2px
- Tagline "Professional Invoices, Simplified": Body2, white with 80% opacity
- Bottom loading indicator: 3 animated dots (white), bouncing with staggered timing

**Animations:** Logo scales in + fades → title slides up → tagline fades → dots bounce  
**No user interaction.** Auto-navigates after initialization.

---

### Screen 2: Login Screen

**Route:** `/login`  
**Layout:** Gradient background + centered white card

**Elements:**
- Background: same gradient as splash
- Top section (above card):
  - Logo (80×80, white container, rounded)
  - "InvoGen" title (H2, white)
  - Tagline (Caption, white/70%)
- White card (border radius 24px, shadow, full width with 24px margins):
  - "Welcome back" (H3, textPrimary)
  - "Sign in to continue" (Body2, textSecondary)
  - Email text field (outlined, email icon prefix)
  - Password text field (outlined, lock icon prefix, visibility toggle suffix)
  - "Sign In" button: full-width, 52px, primary gradient background, white text
  - Divider with "OR" label
  - "Continue with Google" button: full-width, outlined, Google icon + text
  - "Continue as Guest" text button (textSecondary color)
- Loading overlay (full screen dim + circular progress)

**Interactions:**
- Visibility toggle on password field
- Sign In → email auth
- Google → Google SSO
- Guest → bypass auth for demo

---

### Screen 3: Onboarding Screen

**Route:** `/onboarding`  
**Layout:** Full-screen PageView, 3 pages

**Elements per page:**
- Top-right "Skip" text button (textSecondary)
- Centered illustration area:
  - Page 1: Receipt/invoice icon in purple circle (80px icon, 160px container)
  - Page 2: People/group icon in teal circle
  - Page 3: Bar chart icon in green circle
- Title (H2, textPrimary, center-aligned)
- Subtitle (Body1, textSecondary, center-aligned, max 2 lines)
- Page dot indicators: 3 dots, active dot expands to pill shape (primary color)
- Action button (full-width, 52px):
  - Pages 1–2: "Next" (primary filled)
  - Page 3: "Get Started" (primary filled)

**Page Content:**
1. "Create Professional Invoices" / "Generate GST-compliant invoices in seconds and share them as PDFs"
2. "Manage Your Clients" / "Store client details and track all invoices for each customer"
3. "Track Payments & Revenue" / "Monitor paid, pending, and overdue invoices at a glance"

---

### Screen 4: Shell (Main Container)

**Layout:** `IndexedStack` + bottom navigation bar

**Bottom Nav Items (4):**
1. Dashboard — `dashboard` icon — label "Home"
2. Clients — `people` icon — label "Clients"
3. Invoices — `receipt` icon — label "Invoices"
4. Profile — `person` icon — label "Profile"

**Bottom Nav Style:**
- Active icon: filled variant, primary color
- Inactive icon: outlined variant, textHint color
- Active label: primary color, 12px bold
- Background: white, thin top border `#E0E0E0`
- No elevation on nav bar; use a hairline separator instead

---

### Screen 5: Dashboard Screen

**Route:** Home tab (index 0)  
**Layout:** Scrollable column

**AppBar:**
- Left: Dynamic greeting (e.g., "Good morning,") in Body2/textSecondary, user name in H3/textPrimary below
- Right: User avatar (40px circle — shows initials or photo)
- No back button. No title text in center.

**Section 1 — Stat Cards (horizontally scrollable row):**
4 cards, each 140×110px, rounded 16px, gradient backgrounds, white text:
- Card 1 (Purple gradient): "Total Revenue" / ₹ amount (AmountMedium)
- Card 2 (Teal gradient): "Clients" / count (AmountMedium)
- Card 3 (Orange gradient): "Pending" / ₹ amount (AmountMedium)
- Card 4 (Red gradient): "Overdue" / count (AmountMedium)

Each card: small icon (top-right), label (Caption, white/80%), value (AmountMedium, white).

**Section 2 — Quick Actions (2×2 grid):**
4 action cards, equal width, white background, rounded 16px, subtle shadow:
- New Invoice: purple icon bg, receipt icon, "New Invoice" label
- Add Client: teal icon bg, person-add icon, "Add Client" label
- All Invoices: green icon bg, list icon, "All Invoices" label
- Reports: orange icon bg, bar-chart icon, "Reports" label

Each card: 48px rounded icon container (colored bg), icon (24px white), label below (Body2, textPrimary).

**Section 3 — Recent Invoices:**
- Section header: "Recent Invoices" (H4, textPrimary) + "View All" link (primary color, right-aligned)
- List of up to 5 invoice tiles (white cards, 12px radius):
  - Left: small receipt icon in primaryLight circle
  - Center: invoice number (Body2, bold) + client name (Caption, textSecondary)
  - Right column: amount (Body2, bold) + status chip below
- Empty state (if no invoices): centered icon, "No invoices yet", Caption text

**FAB:** Extended FAB, bottom-right, primary gradient, sparkle/AI icon + "Ask AI" text

---

### Screen 6: Client List Screen

**Route:** Clients tab (index 1)  
**Layout:** AppBar + ListView

**AppBar (default):**
- Title "Clients" (H3)
- Right action: search icon button

**AppBar (search mode):**
- TextField replaces title (autofocus, "Search clients…" hint)
- Right action: close/X icon button

**List items (white cards, 12px radius, 8px vertical margin):**
- Left: 44px circle avatar with initials (deterministic color from name), white text
- Center: Client name (Body1, bold) + email (Caption, textSecondary) + phone (Caption, textSecondary)
- Right: invoice count badge (Body2, primaryLight bg, primary text, rounded pill) + edit icon button
- Swipe left reveals red delete action with trash icon

**FAB:** Extended, "+ Add Client", primary color

**Empty states:**
- No clients: icon + "No clients yet" + "Add your first client" button
- No search results: icon + "No results for '[query]'"

---

### Screen 7: Add / Edit Client Screen

**Route:** `/clients/add` and `/clients/edit`  
**Layout:** Scrollable form with section cards

**AppBar:**
- Title: "Add Client" or "Edit Client"
- Right action: "SAVE" text button (primary color)

**Dev Fill Button** (orange, debug builds only — place at top, below AppBar)

**Form Sections (white cards, 16px radius):**

**Card 1 — Customer Information:**
- Card title: "Customer Information" (H4)
- Field: Client Name* (text, person icon)
- Field: Email Address* (email keyboard, email icon)
- Field: Phone Number* (phone keyboard, phone icon)

**Card 2 — Billing Address:**
- Card title: "Billing Address"
- Field: Address (multiline 3 rows, location icon)

**Card 3 — Tax Information:**
- Card title: "Tax Information"
- Field: GSTIN (optional, uppercase, building icon)

**Bottom button:** "SAVE CLIENT" full-width, 52px, primary gradient

**Field style:**
- Outlined border (12px radius)
- Label above field (Caption, textSecondary)
- Required fields marked with red asterisk
- Validation errors shown below field in danger color

---

### Screen 8: Client Detail Screen

**Route:** `/clients/detail`  
**Layout:** Scrollable column

**AppBar:**
- Back button
- Title: client name
- Actions: edit icon, delete icon (danger color)

**Hero Card (gradient or white, large):**
- 64px circle avatar with initials (large)
- Client name (H2)
- Email row (icon + text)
- Phone row (icon + text)
- Address row (if present, icon + text)
- GSTIN chip (if present, small labeled pill)

**Stats Row (3 equal boxes):**
- Total Billed (primary color value)
- Collected (success color value)
- Outstanding (warning color value, or textSecondary if zero)

Each box: Caption label, AmountMedium value, white bg, 12px radius.

**"Create Invoice" button:** Full-width, 52px, primary color

**Invoice History section:**
- Section title "Invoice History" (H4)
- List of invoice tiles (same style as dashboard recent invoices)
- Empty state if no invoices

---

### Screen 9: Invoice List Screen

**Route:** Invoices tab (index 2)  
**Layout:** AppBar + filter chips + ListView

**AppBar:** Same search toggle pattern as client list. Title "Invoices".

**Status Filter Bar (horizontally scrollable, below AppBar):**
- Chips: All · Paid · Sent · Draft · Overdue
- Active chip: primary bg, white text, filled
- Inactive chip: transparent bg, textSecondary border and text
- 8px spacing between chips, 16px horizontal padding

**Invoice Cards (white, 12px radius, 8px margin):**
- Left: receipt icon in primaryLight circle (40px)
- Center top: invoice number (Body2, bold)
- Center bottom: client name (Caption, textSecondary) + date (Caption, textHint)
- Right top: amount (Body2, bold)
- Right bottom: status chip
- Swipe left → delete action (red)

**FAB:** Extended, "+ New Invoice", primary color

**Empty states:** same pattern as client list

---

### Screen 10: Create / Edit Invoice Screen

**Route:** `/invoices/create` and `/invoices/edit`  
**Layout:** Scrollable form with section cards

**AppBar:**
- Title: "New Invoice" or "Edit Invoice"
- Right actions: "SAVE DRAFT" text button (primary)

**Dev Fill Button** (orange, debug only)

**Form Section Cards (white, 16px radius):**

**Card 1 — Invoice Details:**
- Invoice Number (read-only, auto-generated, e.g. INV-000001, gray bg)
- Invoice Date (date picker, calendar icon)
- Due Date (date picker, calendar icon)
- Payment Terms (dropdown: Due on Receipt / Net 15 / Net 30 / Net 45)

**Card 2 — Bill To:**
- Client dropdown (search+select, required)
- When client selected: show client name, address, GSTIN in a subtle info box below the dropdown

**Card 3 — Items:**
- Section title + "+ Add Item" button (right-aligned, text, primary color)
- Each line item row:
  - Description field (full width)
  - Quantity + Rate fields (side by side, 40% / 40%)
  - Amount (read-only, auto-calculated, right-aligned, bold)
  - Delete icon (danger color)
- Divider between items

**Card 4 — GST Configuration:**
- "Apply GST" toggle switch
- When enabled:
  - GST % dropdown (0 / 5 / 12 / 18 / 28)
  - "Inter-state (IGST)" toggle
- Show/hide smoothly on toggle

**Card 5 — Summary (read-only):**
- Subtotal row
- GST breakdown (CGST + SGST or IGST)
- **Total row** (bold, larger)
- Payment Made field (editable, for partial payments)
- **Balance Due** (bold, primary color)

**Card 6 — Notes & Terms:**
- Notes textarea (optional)
- Terms textarea (optional, pre-filled from profile default)

**Bottom Button Row:**
- "SAVE DRAFT" (outlined, primary)
- "MARK AS SENT" (filled, primary)

---

### Screen 11: Invoice Preview Screen

**Route:** `/invoices/preview`  
**Layout:** Scrollable document-style card

**AppBar:**
- Back button
- Title: invoice number
- Actions: edit icon, share icon

**Invoice Document Card (white, 16px radius, full bleed):**

*Header section:*
- Business name (H2, primary color)
- Business address, phone, email, GSTIN (Caption, textSecondary)
- Right side: "TAX INVOICE" label (H3, bold) + status chip
- Horizontal divider

*Invoice meta (2-column grid):*
- Left: Invoice #, Invoice Date, Payment Terms
- Right: Due Date, Status

*Bill To section:*
- "BILL TO" label (Caption, uppercase, textSecondary)
- Client name (H4)
- Address, phone, email, GSTIN

*Items Table:*
- Column headers: Description, Qty, Rate, Amount (right-aligned numbers)
- Row for each item
- Thin dividers between rows

*Totals section (right-aligned):*
- Subtotal
- CGST/SGST or IGST rows (shown only if GST applied)
- **Total** (bold, larger)
- Payment Made (if > 0)
- **Balance Due** (H3, primary color)

*Amount in Words:*
- Italic caption below totals

*Notes section* (if present)

**Action Bar (sticky bottom or floating):**
- "Generate PDF" button (primary)
- "Share" icon button
- "Email" icon button
- "WhatsApp" icon button

---

### Screen 12: Invoice Details Screen

**Route:** `/invoices/details`  
**Layout:** Scrollable column

**Status Header Card:**
- Full-width card with status-based gradient background
- Large icon (check circle for paid, warning for overdue, clock for pending)
- Status message: "Invoice Paid!", "Payment Overdue", "Payment Pending"
- Total amount (Display size, white)
- Balance due (if > 0, white/80%)

**Client Card:**
- Avatar + name + email (tappable → client detail)
- Chevron right icon

**Invoice Summary Card:**
- Invoice number, date, due date
- Items count
- Quick totals

**Payment Card:**
- Payment status
- Amount paid vs total
- Payment history if any

**Action Buttons (at bottom):**
- Mark as Paid (success color)
- Generate PDF (primary)
- Share (outlined)

---

### Screen 13: PDF Viewer Screen

**Route:** `/invoices/pdf-viewer`  
**Layout:** Full-screen PDF viewer

**AppBar:**
- Back button
- Title: PDF filename
- Actions: print icon, share icon

**Body:** Native PDF preview widget (full screen)

**Error state:** Centered icon + "Could not load PDF" + retry button

---

### Screen 14: Profile Screen

**Route:** Profile tab (index 3)  
**Layout:** Scrollable form

**AppBar:**
- Title "Profile"
- Right action: "SAVE" text button (primary)

**Logo Section:**
- Centered 96px circle avatar (shows logo or initials)
- Camera icon overlay (bottom-right of circle, small white circle bg)
- "Tap to change logo" caption below

**Dev Fill Button** (orange, debug only)

**Form Section Cards (same pattern as Add Client):**

**Card 1 — Business Information:**
- Business Name* (text, building icon)
- Business Address (multiline, location icon)
- Email* (email keyboard, email icon)
- Phone (phone keyboard, phone icon)

**Card 2 — Tax Information:**
- GSTIN (optional, uppercase)
- Default GST Rate (dropdown: 0% / 5% / 12% / 18% / 28%)

**Card 3 — Invoice Defaults:**
- Default Payment Terms (dropdown: Due on Receipt / Net 15 / Net 30 / Net 45)
- Default Notes (multiline textarea)

**Sign Out Button:**
- Full-width, outlined, danger color, "Sign Out" label
- Place at bottom with 16px margin

---

### Screen 15: Reports Screen

**Route:** `/reports`  
**Layout:** Scrollable column

**AppBar:** Title "Reports", back button

**Overview Cards (2-column grid):**
- Total Invoiced (primary bg or primaryLight, large amount)
- Total Collected (success bg or successLight, large amount)

**Invoice Status Section:**
- Title "Invoice Status"
- Stacked horizontal bars (full width = 100% of all invoices):
  - Paid: success color
  - Sent: primary color
  - Draft: draft color
  - Overdue: danger color
- Legend below: colored dot + label + count + percentage

**Monthly Revenue Chart:**
- Title "Monthly Revenue (Last 6 Months)"
- Bar chart: 6 bars, labeled with month abbreviation
- Bars filled with primary gradient
- Y-axis: formatted rupee amounts
- Responsive bar heights relative to max value

**Top Clients Section:**
- Title "Top Clients by Revenue"
- List of up to 5 clients:
  - Rank number (bold, primaryLight bg)
  - Client name
  - Revenue amount (right-aligned, bold)

---

### Screen 16: Gemini AI Chat (Bottom Sheet)

**Trigger:** FAB on Dashboard  
**Layout:** `DraggableScrollableSheet` (min 40%, max 92% height)

**Header:**
- Drag handle (36×4px pill, gray, centered)
- Row: sparkle icon in gradient circle (24px) + "InvoGen AI" (H4)
- Subtitle "Powered by Gemini" (Caption, textSecondary)
- Divider

**Message Area (scrollable):**
- AI message bubble: left-aligned, white bg, textPrimary, 16px radius (sharp bottom-left)
- User message bubble: right-aligned, primaryLight bg, primary text, 16px radius (sharp bottom-right)
- Typing indicator: 3 pulsing dots in AI bubble style
- Auto-scroll to latest message

**Input Row (sticky bottom):**
- Text field (rounded, outlined, "Ask anything about invoicing…" hint)
- Send icon button (primary color, enabled only when text non-empty)

---

## 4. Reusable Component Specifications

### 4.1 Status Chip
- Pill shape, 8px horizontal padding, 4px vertical padding
- Background: semi-transparent status color (20% opacity)
- Text: status color, 11px, bold, uppercase, 0.5 letter-spacing
- No border

### 4.2 Section Card
- White background, 16px border radius
- 16px padding all sides
- Subtle shadow: `0 2px 8px rgba(0,0,0,0.06)`
- Section title (H4) at top with 8px bottom margin
- Divider after title (optional)

### 4.3 Empty State
- Centered column: icon (48px, textHint color) → heading (H4) → description (Body2, textSecondary) → optional CTA button
- 32px vertical padding

### 4.4 Avatar (Initials)
- Circle, background: deterministic color from name (cycle through: purple, teal, green, orange, red)
- Initials in white (first letter of first and last name)
- Sizes: 40px (list), 64px (detail page)

### 4.5 Input Field
- Outlined border (1.5px), `textHint` color when inactive, `primary` when focused
- 12px border radius
- Label above field (Caption, textSecondary) — NOT a floating label inside field
- Helper / error text below (Caption)
- 48px minimum height

### 4.6 Primary Button
- 52px height, full width
- Primary gradient background (left to right: `#9333EA` → `#7C3AED`)
- White text, 14px, SemiBold
- 12px border radius
- Disabled state: gray bg, gray text

### 4.7 Outlined Button
- 52px height, full width
- Transparent bg, 1.5px primary border
- Primary color text
- 12px border radius

### 4.8 Stat Card (Dashboard)
- 140×110px minimum, 16px radius
- Gradient background (unique per card)
- White icon (top-right, 20px)
- Label (Caption, white/80%) below icon
- Value (AmountMedium, white, bold) below label

---

## 5. Navigation & Flow Map

```
Splash Screen
  ↓ (auto)
  ├─ Login Screen
  │    ↓ (on auth success)
  └─ Onboarding Screen (first launch only)
       ↓ (on Get Started / Skip)

Shell (Bottom Nav Container)
  ├── Tab 0: Dashboard
  │     ├─ [Quick Action] New Invoice → Create Invoice Screen
  │     ├─ [Quick Action] Add Client → Add Client Screen
  │     ├─ [Quick Action] All Invoices → Invoices Tab
  │     ├─ [Quick Action] Reports → Reports Screen
  │     ├─ [Recent Invoice tap] → Invoice Preview Screen
  │     └─ [FAB] → Gemini AI Chat (Bottom Sheet)
  │
  ├── Tab 1: Client List
  │     ├─ [FAB] → Add Client Screen
  │     ├─ [Client tap] → Client Detail Screen
  │     │     ├─ [Edit] → Edit Client Screen
  │     │     └─ [Create Invoice] → Create Invoice Screen
  │     └─ [Edit icon] → Edit Client Screen
  │
  ├── Tab 2: Invoice List
  │     ├─ [FAB] → Create Invoice Screen
  │     └─ [Invoice tap] → Invoice Preview Screen
  │           ├─ [Edit] → Edit Invoice Screen
  │           └─ [Generate PDF] → PDF Viewer Screen
  │
  └── Tab 3: Profile
        └─ [Sign Out] → Login Screen

Standalone Screens (pushed on nav stack):
  - Reports Screen
  - PDF Viewer Screen
  - Invoice Details Screen
```

---

## 6. Interaction Patterns & Micro-interactions

- **Pull-to-refresh:** Dashboard and Invoice List support pull-to-refresh
- **Swipe-to-delete:** Client List and Invoice List items are dismissible (swipe left → red delete background with trash icon)
- **Delete confirmation:** Always show a dialog before deleting (cannot be undone)
- **Search:** Debounced 300ms, live filtering, toggle between title and search field in AppBar
- **Form validation:** Show errors inline below fields on submit
- **Toast notifications:** Snackbar at bottom for success/error messages (e.g., "Client saved", "Invoice deleted")
- **Loading states:** Show circular progress on async operations; disable buttons during loading
- **Tutorial spotlight:** First-time users see a dimmed overlay with circular cutout highlighting 4 UI areas sequentially (Stats → Quick Actions → Recent Invoices → FAB), with a tooltip card below/above

---

## 7. Accessibility & UX Guidelines

- All interactive elements minimum 48×48px tap target
- Color is never the only indicator of status (always pair with text/icon)
- Error messages are descriptive (not just "Invalid")
- Required fields are marked with * and explained
- Destructive actions (delete) always require confirmation
- Keyboard types match input (email, phone, number for respective fields)
- Screen works in portrait orientation only
- Avoid horizontal scroll except for explicitly scrollable rows (stat cards, filter chips)

---

## 8. Indian Business Context Requirements

- Currency: Indian Rupee (₹ symbol, formatted with Indian number system: lakhs/crores)
  - Example: ₹1,23,456.00 (not ₹123,456.00)
- GST display:
  - Intra-state: show CGST and SGST separately (each at half the rate)
  - Inter-state: show IGST (full rate)
  - Rates: 0%, 5%, 12%, 18%, 28%
- Invoice compliance: TAX INVOICE label, GSTIN fields for both business and client
- Amount in words: spelled out in Indian English below invoice total
- Date format: DD/MM/YYYY

---

## 9. What to Redesign vs What to Keep

### Redesign (visual layer only):
- All colors, gradients, typography
- Card layouts, spacing, shadows
- Icon choices and sizes
- Button styles, input styles
- Empty state illustrations (can use flat illustrations)
- Status chip styles
- Bottom navigation design

### Keep (logic and structure):
- Screen count and navigation routes (do not add or remove screens)
- Form fields and their order (they map to data models)
- All existing interactions and gestures
- The 4-tab bottom navigation structure
- All existing text labels and copy
- GetX state management (internal only, doesn't affect design)

---

*End of UI Design Brief — InvoGen v1.0*
