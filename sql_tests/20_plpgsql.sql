--- Custom plpgsql function
drop function if exists f_sum(a integer, b integer);
CREATE OR REPLACE FUNCTION f_sum(a integer, b integer)
RETURNS integer AS $$
DECLARE
    sum integer;
BEGIN
    sum := a + b;
    RETURN sum;
END;
$$ LANGUAGE plpgsql;
--- Call custom function
select f_sum(101,200);