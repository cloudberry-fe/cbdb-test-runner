-- Create master table
drop table if exists t_hash;
CREATE TABLE t_hash
( id int,
date date,
amt decimal(10,2)
 ) DISTRIBUTED BY (id) 
 PARTITION BY HASH (id) 
 ;
 -- Create partitions
 create table hashpart_0 partition of t_hash for values with (modulus 3, remainder 0);
 create table hashpart_1 partition of t_hash for values with (modulus 3, remainder 1);
 create table hashpart_2 partition of t_hash for values with (modulus 3, remainder 2);
-- Query partition information
select * from pg_partition_tree('t_hash');
-- Insert test data
insert into t_hash SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-04',INTERVAL '1 day') as date,  generate_series(1,100000) id;
-- Check partition pruning in the execution plan
explain select count(*) from t_hash where id = 12345;

-- Detach a partition
alter table t_hash DETACH PARTITION hashpart_2;
-- Query data after detaching the partition
select date,count(*) from t_hash group by date;
-- Attach the partition back to the master table
ALTER TABLE t_hash ATTACH PARTITION hashpart_2 FOR VALUES WITH (modulus 3, remainder 2);