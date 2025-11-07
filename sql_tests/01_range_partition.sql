drop table if exists t_range;
create table t_range(
id int,
date date,
amt decimal(10,2)
) DISTRIBUTED BY (id) 
PARTITION BY RANGE (date) (
   PARTITION P20240401 START(date '2024-04-01') INCLUSIVE,
   PARTITION P20240402 START(date '2024-04-02') INCLUSIVE,
   PARTITION P20240403 START(date '2024-04-03') INCLUSIVE,
   PARTITION P20240404 START(date '2024-04-04') INCLUSIVE
   END (date '2024-04-05') EXCLUSIVE
);
-- Insert test data
insert into t_range SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-04',INTERVAL '1 day') as date,  generate_series(1,100000) id;
-- Query data corresponding to partitions
select date,count(*) from t_range group by date;
-- Check partition pruning in the execution plan
explain select count(*) from t_range where date='2024-04-03';

-- Query partition information
select * from pg_partition_tree('t_range');
-- Detach a partition
alter table t_range DETACH PARTITION t_range_1_prt_p20240401;
-- Query data after detaching the partition
select date,count(*) from t_range group by date;
-- Attach the partition back to the main table
ALTER TABLE t_range ATTACH PARTITION t_range_1_prt_p20240401 FOR VALUES FROM ('2024-04-01') TO ('2024-04-02');
-- Drop a partition
alter table t_range DROP partition P20240403;
-- Query data after dropping the partition
select date,count(*) from t_range group by date;
-- Check if data for the dropped partition range still exists
select count(*) from t_range where date='2024-04-03';