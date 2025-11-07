--- Create test table
drop table if exists t_list;
CREATE TABLE t_list
( id int,
date date,
amt decimal(10,2)
 ) DISTRIBUTED BY (id) 
PARTITION BY LIST (date) (
  PARTITION P20240401 VALUES ('2024-04-01'),
  PARTITION P20240402 VALUES ('2024-04-02'),
  PARTITION P20240403 VALUES ('2024-04-03'),
  PARTITION P20240404 VALUES ('2024-04-04'),
  DEFAULT PARTITION other
 );
-- Insert test data
insert into t_list SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-04',INTERVAL '1 day') as date,  generate_series(1,100000) id;
-- Query data corresponding to partitions
select date,count(*) from t_list group by date;
-- Check partition pruning in the execution plan
explain select count(*) from t_list where date='2024-04-04';

-- Query partition information
select * from pg_partition_tree('t_list');
-- Detach a partition
alter table t_list DETACH PARTITION t_list_1_prt_p20240401;
-- Query data after detaching the partition
select date,count(*) from t_list group by date;
-- Attach the partition back to the main table
ALTER TABLE t_list ATTACH PARTITION t_list_1_prt_p20240401 FOR VALUES IN('2024-04-01');

-- Drop a partition
alter table t_list DROP partition P20240404;
-- Query data after dropping the partition
select date,count(*) from t_list group by date;
-- Check if data for the dropped partition value still exists
select count(*) from t_list where date='2024-04-04';