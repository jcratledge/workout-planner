-- =========================================================
-- Seed data — pulled directly from your 4 whiteboard photos
-- Run after 001_schema.sql
-- =========================================================

-- ---------- Gyms ----------
insert into gyms (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Downtown Gym'),
  ('22222222-2222-2222-2222-222222222222', 'Uptown Gym');

-- ---------- Exercise library ----------
-- Every distinct movement seen across the 4 boards, deduplicated.
insert into exercises (name, category, equipment) values
  -- Connection / warm-up
  ('Skip', 'warmup', 'bodyweight'),
  ('Walking Hip Circles', 'warmup', 'bodyweight'),
  ('Slow Lunge, Lunge, Squat', 'warmup', 'bodyweight'),
  ('Toe Touches', 'warmup', 'bodyweight'),
  ('Side to Side Leg Swings', 'warmup', 'bodyweight'),
  ('Prying Squat', 'warmup', 'bodyweight'),
  ('KB Deadlift', 'warmup', 'kettlebell'),
  ('Lizard Lunge', 'warmup', 'bodyweight'),
  ('Hamstring Scoops', 'warmup', 'bodyweight'),
  ('Glute Bridges', 'warmup', 'bodyweight'),
  ('Slow Air Squats', 'warmup', 'bodyweight'),
  ('Jump Squats', 'warmup', 'bodyweight'),
  ('KB Cleans', 'warmup', 'kettlebell'),
  ('Step Back Lunges', 'warmup', 'bodyweight'),
  ('Buttkickers', 'warmup', 'bodyweight'),
  ('Side Shuffle', 'warmup', 'bodyweight'),
  ('Downward Dog to Lizard Lunge', 'warmup', 'bodyweight'),
  ('Single Leg Glute Bridge', 'warmup', 'bodyweight'),
  ('KB Suitcase Deadlift', 'warmup', 'kettlebell'),
  ('KB Swings/Cleans', 'warmup', 'kettlebell'),

  -- Empowerment / main work
  ('Tempo Squats', 'strength', 'bodyweight'),
  ('Single Leg Abductor Deadlift', 'strength', 'bodyweight'),
  ('Clean Lunge', 'strength', 'kettlebell'),
  ('Racked Anchor Squats', 'strength', 'kettlebell'),
  ('KB Deadlift Walks', 'strength', 'kettlebell'),
  ('Landmine Squat to Tall Kneel', 'strength', 'landmine'),
  ('Hamstring Curl off Wall Ball', 'strength', 'wall_ball'),
  ('Suitcase Deadlift into March', 'strength', 'kettlebell'),
  ('Broad Jump to Walkback', 'plyo', 'bodyweight'),
  ('Step Ups / Box Jumps', 'plyo', 'box'),
  ('Wall Sit w/ Calf Raises', 'strength', 'bodyweight'),
  ('Machine / Jump Rope', 'cardio', 'machine'),
  ('KB Swings', 'cardio', 'kettlebell'),

  -- Accountability / finisher
  ('Single Arm KB Straight Leg Situp', 'core', 'kettlebell'),
  ('Bicycles', 'core', 'bodyweight'),
  ('Skater Hops', 'plyo', 'bodyweight'),
  ('High Knees', 'cardio', 'bodyweight'),
  ('Cardio (Coach''s Choice)', 'cardio', 'varies'),
  ('Slam Balls', 'cardio', 'medicine_ball'),
  ('Sit-Ups', 'core', 'bodyweight'),
  ('Coaches Choice', 'varies', 'varies');

-- =========================================================
-- Workout 1 — board dated 2026-06-01
-- =========================================================
do $$
declare
  v_workout_id uuid;
  v_connection_id uuid;
  v_empowerment_id uuid;
  v_emom_id uuid;
  v_accountability_id uuid;
begin
  insert into workouts (gym_id, workout_date, status)
  values ('11111111-1111-1111-1111-111111111111', '2026-06-01', 'published')
  returning id into v_workout_id;

  insert into blocks (workout_id, label, block_order, block_type)
  values (v_workout_id, 'Connection', 1, 'warmup')
  returning id into v_connection_id;

  insert into blocks (workout_id, label, block_order, block_type, rounds)
  values (v_workout_id, 'Empowerment', 2, 'circuit', 5)
  returning id into v_empowerment_id;

  insert into blocks (workout_id, label, block_order, block_type, time_cap_seconds, work_seconds, rest_seconds, notes)
  values (v_workout_id, 'EMOM', 3, 'emom', 720, 30, 30,
    'Alternate: Machine/Jump Rope, Broad Jump to Walkback, Step Ups/Box Jumps, Wall Sit w/ Calf Raises')
  returning id into v_emom_id;

  insert into blocks (workout_id, label, block_order, block_type, work_seconds, rest_seconds)
  values (v_workout_id, 'Accountability', 4, 'interval', 30, 30)
  returning id into v_accountability_id;

  insert into block_exercises (block_id, exercise_id, exercise_order, reps, reps_right, reps_left)
  values
    (v_connection_id, (select id from exercises where name = 'Skip'), 1, null, null, null),
    (v_connection_id, (select id from exercises where name = 'Walking Hip Circles'), 2, null, null, null),
    (v_connection_id, (select id from exercises where name = 'Slow Lunge, Lunge, Squat'), 3, null, null, null),
    (v_connection_id, (select id from exercises where name = 'Toe Touches'), 4, null, '5R', '5L'),
    (v_connection_id, (select id from exercises where name = 'Side to Side Leg Swings'), 5, null, '5R', '5L'),
    (v_connection_id, (select id from exercises where name = 'Prying Squat'), 6, '5', null, null),
    (v_connection_id, (select id from exercises where name = 'KB Deadlift'), 7, '5', null, null);

  insert into block_exercises (block_id, exercise_id, exercise_order, reps, tempo)
  values
    (v_empowerment_id, (select id from exercises where name = 'Tempo Squats'), 1, '6', '5-2-1'),
    (v_empowerment_id, (select id from exercises where name = 'Single Leg Abductor Deadlift'), 2, '8-10', null);

  insert into block_exercises (block_id, exercise_id, exercise_order)
  values
    (v_emom_id, (select id from exercises where name = 'Machine / Jump Rope'), 1),
    (v_emom_id, (select id from exercises where name = 'Broad Jump to Walkback'), 2),
    (v_emom_id, (select id from exercises where name = 'Step Ups / Box Jumps'), 3),
    (v_emom_id, (select id from exercises where name = 'Wall Sit w/ Calf Raises'), 4);

  insert into block_exercises (block_id, exercise_id, exercise_order, reps_right, reps_left)
  values
    (v_accountability_id, (select id from exercises where name = 'Single Arm KB Straight Leg Situp'), 1, 'R', 'L');
end $$;

-- =========================================================
-- Workout 2 — board dated 2026-06-23 (pyramid format)
-- =========================================================
do $$
declare
  v_workout_id uuid;
  v_connection_id uuid;
  v_empowerment_id uuid;
  v_work_id uuid;
  v_accountability_id uuid;
begin
  insert into workouts (gym_id, workout_date, status)
  values ('11111111-1111-1111-1111-111111111111', '2026-06-23', 'published')
  returning id into v_workout_id;

  insert into blocks (workout_id, label, block_order, block_type, rounds, notes)
  values (v_workout_id, 'Connection', 1, 'circuit', 2, '30 sec each movement')
  returning id into v_connection_id;

  insert into blocks (workout_id, label, block_order, block_type, notes)
  values (v_workout_id, 'Empowerment', 2, 'pyramid', '1-6-1 rep pyramid across 6 rounds')
  returning id into v_empowerment_id;

  insert into blocks (workout_id, label, block_order, block_type, time_cap_seconds, notes)
  values (v_workout_id, 'Work Period', 3, 'amrap', 720,
    'P1: Cardio, P2: 10 Jump Squats / 10 Slam Balls / 10 Sit-Ups')
  returning id into v_work_id;

  insert into blocks (workout_id, label, block_order, block_type)
  values (v_workout_id, 'Accountability', 4, 'interval')
  returning id into v_accountability_id;

  insert into block_exercises (block_id, exercise_id, exercise_order, reps)
  values
    (v_connection_id, (select id from exercises where name = 'Lizard Lunge'), 1, null),
    (v_connection_id, (select id from exercises where name = 'Hamstring Scoops'), 2, null),
    (v_connection_id, (select id from exercises where name = 'Toe Touches'), 3, null),
    (v_connection_id, (select id from exercises where name = 'Glute Bridges'), 4, null),
    (v_connection_id, (select id from exercises where name = 'Slow Air Squats'), 5, '5'),
    (v_connection_id, (select id from exercises where name = 'Jump Squats'), 6, '5'),
    (v_connection_id, (select id from exercises where name = 'KB Cleans'), 7, '5'),
    (v_connection_id, (select id from exercises where name = 'Step Back Lunges'), 8, '5R,5L');

  insert into block_exercises (block_id, exercise_id, exercise_order, notes)
  values
    (v_empowerment_id, (select id from exercises where name = 'Clean Lunge'), 1,
     'Rd1: 1 each side -> Rd6: 6 each side, climbing by 1 rep per round');

  insert into block_exercises (block_id, exercise_id, freetext_name, exercise_order, notes)
  values
    (v_work_id, (select id from exercises where name = 'Cardio (Coach''s Choice)'), null, 1, 'Coach-selected cardio'),
    (v_work_id, null, 'Jump Squats / Slam Balls / Sit-Ups (10 each)', 2, null);

  insert into block_exercises (block_id, exercise_id, exercise_order)
  values
    (v_accountability_id, (select id from exercises where name = 'Slam Balls'), 1),
    (v_accountability_id, (select id from exercises where name = 'Bicycles'), 2);
end $$;

-- =========================================================
-- Workout 3 — board dated 2026-06-29
-- =========================================================
do $$
declare
  v_workout_id uuid;
  v_connection_id uuid;
  v_empowerment_id uuid;
  v_emom_id uuid;
  v_accountability_id uuid;
begin
  insert into workouts (gym_id, workout_date, status)
  values ('11111111-1111-1111-1111-111111111111', '2026-06-29', 'published')
  returning id into v_workout_id;

  insert into blocks (workout_id, label, block_order, block_type, notes)
  values (v_workout_id, 'Connection', 1, 'warmup', '1 min each for first 3 movements')
  returning id into v_connection_id;

  insert into blocks (workout_id, label, block_order, block_type, rounds)
  values (v_workout_id, 'Empowerment', 2, 'circuit', 5)
  returning id into v_empowerment_id;

  insert into blocks (workout_id, label, block_order, block_type, time_cap_seconds, notes)
  values (v_workout_id, 'EMOM', 3, 'emom', 720,
    '3-5 Suitcase DL into 30 sec march (L), then (R); 10-15 KB Swings or Cleans')
  returning id into v_emom_id;

  insert into blocks (workout_id, label, block_order, block_type, work_seconds, rest_seconds, rounds)
  values (v_workout_id, 'Accountability', 4, 'interval', 30, 30, 3)
  returning id into v_accountability_id;

  insert into block_exercises (block_id, exercise_id, exercise_order, reps, reps_right, reps_left)
  values
    (v_connection_id, (select id from exercises where name = 'Skip'), 1, null, null, null),
    (v_connection_id, (select id from exercises where name = 'Buttkickers'), 2, null, null, null),
    (v_connection_id, (select id from exercises where name = 'Side Shuffle'), 3, null, null, null),
    (v_connection_id, (select id from exercises where name = 'Single Leg Glute Bridge'), 4, null, '3R', '3L'),
    (v_connection_id, (select id from exercises where name = 'Prying Squat'), 5, '6', null, null),
    (v_connection_id, (select id from exercises where name = 'KB Suitcase Deadlift'), 6, null, '3R', '3L'),
    (v_connection_id, (select id from exercises where name = 'KB Swings/Cleans'), 7, '6', null, null);

  insert into block_exercises (block_id, exercise_id, exercise_order, reps)
  values
    (v_empowerment_id, (select id from exercises where name = 'Landmine Squat to Tall Kneel'), 1, '5'),
    (v_empowerment_id, (select id from exercises where name = 'Hamstring Curl off Wall Ball'), 2, '10');

  insert into block_exercises (block_id, exercise_id, exercise_order, reps)
  values
    (v_emom_id, (select id from exercises where name = 'Suitcase Deadlift into March'), 1, '3-5 into 30 sec march'),
    (v_emom_id, (select id from exercises where name = 'KB Swings/Cleans'), 2, '10-15');

  insert into block_exercises (block_id, exercise_id, exercise_order)
  values
    (v_accountability_id, (select id from exercises where name = 'Skater Hops'), 1),
    (v_accountability_id, (select id from exercises where name = 'High Knees'), 2);
end $$;

-- =========================================================
-- Workout 4 — board dated 2026-07-09
-- =========================================================
do $$
declare
  v_workout_id uuid;
  v_connection_id uuid;
  v_empowerment_id uuid;
  v_accountability_id uuid;
begin
  insert into workouts (gym_id, workout_date, status)
  values ('11111111-1111-1111-1111-111111111111', '2026-07-09', 'published')
  returning id into v_workout_id;

  insert into blocks (workout_id, label, block_order, block_type, rounds, notes)
  values (v_workout_id, 'Connection', 1, 'circuit', 3, '1 min each for skip/buttkickers/side shuffle')
  returning id into v_connection_id;

  insert into blocks (workout_id, label, block_order, block_type, time_cap_seconds, notes)
  values (v_workout_id, 'Empowerment', 2, 'amrap', 720,
    'Descending swings ladder alongside squats/lunges (see notes)')
  returning id into v_empowerment_id;

  insert into blocks (workout_id, label, block_order, block_type, notes)
  values (v_workout_id, 'Accountability', 3, 'straight_sets', 'Coaches Choice')
  returning id into v_accountability_id;

  insert into block_exercises (block_id, exercise_id, exercise_order, reps, reps_right, reps_left)
  values
    (v_connection_id, (select id from exercises where name = 'Skip'), 1, null, null, null),
    (v_connection_id, (select id from exercises where name = 'Buttkickers'), 2, null, null, null),
    (v_connection_id, (select id from exercises where name = 'Side Shuffle'), 3, null, null, null),
    (v_connection_id, (select id from exercises where name = 'Downward Dog to Lizard Lunge'), 4, null, '3R', '3L'),
    (v_connection_id, (select id from exercises where name = 'Slow Air Squats'), 5, '6', null, null),
    (v_connection_id, (select id from exercises where name = 'Toe Touches'), 6, null, '3R', '3L'),
    (v_connection_id, (select id from exercises where name = 'Hamstring Scoops'), 7, null, '3R', '3L');

  insert into block_exercises (block_id, exercise_id, exercise_order, reps, rest_seconds)
  values
    (v_empowerment_id, (select id from exercises where name = 'Racked Anchor Squats'), 1, '4 each side', 30),
    (v_empowerment_id, (select id from exercises where name = 'KB Deadlift Walks'), 2, '4-5 each side', 30);

  insert into block_exercises (block_id, exercise_id, freetext_name, exercise_order, notes)
  values
    (v_empowerment_id, null,
     'Ladder: 30/10, 25/15, 20/20, 15/25, 10/30 (swings-or-cleans / jump squats), :30 rest between rounds',
     3, 'Descending swings, ascending jump squats');

  insert into block_exercises (block_id, exercise_id, exercise_order)
  values
    (v_accountability_id, (select id from exercises where name = 'Coaches Choice'), 1);
end $$;
