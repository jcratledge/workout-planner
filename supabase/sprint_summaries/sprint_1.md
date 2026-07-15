Here's a structured summary formatted for pasting into a new conversation:

---

## WODBoard — Product Decisions Handoff

**Context:** Workout Planner PWA for a 2–5 gym CrossFit-style network, replacing a manual "planner texts trainer → trainer writes on whiteboard" workflow. Built by Leading Zero LLC (software vendor). Real-world data pulled from 4 whiteboard photos to inform structure.

### User Roles & Permissions
- **Central planner (admin)** — builds/edits workouts for any gym
- **Trainers** — can also build/edit workouts, but scoped to their own gym only (enforced via Row Level Security)
- **Trainer auth**: email/password (not magic link, not shared logins)
- **TV Display**: no login at all — public, accessed via an unguessable per-gym token in the URL
- Daily text-message-to-trainer step is being **eliminated entirely** — the app becomes the sole source of truth

### Use Cases
1. Planner or trainer builds a workout: assign to a gym + date, structured as ordered **blocks** (e.g. Connection / Empowerment / Accountability), each block typed (warmup, straight sets, circuit, pyramid, EMOM, AMRAP, interval), containing exercises pulled from a reusable library or entered as freetext ("Coach's Choice")
2. Workout stays in **draft** until explicitly **published** — nothing reaches the TV until then
3. TV Display shows the **full plan overview** before a session starts, then switches to a **single live block view** once the trainer begins
4. Trainer runs class using **only the TV's own remote** — no phone required — advancing through blocks and starting each block's timer manually
5. Coaching cues (safety reminders, motivational lines) attached per block, shown on-screen during that block, separate from internal builder notes

### Navigation Flows
- **TV Display**: `/display/:token` — public route
  - Flow: *Overview (all blocks, nothing started)* → press Next/OK → *arrive at Block 1 (ready, timer static)* → press again → *timer starts* → work happens → press again → *arrive at Block 2 (ready)* → repeat → last block finishes → press Next → *session marked complete*
  - Previous/Left steps back a block (arrives in "ready," not re-timed)
- **Builder/trainer app**: not yet built — will sit behind login, with routes for the workout builder (per gym/date) and exercise library management

### UI/UX Decisions
- **Builder: explicitly NOT drag-and-drop.** Instead — add exercises via search/select from the library, reorder via simple up/down buttons. Must work identically on laptop and mobile (touch drag-and-drop was judged unreliable/unnecessary).
- **TV Display**: portrait-first layout, LED-clock-inspired monospaced timer (echoes the gym's real physical interval timer), block-type color coding (teal = Connection/warmup, amber = Empowerment/main work, coral = Accountability/finisher), dark graphite theme.
- **Two-stage timer per block**, not a single instant start: *arrive → explain movements → manually start clock → advance*, so a trainer can talk through movements before the clock runs. Timer computed client-side from one timestamp + block config, no server-side ticking.
- **Remote control**: works via both raw arrow-key/Enter events *and* a focus+click fallback, since some TV browsers intercept D-pad presses as focus navigation rather than raw key events (unconfirmed which behavior TV Bro uses — flagged as untested).
- **Branding**: Leading Zero LLC shown *subtly only* — favicon (mountain L/Z mark) + a quiet, low-opacity "Powered by Leading Zero" footer credit. Not a prominent brand, since it's the vendor's identity, not the gym network's.

### Open Questions / Unresolved
- Real end-to-end test on the physical Chromecast with Google TV + TV Bro has **not yet happened** — app isn't deployed to a live URL yet, and it's unconfirmed whether TV Bro forwards D-pad presses as raw keydown events or focus/click events
- Deployment platform changed from Vercel to **Cloudflare Pages** (Vercel's free tier prohibits commercial use) — decision made, not yet executed
- Custom domain setup (a subdomain of leadingzero.net) not yet configured
- Only "Downtown Gym" has seeded workout data; "Uptown Gym" has none — worth seeding before testing multi-gym behavior
- Rep ladders/pyramids (e.g. a descending-reps superset) are currently stored as freetext notes rather than fully structured data — accepted as fine for v1, revisit only if the Builder needs to auto-generate these patterns
- Whether a block needs more than one coaching cue (e.g. one early, one mid-block) — decided one static cue per block is enough for now
- Builder UI itself has not been started