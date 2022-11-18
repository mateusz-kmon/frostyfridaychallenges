-- https://frostyfriday.org/2022/11/18/week-23-basic/


-- in CMD on Windows 
-- the snowql config file filled in with default connection parameters
/*************************************************************************************
snowsql
put file://C:\splitcsv-c18c2b43-ca57-4e6e-8d95-f2a689335892-results\*1.csv @~/w23;
************************************************************************************/


-- check files imported to a user stage
ls @~;


create or replace temporary file format ff_csv
type = csv
skip_header = 1
field_optionally_enclosed_by='"'
;

-- discovery
select $1 as id, $2 as first_name, $3 as last_name, $4 as email, $5 as gender, $6 as ip_address 
from @~/w23 (file_format => ff_csv)
order by 1;


create or replace temporary table w23 (
  id number not null
, first_name varchar not null
, last_name varchar not null
, email2 varchar not null
, gender varchar not null
, email varchar not null
);


-- load
copy into w23 
from (
    select $1 as id, $2 as first_name, $3 as last_name, $4 as email2, $5 as gender, $4 as email
    from '@~/w23'
 ) 
file_format = (format_name = ff_csv)
on_error = continue
;

-- test
select * from w23 order by id limit 1;


-- cleanup
rm @~/w23;