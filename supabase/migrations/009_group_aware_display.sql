-- Updates the public display RPC to walk through block_groups instead
-- of reading block_exercises directly off block_id, so sub-rounds and
-- partner tracks (P1/P2) render correctly on the TV. Also surfaces the
-- branding fields added in 007 and each exercise's video_url.
-- Run after 001-008.

drop function if exists get_display_workout(text);

create or replace function get_display_workout(token text)
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
  join blocks b on b.workout_id = w.id
  left join block_groups bg on bg.block_id = b.id
  left join block_exercises be on be.group_id = bg.id
  left join exercises e on e.id = be.exercise_id
  where g.display_token = token
  order by w.workout_date desc, b.block_order, bg.group_order, be.exercise_order
  limit 300;
$$ language sql stable security definer;

grant execute on function get_display_workout(text) to anon, authenticated;
