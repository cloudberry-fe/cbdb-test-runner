--- @sql@ enable parallel
SET enable_parallel = ON;
SET optimizer = OFF;
--- parallel create ao table
drop table if exists t_p1;
CREATE TABLE t_p1(c1 INT, c2 INT) WITH (parallel_workers=4,APPENDONLY=true) DISTRIBUTED BY (c1);

--- parallel create meterialized view
drop table if exists t_p cascade;
CREATE TABLE t_p(c1 INT, c2 INT) WITH (parallel_workers=4) DISTRIBUTED BY (c1);
--- insert data and analyze
INSERT INTO t_p SELECT i, i+1 FROM generate_series(1, 10000000) i;
ANALYZE t_p;
--- parallel create meterialized view
CREATE MATERIALIZED VIEW matv USING ao_row AS SELECT SUM(a.c2) AS c2, AVG(b.c1) AS c1 FROM t_p a JOIN t_p b ON a.c1 = b.c1 WITH NO DATA DISTRIBUTED BY (c2);
--- parallel refresh meterialized view
REFRESH MATERIALIZED VIEW matv;