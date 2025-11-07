--- @sql@ create table
drop table if exists t_parallel;
CREATE TABLE t_parallel
( id int,
date date,
amt decimal(10,2)
 ) DISTRIBUTED BY (id); 
--- insert data
insert into t_parallel SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-04',INTERVAL '1 day') as date,  generate_series(1,1000000) id;
--- execute query
EXPLAIN analyze select count(*) from t_parallel t1 left join t_parallel t2 on t1.id = t2.id ;

--- enable parallel
SET enable_parallel = ON;
SET optimizer = OFF;
SET max_parallel_workers_per_gather = 4;
--- parallel query 
EXPLAIN analyze select count(*) from t_parallel t1 left join t_parallel t2 on t1.id = t2.id ;