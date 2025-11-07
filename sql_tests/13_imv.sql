---@sql@ Create test table 1
drop table if exists t_incrt_01 CASCADE;
create table t_incrt_01( id int,
date date,
amt decimal(10,2)
 )DISTRIBUTED BY (id);
 --- Create test table 2
drop table if exists t_incrt_02 CASCADE;
create table t_incrt_02( id int,
date date,
amt decimal(10,2)
 )DISTRIBUTED BY (id);
 --- Insert test data
 insert into t_incrt_01 SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-04',INTERVAL '1 day') as date,  generate_series(1,300000) id;
 insert into t_incrt_02 SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-04',INTERVAL '1 day') as date,  generate_series(1,300000) id;
--- Create incremental materialized view
CREATE INCREMENTAL MATERIALIZED VIEW incrt_mv_01 AS 
select t1.* from t_incrt_01 t1 join t_incrt_02 t2 on t1.id = t2.id
DISTRIBUTED BY (id);
--- Query materialized view
select count(*) from incrt_mv_01;
--- Insert data
insert into t_incrt_01 select * from t_incrt_02 limit 100;
--- Query materialized view, auto-update
select count(*) from incrt_mv_01;