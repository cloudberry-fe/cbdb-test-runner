--- Create plpython3u extension
CREATE EXTENSION if not exists plpython3u;

--- Create plpython3u custom function
drop function if exists plpython3u_max (a integer, b integer);
CREATE OR REPLACE FUNCTION plpython3u_max (a integer, b integer)
  RETURNS integer
AS $$
  if (a is None) or (b is None):
    return None
  if a > b:
    return a
  return b
$$ LANGUAGE plpython3u;
--- Call custom function
select plpython3u_max(10,23);

--- Remove leading and trailing spaces from string
CREATE OR REPLACE FUNCTION pytrim(arg text)
  RETURNS text
AS $$
  global arg
  import re
  arg=str(arg)
  arg=arg.strip(' ,')
  if arg == '' or arg == 'None':
      arg=None
  return arg
$$ LANGUAGE plpython3u;
--- Call custom function
select length(' abc d e f   '),length(pytrim(' abc d e f  '));

--- Insert data
drop table t_fun cascade;
CREATE TABLE t_fun(name TEXT,id INT);
CREATE OR REPLACE FUNCTION fun_insert(name text,id int) RETURNS text AS $$
    try:
        plan = plpy.prepare("INSERT INTO t_fun(name,id) VALUES ($1,$2)" , ["text", "int"])
        plpy.execute(plan, [name, id])
    except plpy.SPIError:
        return "something went wrong"
    else:
        return "added success"
$$ LANGUAGE plpython3u;

select fun_insert('DataBase',1);
select * from t_fun;