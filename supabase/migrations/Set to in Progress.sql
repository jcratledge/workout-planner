update workouts
set session_status = 'in_progress',
    current_block_id = (
      select id from blocks
      where workout_id = workouts.id
      order by block_order asc limit 1
    ),
    current_block_started_at = now()
where gym_id = '11111111-1111-1111-1111-111111111111'
  and workout_date = '2026-07-09';