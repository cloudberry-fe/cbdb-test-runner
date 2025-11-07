---create table
drop table if exists foo;
CREATE TABLE foo(i int,d text,c text, CONSTRAINT i_uniq UNIQUE(i,d));