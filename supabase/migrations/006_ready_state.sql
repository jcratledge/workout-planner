-- =========================================================
-- Two-stage block advancement: arrive at a block (ready, timer
-- not running) -> start its timer -> advance to the next block
-- (also arriving in "ready" state). Lets a trainer explain the
-- movements before the clock starts, using a single remote button.
-- Run after 001-005.
-- =========================================================

create or replace function advance_display_session(token text, direction text)
returns void as $$
declare
  v_gym_id uuid;
  v_workout_id uuid;
  v_current_block_id uuid;
  v_current_started_at timestamptz;
  v_current_order int;
  v_target_block_id uuid;
begin
  select g.id into v_gym_id from gyms g where g.display_token = token;
  if v_gym_id is null then
    raise exception 'invalid display token';
  end if;

  select w.id, w.current_block_id, w.current_block_started_at
    into v_workout_id, v_current_block_id, v_current_started_at
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

  if direction = 'next' then
    if v_current_block_id is null then
      -- Nothing shown yet: arrive at block 1, timer not running.
      select id into v_target_block_id
      from blocks where workout_id = v_workout_id order by block_order asc limit 1;
      if v_target_block_id is not null then
        update workouts
        set session_status = 'in_progress', current_block_id = v_target_block_id, current_block_started_at = null
        where id = v_workout_id;
      end if;

    elsif v_current_started_at is null then
      -- On a block, trainer just finished explaining it: start the clock.
      update workouts set current_block_started_at = now() where id = v_workout_id;

    else
      -- Timer already running: move on, arriving at the next block un-timed.
      select block_order into v_current_order from blocks where id = v_current_block_id;
      select id into v_target_block_id
      from blocks
      where workout_id = v_workout_id and block_order > v_current_order
      order by block_order asc limit 1;

      if v_target_block_id is not null then
        update workouts
        set current_block_id = v_target_block_id, current_block_started_at = null
        where id = v_workout_id;
      else
        update workouts set session_status = 'complete' where id = v_workout_id;
      end if;
    end if;

  elsif direction = 'previous' then
    if v_current_block_id is null then
      return; -- already at the very start, nothing before it
    end if;
    select block_order into v_current_order from blocks where id = v_current_block_id;
    select id into v_target_block_id
    from blocks
    where workout_id = v_workout_id and block_order < v_current_order
    order by block_order desc limit 1;

    if v_target_block_id is not null then
      update workouts
      set current_block_id = v_target_block_id, current_block_started_at = null
      where id = v_workout_id;
    end if;
  end if;
end;
$$ language plpgsql security definer;

grant execute on function advance_display_session(text, text) to anon, authenticated;