-- Provides four functions: Soundex, Levenshtein, Metaphone and Double Metaphone, used to determine string similarity and distance.
--- Create fuzzystrmatch extension
create extension if not exists fuzzystrmatch;

--- Use levenshtein function to calculate edit distance between two strings
SELECT levenshtein('word', 'world') AS lev_dist;
--- Use soundex function to compare Soundex codes of words; difference counts matching positions, range 0-4
SELECT soundex('Anne'), soundex('Andrew'), difference('Anne', 'Andrew');
--- Use dmetaphone function to determine string similarity through phonetic codes
SELECT dmetaphone('word'), dmetaphone('world');