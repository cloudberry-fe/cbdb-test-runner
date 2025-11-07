---@sql@ Create stored procedure with return value, calling custom function
DROP PROCEDURE if exists p_sum(IN input_param1 INTEGER,IN input_param2 INTEGER, OUT output_param INTEGER);
CREATE OR REPLACE PROCEDURE p_sum(IN input_param1 INTEGER,IN input_param2 INTEGER, OUT output_param INTEGER)
   AS $$
   BEGIN
     output_param := input_param1 + input_param2;
     exception when others then rollback;
   END;
   $$ LANGUAGE plpgsql;
--- Call stored procedure
call p_sum(1000,2000,null);

--- Create stored procedure without return value, calling custom function
DROP PROCEDURE if exists p_insert(IN input_param1 INTEGER,IN input_param2 INTEGER);
CREATE OR REPLACE PROCEDURE p_insert(IN input_param1 INTEGER,IN input_param2 INTEGER)
   AS $$
   BEGIN
     CREATE TABLE IF NOT EXISTS t_insert(c1 timestamp,c2 int) DISTRIBUTED BY(c1) ;
     insert into t_insert values(now(),input_param1 + input_param2);
     exception when others then rollback;
   END;
   $$ LANGUAGE plpgsql;
--- Call stored procedure
call p_insert(1000,2000);