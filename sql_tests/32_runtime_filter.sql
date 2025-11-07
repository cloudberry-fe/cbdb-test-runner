-- @sql@ create table
DROP TABLE IF EXISTS fact, dim;
CREATE TABLE fact (fid int, did int, val int);
CREATE TABLE dim (did int, proj_id int, filter_val int);

-- insert data，80% of the fact.did and dim.did overlap
INSERT INTO fact SELECT i, i % 8000 + 1, i FROM generate_series(1, 100000) s(i);
INSERT INTO dim SELECT i, i % 10, i FROM generate_series(1, 10000) s(i);
ANALYZE fact, dim;

-- View explain
EXPLAIN (COSTS OFF) SELECT COUNT(*) FROM fact, dim WHERE fact.did = dim.did AND proj_id < 2;
 
-- enable runtime filter
SET optimizer TO off; 
SET gp_enable_runtime_filter TO on;
--RuntimeFilter in the explain
EXPLAIN (COSTS OFF) SELECT COUNT(*) FROM fact, dim WHERE fact.did = dim.did AND proj_id < 2;