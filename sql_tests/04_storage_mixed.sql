--- Create test partitioned heap table
drop table if exists t_row2column;
create table t_row2column
( id int,
date date,
amt decimal(10,2)
  ) distributed by (id) 
partition by range(date) 
(
    partition p202401 start (date '2024-01-01') inclusive end (date '2024-02-01') exclusive,
    partition p202402 start (date '2024-02-01') inclusive end (date '2024-03-01') exclusive,
    partition p202403 start (date '2024-03-01') inclusive end (date '2024-04-01') exclusive,
    default partition default_p
);
-- Insert test data
insert into t_row2column SELECT id,date, random()*100 as usage FROM generate_series('2024-01-01','2024-04-01',INTERVAL '1 month') as date,  generate_series(1,1000000) id;
-- Create temporary table for row-to-column storage conversion
CREATE TABLE t_row2column_1_prt_p202402_temp
with (appendonly=true, orientation=column, compresstype=zstd, compresslevel=1)  
as (select * from t_row2column_1_prt_p202402)  
DISTRIBUTED BY (id);  
-- Exchange the specified partition in the partitioned table
alter table t_row2column exchange partition p202402 with table t_row2column_1_prt_p202402_temp;
-- Drop the table that was exchanged out 
drop table t_row2column_1_prt_p202402_temp;
-- Create an index on the hybrid storage table (row and column partitions)
create index idx_t_row2column on t_row2column(id,amt);
-- Analyze table statistics
analyze t_row2column;
-- Query execution plan check
explain select * from t_row2column where id = 10 and amt = 10.1;