# WODBoard — Sprint 3 Summary
*(Reconstructed from conversation history — no original summary was committed at the time.)*

## Key Decision: Retire the browser display, go native
Live testing on Chromecast with TV Bro (and other Android browsers) showed the
browser-based approach didn't work for a TV kiosk: no real kiosk mode, D-pad
navigation fought with browser chrome (back/forward/reload buttons stealing
focus), and the long display-token URL was painful to type with a remote.

**Decision:** build a native Android TV app instead (Kotlin + Jetpack Compose),
sideloaded via ADB directly to the Chromecast with Google TV device — no app
store needed.

## Retired
- `src/pages/TvDisplay.tsx`, `src/types/display.ts`, and the browser-based
  OverviewView/LiveBlockView components are fully retired. The PWA Builder
  repo keeps the Supabase migrations but the browser display code is dead.

## Built
- Initial Android Studio project scaffolded (Kotlin + Jetpack Compose)
- First version of `MainActivity.kt` and `WorkoutRepository.kt`, pulling
  published workouts from `get_display_workout` over the display token
- Confirmed running on **actual Chromecast with Google TV hardware** via
  Android Studio + ADB (not just the emulator)

## Key learning
Test on real hardware early — the emulator is slow enough that it hides real
D-pad/remote UX problems the physical device surfaces immediately.

## Market context
Confirmed WODBoard sits in an established category (Fit Viz, WODscreen,
GymBoard already exist) — per-gym branding customization is a standard,
expected feature in this space, not a differentiator to skip.

## Next
Sprint 4: block groups (sub-rounds, P1/P2 partner tracks), splash screen
polish, D-pad scrolling, trainer controls.
