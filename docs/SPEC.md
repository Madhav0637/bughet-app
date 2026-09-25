# BudgetApp — MVP Specification

> Working name. Status: **MVP built** (all milestones complete, 2026-09-24). Spec finalized 2026-09-23.

## 1. Overview

A minimal personal expense tracker for iPhone whose core advantage is **speed of capture**. An expense is logged by double-tapping the back of the iPhone, answering three quick prompts, and it saves silently. A dashboard shows where the money went.

**Success metric:** log an expense in **under 5 seconds**, starting from an unlocked phone, without opening the app.

**Audience:** a single user (personal use). Built solo as a learning and portfolio project.

## 2. Decision log

| Area | Decision |
|---|---|
| Platform | iPhone only, native Swift, minimum iOS 26 |
| Quick entry | Back Tap → Shortcut → "On what?" → amount → category → silent save |
| Prompt style | Keep the iOS pop-up over the current screen. iOS draws the text prompt in its standard style (smaller than the number prompt) and offers no font control; a full-screen in-app entry screen was tried and rejected (2026-09-24) |
| Lock state | Quick entry works only when the iPhone is unlocked (Face ID) |
| Capture | Manual entry only (no SMS, bank, or receipt capture) |
| Data | On-device only. No backend, no login, no sync |
| Currency | INR only, whole rupees (no paise) |
| Required fields | Merchant, amount, and category, always all three |
| Category step | Always picked from the list (no auto-fill) |
| Date | Always "now" on entry; editable later in the app |
| Categories | Presets plus user-managed (add, edit, delete), each with a name and an emoji |
| Category order | Most-used first; ties sorted alphabetically |
| Category deletion | Blocked while any expense uses it; a "Move all expenses to…" action empties a category |
| Dashboard periods | Week, Month, or Year, current period only (no browsing past periods) |
| Period boundaries | Weeks start Monday, months start on the 1st |
| Dashboard display | Lists only, no charts |
| History | Full list with search (merchant) and category filter across all dates; edit and delete |
| App lock | None |
| Signing | Free Apple ID (app must be reinstalled from Xcode every 7 days) |

## 3. Scope

### In the MVP
- Quick entry through the Back Tap Shortcut
- In-app "Add expense" (same three fields)
- Dashboard: period switcher, total, category breakdown, 5 most recent expenses
- History: search, category filter, edit, swipe to delete
- Category management: add, edit, delete (blocked while in use), move all expenses to another category
- Export as a CSV spreadsheet or a PDF report, shared as a real file
- Back Tap setup guide in Settings
- Dark mode (follows the system setting)

### Out of the MVP
Income, budgets, recurring expenses, widgets, app lock, cloud sync or backup, charts, multiple currencies, paise, past-period navigation, receipts, automatic capture.

## 4. Tech stack

| Layer | Choice |
|---|---|
| Language / UI | Swift, SwiftUI |
| Persistence | SwiftData (on-device) |
| Quick entry | App Intents |
| Tests | Swift Testing |
| Tooling | Xcode 27; built and run on an iPhone 13 (iOS 26) and the simulator |
| Dependencies | None |

## 5. Architecture

```
Back Tap → Shortcut → LogExpenseIntent ──┐
                                         ├──→ Services ──→ SwiftData store
SwiftUI screens (Add/Edit, Categories) ──┘       ↑
                                                 │ read-only
SwiftUI screens (Dashboard, History) ── queries ─┘
```

- **Reads:** screens read through SwiftData queries, which refresh automatically when data changes.
- **Writes:** every change goes through a service, so the Shortcut and the app apply the same validation.
- **Calculations** (period ranges, totals, filtering, CSV and PDF) are plain functions with no UI or database code, so they can be unit-tested on their own.
- **No per-screen view models.** SwiftData queries are designed to live in views, and a view-model layer would add code without adding value at this size.
- **The intent lives in the main app target** (no separate extension). It shares the app's database and needs no paid-account capabilities.
- **Expected volume:** about 10 entries a day, roughly 3,650 a year. Aggregating a year of data in memory is fine at this scale.

## 6. Data model

### Category

| Field | Type | Rules |
|---|---|---|
| id | UUID | |
| name | String | Required; trimmed; unique regardless of case |
| emoji | String | Required; one emoji |
| expenses | [Expense] | Inverse relationship; deletion blocked while not empty |

### Expense

| Field | Type | Rules |
|---|---|---|
| id | UUID | |
| merchant | String | Required; trimmed; not empty |
| amount | Int | Whole rupees; greater than 0 |
| date | Date | Set to now on creation; editable in the app; indexed |
| category | Category | Required |

### Rules
- **Default categories**, created on first launch: 🍔 Food, 🚕 Transport, 🛍️ Shopping, 🧾 Bills, 🎬 Entertainment, 💊 Health, 📦 Other.
- **At least one category must always exist,** otherwise quick entry has nothing to offer.
- **Category order everywhere** (Shortcut list, in-app picker, Settings): number of expenses, highest first, then alphabetical. New categories start at the bottom.

## 7. Interfaces

There is no server, so there is no REST API. The app exposes one system-facing action and a set of internal services.

### LogExpenseIntent (system-facing)

| Property | Value |
|---|---|
| Title | Log Expense |
| Parameters, in order | `merchant` (text, prompt "On what?") → `amount` (whole number, prompt "Amount (₹)") → `category` (chosen from the category list, most-used first) |
| Opens the app | No |
| Authentication | Requires an unlocked device |
| Success result | None (silent) |
| Failure result | Error message, e.g. "Amount must be more than ₹0" |

### Internal services

| Service | Responsibilities |
|---|---|
| ExpenseService | Add, update, and delete expenses; validate merchant, amount, and category |
| CategoryService | Create defaults on first launch; add and edit categories; move all expenses from one category to another; delete (fails with "Used by N expenses" when not empty, or when it is the last category); return categories in usage order |
| PeriodCalculator | Return the date range of the current week (Monday start), month (1st), or year, in the device time zone |
| SpendingSummary | For a period: total, per-category amounts (highest first), and the 5 most recent expenses |
| CSVExporter | Export all expenses as CSV with columns `Date` (`yyyy-MM-dd HH:mm`), `Merchant`, `Category`, `Amount` (plain integer). Escapes commas, quotes and line breaks; prefixes text starting with = + - @ with an apostrophe |
| PDFReport | A4 report: title, date range, total, spending by category with percentages, and a paginated table of every expense |
| ExportWriter | Writes a CSV or PDF to a dated file (`BudgetApp-expenses-yyyy-MM-dd.csv` / `.pdf`) so the share sheet keeps the extension |
| HistoryFilter | Merchant search (ignores case and accents), category filter, grouping by day, day titles |

### Formatting
Amounts are shown as `₹` with Indian digit grouping and no decimals, e.g. `₹1,23,456`.

## 8. Screens and flows

### Quick entry
1. Double-tap the back of the iPhone (phone unlocked)
2. "On what?" → type the merchant → Done
3. "Amount (₹)" → type the amount on the number pad → Done
4. Category list → tap one → saved silently

### Tab 1: Dashboard
- Week / Month / Year segmented control. Defaults to Month and remembers the last choice.
- Large total for the current period, e.g. `₹12,340`
- Category breakdown: emoji, name, and amount, highest first
- The 5 most recent expenses, with "See all" linking to History
- Empty state: "No expenses this month. Double-tap the back of your iPhone to add one."
- A **+** button opens Add Expense

### Tab 2: History
- Search by merchant (case-insensitive, all dates)
- Category filter; can be combined with search
- List grouped by day, newest first
- Swipe to delete; tap to open Edit Expense
- A **+** button opens Add Expense

### Tab 3: Settings
- **Categories:** list in usage order, showing each category's expense count. Tap a category to edit its name and emoji, or use "Move all expenses to…". Delete is blocked while the category is in use and points to the move action.
- **Export Data:** choose Spreadsheet (CSV) or Report (PDF); the file opens in the share sheet
- **Set up Back Tap:** step-by-step guide:
  1. In the Shortcuts app, create a shortcut containing the "Log Expense" action
  2. Go to Settings → Accessibility → Touch → Back Tap → Double Tap and pick that shortcut

### Add / Edit Expense
- **Add:** merchant, amount, and category. Save stays disabled until all three are valid.
- **Edit:** the same fields plus a date picker.

## 9. Project structure

```
budget-app/
├── BudgetApp.xcodeproj
├── BudgetApp/
│   ├── App/           # App entry point, ModelContainer setup
│   ├── Models/        # Expense, Category
│   ├── Services/      # ExpenseService, CategoryService, PeriodCalculator,
│   │                  # SpendingSummary, HistoryFilter, CSVExporter, PDFReport, ExportWriter
│   ├── Intents/       # LogExpenseIntent, CategoryEntity + query
│   ├── Features/
│   │   ├── Dashboard/
│   │   ├── History/
│   │   ├── ExpenseForm/
│   │   └── Settings/  # Categories, Export, Back Tap guide
│   └── Shared/        # INR formatting, reusable views
├── BudgetAppTests/    # Service and calculation tests
├── docs/              # SPEC.md, screenshots
└── tools/             # make-app-icon.swift
```

## 10. Build plan

| # | Milestone | Done when | Status |
|---|---|---|---|
| 0 | Setup | Xcode project created; a blank app runs on the iPhone with free signing | ✅ |
| 1 | **Back Tap prototype** | Back Tap logs an expense on the iPhone without opening the app, and it appears in a plain list (see §11) | ✅ |
| 2 | Data layer and tests | Models, services, validation, default categories, PeriodCalculator, SpendingSummary, all unit-tested | ✅ |
| 3 | In-app entry and History | Add/Edit screens, search, category filter, delete | ✅ |
| 4 | Dashboard | Period switcher, total, category breakdown, recent list | ✅ |
| 5 | Category management | Add, edit, move-all, delete rules; the intent's category list reflects changes and usage order | ✅ |
| 6 | Export and polish | CSV and PDF export, empty states, Back Tap guide, dark mode check, app icon | ✅ |
| 7 | Showcase | README with architecture diagram, screenshots, Back Tap demo GIF | ✅ (demo GIF to add once recorded on the iPhone) |

## 11. Risks to verify in Milestone 1

All verified on the iPhone on 2026-09-24:

- ✅ The intent asks for its parameters in declaration order (merchant → amount → category)
- ✅ The amount prompt shows a number pad
- ✅ The intent runs without opening the app
- ✅ Back Tap can select the shortcut that contains "Log Expense"
- ✅ Total time from Back Tap to saved is about 5 seconds

Still to confirm over time:
- Free provisioning: after the 7-day expiry, re-running from Xcode keeps existing data (**never delete the app from the phone**)

## 12. Android version

> Status: **built** (all milestones complete, 2026-09-25). Lives in the `Android/` folder of this repo; the iOS app is unchanged.

### Decision log

| Area | Decision |
|---|---|
| Scope | Same features and rules as the iOS app (sections 2–8): INR whole rupees, on-device only, same 7 default categories, unique names, delete blocked while in use, most-used first, Monday-start weeks, silent save, unlocked only |
| Stack | Kotlin, Jetpack Compose, Room, ViewModels; JUnit for logic and instrumented tests for the database; `android.graphics.pdf.PdfDocument` for PDF; only Google's Jetpack libraries |
| Device support | Android 8.0 (API 26) and newer, about 97% of phones in use; targets API 37 |
| Package | `com.madhav0637.budgetapp` (same as the iOS bundle ID) |
| Distribution | Personal use, installed from Android Studio; no Play Store for now |
| Testing | Android emulator for now (a real phone is needed only for brand-specific gestures) |

### Quick entry on Android

No hardware gesture exists on every Android phone, and apps can't listen to the power button. So quick entry is reachable in layers:

| Entry point | Availability |
|---|---|
| **Quick Settings tile** "Log Expense" | Every Android phone (7.0+) |
| **Launcher shortcut**: long-press the app icon → Log Expense (can be pinned to the home screen) | Every Android phone |
| **Brand gestures**: Samsung side-button double press, Pixel Quick Tap, and similar settings on other brands | Most phones; set the gesture to open the separate **"Log Expense"** launcher entry |

The "Log Expense" entry is a second launcher icon that opens straight into the pop-up. It exists because brand gesture settings can open an app but not a specific screen. The cost is a second icon in the app drawer, which was accepted.

**The pop-up** is the app's own translucent window drawn over whatever app is on screen, not a full-screen app. It has the same three steps as iOS (On what? → Amount → Category), and **both text steps use the same big, bold style**, which iOS's system prompts could not offer.

### Build plan

| # | Milestone | Status |
|---|---|---|
| A0 | Android Studio project, runs in the emulator | ✅ |
| A1 | Quick-entry pop-up, Room database, tile, launcher shortcut, "Log Expense" entry | ✅ |
| A2 | Rules and calculations ported from iOS, with JVM and on-device tests | ✅ |
| A3 | History: search, category chips, day headings, swipe to delete with Undo, edit sheet | ✅ |
| A4 | Dashboard and bottom tab bar | ✅ |
| A5 | Settings tab and category management | ✅ |
| A6 | CSV/PDF export, quick-entry setup guide, green ₹ icon | ✅ |
| A7 | README covering both apps | ✅ |

**Tests:** 46 JVM tests for the domain layer and 18 on-device tests against an in-memory Room database.

