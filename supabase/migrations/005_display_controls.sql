-- =========================================================
-- Display-driven session control
-- Lets the public TV page (no login) advance/rewind its own
-- live session using only the display_token it already has —
-- e.g. from a Chromecast/Fire Stick remote's D-pad, with no
-- phone or trainer login involved.
-- Run after 001-004.
-- =========================================================

create or replace function advance_display_session(token text, direction text)
returns void as $$
declare
  v_gym_id uuid;
  v_workout_id uuid;
  v_current_block_id uuid;
  v_current_order int;
  v_target_block_id uuid;
begin
  select g.id into v_gym_id from gyms g where g.display_token = token;
  if v_gym_id is null then
    raise exception 'invalid display token';
  end if;

  select w.id, w.current_block_id into v_workout_id, v_current_block_id
  from workouts w
  where w.gym_id = v_gym_id and w.status = 'published'
  order by w.workout_date desc
  limit 1;

  if v_workout_id is null then
    raise exception 'no published workout for this gym';
  end if;

  if direction = 'reset' then
    update workouts
    set session_status = 'not_started', current_block_id = null, current_block_started_at = null
    where id = v_workout_id;
    return;
  end if;

  if v_current_block_id is null then
    -- Session hasn't started yet: "next" (or pressing Select on the overview) begins at block 1.
    select id into v_target_block_id
    from blocks where workout_id = v_workout_id order by block_order asc limit 1;
  else
    select block_order into v_current_order from blocks where id = v_current_block_id;

    if direction = 'next' then
      select id into v_target_block_id
      from blocks
      where workout_id = v_workout_id and block_order > v_current_order
      order by block_order asc limit 1;
    elsif direction = 'previous' then
      select id into v_target_block_id
      from blocks
      where workout_id = v_workout_id and block_order < v_current_order
      order by block_order desc limit 1;
    end if;
  end if;

  if v_target_block_id is not null then
    update workouts
    set session_status = 'in_progress',
        current_block_id = v_target_block_id,
        current_block_started_at = now()
    where id = v_workout_id;
  elsif direction = 'next' then
    -- Advancing past the last block ends the session.
    update workouts set session_status = 'complete' where id = v_workout_id;
  end if;
  -- direction = 'previous' with no earlier block: no-op, already at the start.
end;
$$ language plpgsql security definer;

-- Explicit grants — belt-and-suspenders alongside Postgres' default
-- PUBLIC execute privilege, in case that default was ever revoked.
grant execute on function advance_display_session(text, text) to anon, authenticated;
grant execute on function get_display_workout(text) to anon, authenticated;
