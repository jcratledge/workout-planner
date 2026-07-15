-- =========================================================
-- Workout Planner PWA — Core Schema
-- Run this in the Supabase SQL editor (or via `supabase migration`)
-- =========================================================

-- ---------- Enums ----------
create type user_role as enum ('admin', 'trainer');
create type block_type as enum (
  'warmup',       -- loose warm-up movements, usually x rounds, no strict scoring
  'straight_sets',-- simple list: exercise x sets x reps
  'circuit',      -- fixed number of rounds through a list of exercises
  'pyramid',      -- reps climb (or drop) each round, e.g. Rd1 x1 ... Rd6 x6
  'emom',         -- every-minute-on-the-minute, time-capped
  'amrap',        -- as many rounds as possible, time-capped
  'interval'      -- work/rest interval finisher, e.g. 30s work / 30s rest
);

-- ---------- Gyms ----------
create table gyms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  -- unguessable token used in the public TV display URL: /display/{display_token}
  display_token text unique not null default encode(gen_random_bytes(12), 'hex'),
  created_at timestamptz not null default now()
);

-- ---------- Profiles (extends Supabase auth.users) ----------
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role user_role not null default 'trainer',
  -- null gym_id = admin/planner who can see all gyms
  gym_id uuid references gyms(id),
  created_at timestamptz not null default now()
);

-- ---------- Exercise library ----------
-- The reusable catalog the builder drags from, instead of retyping every time.
create table exercises (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  category text,        -- 'warmup', 'strength', 'cardio', 'core', 'plyo'
  equipment text,        -- 'bodyweight', 'kettlebell', 'wall_ball', 'landmine', 'machine'
  default_notes text,
  created_at timestamptz not null default now()
);

-- ---------- Workouts ----------
-- One row per gym per day.
create table workouts (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references gyms(id),
  workout_date date not null,
  status text not null default 'draft' check (status in ('draft', 'published')),
  created_by uuid references profiles(id),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (gym_id, workout_date)
);

-- ---------- Blocks ----------
-- The named sections of a workout: Connection / Empowerment / Accountability, etc.
create table blocks (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid not null references workouts(id) on delete cascade,
  label text not null,               -- 'Connection', 'Empowerment', 'Accountability', or custom
  block_order int not null,          -- display/drag order within the workout
  block_type block_type not null default 'straight_sets',
  rounds int,                        -- fixed round count, e.g. 5 (circuit) or 6 (pyramid)
  time_cap_seconds int,              -- EMOM/AMRAP duration, e.g. 720 for "12 min"
  work_seconds int,                  -- interval work time, e.g. 30
  rest_seconds int,                  -- interval rest time, e.g. 30
  notes text
);

-- ---------- Block exercises ----------
-- Individual exercise entries within a block, in order.
create table block_exercises (
  id uuid primary key default gen_random_uuid(),
  block_id uuid not null references blocks(id) on delete cascade,
  exercise_id uuid references exercises(id),
  freetext_name text,          -- used when there's no library match, e.g. "Coaches Choice"
  exercise_order int not null,
  sets int,
  reps text,                   -- kept as text: '5', '8-10', '30 sec' all need to fit
  reps_right text,             -- for R/L split reps, e.g. '3R'
  reps_left text,              -- e.g. '3L'
  tempo text,                  -- e.g. '5-2-1' (eccentric-pause-concentric seconds)
  rest_seconds int,
  notes text,
  constraint exercise_or_freetext check (
    exercise_id is not null or freetext_name is not null
  )
);

-- ---------- Helpful indexes ----------
create index idx_workouts_gym_date on workouts (gym_id, workout_date);
create index idx_blocks_workout on blocks (workout_id, block_order);
create index idx_block_exercises_block on block_exercises (block_id, exercise_order);

-- ---------- Row Level Security ----------
alter table gyms enable row level security;
alter table profiles enable row level security;
alter table exercises enable row level security;
alter table workouts enable row level security;
alter table blocks enable row level security;
alter table block_exercises enable row level security;

-- Helper: is the current user an admin?
create or replace function is_admin() returns boolean as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'admin'
  );
$$ language sql stable security definer;

-- Helper: which gym does the current user belong to?
create or replace function my_gym_id() returns uuid as $$
  select gym_id from profiles where id = auth.uid();
$$ language sql stable security definer;

-- Gyms: anyone authenticated can read gym names (needed for the picker);
-- only admins can create/edit gyms.
create policy "gyms_select_all" on gyms for select using (true);
create policy "gyms_admin_write" on gyms for all using (is_admin());

-- Profiles: users can see their own profile + admins see everyone.
create policy "profiles_select_own_or_admin" on profiles
  for select using (id = auth.uid() or is_admin());
create policy "profiles_update_own" on profiles
  for update using (id = auth.uid());

-- Exercises: shared library, readable by all authenticated users,
-- writable by anyone authenticated (trainers contribute to the library too).
create policy "exercises_select_all" on exercises for select using (auth.uid() is not null);
create policy "exercises_insert_authenticated" on exercises for insert with check (auth.uid() is not null);
create policy "exercises_update_authenticated" on exercises for update using (auth.uid() is not null);

-- Workouts: admins see/edit all; trainers see/edit only their own gym's workouts.
create policy "workouts_select" on workouts
  for select using (is_admin() or gym_id = my_gym_id());
create policy "workouts_write" on workouts
  for all using (is_admin() or gym_id = my_gym_id());

-- Blocks / block_exercises inherit access through their parent workout.
create policy "blocks_select" on blocks
  for select using (
    is_admin() or workout_id in (select id from workouts where gym_id = my_gym_id())
  );
create policy "blocks_write" on blocks
  for all using (
    is_admin() or workout_id in (select id from workouts where gym_id = my_gym_id())
  );

create policy "block_exercises_select" on block_exercises
  for select using (
    is_admin() or block_id in (
      select b.id from blocks b
      join workouts w on w.id = b.workout_id
      where w.gym_id = my_gym_id()
    )
  );
create policy "block_exercises_write" on block_exercises
  for all using (
    is_admin() or block_id in (
      select b.id from blocks b
      join workouts w on w.id = b.workout_id
      where w.gym_id = my_gym_id()
    )
  );

-- ---------- Public TV display access ----------
-- The display page has NO login. It reads published workouts via the
-- gym's display_token, using a SECURITY DEFINER function so RLS above
-- (which requires auth.uid()) doesn't block it.
create or replace function get_display_workout(token text)
returns table (
  workout_id uuid,
  workout_date date,
  gym_name text,
  block_id uuid,
  block_label text,
  block_order int,
  block_type block_type,
  rounds int,
  time_cap_seconds int,
  work_seconds int,
  rest_seconds int,
  block_notes text,
  exercise_id uuid,
  exercise_name text,
  freetext_name text,
  exercise_order int,
  sets int,
  reps text,
  reps_right text,
  reps_left text,
  tempo text,
  ex_rest_seconds int,
  ex_notes text
) as $$
  select
    w.id, w.workout_date, g.name,
    b.id, b.label, b.block_order, b.block_type, b.rounds,
    b.time_cap_seconds, b.work_seconds, b.rest_seconds, b.notes,
    be.exercise_id, e.name, be.freetext_name, be.exercise_order,
    be.sets, be.reps, be.reps_right, be.reps_left, be.tempo,
    be.rest_seconds, be.notes
  from gyms g
  join workouts w on w.gym_id = g.id and w.status = 'published'
  join blocks b on b.workout_id = w.id
  left join block_exercises be on be.block_id = b.id
  left join exercises e on e.id = be.exercise_id
  where g.display_token = token
  order by w.workout_date desc, b.block_order, be.exercise_order
  limit 200;
$$ language sql stable security definer;
