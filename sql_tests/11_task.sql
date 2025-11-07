---@sql@ Create test table
drop table if exists t_task;
CREATE TABLE t_task (message TEXT,time timestamp);
--- Create Task that inserts a record every three seconds
drop task if exists task_insert_t_task;
CREATE TASK task_insert_t_task SCHEDULE '3 seconds' AS $$INSERT INTO t_task values ('Hello',now())$$;
--- Query task status
select * from pg_task;
--- Query task execution history
select * from pg_task_run_history;
--- Deactivate task
alter task task_insert_t_task not active;
--- Activate task
alter task task_insert_t_task active;