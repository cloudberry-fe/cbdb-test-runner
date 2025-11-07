---@sql@ Create test table
drop table if exists t_update_select;
create table t_update_select
( id int,
date date,
amt decimal(10,2)
 ) DISTRIBUTED BY (id); 
insert into t_update_select SELECT id,date, random()*100 as usage FROM generate_series('2024-04-01','2024-04-01',INTERVAL '1 day') as date,  generate_series(1,4) id;
--- Query test table data
select * from t_update_select;
--- Increase by 10% for records where amt is below average for the same date
UPDATE t_update_select e
SET amt = amt * 1.1
WHERE amt < (
    SELECT AVG(amt)
    FROM t_update_select
    WHERE date = e.date
);

--- Update with table join
WITH temp as 
(select id,date,amt*2 amt from t_update_select)
UPDATE t_update_select p
SET amt = i.amt
FROM temp i
WHERE p.id = i.id;

--- Update with complex conditions
UPDATE t_update_select o
SET date = now()::date
WHERE id < 3
  AND EXISTS (
    SELECT 1
    FROM t_update_select c
    WHERE o.id = c.id
      AND c.amt < 100
);

--- Update multiple fields
UPDATE t_update_select
SET (id,date,amt) =
(SELECT 2,'2024-05-01'::date,98.1) where date = '2024-04-01';

--- Query results after update
select * from t_update_select;