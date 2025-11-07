
--- Create pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;
--- Create test table
drop table if exists t_vector;
CREATE TABLE t_vector (
  id bigserial PRIMARY KEY, 
  item text, 
  embedding vector(2)
);
--- Insert test data
INSERT INTO
  t_vector (item, embedding)
VALUES
  ('客车', '[1, 1]'),
  ('卡车', '[1.3, 0.85]'),
  ('飞机', '[5, 0.5]');
--- Use cosine similarity operator <=> to calculate similarity between truck, car, and airplane
SELECT
  item,
  1 - (embedding <=> '[1.3, 0.85]') AS cosine_similarity
FROM
  t_vector
ORDER BY
  cosine_similarity DESC;
--- Create ivfflat index
CREATE INDEX ON t_vector USING ivfflat(embedding vector_cosine_ops) WITH(lists = 100);
--- Create HNSW index
CREATE INDEX ON t_vector USING HNSW(embedding vector_cosine_ops);
CREATE INDEX ON t_vector USING HNSW(embedding vector_l2_ops);

--- Generate random vectors of fixed length as test data
CREATE OR REPLACE FUNCTION random_array(dim integer) 
    RETURNS DOUBLE PRECISION[] 
AS $$ 
    SELECT array_agg(random()) 
    FROM generate_series(1, dim); 
$$ 
LANGUAGE SQL 
VOLATILE 
COST 1;
--- Create a table to store 30-dimensional vectors
drop table if exists t_vector_30;
CREATE TABLE t_vector_30(id BIGINT, embedding VECTOR(30));
--- Insert test data
INSERT INTO t_vector_30 SELECT i, random_array(30)::VECTOR(30) FROM generate_series(1, 1000) AS i;
Select count(*) from t_vector_30;
--- Create ivfflat index
CREATE INDEX ON t_vector_30 USING ivfflat(embedding vector_cosine_ops) WITH(lists = 100);
--- Create HNSW index
CREATE INDEX ON t_vector_30 USING HNSW(embedding vector_cosine_ops);
--- Query table and index sizes
select pg_size_pretty(pg_relation_size('t_vector_30')) as table_size;
select pg_size_pretty(pg_relation_size('t_vector_30_embedding_idx')) as hnsw_size;
select pg_size_pretty(pg_relation_size('t_vector_30_embedding_idx1')) as hnsw_size;
--- Query test
WITH tmp AS (
    SELECT random_array(30)::VECTOR(30) AS vec
)
SELECT id
FROM t_vector_30
ORDER BY embedding <=> (SELECT vec FROM tmp)
LIMIT FLOOR(RANDOM() * 50);
