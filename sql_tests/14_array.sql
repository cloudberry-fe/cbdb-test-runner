--- @sql@ Create test table
drop table if exists t_array;
CREATE TABLE t_array (
    name            text,
    pay_by_quarter  integer[],
    schedule        text[][]
);
--- Insert data
INSERT INTO t_array
    VALUES ('Bill',
    '{10000, 10000, 10000, 10000}',
    '{{"meeting", "lunch"}, {"training", "presentation"}, {"training", "presentation"}}');
INSERT INTO t_array
    VALUES ('Peter',
    '{20000, 20000, 20000, 20000}',
    '{{"meeting", "lunch"}, {"training", "presentation"}, {"work", "presentation"}}');
--- Query sum of pay_by_quarter array
select sum(pay_by_quarter) from t_array ;  
--- Query rows where schedule contains 'work'
select * from t_array where schedule @> ARRAY['work'];
--- Query the second element of pay_by_quarter field
select pay_by_quarter[2] from t_array ;