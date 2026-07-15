# WODBoard Project Handoff Summary

## Project Overview

**Product Name:** WODBoard (CrossFit gym workout display system)  
**Company:** Leading Zero LLC (software vendor)  
**Client:** Gym network of 2–5 locations with multiple trainers per gym  
**Core Problem Solved:** Replaces manual whiteboard-based daily workout posting with a live digital display system

---

## Architecture & Tech Stack

**Frontend:** Vite + React + TypeScript (PWA)  
**Hosting:** Cloudflare Workers (switched from Vercel; Vercel free tier prohibits commercial use)  
**Domain:** `wodboard.leadingzero.net` (Cloudflare Pages/Workers)  
**Database:** Supabase (Postgres + Auth + Realtime, project: "workout-planner")  
**DNS:** Cloudflare zone management (migrated from Ionos); `servicetime.leadingzero.net` (Vercel-hosted) preserved as DNS-only (grey cloud) CNAME  
**TV Display Hardware:** Chromecast with Google TV + TV Bro browser (migrating to native Android TV app)

---

## What's Built So Far

**1. Database Schema (Migrations 001–006, live in Supabase)**
- Tables: `gyms`, `profiles`, `exercises`, `workouts`, `blocks`, `block_exercises`
- Block types enum: `warmup`, `straight_sets`, `circuit`, `pyramid`, `emom`, `amrap`, `interval`
- Row Level Security enforced throughout
- Two security-definer RPCs:
  - `get_display_workout(token)` — public read access via display token
  - `advance_display_session(token, direction)` — allows TV to change blocks without trainer login
- Seed data: 40+ exercises, 4 complete workouts from real whiteboard photos

**2. TV Display Page (`/display/:token`)**
- Route: `/display/:token` where token is gym's `display_token` (unguessable 24-char hex)
- Public, no login required
- Fetches workout via `get_display_workout(token)` RPC
- Real-time subscriptions on `workouts`, `blocks`, `block_exercises` tables
- Visual design: graphite background (#14181C), JetBrains Mono timer, Oswald labels, teal/amber/coral block-type color coding (mirrors gym's physical LED clock)
- Two display states:
  - **Overview:** full workout with all blocks visible (pre-session)
  - **Live:** single active block in focus with timer, exercises, coaching notes (during `session_status = 'in_progress'`)
- D-pad remote control (keydown listeners for Arrow Right/Left/Enter)
- Leading Zero LLC branding: subtle (favicon + low-opacity footer only)

**3. Deployment**
- ✅ Code pushed to GitHub (`jcratledge/workout-planner`, private repo)
- ✅ Connected to Cloudflare Pages CI/CD (auto-deploy on push)
- ✅ 14 GitHub issues created and tracked on a Kanban board (completed issues closed, open backlog for Builder UI)
- ✅ Custom domain `wodboard.leadingzero.net` wired to Cloudflare Worker
- ✅ Live and functioning

---

## User Roles & Permissions

**Three user personas identified:**

1. **Planner/Admin** — central gym network planner; can see/edit workouts for all gyms; email/password auth (decided)
2. **Trainer** — creates and publishes workouts for their own gym; email/password auth; can control live session via D-pad remote on TV display
3. **Gym Members** — view-only; see live workout on gym TV during class

**Permission Model:**
- Trainers scoped by `gym_id` (RLS enforces this)
- Planners have `gym_id = null` (can access all gyms)
- TV display is **public** (no login) but scoped by unguessable `display_token`
- Session control (block advancement) goes through `advance_display_session()` RPC using only the token (no trainer auth required on the TV device itself)

---

## Workout Structure & Data Model

**Three-part session format** (extracted from real whiteboard photos):
1. **Connection** — warmup block (teal color coding)
2. **Empowerment** — main work block (amber color coding)
3. **Accountability** — finisher block (coral color coding)

**Block data includes:**
- `block_type` (enum: warmup, straight_sets, circuit, pyramid, emom, amrap, interval)
- `rounds`, `time_cap_seconds`, `work_seconds`, `rest_seconds`, `notes`
- Exercises within each block with per-side reps (`repsRight`/`repsLeft`), tempo notation, rest intervals

**Session state tracking:**
- `session_status`: 'not_started' | 'in_progress' | 'complete'
- `current_block_id`: which block is active
- `current_block_started_at`: timestamp for timer calculation

---

## UI/UX Decisions Made

### TV Display Layout
- **Landscape-optimized** (16:9 aspect ratio, Chromecast output; portrait mode not feasible on TV hardware)
- **Timer prominence:** large, LED-clock-style (monospaced font), but not oversized
- **Header compression:** gym name + date squeezed to single line, minimal padding (reduce from 10-12% to ~5-6% of screen)
- **Exercise visibility:** keep readable, important secondary element
- **Metadata (CONNECTION / ELAPSED):** compress hard or remove (low-value information)
- **No drag-and-drop:** explicit decision for Builder UI (add-from-library + up/down reorder instead; must work on both laptop and mobile/touch)

### Remote Control & Navigation
- **D-pad as the only control device** — no trainer phone integration required (eliminates battery/compatibility concerns)
- **Current D-pad mapping (TWO-STAGE BLOCK ADVANCEMENT):**
  - First press → move block to **READY** state (preview, timer paused)
  - Second press → move to **START** state (timer begins running)
  - This decouple matches how trainers actually coach: explain the movement verbally, then start the clock
- **Separate timer controls needed** (TBD in native app): start/pause timer independently from block advancement
- **Navigation challenge with browser:** TV Bro and other Android browsers expose unwanted UI chrome (back/forward/reload buttons), adding cognitive load. Solution: migrate to native Android TV app.

### Display Token Simplification (OPEN DECISION)
- Current token: 24-character hex string (unguessable but painful to type on D-pad)
- **Options considered:**
  - Option 1: Use gym name slug (`/display/gym1`, `/display/leadingzero-main`)
  - Option 2: Use short numeric ID (`/display/1`)
  - Option 3: Keep token but shorten to 6-8 chars (still unguessable, easier to type)
- **Decision pending:** choose Option 1 or 2 for simplicity (no real security threat at gym scope)
- **Workaround implemented:** bookmark the URL in browser so it's one-click access (avoids repeated D-pad typing)

---

## What's NOT Built Yet

### Builder UI (Trainer-Facing Workout Creation)
- **Scope:** planner/trainer interface to create, edit, and publish workouts
- **Requirements:**
  - Exercise library browser (search/add-from-library, no drag-and-drop)
  - Up/down reorder controls for blocks and exercises (must work on laptop + mobile equally)
  - Workout creation form structured by Connection/Empowerment/Accountability sections
  - Trainer auth (email/password login, decided)
  - Multi-gym support (trainers scoped to their gym, planners see all)
  - Multi-trainer permissions per gym (future backlog item)
- **Status:** 14 GitHub issues open, tracking this as major next phase

### Trainer Authentication
- Email/password scheme decided
- Not yet implemented; TV display uses token-based access only (no auth required)

---

## Navigation Flows & Use Cases

### Use Case 1: Daily Workout Setup (Trainer Workflow)
1. Trainer logs into Builder UI (email/password)
2. Creates/edits workout for today (Connection → Empowerment → Accountability)
3. Selects exercises from library, reorders with up/down arrows, adds reps/tempo/notes
4. Publishes workout
5. Workout appears live on gym's TV display within seconds (realtime subscription)

### Use Case 2: Live Session Control (Trainer + TV Display)
1. Session begins; trainer stands at TV with Chromecast remote
2. Presses D-pad **Right** (or **Enter**) to advance to first block → block moves to READY state (preview mode, timer paused)
3. Explains the movement to class verbally
4. Presses D-pad **Right** again → block moves to START state, timer begins running
5. Timer counts up (elapsed time) or down depending on block type (EMOM, AMRAP, intervals)
6. Trainer presses D-pad **Left** to go back to previous block if needed
7. When block is complete, trainer advances to next block (Empowerment), timer resets
8. Cycle repeats for Accountability (finisher)
9. When last block is complete, session ends (status = 'complete')

### Use Case 3: Chromecast Setup (One-Time)
1. Trainer navigates to `https://wodboard.leadingzero.net/display/d71ebe7f40389eb8f677ad9d` on Chromecast browser (painful D-pad typing OR simplified token)
2. Bookmarks the URL
3. Future sessions: just click bookmark, page loads instantly

---

## Open Questions & Unresolved Decisions

1. **Display token scheme:** Shorten to 6-8 chars, or switch to gym name slug (Option 1/2/3 above)?
   - *Impact:* UX friction on D-pad entry; affects RPC lookup logic
   - *Decision needed before:* building native Android TV app

2. **Timer pause/resume logic:** How should trainers pause mid-block?
   - Current model: advancing block resets timer
   - Needed: independent pause/resume control that doesn't change blocks
   - *Database requirement:* add `timer_paused_at` or similar state field
   - *D-pad mapping:* which keys trigger pause/resume/reset?
   - *Decision needed before:* finalizing native app D-pad controls

3. **Multi-location rollout:** How should the system handle 2–5 gym locations?
   - Trainer sees only their gym's workouts (enforced via RLS)
   - Planner sees all gyms (admin dashboard TBD)
   - Multiple displays per gym (one per class/time slot) not yet scoped
   - *Decision needed before:* Builder UI implementation

4. **Browser vs native app path:**
   - **Decided:** Build native Android TV app instead of relying on browser (TV Bro, Firefox kiosk modes are insufficient)
   - *Timeline:* 2–3 weeks for native app (Kotlin + Jetpack Compose)
   - *Feasibility:* high; will sideload APK to Chromecast (no App Store)
   - *Next step:* start Android TV project in Android Studio (handoff to new chat recommended)

5. **Supabase migrations folder in GitHub:** 
   - Four migration files (001–006) confirmed in project knowledge
   - Unknown if `/supabase/migrations` folder exists in repo yet
   - *Action:* verify folder presence; if missing, create and commit all migration scripts for version control

6. **Future: move servicetime off Vercel to Cloudflare**
   - Currently servicetime.leadingzero.net uses Vercel (DNS-only CNAME on Cloudflare)
   - Deferred; no immediate action needed
   - *Future:* consolidate all projects to Cloudflare if beneficial

---

## Key Principles & Learnings

- **Vercel free tier prohibits commercial use** — Cloudflare Pages is the correct choice for Leading Zero LLC
- **Cloudflare has moved to Workers-based static asset model** — `wrangler.jsonc` with `assets` directory and `not_found_handling: "single-page-application"` is the current standard (not `_redirects`)
- **"WOD" not "Box"** — WOD (Workout of the Day) is trainer/member terminology; "Box" = gym itself
- **Database RLS is the real security boundary** — schema visibility doesn't matter if RLS policies enforce it correctly
- **Simplicity over features** — no drag-and-drop, no phone integration, D-pad only; trainers shouldn't need to learn new tech
- **GitHub Issues as portfolio signal** — work is deliberately documented to reflect real-world engineering practice for job search

---

## File Locations & Key References

**GitHub repo:** `jcratledge/workout-planner` (private)  
**Supabase project:** "workout-planner"  
**Domain:** `wodboard.leadingzero.net` (Cloudflare Workers)  
**GitHub Issues:** 14 open/closed, Kanban board tracking  
**Project knowledge synced:** Migrations 001–006, seed data, RPC functions, TV display component

**SQL migrations in project:**
- 001_schema.sql — core tables, enums, RLS policies
- 002_seed.sql — exercise library and 4 sample workouts
- 003_live_session.sql — session-state tracking
- 004_realtime.sql — realtime publication setup
- 005_display_controls.sql — `advance_display_session()` RPC
- 006_ready_state.sql — two-stage block advancement (READY → START)

---

## Next Steps (Prioritized)

1. **Decide on display token scheme** (simplified vs current hex) — small decision, enables native app work
2. **Build native Android TV app** (Kotlin + Jetpack Compose) — 2–3 weeks, sideload to Chromecast
3. **Implement D-pad control logic** in native app (next/previous blocks, timer start/pause/reset)
4. **Builder UI (add-from-library, reorder controls, trainer auth)** — large phase, multiple GitHub issues
5. **Multi-gym & multi-trainer permissions** — backlog
6. **Future: native app distribution & documentation** for production rollout

---

**This handoff is current as of [TODAY'S DATE]. Josh is the primary engineer and maintainer.**