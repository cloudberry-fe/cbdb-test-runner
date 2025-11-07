-- @sql@ create table 
drop table if exists t01;
drop table if exists t02;
CREATE TABLE t01(id INT, val1 INT);
CREATE TABLE t02(id INT, val2 INT);
-- execute queries with aggregation and concatenation operations
EXPLAIN (COSTS OFF) SELECT id, SUM(val1) FROM t01 NATURAL JOIN t02 GROUP BY id;

--- enable agg pushdown
set gp_enable_agg_pushdown = ON;
SET optimizer = OFF;
-- execute queries with aggregation and concatenation operations
EXPLAIN (COSTS OFF) SELECT id, SUM(val1) FROM t01 NATURAL JOIN t02 GROUP BY id;