# Takhti Grow (working title) — Pilot App Design Document v1.0

**Owner:** HomiLabs Solutions SMC Pvt Ltd · **Content partner:** Takhti Online (Adeel Imtiaz)
**Prepared:** 10 October 2026 · **Status:** Draft for confirmation — nothing in Section 14 counts as decided until confirmed

---

## 1. Summary

Takhti Grow is an Android app for adults that turns Takhti's neuroscience videos into one small daily lesson. Each lesson follows the same loop: **read the key idea → watch a short clip → do one action → reflect in the evening → optional quick check**. The pilot ships with 3 onboarding screens and 4 lessons from the reviewed Content Pack v0.1.

The pilot's job is to learn whether adults come back daily. It is not a full product. Everything that does not serve that question stays out (Section 3.2).

---

## 2. Locked decisions

| # | Decision | Source |
|---|---|---|
| L1 | HomiLabs owns the app; Takhti is the content partner | Homi, 9 Oct |
| L2 | Audience: adults (18+), self-growth, neuroscience-informed | Homi, 8 Oct |
| L3 | Pilot content: 3 onboarding screens + Lessons 1–4 from Content Pack v0.1 | Homi + Adeel review, 9 Oct |
| L4 | App language: English only | Homi, 10 Oct |
| L5 | Sign-in: Google + email/password | Homi, 10 Oct |
| L6 | Video: embed Takhti's YouTube videos at lesson timestamps | Homi, 10 Oct |
| L7 | Name: "Takhti Grow (working title)" until the real name is chosen | Homi, 10 Oct |
| L8 | Stack: Flutter (Android first) + Firebase (Auth + Cloud Firestore) | HomiLabs standard stack |
| L9 | No medical or ADHD claims anywhere in the app | Content Pack v0.1, fact-check section |

---

## 3. Scope

### 3.1 In the pilot

1. Onboarding (3 screens, shown before sign-in)
2. Sign-in / sign-up (Google, email + password), password reset, 18+ confirmation
3. Reminder setup (lesson time, reflection time)
4. Today screen with streak and the 5-step daily loop
5. Lesson flow: Key idea, Watch, Do, Reflect, Quick check, Lesson complete
6. Journey (list of 4 lessons: locked / available / done)
7. Reflections history (read-only list of past answers)
8. Profile & settings: name, reminder times, about Takhti, privacy policy, sign out, **delete account**
9. Pilot feedback (rating + comment after Lesson 4)
10. Two local daily notifications (lesson, reflection)

### 3.2 Not in the pilot (flag before adding — scope creep)

- Urdu UI, dark-mode polish beyond the system default, iOS build
- Parenting track (podcast content)
- Social features, sharing, leaderboards, comments
- Ads, payments, subscriptions
- Push notifications from a server (FCM) — local notifications are enough
- Admin web panel — lessons are entered in the Firebase console or by a seed script
- Downloading videos for offline viewing

---

## 4. Critique — risks to resolve before build

1. **English app, Urdu videos.** The UI is English, but every Takhti video is in Urdu/Hindi. An English-only user cannot follow the clips. **Fix:** Adeel adds English subtitles to the 4 source videos in YouTube Studio. The player then requests English captions (`cc_lang_pref=en`, `cc_load_policy=1`). Without this, the target audience is "English-reading adults who also understand spoken Urdu". Say that plainly in the store listing.
2. **Embedding must be allowed.** Each source video must have "Allow embedding" switched on in YouTube Studio. If Adeel ever deletes, privatises or re-uploads a video, that lesson breaks. The app needs a fallback message (Section 6, S9).
3. **Four lessons = four days.** The pilot will run out of content within a week. That is acceptable for a pilot only if it is labelled as one ("Pilot — 4 lessons") and ends with the feedback screen. Do not publish it as a finished product.
4. **Login before value.** Asking strangers to create an account before they see anything loses many of them. **Fix:** onboarding is shown first, sign-in second. Lesson 1's key idea could even be shown before sign-in (open decision D3).
5. **Reflections are personal writing.** Storing them in the cloud means HomiLabs holds private thoughts of users. The privacy policy and the Play Data Safety form must say so. The note field is optional and capped at 500 characters.
6. **Google sign-in breaks most often at release.** It needs the SHA-1 and SHA-256 of the **Play App Signing key**, not only the debug key. Add them in Firebase before the first Play test track build (Section 10).

---

## 5. Login flow

### 5.1 Flow

```
App launch
   │
   ▼
[S0 Splash] ── checks Firebase Auth state ──┐
   │                                        │ signed in
   │ not signed in                          ▼
   ▼                              user doc exists?
[S1 Onboarding 1–3]                 │ yes → reminders set? ── yes → [S7 Today]
   │ "Get started"                  │                       └─ no  → [S6 Reminders]
   ▼                                └ no  → create user doc → [S6 Reminders]
[S2 Sign in]
   ├── "Continue with Google" ──► Google account picker ──► 18+ & terms sheet (first time only) ──┐
   ├── Email + password ──► "Sign in" ─────────────────────────────────────────────────────────────┤
   ├── "Create account" ──► [S3 Create account] ──► verification email sent ──────────────────────┤
   └── "Forgot password?" ──► [S4 Reset] ──► reset email ──► back to S2                           │
                                                                                                   ▼
                                                                                  create users/{uid} doc
                                                                                                   ▼
                                                                                         [S6 Reminders] → [S7 Today]
```

### 5.2 Rules

| Rule | Detail |
|---|---|
| Adults only | Every new account ticks **"I confirm I am 18 or older."** Without it the account is not created. We store only `ageConfirmed18: true` and the timestamp, not a date of birth (less personal data to hold). Google users see the same tick-box in a one-time sheet. |
| Terms | Same screen: "I agree to the Terms and Privacy Policy" (links to homilabs.org). Store `termsVersion` accepted. |
| Email verification | A verification email is sent at sign-up. The pilot does **not** block use until verified (less friction); Profile shows "Email not verified — resend". Revisit before public launch (D4). |
| Password | Minimum 8 characters, at least one letter and one number. Show/hide toggle. |
| Errors | Plain words: "That email is already registered — sign in instead", "Wrong email or password", "No internet connection — try again". Never show raw Firebase error codes. |
| Account linking | If a Google user later tries email sign-up with the same address, Firebase returns "account exists with different credential" → show "This email uses Google sign-in. Continue with Google." |
| Sign out | Profile → Sign out → back to S2 (onboarding not shown again). |
| Delete account | Required by Google Play. Profile → Delete account → re-enter password or re-select Google account → deletes all user data (Section 8.5), then the auth account → back to S1. A web page on homilabs.org explains how to request deletion without the app (Play requirement). |

---

## 6. Screen designs

**Navigation:** after sign-in, a bottom bar with 4 tabs — **Today · Journey · Reflections · Profile**. The lesson flow (S8–S13) opens full-screen above the tabs with a back arrow and a 5-dot step indicator.

**Design basics:** Material 3. One calm accent colour (placeholder: deep teal `#1F6F6B`; replace with Takhti's brand colour if it has one), white/very light grey backgrounds, one bundled font family (e.g. Inter or Noto Sans), body text 16 sp minimum, all tap targets ≥ 48 dp, works with Android font scaling up to 200%. Portrait first; layouts use flexible widths, never fixed pixel widths.

### S0 — Splash
Logo + "Takhti Grow" + "by HomiLabs × Takhti". Shows for no longer than auth check takes (≤ 1.5 s typical). No buttons.

### S1 — Onboarding (3 pages, swipe or "Next")

```
┌──────────────────────────────┐
│                         Skip │
│                              │
│        [ illustration ]      │
│                              │
│  Your brain can change,      │
│  at any age.                 │
│                              │
│  We were told the brain is   │
│  fixed after childhood.      │
│  Neuroscience now shows it   │
│  keeps rewiring itself.      │
│                              │
│          ●  ○  ○             │
│  ┌────────────────────────┐  │
│  │          Next          │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```
- Page 1: "Your brain can change, at any age." (Content Pack, Screen 1)
- Page 2: "I used to be terrified of speaking." — Adeel's story + optional 40-second clip (Course Launch 1:10–2:00)
- Page 3: "How this works" — the daily loop as 5 small icons: Read · Watch · Do · Reflect · Check. Button: **Get started** → S2.
- Shown once per install (stored locally in `shared_preferences`).

### S2 — Sign in

```
┌──────────────────────────────┐
│  Welcome                      │
│  Sign in to keep your streak  │
│  and reflections safe.        │
│                               │
│  ┌─────────────────────────┐  │
│  │ G  Continue with Google │  │
│  └─────────────────────────┘  │
│  ─────────── or ───────────   │
│  Email                        │
│  [__________________________] │
│  Password                👁   │
│  [__________________________] │
│               Forgot password?│
│  ┌─────────────────────────┐  │
│  │         Sign in         │  │
│  └─────────────────────────┘  │
│  New here?  Create account    │
└──────────────────────────────┘
```
States: loading spinner inside the button; inline error under the field; offline banner.

### S3 — Create account
Fields: **Name** (2–40 chars), **Email**, **Password**, **Confirm password**.
Two required tick-boxes: "I confirm I am 18 or older" · "I agree to the Terms and Privacy Policy".
Button **Create account** stays disabled until all fields are valid and both boxes are ticked.
After success: snackbar "Verification email sent to …" → S6.

### S4 — Forgot password
One email field + **Send reset link**. Always shows the same message ("If an account exists for this email, a reset link is on its way") so the screen does not reveal which emails are registered.

### S5 — 18+ and terms sheet (Google first sign-in only)
Bottom sheet with the same two tick-boxes and **Continue**. Closing it signs the user out again.

### S6 — Reminders (first run; also reachable from Profile)

```
┌──────────────────────────────┐
│  When should we remind you?   │
│                               │
│  Daily lesson         08:00 ▸ │
│  Evening reflection   21:00 ▸ │
│                               │
│  We'll send two gentle        │
│  reminders a day. You can     │
│  change or turn them off any  │
│  time in Profile.             │
│                               │
│  ┌─────────────────────────┐  │
│  │   Allow notifications   │  │
│  └─────────────────────────┘  │
│         Not now               │
└──────────────────────────────┘
```
"Allow notifications" asks Android 13+ notification permission, then schedules two local daily notifications. "Not now" saves times but schedules nothing.

### S7 — Today (home tab)

```
┌──────────────────────────────┐
│  Good morning, Homi     🔥 3  │
│                               │
│  ┌─────────────────────────┐  │
│  │ LESSON 2 OF 4            │  │
│  │ One thing at a time      │  │
│  │                          │  │
│  │ ✓ Read  ✓ Watch  ● Do    │  │
│  │ ○ Reflect  ○ Check       │  │
│  │                          │  │
│  │ ┌──────────────────────┐ │  │
│  │ │   Continue: Do        │ │  │
│  │ └──────────────────────┘ │  │
│  └─────────────────────────┘  │
│                               │
│  Tonight: reflect at 21:00    │
│                               │
│ [Today] Journey Reflect. Prof │
└──────────────────────────────┘
```
States:
- **Lesson available** (above). The button jumps to the first unfinished step.
- **Reflection waiting** (action committed, reflection not done): card shows "How did it go?" → S11.
- **Done for today:** "Lesson complete. Next lesson unlocks tomorrow." + streak.
- **Pilot finished** (all 4 done): "You've finished the pilot. More lessons are coming." + **Give feedback** → S16.
- **Offline:** cached lesson still opens; the Watch step shows "Needs internet".

Streak 🔥 = consecutive local calendar days with at least one completed lesson. Missing a day resets it to 0. Show a plain number with the word "day streak" for screen readers.

### S8 — Step 1: Key idea
Title, source line in small text ("From: *Your Brain Runs on 20 Watts* — Takhti"), the 3 key-idea bullets, button **Next: Watch**.

### S9 — Step 2: Watch

```
┌──────────────────────────────┐
│ ←   ● ● ○ ○ ○                │
│  ┌──────────────────────────┐ │
│  │                          │ │
│  │   YouTube player (16:9)  │ │
│  │   clip 8:22 – 9:28       │ │
│  └──────────────────────────┘ │
│  Clip from Takhti Online      │
│  Watch the full video ↗       │
│                               │
│  ┌─────────────────────────┐  │
│  │      Next: Do            │  │
│  └─────────────────────────┘  │
└──────────────────────────────┘
```
- Player starts at `clipStartSec` and stops at `clipEndSec`; English captions requested.
- "Watch the full video ↗" opens the YouTube app at the same timestamp (counts as a channel view).
- **Next** is always enabled (the user may skip the clip); the step counts as done when the clip reaches its end or the user taps Next after ≥ 10 seconds of playback.
- Error state (video removed, embedding off, no internet): "This clip can't play right now" + "Open in YouTube" + Next.

### S10 — Step 3: Do (today's action)
Action text in a highlighted card. Button **I'll do this today** → saves `actionCommittedAt` → back to Today. In the evening, S11 asks whether it happened.

### S11 — Step 4: Evening reflection

```
┌──────────────────────────────┐
│ ←   ● ● ● ● ○                │
│  Did you do today's action?   │
│  ( Yes )  ( Partly )  ( No )  │
│                               │
│  At what point today did your │
│  work start to slip?          │
│  ┌──────────────────────────┐ │
│  │ Write a line (optional)  │ │
│  │                    0/500 │ │
│  └──────────────────────────┘ │
│  Only you can see this.       │
│  ┌─────────────────────────┐  │
│  │          Save            │  │
│  └─────────────────────────┘  │
└──────────────────────────────┘
```
Save needs one of the three chips; text is optional. Available any time after the action is committed (not only after 21:00).

### S12 — Step 5: Quick check (optional)
3 multiple-choice questions, one per page. After each answer: correct option highlighted with a ✓ icon **and** the word "Correct" / "Not quite" (never colour alone) + one-line explanation. "Skip quiz" link on the first page.

### S13 — Lesson complete
"Lesson 2 complete" + streak + "Next lesson unlocks tomorrow" + **Back to Today**. Light haptic tick; no confetti that ignores the system "remove animations" setting.

### S14 — Journey tab
Vertical list of the 4 lessons with a state chip: **Done ✓ · Today · Locked 🔒 (unlocks tomorrow)**. Done lessons reopen read-only (key idea, clip, action, their own reflection).

### S15 — Reflections tab
Newest first: date, lesson title, Yes/Partly/No chip, their note. Empty state: "Your reflections will appear here after your first evening check-in."

### S16 — Profile & settings
Name (editable) · Email (+ "Not verified — resend") · Reminders (→ S6) · About Takhti (Adeel's short bio + link to channel) · Give pilot feedback · Privacy policy · Terms · Sign out · **Delete account** (red text, confirmation dialog that lists what will be deleted, then re-authentication).

Pilot feedback dialog: 1–5 stars + "What should we improve?" (optional, ≤ 1000 chars) → `feedback` collection.

### Disclaimer (About + store listing)
"Takhti Grow shares educational content about learning and habits. It is not medical advice and does not diagnose or treat any condition."

---

## 7. Lesson unlock and progress rules

| Rule | Detail |
|---|---|
| Order | Lessons unlock in `order` 1 → 4. |
| Daily pacing | Lesson N+1 unlocks at 00:00 device-local time on the day **after** Lesson N is completed. |
| Completion | A lesson is complete when Key idea, Watch, Do and Reflect are done. Quick check is optional. |
| Streak | +1 for each local day with a completed lesson; reset to 0 if a whole local day passes without one. Computed on the device, stored in the user doc. |
| Time zone | Dates stored as `localDate` strings (`2026-10-10`) plus a UTC timestamp, so travel does not corrupt history. |
| Re-doing | Done lessons are read-only; reflections cannot be edited after saving (keeps the history honest; revisit after pilot). |

---

## 8. Cloud Firestore — requirements

### 8.1 Why Firestore

- Keeps progress and reflections when the user changes phone (needed once there is a login).
- Lesson content lives in Firestore, so lessons can be corrected or added **without a new app release**.
- Offline cache is on by default on Android: lessons already loaded and the user's own data still open without internet; writes sync when back online.

### 8.2 Collections

```
lessons/{lessonId}                      ← read-only for the app
appConfig/main                          ← read-only for the app
users/{uid}                             ← one doc per user
users/{uid}/progress/{lessonId}         ← one doc per lesson started
users/{uid}/reflections/{reflectionId}  ← one doc per evening reflection
feedback/{feedbackId}                   ← create-only
```

### 8.3 Document fields

**`lessons/{lessonId}`** (e.g. `l01-brain-20-watts`)

| Field | Type | Example / rule |
|---|---|---|
| `order` | number | 1 |
| `published` | bool | true |
| `title` | string | "Your brain runs on 20 watts" |
| `sourceVideoTitle` | string | "Your Brain Runs on 20 Watts — Here's Why Try Harder Fails" |
| `youtubeId` | string | 11-character video id |
| `clipStartSec` / `clipEndSec` | number | 502 / 568 |
| `keyIdea` | array<string> | exactly 3 bullets |
| `action` | string | today's action text |
| `reflectionQuestion` | string | evening question |
| `quiz` | array<map> | `{question, options: [3 strings], correctIndex, explanation}` × 3 |
| `contentVersion` | number | bump on every edit |
| `updatedAt` | timestamp | |

**`appConfig/main`**

| Field | Type | Purpose |
|---|---|---|
| `minSupportedBuild` | number | force-update message if the app is older |
| `pilotLessonCount` | number | 4 |
| `privacyUrl`, `termsUrl`, `deleteAccountUrl` | string | homilabs.org pages |

**`users/{uid}`**

| Field | Type | Notes |
|---|---|---|
| `displayName` | string | 2–40 chars |
| `email` | string | copy from Auth, for support only |
| `authProvider` | string | `google` \| `password` |
| `ageConfirmed18` | bool | must be `true` |
| `ageConfirmedAt` | timestamp | |
| `termsVersion` | string | e.g. `2026-10` |
| `createdAt` | timestamp | server time |
| `reminderLessonTime` | string | `"08:00"` |
| `reminderReflectionTime` | string | `"21:00"` |
| `remindersEnabled` | bool | |
| `timeZone` | string | `"Asia/Karachi"` |
| `currentStreak` / `longestStreak` | number | |
| `lastCompletedLocalDate` | string | `"2026-10-10"` |
| `lessonsCompleted` | number | 0–4 |

**`users/{uid}/progress/{lessonId}`**

| Field | Type |
|---|---|
| `startedAt`, `keyIdeaReadAt`, `clipWatchedAt`, `actionCommittedAt`, `reflectionDoneAt`, `quizDoneAt`, `completedAt` | timestamp (null until done) |
| `completedLocalDate` | string |
| `quizAnswers` | array<number> |
| `quizScore` | number 0–3 |

**`users/{uid}/reflections/{reflectionId}`**

| Field | Type | Rule |
|---|---|---|
| `lessonId` | string | |
| `question` | string | copy of the question at the time (lesson text may change later) |
| `actionDone` | string | `yes` \| `partly` \| `no` |
| `note` | string | optional, ≤ 500 chars |
| `localDate` | string | |
| `createdAt` | timestamp | server time |

**`feedback/{feedbackId}`**

| Field | Type |
|---|---|
| `uid` | string (must equal the signer) |
| `rating` | number 1–5 |
| `comment` | string ≤ 1000 |
| `appBuild` | number |
| `createdAt` | timestamp |

### 8.4 Security rules (starting point)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() { return request.auth != null; }
    function isOwner(uid) { return signedIn() && request.auth.uid == uid; }

    match /lessons/{lessonId} {
      allow read: if signedIn() && resource.data.published == true;
      allow write: if false;            // edited in console / admin script only
    }

    match /appConfig/{doc} {
      allow read: if true;              // needed before sign-in (force update check)
      allow write: if false;
    }

    match /users/{uid} {
      allow read, delete: if isOwner(uid);
      allow create: if isOwner(uid)
        && request.resource.data.ageConfirmed18 == true
        && request.resource.data.displayName is string
        && request.resource.data.displayName.size() >= 2
        && request.resource.data.displayName.size() <= 40;
      allow update: if isOwner(uid)
        && request.resource.data.ageConfirmed18 == resource.data.ageConfirmed18
        && request.resource.data.createdAt == resource.data.createdAt;

      match /progress/{lessonId} {
        allow read, write: if isOwner(uid);
      }

      match /reflections/{reflectionId} {
        allow read, delete: if isOwner(uid);
        allow create: if isOwner(uid)
          && request.resource.data.actionDone in ['yes', 'partly', 'no']
          && (!('note' in request.resource.data)
              || request.resource.data.note.size() <= 500);
        allow update: if false;         // reflections are not edited (Section 7)
      }
    }

    match /feedback/{feedbackId} {
      allow create: if signedIn()
        && request.resource.data.uid == request.auth.uid
        && request.resource.data.rating is int
        && request.resource.data.rating >= 1
        && request.resource.data.rating <= 5
        && request.resource.data.comment.size() <= 1000;
      allow read, update, delete: if false;
    }
  }
}
```
Test these rules in the Firebase Emulator before deploying. Rules are not filters: the app must query only what the rules allow (e.g. `where('published', isEqualTo: true)`).

### 8.5 Account deletion (data)
Firestore does **not** delete subcollections when a parent document is deleted. Order in the app:
1. Re-authenticate (password or Google).
2. Delete every doc in `users/{uid}/reflections` and `users/{uid}/progress` (a batch; the pilot has < 50 docs per user).
3. Delete `users/{uid}`.
4. Delete the Firebase Auth user.
5. Clear local preferences and cancel notifications.

Feedback docs are kept but contain only the uid, rating and comment; say so in the privacy policy, or delete them in the same batch (D6).

### 8.6 Indexes
- `lessons`: `published ==` + `orderBy order` → **one composite index** (`published` ASC, `order` ASC). The console link appears in the first failed query's error; or add it in `firestore.indexes.json`.
- `reflections`: `orderBy createdAt desc` on a single field → automatic index, nothing to add.

### 8.7 Reads, writes and cost
A typical active user per day: ~6 reads (config, user, today's lesson, progress, reflections list) and ~6 writes (progress steps, reflection, user streak). That is well within the Firebase Spark (free) plan's daily quota for a pilot of a few hundred users. Check current quotas in the Firebase console before launch; Google changes them.

### 8.8 Seeding lessons
A small Node.js script (`tool/seed_lessons.js`, Firebase Admin SDK, run from homi-nas) reads `lessons.json` and writes the 4 lesson docs. Content edits go into `lessons.json` → re-run the script → bump `contentVersion`. The JSON file is committed to git, so lesson history is versioned.

---

## 9. Packages (pubspec.yaml)

Versions are the latest on pub.dev as of 10 Oct 2026; caret ranges, with `pubspec.lock` committed.

```yaml
environment:
  sdk: ^3.9.0          # match your installed Flutter's Dart SDK

dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^4.15.0            # Firebase initialisation
  firebase_auth: ^6.7.0             # email/password + Google credential sign-in
  cloud_firestore: ^6.10.0          # data (Section 8)
  google_sign_in: ^7.2.0            # Google account picker (v7 API: GoogleSignIn.instance.initialize/authenticate)
  youtube_player_iframe: ^6.0.2     # embedded YouTube clip with start/end + captions
  flutter_local_notifications: ^22.3.1  # 2 daily reminders
  timezone: ^0.11.1                 # schedule notifications at local time
  flutter_timezone: ^5.1.1          # read the device time zone
  flutter_riverpod: ^3.4.3          # state management (HomiLabs standard)
  go_router: ^18.0.2                # navigation + auth redirect
  shared_preferences: ^2.5.6        # "onboarding seen" flag only
  url_launcher: ^6.3.0              # open full video in YouTube, privacy links

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

Optional, recommended before public launch: `firebase_crashlytics: ^5.4.0` (crash reports). Left out of the pilot build unless you want it now (D7).

**Firebase console setup**
1. Create project "takhti-grow" (or under the HomiLabs org).
2. Authentication → enable **Email/Password** and **Google**.
3. Firestore → create database (region: `asia-south1` Mumbai, closest to Pakistan) in production mode → paste rules (8.4).
4. Add Android app `org.homilabs.takhtigrow` (placeholder package name — D8).
5. Add SHA-1 **and** SHA-256 for debug key, upload key **and Play App Signing key**.
6. Run `flutterfire configure` → generates `firebase_options.dart`.
7. Create the composite index (8.6); seed lessons (8.8).

**Android settings:** `minSdkVersion 23` (Firebase requirement), `POST_NOTIFICATIONS` permission (Android 13+), `SCHEDULE_EXACT_ALARM` **not** needed — use inexact daily notifications (avoids an extra Play declaration).

---

## 10. App structure (Flutter)

Feature-first folders, Riverpod for state, one repository per data area. Kept small on purpose.

```
lib/
  main.dart                 // Firebase init, ProviderScope, router
  app/router.dart           // go_router + redirect: signed-out → /sign-in
  app/theme.dart            // colours, text styles
  features/
    onboarding/             // S1
    auth/                   // S2–S5, AuthRepository (Firebase Auth + Google)
    reminders/              // S6, NotificationService
    today/                  // S7
    lesson/                 // S8–S13, LessonRepository, ProgressRepository
    journey/                // S14
    reflections/            // S15, ReflectionRepository
    profile/                // S16, account deletion, feedback
  shared/
    models/                 // Lesson, UserProfile, Progress, Reflection
    widgets/                // step dots, primary button, error/empty views
tool/seed_lessons.js
firestore.rules
firestore.indexes.json
```

---

## 11. Build phases (one piece at a time, verify, then next)

| Phase | Build | Done when |
|---|---|---|
| 1 | Firebase project, Flutter skeleton, theme, router | App launches to an empty Today on a real phone |
| 2 | Onboarding + email sign-up/sign-in + 18+ tick + user doc | New account appears in Auth and `users/` |
| 3 | Google sign-in (+ SHA keys) + password reset | Google login works on a **release** build |
| 4 | Seed lessons; Today + Key idea + Watch | Lesson 1 clip plays from 8:22 to 9:28 with captions |
| 5 | Do + Reflect + Quick check + progress + unlock rule + streak | Lesson 1 completes; Lesson 2 unlocks next day (test by changing the phone date) |
| 6 | Journey + Reflections tabs | History shows correctly after 2 lessons |
| 7 | Reminders + notification permission | Both notifications arrive at the set times after a phone restart |
| 8 | Profile, sign out, delete account, feedback | Deleted user leaves no docs in Firestore |
| 9 | Rules tested in emulator, privacy/deletion pages on homilabs.org, Play listing (18+, Data Safety), internal test track | 5 testers complete Lesson 1 from a Play install |

Close each session with the usual backup routine: git commit + push, local snapshot, Google Drive sync.

---

## 12. Google Play requirements

- **Target audience:** 18+ only (Play Console → Target audience and content).
- **Data safety form:** collects name, email, user-generated content (reflections, feedback), app activity (progress); all linked to the account; encrypted in transit; user can request deletion.
- **Account deletion:** in-app (S16) **and** a web page URL (homilabs.org) — both required.
- **Privacy policy URL:** homilabs.org page covering Firebase (Google) as processor, reflections storage, deletion.
- **Health claims:** none. Category: Education or Health & Fitness — Education avoids extra health-app scrutiny (D9).
- **Content rights:** written permission from Takhti Online to use its videos, titles and Adeel's name/likeness in the app and listing (a one-page letter is enough, even within the family).

---

## 13. What the pilot measures

Read from Firestore after 2–4 weeks (no analytics SDK needed):

| Question | Measure |
|---|---|
| Do people finish Lesson 1? | users with `progress/l01.completedAt` ÷ users created |
| Do they come back? | users with ≥ 2 lessons completed on different days |
| Is the evening step used? | reflections ÷ completed lessons |
| Do clips get watched? | `clipWatchedAt` set ÷ lessons started |
| Did they like it? | average feedback rating + comments |

---

## 14. Open decisions (confirm before Phase 1)

| # | Question | Recommendation |
|---|---|---|
| D1 | English captions on the 4 source videos? (Risk 1) | Yes — Adeel adds them before Phase 4 |
| D2 | Final app name | Keep working title until Play listing (Phase 9) |
| D3 | Show Lesson 1's key idea before sign-in? | Yes — shows value before asking for an account |
| D4 | Block use until email is verified? | No for pilot; yes before public launch |
| D5 | Next lesson unlocks next day, or immediately? | Next day (builds the daily habit) |
| D6 | Delete feedback docs with the account? | Yes — simplest to explain in the privacy policy |
| D7 | Add Crashlytics in the pilot? | Yes — cheap, and pilot crashes are otherwise invisible |
| D8 | Package name | `org.homilabs.takhtigrow` (cannot change after first Play upload) |
| D9 | Play category | Education |
| D10 | Brand colour and logo from Takhti? | Ask Adeel; teal placeholder until then |
