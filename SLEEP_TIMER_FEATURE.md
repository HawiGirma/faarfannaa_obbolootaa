# Sleep Timer Feature

## Overview
A sleep timer feature has been added to automatically stop audio playback after a specified duration.

## Features

### 1. **Sleep Timer Button**
- Located in the player screen's top bar (bedtime icon)
- Highlighted in primary color when a timer is active
- Opens the sleep timer dialog when tapped

### 2. **Sleep Timer Dialog**
- Beautiful modern UI with multiple preset durations:
  - 5 minutes
  - 10 minutes
  - 15 minutes
  - 30 minutes
  - 45 minutes
  - 1 hour

### 3. **Active Timer Display**
- Shows remaining time in a prominent display
- Updates every second with countdown
- Visual indicator with primary color highlighting
- Option to cancel the active timer

### 4. **Functionality**
- Timer stops playback completely when it expires
- User gets a confirmation snackbar when setting a timer
- Timer persists even if user navigates away from player screen
- Automatically cleaned up when expired or canceled

## Technical Implementation

### Audio Player Service (`audio_player_service.dart`)
- Added `Timer? _sleepTimer` for timer management
- Added `DateTime? _sleepEndTime` to track when timer expires
- New methods:
  - `setSleepTimer(Duration)` - Sets a new sleep timer
  - `cancelSleepTimer()` - Cancels active timer
  - `getRemainingTime()` - Returns remaining duration
  - `hasSleepTimer` - Getter to check if timer is active

### Sleep Timer Dialog (`sleep_timer_dialog.dart`)
- Modal dialog with preset duration options
- Real-time countdown display for active timers
- Clean, intuitive UI matching app design
- Auto-updates every second to show remaining time

## User Flow

1. User taps the bedtime icon in player screen
2. Sleep timer dialog appears with duration options
3. User selects desired duration
4. Confirmation snackbar appears
5. Bedtime icon highlights in primary color
6. Timer counts down in background
7. When timer expires, playback stops automatically
8. User can cancel timer anytime by reopening dialog

## Design Considerations

- Non-intrusive: Timer runs silently in background
- Visual feedback: Icon highlights when timer is active
- Flexible: Multiple preset durations for different use cases
- User control: Easy to cancel or modify timer
- Smooth UX: Confirmation messages and real-time updates
