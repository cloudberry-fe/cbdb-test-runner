--- create table existing_table and insert data
drop table if exists existing_table cascade;;
CREATE TABLE existing_table (
   id INT,
   name VARCHAR(100),
   value INT
);
INSERT INTO existing_table (id, name, value) VALUES
(1, 'Alice', 100),
(2, 'Bob', 150),
(3, 'Charlie', 200),
(1, 'Alice', 101),
(2, 'Bob', 151),
(3, 'Charlie', 201);

--- Create dynamic table that automatically refreshes every 1 minutes
CREATE DYNAMIC TABLE dynamic_existing_table SCHEDULE '*/1 * * * *' AS SELECT id,max(value) FROM existing_table  GROUP BY id DISTRIBUTED BY(id);

--- Query dynamic table refresh configuration
SELECT pg_get_dynamic_table_schedule('dynamic_existing_table'::regclass::oid);

--- Manual refresh
REFRESH DYNAMIC TABLE dynamic_existing_table;

--- insert data
INSERT INTO existing_table (id, name, value) VALUES (5, 'Alice', 190);

--- Query the dynamic table after 1 minute
select * from dynamic_existing_table;