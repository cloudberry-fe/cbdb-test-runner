--- @sql@ create extension
CREATE EXTENSION if not exists pg_hint_plan;
--- Enable user level pg_hint_plan
ALTER USER gpadmin SET session_preload_libraries='pg_hint_plan';
--- create table
drop table if exists t_hint01;
CREATE TABLE t_hint01
( id int,
date date,
amt decimal(10,2)
 ) DISTRIBUTED BY (id); 
 drop table if exists t_hint02;
 CREATE TABLE t_hint02
( id int,
date date,
amt decimal(10,2)
 ) DISTRIBUTED BY (id); 
 CREATE INDEX idx_t_hint02 ON t_hint02(id);
--- insert data
insert into t_hint01 SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-04',INTERVAL '1 day') as date,  generate_series(1,1000) id;
insert into t_hint02 SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-04',INTERVAL '1 day') as date,  generate_series(1,100000) id;
--- set optimizer to off
/*+ SET(optimizer off) */EXPLAIN SELECT * FROM t_hint01 t1 JOIN t_hint02 t2 ON t1.id = t2.id;
--- Force IndexScan
EXPLAIN SELECT /*+ IndexScan(t1) */ * FROM t_hint02 t1 WHERE id = 10;
--- Force SeqScan
EXPLAIN SELECT /*+ SeqScan(t1)  */ * FROM t_hint02 t1 WHERE id = 10;
--- Force NestLoop
EXPLAIN SELECT /*+ NestLoop(t1 t2) */ * FROM t_hint01 t1 JOIN t_hint02 t2 ON t1.id = t2.id WHERE t1.id = 10;
--- Force HashJoin
EXPLAIN SELECT /*+ HashJoin(t1 t2) */ * FROM t_hint01 t1 JOIN t_hint02 t2 ON t1.id = t2.id WHERE t1.id = 10;