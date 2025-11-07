--- @sql@ enable AQUMV
set enable_answer_query_using_materialized_views=on; 
set optimizer=off ;  
set gp_eager_two_phase_agg = true; 

--- create table and insert data
drop table if exists aqumv_t1 cascade;
CREATE TABLE aqumv_t1(c1 INT, c2 INT, c3 INT) DISTRIBUTED BY (c1);
INSERT INTO aqumv_t1 SELECT i, i+1, i+2 FROM generate_series(1, 10000000) i;
ANALYZE aqumv_t1;
--- create incremental meterialized view
CREATE INCREMENTAL MATERIALIZED VIEW mvt1 AS SELECT c1 AS mc1, c2 AS mc2, ABS(c2) AS mc3, ABS(ABS(c2) - c1 - 1) AS mc4
  FROM aqumv_t1 WHERE c1 > 30 AND c1 < 40 DISTRIBUTED BY (mc1);
ANALYZE mvt1;

--- Automated replacement of materialized views for querying
explain analyze SELECT SQRT(ABS(ABS(c2) - c1 - 1) + ABS(c2)) FROM aqumv_t1 WHERE c1 > 30 AND c1 < 40 AND SQRT(ABS(c2)) > 5.8;