-- Adds an optional target_date filter to the display RPC so the
-- trainer menu's "Change day" can request a specific past published
-- workout, plus a new RPC to list which recent dates actually have
-- a published workout (so the menu only shows real options).
-- Run after 001-009.

drop function if exists get_display_workout(text);

create or replace function get_display_workout(token text, target_date date default null)
returns table (
  workout_id uuid,
  workout_date date,
  gym_name text,
  gym_logo_url text,
  gym_splash_message text,
  workout_splash_message text,
  session_status text,
  current_block_id uuid,
  current_block_started_at timestamptz,
  block_id uuid,
  block_label text,
  block_order int,
  block_type block_type,
  time_cap_seconds int,
  work_seconds int,
  rest_seconds int,
  block_notes text,
  display_message text,
  group_id uuid,
  group_order int,
  group_rounds int,
  group_track_label text,
  group_notes text,
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
  ex_notes text,
  ex_video_url text
) as $$
  select
    w.id, w.workout_date, g.name, g.logo_url, g.splash_message, w.splash_message,
    w.session_status, w.current_block_id, w.current_block_started_at,
    b.id, b.label, b.block_order, b.block_type,
    b.time_cap_seconds, b.work_seconds, b.rest_seconds, b.notes, b.display_message,
    bg.id, bg.group_order, bg.rounds, bg.track_label, bg.notes,
    be.exercise_id, e.name, be.freetext_name, be.exercise_order,
    be.sets, be.reps, be.reps_right, be.reps_left, be.tempo,
    be.rest_seconds, be.notes, e.video_url
  from gyms g
  join workouts w on w.gym_id = g.id and w.status = 'published'
    and (target_date is null or w.workout_date = target_date)
  join blocks b on b.workout_id = w.id
  left join block_groups bg on bg.block_id = b.id
  left join block_exercises be on be.group_id = bg.id
  left join exercises e on e.id = be.exercise_id
  where g.display_token = token
  order by w.workout_date desc, b.block_order, bg.group_order, be.exercise_order
  limit 300;
$$ language sql stable security definer;

create or replace function list_recent_workout_dates(token text, days_back int default 30)
returns table (workout_date date) as $$
  select w.workout_date
  from workouts w
  join gyms g on g.id = w.gym_id
  where g.display_token = token
    and w.status = 'published'
    and w.workout_date >= (current_date - days_back)
  order by w.workout_date desc;
$$ language sql stable security definer;

grant execute on function get_display_workout(text, date) to anon, authenticated;
grant execute on function list_recent_workout_dates(text, int) to anon, authenticated;
