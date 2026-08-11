# WODBoard — Sprint 4 Summary
*(Reconstructed from conversation history — no original summary was committed at the time.)*

## Database
- **Migration 008**: `block_groups` table added (sub-round / P1-P2 partner
  track support), `group_id` added to `block_exercises`, `video_url` added
  to `exercises`, existing rows backfilled into one group per block.
- **Migration 009**: `get_display_workout` rewritten to be group-aware,
  walking through `block_groups` instead of reading `block_exercises`
  directly off `block_id`.
- **Migration 010**: `target_date` param added to `get_display_workout`
  (optional, defaults to most recent), plus a new `list_recent_workout_dates`
  RPC so the trainer menu can list real published dates.

## Android TV app
- `WorkoutRepository.kt` v2 and `MainActivity.kt`: `DisplayGroup`/`DisplayBlock`
  models, `computeTimerDisplay` now pulls round counts from `block.groups`
- D-pad Up/Down scrolling on the Overview screen
  (`rememberLazyListState`, `rememberCoroutineScope`, `animateScrollBy`,
  `@OptIn(ExperimentalFoundationApi::class)`)
- Splash screen: white rounded card for the gym logo, gym name below it,
  "Press → to begin" hint, Leading Zero branding (icon + text) — splash only,
  not a persistent footer
- Header: wall clock only, gym name shown on the Overview screen only, date
  dropped entirely
- Tabata confirmed as a UI preset (work=20s / rest=10s) on the existing
  interval block type — no new enum needed
- Long-press-Enter opens a D-pad-navigable trainer menu (extensible
  `MenuAction` list); first option is "Change day," pulling real published
  dates via `list_recent_workout_dates` and showing an amber
  "Showing [date], not today's workout" banner when applicable

## Confirmed on real hardware
Menu, splash icon, and fallback banner all verified working on the actual
Chromecast with Google TV device, not just Android Studio's emulator.

## Closed out early Sprint 5
Two loose threads from Sprint 4 close (splash screen crowding/overscan,
and the Change-day list having only 1-2 real dates to scroll through) were
resolved via a seed script that built out more real published workout days,
plus splash layout tweaks — both confirmed good before Sprint 5 planning
started.

## Next
Sprint 5: Builder UI — trainer auth, add-from-library, sets/reps/tempo entry,
group/track editing.
