## The Chalkboard

An iOS “chalkboard” for quickly capturing items (tasks/reminders/notes), assigning due dates (optionally with a time), and getting local notifications when something is due.

This repo currently contains **two iOS apps**:

- **`The Chalkboard/`**: UIKit + Core Data (Main storyboard). This is where the reminder parsing + notifications live.
- **`The New Chalkboard/`**: SwiftUI-based app target (work-in-progress / newer UI exploration).

## Features

- **Fast capture**: an auto-growing input bar for adding items quickly.
- **Natural-language due dates**: type a date/time in the text and it will be parsed into a due date (and optional due time).
  - Examples: `Pay rent tomorrow`, `Submit report Friday at 9am`, `Remind me to call mom on May 2 at 14:30`
- **Manual due date/time picker**: if you don’t include a date/time in the text, you can pick it.
- **Local notifications**: if an item has a due time, the app schedules a local notification at that time.
  - Foreground notifications are presented as banners/lists (where supported).
  - At most one pending due notification is kept per item (idempotent rescheduling).
- **Priority**: optional priority severity (Low/Medium/High) attached to an item.
- **Completion**: mark items completed; UI adapts styling and badges.
- **Markdown-friendly editing**:
  - List continuation on Return for unordered (`-`, `*`, `+`, `•`), ordered (`1.` / `1)`), and task lists (`- [ ]` / `- [x]`).
  - Task-list/checklist items are visually recognized in the list.
- **Persistence**: items are stored with Core Data (`CDChalkboardItem`) and mapped into a value-type domain model (`ChalkboardItem`).

## Requirements

- **Xcode**: recent Xcode version with Swift 5 support
- **iOS deployment target** (UIKit app): **iOS 17.6+** (see `The Chalkboard/The Chalkboard.xcodeproj`)

## Getting started

### Run the UIKit app (`The Chalkboard`)

1. Open `The Chalkboard/The Chalkboard.xcodeproj` in Xcode
2. Select the `The Chalkboard` scheme
3. Run on an iPhone simulator/device
4. On first launch, allow **Notifications** when prompted (needed for due-time alerts)

### Run the SwiftUI app (`The New Chalkboard`)

1. Open `The New Chalkboard/The New Chalkboard.xcodeproj` in Xcode
2. Select the `The New Chalkboard` scheme
3. Run on a simulator/device

## How natural-language reminders work (UIKit app)

When you add/edit an item, the app attempts to detect dates using `NSDataDetector` (date checking). If a date is found:

- The detected date becomes the **due date** (stored as start-of-day).
- If the detected text includes an explicit time (e.g. `9am`, `14:30`, `tonight`), the app also captures a **due time** (stored as minutes since midnight).
- The item title is **cleaned** by removing the detected date text and stripping common leading phrases like “remind me to…”.

## Notifications (UIKit app)

- Notifications are scheduled only when an item has a **due time** and the resulting fire date is in the future.
- Each item uses a stable identifier: `chalkboard.due.<item-uuid>`.
- Rescheduling is idempotent: the existing pending request for the item is removed, then re-added if applicable.

## Repo layout (high level)

- **`The Chalkboard/The Chalkboard/`**: UIKit app sources (controllers, views, Core Data model/store, utilities)
- **`The New Chalkboard/The New Chalkboard/`**: SwiftUI app sources
