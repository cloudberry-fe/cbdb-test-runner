---@sql@ Create test table
drop table if exists t_brin_index;
CREATE TABLE t_brin_index
( id int,
date date,
amt decimal(10,2)
 ) DISTRIBUTED BY (id); 
--- Insert test data
insert into t_brin_index SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-04',INTERVAL '1 day') as date,  generate_series(1,1000000) id;
--- Create btree index:
CREATE INDEX idx_t_brin_index_bree ON t_brin_index USING btree (id);
--- Create brin index:
CREATE INDEX idx_t_brin_index_brin ON t_brin_index USING brin (id);
--- Check sizes of table, btree index, and brin index
select pg_size_pretty(pg_total_relation_size('t_brin_index')) as table_size;
select pg_size_pretty(pg_relation_size('idx_t_brin_index_bree')) as btree_size;
select pg_size_pretty(pg_relation_size('idx_t_brin_index_brin')) as brin_size;
--- Query execution plan and performance with brin index
drop index idx_t_brin_index_bree;
explain analyze select * from t_brin_index where id = 100;
--- Query execution plan and performance without any index
drop index idx_t_brin_index_brin;
explain analyze select * from t_brin_index where id = 100;