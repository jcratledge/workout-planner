-- =========================================================
-- Live Session State Layer
-- Adds: which block is currently on screen, when it started,
-- and a coaching-cue field per block for the TV display.
-- Run after 001_schema.sql and 002_seed.sql.
-- =========================================================

-- ---------- Workouts: track live session state ----------
alter table workouts
  add column session_status text not null default 'not_started'
    check (session_status in ('not_started', 'in_progress', 'complete')),
  add column current_block_id uuid references blocks(id),
  add column current_block_started_at timestamptz;

-- ---------- Blocks: coaching cue shown on the TV during this block ----------
-- Distinct from `notes`, which is builder-facing planning detail.
-- `display_message` is trainer/TV-facing: a motivational line or a
-- safety reminder (e.g. "keep the weight below shoulder height").
alter table blocks
  add column display_message text;

-- ---------- Refresh the public TV display function ----------
-- Postgres won't let CREATE OR REPLACE change a function's output
-- columns, so we drop and recreate it with the new fields included.
drop function if exists get_display_workout(text);

create or replace function get_display_workout(token text)
returns table (
  workout_id uuid,
  workout_date date,
  gym_name text,
  session_status text,
  current_block_id uuid,
  current_block_started_at timestamptz,
  block_id uuid,
  block_label text,
  block_order int,
  block_type block_type,
  rounds int,
  time_cap_seconds int,
  work_seconds int,
  rest_seconds int,
  block_notes text,
  display_message text,
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
    w.session_status, w.current_block_id, w.current_block_started_at,
    b.id, b.label, b.block_order, b.block_type, b.rounds,
    b.time_cap_seconds, b.work_seconds, b.rest_seconds, b.notes, b.display_message,
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

-- ---------- Example: advancing a live session ----------
-- The trainer's "Next" button just needs to run something like this
-- (app-side, with the real workout_id / next block's id):
--
--   update workouts
--   set session_status = 'in_progress',
--       current_block_id = '<next-block-uuid>',
--       current_block_started_at = now()
--   where id = '<workout-uuid>';
--
-- Existing RLS on `workouts` already allows this for trainers on
-- their own gym's workouts, so no new policy is needed.

-- ---------- Optional seed touch-up ----------
-- Give one seeded workout a couple of coaching cues, so the TV
-- has something real to render on the first pass.
update blocks set display_message = 'Move with control — this is about connecting to the movement, not speed.'
where label = 'Connection' and workout_id = (
  select id from workouts where workout_date = '2026-06-01' limit 1
);

update blocks set display_message = 'Keep the kettlebell below shoulder height on the swing — no overhead pressing here.'
where label = 'EMOM' and workout_id = (
  select id from workouts where workout_date = '2026-06-01' limit 1
);
