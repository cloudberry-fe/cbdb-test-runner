--- Create test table
drop table if exists t_upsert;
create table t_upsert(c1 int primary key,c2 varchar(10));
--- Insert test data
insert into t_upsert values(1,'1');
--- Query existing data in the table
select * from t_upsert;
--- Execute upsert operation, no primary key conflict
insert into t_upsert values(2,'2') on conflict(c1) do update set c2=EXCLUDED.c2;
--- Execute upsert operation with primary key conflict
insert into t_upsert values(1,'1-1') on conflict(c1) do update set c2=EXCLUDED.c2;
--- Query data after insertion
select * from t_upsert;