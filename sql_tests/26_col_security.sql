--- Create test user
create user user04 with password 'user04';
--- Create test table
drop table if exists t_grant_col;
create table t_grant_col
( id int,
  state text
 ) DISTRIBUTED BY (id); 
--- Insert 10 test records
insert into t_grant_col SELECT generate_series(1,10),'y';
--- Grant column-level SELECT permission on id column to user04
grant select (id) on table t_grant_col to user04;
--- user04 can only query the id column
set role to user04;
select * from t_grant_col;  -- ERROR:  permission denied for table t_grant_col
select id from t_grant_col;
set role to gpadmin;