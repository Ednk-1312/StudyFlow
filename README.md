# StudyFlow

StudyFlow is a privacy-first student command center for **iPhone, iPad, and Mac**. It combines a smart homework planner, an assignment scanner, searchable study materials, on-device study AI, a study timer, a school-focused calendar, a utility toolbox, and optional read-only Google Classroom sync.

Your school, organized automatically.

## What's new in this build

**macOS support is here.** StudyFlow now runs natively on Mac (Apple silicon and Intel):

- **Mac-native navigation** — the iOS tab bar becomes a real sidebar (`NavigationSplitView`) with the five sections (Today, Assignments, Planner, Materials, Tools) and full keyboard navigation
- **Menu bar & shortcuts** — a **Go** menu (⌘1–⌘5 switch sections, ⌘D opens Study AI, ⇧⌘S starts a study session), File ▸ New Task… (⇧⌘N) and Scan Document… (⇧⌘M), and Settings… (⌘,) — every command works from any section
- **Liquid Glass app icon** (`MacIcon.icon`) authored for macOS 26: teal clipboard-and-check glyph over a cream plate, with an automatic **dark-mode plate variant** and system-rendered squircle, glass, and specular sheen
- **Careful sheet behavior** — a running study timer can't be dismissed with Esc (only its own Complete/Finish flows close it), onboarding requires an explicit choice, and all sheets open at proper Mac form sizes
- **Relocated presentations** — Quick Add and Scan are owned by the window root on macOS so the File-menu commands work everywhere; Home View keeps them on iOS exactly as before
- **Window sizing** — minimum 720×480 so the dashboard, planner, and split layouts never collapse
- **Deployment target** — Mac build requires **macOS 26+**; iOS requirements are unchanged
- The iOS Home Screen **widget extension remains iOS-only** and is automatically excluded from Mac builds

## Features

### Planner & assignments
- **Home ("Today")** answers "what should I work on right now?": today's work, recommended next task, study-session CTA, upcoming deadlines and tests, quick add
- Fast manual assignment entry (Quick Add in seconds), full editor, priorities, estimated effort, notes, rescheduling
- Complete, undo completion, delete with snapshot-based undo (restores data, reminders, and Spotlight entries)
- **Deterministic study planner** that builds recommended task order, study blocks, and breaks from due dates, effort, priority, and exams. It recalculates when tasks go unfinished and never changes a deadline.
- Filtering by status and class, plus search across titles, classes, and notes

### Homework scanner
- Camera capture and photo library import (photo import on Mac; camera capture is an iPhone/iPad feature)
- Vision OCR runs off the main thread with an editable confirmation screen
- Uncertain extractions are flagged, never silently saved, and missing fields are never invented

### Materials
- PDFs, images, scans, notes, and imported files organized by subject, with tags and assignment associations
- On-device text extraction and local search across titles, subjects, extracted text, and tags
- Spotlight indexing for assignments and materials

### Study AI (on-device)
- Summarizer, concept explainer, flashcards, and interactive quiz built on Apple's on-device Foundation Models
- Clear error states with retry; output is always presented as a suggestion, never authoritative school data

### Study timer
- Assignment-linked sessions with planned durations, pause/resume, breaks, and history
- The completion sheet asks whether the assignment is finished; it never auto-completes
- On macOS the session runs in a dedicated sheet that cannot be lost to an accidental Esc

### School calendar
- Day views for assignments, tests, and study sessions
- Exam countdowns with distributable preparation windows and manual override

### Utility toolbox
Grade Calculator, What-If Grade Calculator, Weighted Grade Calculator, GPA Calculator, Percentage Calculator, Unit Converter, Word and Character Counter, Exam and Assignment Countdowns, Random Group Generator, and Study Session History. All offline, no account required.

### Google Classroom (optional)
- Real OAuth sign-in with Keychain token storage, silent refresh, and duplicate-safe read-only sync of courses and coursework
- Fails gracefully everywhere: school-restricted accounts get a clear explanation, offline states are honest, and a failed sync never erases local data
- Fully optional; every other feature works without it

### System integration
- Home Screen widgets (iPhone/iPad): Today's Assignments, Next Assignment, Study Session, Exam Countdown (the app is the single writer to a shared app group; widgets never touch the SwiftData store)
- Local notifications with stable per-assignment identifiers, contextual permission requests, and automatic rescheduling/cancellation
- App Intents and Shortcuts: add assignment, start session, mark complete, search materials
- Short onboarding, Privacy settings, in-app Privacy Policy, and a Developer Diagnostics panel

## Privacy

- Local-first: assignments, planner state, sessions, materials, and preferences are stored on device with SwiftData
- No advertising, tracking, or analytics SDKs
- OAuth tokens live in the Keychain, never in UserDefaults
- `PrivacyInfo.xcprivacy` manifests accurately describe required-reason API usage for both the app and the widget extension
- Google Classroom is the only external service, it is optional and read-only

## Requirements

- Xcode 26 or later (the Mac icon and macOS target use the macOS 26 SDK)
- iOS 17.0 or later (iPhone and iPad)
- macOS 26 or later for the Mac build
- An Apple ID for development signing (free account works)
- No third-party dependencies

## Building

1. Clone the repository.
2. Open `Study Tracking AIO.xcodeproj` in Xcode.
3. Select the **Study Tracking AIO** target, then Signing & Capabilities, and set your team.
4. If you use the widgets, add the same team to the **StudyOSWidgetsExtension** target. Both targets use the App Group `group.com.Study-Tracking-AIO`; Xcode creates it automatically on first build with your team selected.
5. Build and run — pick **My Mac** for the macOS app, or a device/simulator for iOS.

### Building the macOS app (CLI)

```bash
xcodebuild -project "Study Tracking AIO.xcodeproj" \
  -scheme "Study Tracking AIO" \
  -configuration Debug \
  -destination "platform=macOS" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

The app lands in DerivedData; `StudyFlow.app` mounts the platform-appropriate icon automatically (`MacIcon` on macOS, `AppIcon` on iOS).

### Running the test suite

The project ships an in-app suite (11 suites: planner, due-date parsing, deduplication, notifications, sessions, grades, sync, keychain, material indexing, OAuth copy, error classification) that runs identically on iOS and macOS:

```bash
# Build for macOS, then run the suite headlessly:
.build/.../StudyFlow.app/Contents/MacOS/StudyFlow -run-tests
# → [StudyOSTests] ALL 11/11 TEST SUITES PASSED CLEANLY
```

## Accessibility

Dynamic Type, VoiceOver labels and focus order, Reduce Motion, Increase Contrast, and Bold Text are supported throughout. Status is never communicated by color alone, and essential actions are never gesture-only. On macOS, every sidebar section and primary action is reachable from the menu bar with full-keyboard shortcuts.

## License

All rights reserved. Copyright 2026 Eshan Nandakumar.
