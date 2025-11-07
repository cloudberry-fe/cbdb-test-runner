-- Create test user
create user user03 with password 'user03';
-- Create test table
drop table if exists t_grant;
create table t_grant
( id int,
  state text
 ) DISTRIBUTED BY (id); 
 grant select on table t_grant to user03;
-- Insert 10 test records
insert into t_grant SELECT generate_series(1,10),'y';
-- Create policy: only allow users to view records where id < 6
CREATE POLICY id_policy ON t_grant USING (id < 6);
-- Enable RLS
ALTER TABLE t_grant ENABLE ROW LEVEL SECURITY;
-- Query RLS-enabled table as user03
set role to user03;
select * from t_grant;
set role to gpadmin;