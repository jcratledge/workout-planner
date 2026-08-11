-- Per-gym branding (logo on the splash screen) and resolves the
-- "gym-level vs per-workout coaching message" open decision from
-- Sprint 3 by adding both: a gym-level default and a per-workout
-- override.
-- Run after 001-006.

alter table gyms add column logo_url text;
alter table gyms add column splash_message text;

alter table workouts add column splash_message text;
