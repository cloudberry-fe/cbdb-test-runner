---@sql@ Custom plpgsql function
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

---@sql@ Create plpython3u extension
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

---@sql@set:ON_ERROR_STOP=0 Create plperl language
create extension if not exists plperl;

---@sql Create plperl function
drop function if exists perl_max (integer, integer);
CREATE FUNCTION perl_max (integer, integer) RETURNS integer AS $$
    my ($x, $y) = @_;
    if (not defined $x) {
        return undef if not defined $y;
        return $y;
    }
    return $x if not defined $y;
    return $x if $x > $y;
    return $y;
$$ LANGUAGE plperl;
--- Call custom function
select perl_max(10,23);