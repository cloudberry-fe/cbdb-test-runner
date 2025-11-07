---@sql@ Create test table
drop table if exists tax_revenue;
CREATE TABLE tax_revenue (
  id SERIAL PRIMARY KEY,
  year CHAR(4) NOT NULL,
  quarter CHAR(1) NOT NULL,
  revenue INT NOT NULL
);
--- Insert test data
INSERT INTO tax_revenue
  (year, quarter, revenue)
VALUES
  ('2023', '1', 3421),
  ('2023', '2', 3632),
  ('2023', '3', 4213),
  ('2023', '4', 6321),
  ('2024', '1', 2341),
  ('2024', '2', 5431),
  ('2024', '3', 3762),
  ('2024', '4', 5431);
--- Common window functions
--- Aggregate functions
select min(revenue),max(revenue),count(revenue),sum(revenue),avg(revenue) from tax_revenue;
-- First/Last value functions
select year, FIRST_VALUE(revenue) OVER ( PARTITION BY  year)  from tax_revenue;
select year, LAST_VALUE(revenue) OVER ( PARTITION BY  year)  from tax_revenue;
-- Offset functions
SELECT *, lag(revenue, 1) OVER (PARTITION BY year  ORDER BY quarter DESC) c_lag FROM tax_revenue;
SELECT *, lead(revenue, 1) OVER (PARTITION BY year  ORDER BY quarter DESC) c_lead FROM tax_revenue;
-- Ranking functions
SELECT *, ROW_NUMBER() OVER ( PARTITION BY year ORDER BY quarter DESC ) sn FROM tax_revenue;
SELECT *, RANK() OVER ( PARTITION BY year ORDER BY quarter DESC ) sn FROM tax_revenue;
SELECT *, DENSE_RANK() OVER ( PARTITION BY year ORDER BY quarter DESC ) sn FROM tax_revenue;
-- Bucketing functions
SELECT *, NTILE(2) OVER ( PARTITION BY year ORDER BY quarter DESC ) sn FROM tax_revenue;
-- Distribution functions
SELECT *, CUME_DIST()  OVER ( PARTITION BY year ORDER BY quarter DESC ) sn FROM tax_revenue;
SELECT *, CUME_DIST()  OVER ( PARTITION BY year ORDER BY quarter DESC ) sn FROM tax_revenue;