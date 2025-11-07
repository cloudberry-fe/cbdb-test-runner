---@sql@ Create test table 1
drop table if exists t_view_1 CASCADE;
create table t_view_1
( id int,
date date,
amt decimal(10,2)
 ) DISTRIBUTED BY (id); 
insert into t_view_1 SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-04',INTERVAL '1 day') as date,  generate_series(1,100000) id;
--- Create test table 2
drop table if exists t_view_2 CASCADE;
create table t_view_2
( id int,
  state text
 ) DISTRIBUTED BY (id); 
insert into t_view_2 SELECT generate_series(1,10),'y';
--- Create materialized view joining two tables
drop MATERIALIZED VIEW if exists mv_01;
CREATE MATERIALIZED VIEW mv_01
with (appendonly=true, compresstype=zstd, compresslevel=1) 
 AS
select t1.* from t_view_2 t2 left join t_view_1 t1 on t1.id = t2.id
distributed by (id);
--- Refresh materialized view
refresh materialized view mv_01;
--- Create index on materialized view
create index idx_01 on mv_01(id);
--- Clear view:
refresh materialized view mv_01 with no data;
--- Define materialized view auto-refresh frequency:
--drop task if exists refresh_mv_01;
--CREATE TASK refresh_mv_01 SCHEDULE '3 seconds' AS $$refresh materialized view mv_01 with data$$;