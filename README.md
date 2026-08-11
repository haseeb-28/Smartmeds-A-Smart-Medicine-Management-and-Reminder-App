# SmartMeds — Module 1: Authentication + Module 2: Dashboard

Flutter + Supabase Auth + Riverpod implementation of the Authentication
and Dashboard modules from the SmartMeds PRD.

## Module 1 — Authentication

- Register (name, email, password, confirm password)
- Login
- Forgot Password (email reset link)
- Email Verification (auto-detects verification via polling + resend)
- Remember Login (Supabase persists the session locally by default —
  `AuthGate` in `main.dart` reads it on launch and routes accordingly)
- Logout (clears session, drops back to Login)

## Setup

1. Create a Supabase project at https://supabase.com
2. In **Project Settings → API**, copy your Project URL and anon/public key
3. Paste them into `lib/core/services/supabase_service.dart`:
   ```dart
   static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```
4. In Supabase Dashboard → Authentication → URL Configuration, add:
   - `io.smartmeds.app://email-verified`
   - `io.smartmeds.app://reset-password`
   as redirect URLs (or your actual deep link scheme once you configure one).
5. Run:
   ```bash
   flutter pub get
   flutter run
   ```

## Module 2 — Dashboard

- Greeting header (time-of-day aware: Good Morning/Afternoon/Evening)
- Today's Progress ring card + current streak
- 7-day mini calendar strip (taken/missed/upcoming color coding)
- Weekly adherence + longest streak stat tiles
- Today's Medicines list with status icons
- Quick Add FAB (stubbed — wires to Module 3 once it exists)
- Pull-to-refresh

**Important — this module currently runs on mock data.** `dashboard_provider.dart`
returns hardcoded `DashboardSummary` data because Module 3 (Medicines) and
Module 4 (Reminders) don't exist yet. The `DashboardSummary` model shape is
deliberately stable so that once those modules are built, only the provider's
internals need to change — none of the UI widgets should need to change.

## Module 3 — Medicine Management

- Add / Edit / Delete medicine
- Pause / Resume / Archive medicine
- Fields: name, brand name, generic name, dosage form (tablet/capsule/injection/syrup/drops), meal timing (before/after/with food/anytime), quantity, start date, optional end date, notes
- Medicine list screen split into Active / Paused sections, swipe-to-delete, low-stock and out-of-stock indicators
- Medicine detail screen with pause/resume/archive/delete actions
- Dashboard's "Quick Add" FAB and "See All" now open real Module 3 screens instead of stubs

**Requires a Supabase table.** Run `supabase/002_medicines_table.sql` in your
Supabase project's SQL Editor before testing this module — it creates the
`medicines` table, an `updated_at` trigger, Row Level Security policies (so
each user only ever sees their own medicines), and a public storage bucket
for future medicine images.

**Still mock data on the Dashboard.** `dashboard_provider.dart` still returns
hardcoded progress/streak numbers — that data depends on the
`medicine_schedule` and `medicine_history` tables from Module 4 (Reminders)
and Module 5 (Confirmation), which don't exist yet. Medicines you add in
Module 3 will show up correctly in the Medicine List, just not yet reflected
in the Dashboard's progress ring.

## Module 4 — Reminder System

- Add reminder times per medicine via presets (Morning/Afternoon/Evening/Night) or a custom time picker
- Local notifications scheduled via `flutter_local_notifications`, repeating daily at the set time
- Notification actions: **Take Now**, **Skip**, **Snooze 10m** (buttons on the notification itself)
- "Today's Medicines" on the Dashboard is now real: it queries `medicine_history` instead of mock data
- Dashboard's progress ring, weekly adherence %, streak, and 7-day calendar strip are all computed from real dose data
- "Manage Reminders" button added to Medicine Detail (Module 3) screen

**Requires a second Supabase migration.** Run `supabase/003_reminders_table.sql`
after `002_medicines_table.sql` — it adds `medicine_schedule` (reminder times)
and `medicine_history` (actual dose events + their taken/missed/skipped status).

**Platform setup needed before notifications will fire — this is not optional:**

*Android* (`android/app/src/main/AndroidManifest.xml`), inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```
And inside `<application>`, register the notification receiver (see the
`flutter_local_notifications` package README's "Android setup" section —
this project uses `zonedSchedule` with `exactAllowWhileIdle`, which needs
the exact-alarm permission granted at runtime on Android 12+).

*iOS*: enable the "Push Notifications" and "Background Modes → Remote
notifications" capabilities in Xcode. No further code changes needed —
permission is requested automatically in `NotificationService.initialize()`.

**Known limitation — read before assuming reminders "just work":** today's
dose entries (`medicine_history` rows) are currently created lazily / not
yet auto-generated. There is no scheduled job that turns "8:00 AM reminder"
into "today's 8:00 AM dose row" automatically. In production this belongs in
a Supabase Edge Function (cron) that runs once daily and inserts a
`medicine_history` row for every active schedule. Right now, `ReminderRepository.createDoseEntry()`
exists and works, but nothing calls it automatically yet — that's the
natural next piece of work, likely alongside Module 5 (Confirmation UI).

## Module 5 — Medicine Confirmation

This closes the gap flagged at the end of Module 4. Three things now happen
automatically that didn't before:

1. **Today's doses actually get created.** `ReminderRepository.generateTodayDoseEntries()`
   runs on every dashboard load — it checks all active schedules and creates
   a `medicine_history` row for any that don't have one yet today.
2. **Overdue doses auto-mark as missed.** `autoMarkOverdueMissed()` runs
   alongside it, flipping anything still "upcoming" more than 30 minutes
   past its scheduled time to "missed" (30 min mirrors the grace window
   Module 12's caregiver alerts will use later).
3. **Notification button taps actually do something.** `notification_action_handler.dart`
   wires Take Now / Skip / Snooze 10m directly to Supabase — including when
   the app is backgrounded or killed, since it talks to the repository
   directly rather than through Riverpod (there may be no live widget tree
   when the OS delivers the action).

Also added:
- **Take Now / Skip buttons directly on the Dashboard** — for when the user
  opens the app instead of responding to the notification
- **Stock actually decrements** on confirmed doses (both from in-app buttons
  and notification taps) — the `decrementStock()` hook built in Module 3 is
  now actually called

**Known simplification, stated plainly:** stock decrements by 1 unit per
confirmed dose regardless of how many units that dose actually is (e.g. "2
tablets" still only decrements by 1). Fixing this needs a units-per-dose
field added to `MedicineSchedule`, which is a reasonable small follow-up
rather than something blocking this module.

**Still relying on the app being opened** to generate today's doses and
catch overdue ones — there is still no server-side cron doing this
independent of the user opening the app, which matters once Module 12
(Caregiver Alerts) needs to notify someone else about a missed dose even if
the patient never opens SmartMeds that day. A Supabase Edge Function on a
daily/hourly schedule is still the right eventual fix; noting it again here
since Module 5 doesn't remove that dependency, it just makes today's app-open
path fully functional.

## Module 6 — Daily Progress

- Today tab: Morning/Afternoon/Evening/Night breakdown with a check/cross/skip
  icon per slot, plus an overall completion ring (e.g. "67% — 2 of 3 taken")
- Weekly tab: last 7 days as a bar chart, color-coded by adherence (green
  ≥80%, orange ≥50%, red below that)
- Monthly tab: current month bucketed into weekly bars, same color coding
- Reachable from the Dashboard two ways: tapping the Progress ring card, or
  the new insights icon in the app bar

**Design note:** time-of-day slots (Morning/Afternoon/Evening/Night) are
classified purely by the hour of `scheduled_time` (5am–12pm = Morning, etc.),
not by the reminder's `label` field from Module 4. This means a "Custom"
reminder at 9am still shows up correctly under Morning here, without needing
a join back to `medicine_schedule`. Bar charts are hand-rolled (`Container`
heights, no charting package) to avoid adding a dependency for something this
simple — fine for weekly/monthly bar counts, but would need a real charting
library if Module 14 (full Statistics with pie/line charts) wants something
more elaborate.

## Module 7 — Calendar

- Full month grid, color-coded per day: green = all doses taken, red = at
  least one missed, yellow/orange = at least one skipped (missed takes
  priority over skipped if a day has both, since it's the more important
  signal to surface)
- Month navigation with prev/next arrows
- Tap any day with doses on it to open a bottom sheet showing that day's
  complete dose history (medicine, time, status)
- Days with no doses at all render as plain uncolored cells and aren't
  tappable — nothing to show
- Reachable from the Dashboard two ways: "View Calendar" link, or tapping
  the mini 7-day strip directly

**Reuses the same dominant-status logic as Module 6**, just extended from a
7-day strip to a full month grid and from "compute on the fly" to "also
let the user drill into any individual day's history" — no new database
tables needed, this is purely a different view over `medicine_history`.

## Module 8 — Medicine History

- Search by medicine name (client-side, applied on top of server-filtered results)
- Filter sheet: date range, medicine, status (Taken/Missed/Skipped/Upcoming),
  with an active-filter count badge on the filter icon
- Export to **CSV** or **PDF**, respecting whatever filters are currently
  applied — export what you're looking at, not everything
- Reachable from the new History icon in the Dashboard app bar

**New packages added:** `pdf` + `printing` (PDF generation and the native
share/print sheet), `share_plus` (CSV sharing), `path_provider` (temp file
location for the CSV before sharing). Run `flutter pub get` after pulling
this module.

**Filtering split between server and client, worth understanding if you
extend this:** date range, medicine, and status filters run as real Supabase
queries (indexed, cheap). The text search box, however, filters client-side
across whatever the server query already returned — it can't search medicine
names that were filtered out by other criteria first, and at very large
history volumes (thousands of rows) this client-side step would need to move
server-side via a Postgres function or a `medicines.name.ilike` filter on
the embedded resource. Not a concern at personal-app scale, worth knowing
before assuming it scales indefinitely.

**Export service lives in `core/services/export_service.dart`, not inside
the history feature** — deliberately, since Module 14 (Reports) will very
likely want the same CSV/PDF export for weekly/monthly/adherence reports
rather than duplicating this logic.

## Module 9 — Medicine Stock

Most of the actual stock *tracking* already existed — `quantity_total` /
`quantity_remaining` on the medicines table (Module 3) and `decrementStock()`
firing on every confirmed dose (Module 5). This module adds the piece that
was still missing: **alerts and a dedicated stock view.**

- Stock screen listing every medicine sorted lowest-stock-first, so
  anything needing attention is always at the top
- Visual stock bar per medicine (green/orange/red by level)
- A banner counting how many medicines currently need attention
- **Refill action** — add units to both `quantity_total` and
  `quantity_remaining` in one step
- **Automatic alerts**, now actually wired: `MedicineRepository.decrementStock()`
  fires a real notification the moment stock crosses into low (≤5 units) or
  out-of-stock (0), matching the PRD's "Only 5 tablets remaining" /
  "Out of Stock" notifications. This fires from **wherever** stock changes —
  in-app Take Now button or a notification action tap — since the alert
  logic lives in the repository, not duplicated at each call site.
- Reachable from the new Stock icon in the Dashboard app bar

**One deliberate behavior worth knowing:** the low-stock alert only fires on
the *transition* into low stock, not on every single dose taken while
already low. Otherwise a medicine sitting at 3 remaining for a week would
notify you daily, which stops being useful fast. Out-of-stock still fires
every time stock hits exactly 0 from above, since a "just ran out" alert
matters each time it happens, not just the first.

## Module 10 — Prescription Manager

- Upload photos (camera or gallery) categorized as Blood Test, X-Ray,
  Prescription, or Others — matching the PRD's categories exactly
- Grid view with category filter, tap any document for a full-screen
  zoomable preview
- Delete removes both the storage file and its database row

**Files are stored privately, not publicly** — this is a deliberate
difference from Module 3's medicine-image bucket. Prescriptions are
sensitive medical documents, so `supabase/004_prescriptions_table.sql`
creates the `prescriptions` storage bucket with `public: false` and RLS
policies scoped to `{user_id}/...` folders. Viewing a file works via a
short-lived signed URL (`getSignedUrl()`, 1 hour by default) generated
fresh each time, rather than a permanent public link.

**Requires a third Supabase migration.** Run `supabase/004_prescriptions_table.sql`
after `003_reminders_table.sql`.

**New packages:** `image_picker` (camera/gallery access) and `uuid`
(unique storage filenames). Both need platform permission entries:

*Android* (`AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

*iOS* (`Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>SmartMeds needs camera access to photograph prescriptions and lab reports.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>SmartMeds needs photo library access to attach existing prescription images.</string>
```

**Scoped down from the PRD, stated plainly:** this module handles photos
only (camera/gallery via `image_picker`), not arbitrary PDF/document
uploads. "Doctor Notes" and "Lab Reports" as PDFs would need `file_picker`
added on top of this — a reasonable follow-up, not included here to avoid
stacking a second file-selection package on the first pass.

## Module 11 — Family Profiles

This is the first module that changes the data model rather than adding a
new isolated feature, so read this section fully before assuming
everything is scoped correctly — some things are, some explicitly aren't yet.

**New concept:** one Supabase account can now manage multiple *profiles*
(Myself, Mother, Father, etc.) — not separate logins, just rows the account
holder manages, matching the PRD's "Son manages Mother's medicines" model.
A horizontal profile switcher now sits on the Dashboard; whichever profile
is selected there drives what the rest of the app shows.

**What IS profile-scoped now (verified, not just added-and-hoped):**
- **Medicines** (Module 3) — `fetchActiveAndPaused`/`fetchArchived` now
  require a `profileId`; adding a medicine tags it with the currently
  selected profile
- **Today's doses, weekly adherence, streak, 7-day calendar strip**
  (Modules 4/5/6's Dashboard-facing data) — `ReminderRepository`'s queries
  now join through `medicines!inner(profile_id)` and filter on it
- **Prescriptions** (Module 10) — same treatment, `profile_id` required on
  upload and fetch
- **Stock** (Module 9) — scoped "for free," since it reads from the same
  `medicineListProvider` that Medicines uses

**What is NOT profile-scoped yet — stated plainly, not buried:**
- **Medicine History screen (Module 8)**, **Calendar screen (Module 7)**,
  and the **Progress screen's Weekly/Monthly tabs (Module 6)** still query
  `medicine_history` filtered only by `user_id`, not by profile. Right now
  switching profiles on the Dashboard does NOT change what these three
  screens show — they'll display every family member's combined history
  mixed together. This needs the same `medicines!inner(profile_id)` filter
  pattern already applied in `reminder_repository.dart`, applied to
  `history_repository.dart`, `calendar_repository.dart`, and
  `progress_repository.dart`. Not done here to keep this module's diff
  reviewable rather than touching every repository in one pass.

**Deletion behavior worth knowing:** deleting a family member cascades
(via `on delete cascade` in the SQL) to *all* of that profile's medicines,
schedules, dose history, and prescriptions. The confirmation dialog says
this, but it's a real, unrecoverable cascade — not a soft delete.

**Requires a fourth Supabase migration** — and this one is different from
the others: it includes a data backfill, not just new tables.
`supabase/005_family_profiles.sql` creates `family_members`, adds
`profile_id` to `medicines` and `prescriptions`, and — critically — creates
a "Myself" profile for every existing user and points their existing data
at it, so nothing already in the app disappears after running this
migration. Read the migration before running it if you have real data in
a shared/staging project.

## Module 12 — Caregiver Support

The PRD's original framing (separate Patient and Caregiver logins, one
account getting notified about a different account's data) doesn't fit
this app's actual architecture — Module 11 built *one account managing
multiple profiles*, not separate logins per family member. So this module
adapts the PRD's intent to that reality: **the account holder is the
caregiver**, and gets a distinctly-named alert whenever a family member's
(non-self) dose goes unconfirmed past the grace window.

- `NotificationService.showCaregiverAlert()` — a notification worded
  exactly like the PRD's example: *"Mother missed a dose — Mother missed
  their 2:00 PM Metformin."* Deliberately separate from the generic
  Module 9 stock alert and Module 4 dose-reminder notifications, both in
  wording and in its own Android notification channel (`caregiver_alerts`)
  so a user can mute/prioritize it independently in system settings.
- Fires from `ReminderRepository.autoMarkOverdueMissed()` the moment a
  dose crosses the 30-minute grace window — but explicitly skipped for
  `is_self = true` profiles, since alerting yourself that you missed your
  own dose isn't "caregiver support," it's just Module 5's normal missed-
  dose handling.
- **Checks every profile on the account, not just the one currently
  selected** — `checkMissedDosesAcrossAllProfiles()` runs on every
  dashboard load regardless of which profile is active. This was a real
  gap I closed rather than left as a caveat: without it, a caregiver
  looking at their own "Myself" profile would never find out Mother
  missed a dose unless they happened to switch to her profile at the
  right moment.

**Still a real, unresolved limitation — not glossed over:** this only
checks when *someone opens the app*. There is still no server-side cron
(Supabase Edge Function) generating dose entries and checking for misses
independently of app opens — flagged since Module 4, still true here. For
a caregiver who doesn't open the app themselves that day, no alert fires,
because nothing runs to detect the miss in the first place. This is the
single most important piece of infrastructure still missing for Module 12
to work as a caregiver would actually expect — solving it properly needs
a scheduled Edge Function, not another client-side patch.

**No dedicated screen for this module** — the PRD describes it purely as
a notification behavior (Patient/Caregiver relationship → alert), not a
UI surface, so nothing was added to the folder structure here.

## Module 13 — Elderly Mode

A single toggle (Accessibility screen, reachable from the Dashboard's
overflow menu) that changes how the whole app looks and behaves — stored
locally via `shared_preferences` since it's a device display preference,
not account data that needs to sync.

**How each PRD item was actually implemented, not just checked off:**
- **Large Font** — driven mainly by `MediaQuery`'s `textScaler` set to 1.3x
  in `main.dart`'s `MaterialApp.builder`. This matters because most screens
  in this app use hardcoded `TextStyle(fontSize: ...)` rather than
  `Theme.of(context).textTheme` — a `ThemeData` text-theme scale alone
  wouldn't have reached them. `MediaQuery` scaling applies at the render
  layer to every `Text` widget regardless, which is what actually makes
  this apply app-wide with zero changes to the ~15 existing screens.
- **Large Buttons** — `AppTheme.elderly()`'s button themes set an 88×60
  minimum size app-wide.
- **High Contrast** — `AppTheme.elderly()` swaps in pure black-on-white
  instead of the softer greys used elsewhere.
- **Simple Navigation / Minimal Interface** — the Dashboard conditionally
  renders `ElderlyDashboardView` instead of the normal layout: no calendar
  strip, no stats row, no progress ring — just today's pending medicines
  with two large Take/Skip buttons each. Every other screen (Progress,
  History, Calendar, Stock, Prescriptions, Family) is unchanged and still
  reachable from the same overflow menu — Elderly Mode simplifies the
  primary screen, it doesn't remove functionality from the rest of the app.
- **Voice Feedback** — `VoiceFeedbackService` (built on `flutter_tts`)
  speaks short confirmations ("Metformin taken. Well done.") when a dose
  is confirmed or skipped, and confirms when the mode itself is switched on.

**Deliberately narrow scope on Voice Feedback, stated plainly:** this
speaks a handful of specific confirmation moments, not the whole UI. Full
screen-reader-style narration of every screen would mean reimplementing
something close to platform accessibility support (TalkBack/VoiceOver),
which is a much larger effort than one module reasonably covers — for
that level of support, the right answer is ensuring proper Semantics
labels throughout so the *platform's own* screen reader works, which
hasn't been audited here.

**New packages:** `shared_preferences` (local toggle persistence) and
`flutter_tts` (voice feedback). No platform permission setup needed for
either — TTS uses the OS's built-in engine.

## Module 14 — Statistics

A deeper reporting layer than Module 6's Progress screen — same underlying
`medicine_history` data, different lens. Reachable from the Dashboard menu
as "Statistics," separate from "Progress."

**How this differs from Module 6, concretely, not just in name:**
- **Medicine Adherence %** and **Missed Medicines count** as explicit stat
  cards, not just implied by a progress ring
- **Average Delay** — genuinely new: average minutes between scheduled
  time and actual confirmation time for taken doses (`responded_time -
  scheduled_time`), shown as "Xm late" / "Xm early" / "On time"
- **Longest Streak** here is a *true* longest-ever streak, scanning all
  history — not the same number as the Dashboard's streak, which only
  looks at the last 7 days. These two numbers can legitimately differ, and
  that's correct, not a bug: they're answering different questions ("how
  am I doing lately" vs. "what's my best-ever run").
- **Pie chart** (status breakdown: taken/missed/skipped) and **line chart**
  (daily adherence trend over the period) — added `fl_chart` for these
  specifically, since hand-rolling pie/line charts well (the way Module 6's
  simple bars were hand-rolled) is meaningfully harder to get right than a
  bar chart, and this was flagged back in Module 6 as the point where a
  real charting library would become worth it.
- Week / Month / All Time period selector

**This module's queries ARE profile-scoped from the start** (joins through
`medicines!inner(profile_id)`, same pattern as `reminder_repository.dart`)
— unlike the Module 8/7/6 gap flagged back in Module 11, which is still
open. Statistics didn't inherit that gap because it's new code written
after the profile-scoping pattern already existed, not because the earlier
gap got fixed.

**Growing menu, worth flagging:** the Dashboard's overflow menu is now 7
items (Progress, Statistics, History, Stock, Prescriptions, Family,
Accessibility). Still usable, but this is close to where a drawer or
bottom navigation would serve better than a single popup menu — a UX
call worth revisiting once the module list is closer to done rather than
mid-build.

## Module 15 — Offline Support

**Read this section before assuming "offline support" means what the PRD's
tech-stack section originally implied.** The PRD lists Drift/SQLite as the
local database, which points toward a genuine offline-first architecture —
every table mirrored locally, every repository reading/writing local-first
and syncing in the background. That's a rewrite of every repository built
across Modules 3–14, not an incremental module. What's built here instead
is a **scoped, pragmatic version** covering the PRD's explicitly-listed
offline features, using `shared_preferences` for caching rather than a
real local database.

**What actually works offline, verified by tracing the code path:**
- **View medicines** — `MedicineListController` caches the medicine list
  on every successful fetch and falls back to that cache on failure
- **View today's doses** — same pattern in `TodayDosesController`
- **Mark taken / skipped while offline** — the confirmation still applies
  optimistically to local UI state immediately (same as online), and gets
  queued via `OfflineQueueService` instead of failing silently
- **Receive reminders** — this one was already true before this module,
  worth noting explicitly: Module 4's dose reminders are scheduled via
  `flutter_local_notifications`, which fires from the OS's own alarm
  system, not a network call. Reminders already worked offline; this
  module didn't need to do anything for that PRD line item.
- **Automatically sync when internet returns** — two mechanisms, covering
  two different real scenarios: an opportunistic sync at the start of
  every dashboard load (covers "reopened the app after being offline"),
  and a `ConnectivityService` stream listener set up once in `main.dart`
  (covers "app stayed open and reconnected mid-session," which the
  opportunistic-only approach would miss)

**What does NOT work offline — stated plainly, not glossed over:**
- **Generating today's doses in the first place.** `generateTodayDoseEntries()`
  is a write to Supabase — if it's never succeeded once since the device
  went offline, there's nothing to view offline yet for that day. The
  cache only helps if there was at least one successful online load first.
- **History, Calendar, Statistics, Prescriptions** — none of these read
  from cache; they're online-only, same as before this module.
- **Adding/editing medicines, uploading prescriptions, managing family
  profiles** — deliberately NOT queued for offline sync. Only dose
  confirmations are queued, since that's the one write a patient
  realistically can't defer mid-outage; the rest can reasonably wait
  until the connection is back.
- **Conflict handling is naive.** If a dose gets modified from another
  device while an offline queued action is pending, the queued action
  just overwrites whatever's there when it replays — there's no
  last-write-wins timestamp comparison or conflict UI.
- `ConnectivityService` reports whether the device *thinks* it has a
  network connection, not whether Supabase is actually reachable — a
  captive portal or DNS issue could still show "online."

**New package:** `connectivity_plus`. No platform permission setup needed.

## Module 16 — Settings

The last core PRD module — and several earlier modules referenced a
Settings screen that didn't exist yet, so this closes those loose ends too.

**Appearance**
- **Dark Mode** — Light / Dark / System, persisted like Elderly Mode.
  Precedence rule worth knowing: if Elderly Mode (Module 13) is also on,
  Elderly Mode's high-contrast light theme always wins — the two aren't
  designed to compose. A "dark elderly mode" was judged not worth the
  added theme-matrix complexity for this app's scope.
- **Language** — the picker is real and persists a choice, but only
  English actually changes anything. The other three languages listed
  render disabled with a "Coming soon" badge rather than silently doing
  nothing when picked. Retrofitting real i18n now would mean wrapping
  every hardcoded string across all 16 modules in `flutter_localizations`
  + ARB files — a large, separate effort, not something to fake here.

**Notifications**
- **Notification Sound** and **Reminder Volume** — both are real,
  persisted preferences, but **neither is currently wired into how
  notifications actually play.** Being direct about why: Android
  notification channels (`medicine_reminders`, `stock_alerts`,
  `caregiver_alerts` — all created back in Modules 4/9/12) are immutable
  once created; changing their sound requires deleting and recreating the
  channel with a new id, which isn't done here. Per-app notification
  volume also isn't something `flutter_local_notifications` exposes
  directly — it's governed by the device's own notification/alarm volume
  in system settings. These preferences are stored for real so the wiring
  can be finished later without another data migration, but flipping
  them right now won't audibly change anything yet.

**Data**
- **Backup** — exports medicines + dose history as JSON via the share
  sheet, reusing `ExportService` from Module 8. Explicitly export-only:
  there's no restore/import flow, and this isn't an automatic cloud
  backup — Supabase already is the source of truth and is backed up
  server-side by Supabase itself. This exists for the PRD's line item as
  a manual "take your data with you" snapshot.

**Account**
- **Account screen** — email, member-since date, change password (via
  Supabase Auth directly), logout
- **Delete Account** — this is the one piece that genuinely can't be done
  from Flutter code alone, and it's not faked here. Deleting an
  `auth.users` row requires the Supabase `service_role` key, which must
  never ship inside a client app. The Flutter side calls a Supabase Edge
  Function (`supabase.functions.invoke('delete-account')`); the function
  itself lives at `supabase/functions/delete-account/index.ts` as
  reference source and **is not deployed by anything in this repo** — it
  needs `supabase functions deploy delete-account` run separately via the
  Supabase CLI, with the service role key configured as a function
  secret. Deleting the account cascades to every family profile,
  medicine, schedule, dose history row, and prescription via the same
  `on delete cascade` foreign keys already in the SQL migrations —
  confirmed with an explicit warning dialog before it's called.

**Housekeeping done alongside this module:** the Dashboard's navigation
was converted from the overflow popup menu (8 items would have been one
too many, per the note flagged back in Module 14) to a proper `Drawer` —
same destinations, room to keep growing. Logout moved from an app bar icon
into the drawer.

## Folder structure

```
lib/
├── core/
│   ├── services/supabase_service.dart
│   └── constants/auth_validators.dart
├── features/
│   └── authentication/
│       ├── data/auth_repository.dart
│       ├── providers/auth_provider.dart
│       └── presentation/
│           ├── screens/
│           │   ├── login_screen.dart
│           │   ├── register_screen.dart
│           │   ├── forgot_password_screen.dart
│           │   └── email_verification_screen.dart
│           └── widgets/
│               ├── auth_text_field.dart
│               └── auth_button.dart
├── features/
│   └── dashboard/
│       ├── data/dashboard_models.dart
│       ├── providers/dashboard_provider.dart
│       └── presentation/
│           ├── screens/dashboard_screen.dart
│           └── widgets/
│               ├── dashboard_drawer.dart
│               ├── greeting_header.dart
│               ├── progress_card.dart
│               ├── mini_calendar_strip.dart
│               ├── stats_summary_row.dart
│               ├── upcoming_medicine_list.dart
│               └── section_header.dart
├── features/
│   └── medicines/
│       ├── data/
│       │   ├── medicine_model.dart
│       │   └── medicine_repository.dart
│       ├── providers/
│       │   └── medicine_provider.dart
│       └── presentation/
│           ├── screens/
│           │   ├── medicine_list_screen.dart
│           │   ├── add_edit_medicine_screen.dart
│           │   └── medicine_detail_screen.dart
│           └── widgets/
│               ├── medicine_card.dart
│               ├── dosage_form_selector.dart
│               └── meal_timing_selector.dart
├── features/
│   └── reminders/
│       ├── data/
│       │   ├── reminder_model.dart
│       │   └── reminder_repository.dart
│       ├── providers/
│       │   └── reminder_provider.dart
│       └── presentation/
│           ├── screens/
│           │   └── reminder_settings_screen.dart
│           └── widgets/
│               ├── schedule_time_tile.dart
│               └── time_preset_chips.dart
├── features/
│   └── progress/
│       ├── data/
│       │   ├── progress_models.dart
│       │   └── progress_repository.dart
│       ├── providers/
│       │   └── progress_provider.dart
│       └── presentation/
│           ├── screens/
│           │   └── daily_progress_screen.dart
│           └── widgets/
│               ├── time_slot_row.dart
│               ├── completion_ring.dart
│               └── progress_bar_chart.dart
├── features/
│   └── calendar/
│       ├── data/
│       │   ├── calendar_models.dart
│       │   └── calendar_repository.dart
│       ├── providers/
│       │   └── calendar_provider.dart
│       └── presentation/
│           ├── screens/
│           │   └── calendar_screen.dart
│           └── widgets/
│               ├── month_grid.dart
│               ├── day_cell.dart
│               ├── calendar_legend.dart
│               └── day_history_sheet.dart
├── features/
│   └── history/
│       ├── data/
│       │   ├── history_models.dart
│       │   └── history_repository.dart
│       ├── providers/
│       │   └── history_provider.dart
│       └── presentation/
│           ├── screens/
│           │   └── medicine_history_screen.dart
│           └── widgets/
│               ├── history_list_tile.dart
│               └── history_filter_sheet.dart
├── features/
│   └── stock/
│       ├── data/
│       │   └── stock_models.dart
│       ├── providers/
│       │   └── stock_provider.dart
│       └── presentation/
│           ├── screens/
│           │   └── stock_screen.dart
│           └── widgets/
│               ├── stock_progress_bar.dart
│               └── refill_dialog.dart
├── features/
│   └── prescriptions/
│       ├── data/
│       │   ├── prescription_model.dart
│       │   └── prescription_repository.dart
│       ├── providers/
│       │   └── prescription_provider.dart
│       └── presentation/
│           ├── screens/
│           │   ├── prescription_list_screen.dart
│           │   ├── add_prescription_screen.dart
│           │   └── prescription_detail_screen.dart
│           └── widgets/
│               ├── category_selector.dart
│               └── prescription_card.dart
├── features/
│   └── family/
│       ├── data/
│       │   ├── family_member_model.dart
│       │   └── family_repository.dart
│       ├── providers/
│       │   └── family_provider.dart
│       └── presentation/
│           ├── screens/
│           │   ├── family_list_screen.dart
│           │   └── add_edit_family_member_screen.dart
│           └── widgets/
│               ├── profile_avatar.dart
│               └── profile_switcher.dart
├── features/
│   └── accessibility/
│       └── presentation/
│           ├── screens/
│           │   └── accessibility_screen.dart
│           └── widgets/
│               └── elderly_dashboard_view.dart
├── features/
│   └── statistics/
│       ├── data/
│       │   ├── statistics_models.dart
│       │   └── statistics_repository.dart
│       ├── providers/
│       │   └── statistics_provider.dart
│       └── presentation/
│           ├── screens/
│           │   └── statistics_screen.dart
│           └── widgets/
│               ├── stat_card.dart
│               ├── period_selector.dart
│               ├── status_pie_chart.dart
│               └── adherence_line_chart.dart
├── features/
│   └── offline/
│       └── presentation/
│           └── widgets/
│               └── offline_banner.dart
├── features/
│   └── settings/
│       ├── data/
│       │   └── settings_models.dart
│       ├── providers/
│       │   ├── theme_mode_provider.dart
│       │   ├── notification_prefs_provider.dart
│       │   └── language_provider.dart
│       └── presentation/
│           ├── screens/
│           │   ├── settings_screen.dart
│           │   ├── account_screen.dart
│           │   ├── privacy_screen.dart
│           │   └── about_screen.dart
│           └── widgets/
│               ├── settings_tile.dart
│               ├── theme_mode_picker.dart
│               └── language_picker.dart
├── core/
│   ├── theme/
│   │   └── app_theme.dart
│   ├── providers/
│   │   ├── elderly_mode_provider.dart
│   │   └── connectivity_provider.dart
│   └── services/
│       ├── notification_service.dart
│       ├── notification_action_handler.dart
│       ├── export_service.dart
│       ├── voice_feedback_service.dart
│       ├── connectivity_service.dart
│       ├── local_cache_service.dart
│       ├── offline_queue_service.dart
│       └── sync_service.dart
└── main.dart
```

## Supabase SQL migrations

Run in order via Supabase SQL Editor:
1. `supabase/002_medicines_table.sql` — Module 3's `medicines` table + RLS
2. `supabase/003_reminders_table.sql` — Module 4's `medicine_schedule` + `medicine_history` tables + RLS
3. `supabase/004_prescriptions_table.sql` — Module 10's `prescriptions` table + private storage bucket + RLS
4. `supabase/005_family_profiles.sql` — Module 11's `family_members` table + `profile_id` columns + data backfill (read before running — see Module 11 notes above)

## Supabase Edge Functions

Unlike the SQL migrations above, this is NOT run through the SQL Editor —
it's a separate Deno/TypeScript function deployed via the Supabase CLI:

- `supabase/functions/delete-account/index.ts` — Module 16's account
  deletion. Deploy with `supabase functions deploy delete-account` after
  configuring the `service_role` key as a function secret. Nothing in
  this repo deploys it automatically; the Delete Account button in the
  app will fail with a clear error message until this is deployed.

## Notes / next steps

- Deep links for reset-password and email-verified redirects need platform
  config (Android `AndroidManifest.xml` intent filter, iOS URL scheme) before
  they'll open the app directly — right now Supabase will still send the
  emails and the polling in `EmailVerificationScreen` will pick up
  verification once it happens, deep link or not.
- `AuthValidators` are intentionally dependency-free; swap in a package
  like `formz` later if forms grow more complex.
- This module hands off to `_DashboardPlaceholder` in `main.dart` — replace
  that with your real Module 2 (Dashboard) screen.
