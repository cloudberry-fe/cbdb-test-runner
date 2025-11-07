--- Create plperl language
create extension if not exists plperl;
--- Create plperl function
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