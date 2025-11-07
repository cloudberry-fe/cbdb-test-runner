--- Create Pax compression table
drop table if exists t_pax;
create table t_pax( id int,
date date,
amt decimal(10,2)
 ) using pax 
 WITH(minmax_columns='id,date', cluster_columns='id',compresstype=zstd, compresslevel=3)
DISTRIBUTED BY (id);
--- insert data
insert into t_pax SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-04',INTERVAL '1 day') as date,  generate_series(1,1000000) id;
--- query pax table size (21MB)
select pg_size_pretty(pg_total_relation_size('t_pax')) as table_size;
--- query pax table (100ms)
select * from t_pax where id= 1000;

--- Create heap table
drop table if exists t_heap;
create table t_heap( id int,
date date,
amt decimal(10,2)
 )DISTRIBUTED BY (id);
--- insert data
insert into t_heap SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-04',INTERVAL '1 day') as date,  generate_series(1,1000000) id;
--- query heap table size (168MB)
select pg_size_pretty(pg_total_relation_size('t_heap')) as table_size;
--- query heap table (500ms)
select * from t_heap where id= 1000;

--- Create ao_co compression table
drop table if exists t_column;
create table t_column( id int,
date date,
amt decimal(10,2)
 )using ao_column 
 with(COMPRESSTYPE=zstd, COMPRESSLEVEL=3)
 DISTRIBUTED BY (id);
--- insert data
insert into t_column SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-04',INTERVAL '1 day') as date,  generate_series(1,1000000) id;
--- query ao_co table size (21MB)
select pg_size_pretty(pg_total_relation_size('t_column')) as table_size;
--- query ao_co table (120ms)
select * from t_column where id= 1000;