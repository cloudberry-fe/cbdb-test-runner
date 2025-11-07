-- Create anon extension
CREATE EXTENSION IF NOT EXISTS anon;
-- Enable anon masking for database testdb
create database testdb;
ALTER DATABASE testdb SET anon.transparent_dynamic_masking TO true;

-- Define masking user
create user user_anon with password 'pw12345';
SECURITY LABEL FOR anon ON ROLE user_anon IS 'MASKED';

-- Create test table
\c testdb
CREATE TABLE people (id TEXT, firstname TEXT, lastname TEXT, phone TEXT);
INSERT INTO people VALUES ('T1','Sarah', 'Conor','0609110911');
grant select on table people to user_anon;

-- Define masking rules
SECURITY LABEL FOR anon ON COLUMN people.lastname IS 'MASKED WITH FUNCTION anon.random_string(4)';
SECURITY LABEL FOR anon ON COLUMN people.phone IS 'MASKED WITH FUNCTION anon.partial(phone,2,$$******$$,2)';

-- Query as masked user
--set role to user_anon;
select * from people;

-- Query defined masking rules
SELECT n.nspname schema_name,c.relname AS table_name, a.attname AS column_name, s.provider, s.label
FROM pg_seclabel s
JOIN pg_class c ON s.objoid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
LEFT JOIN pg_attribute a ON s.objoid = a.attrelid AND s.objsubid = a.attnum
WHERE s.provider = 'anon';

-- Query database users with masking enabled
select objname role_name,provider,label from pg_seclabels where objtype = 'role';