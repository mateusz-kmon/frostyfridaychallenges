-- https://frostyfriday.org/2023/02/24/week-35-intermediate/

create stage external_table_stage
	url = 's3://frostyfridaychallenges/challenge_35/'
;


-- Discovery
ls @external_table_stage;

create or replace temp file format ff_csv_discovery
type = csv
field_delimiter = NONE
-- record_delimiter = NONE
skip_header = 0
;

select $1
from @external_table_stage/2022/06/salesdata_41699.csv (file_format=>ff_csv_discovery)
;



-- Execution
create or replace file format ff_csv
type = csv
field_delimiter = ','
skip_header = 1
field_optionally_enclosed_by = '"'
;

create or replace external table frosty_et (
  SALE_MONTH date as to_date(split_part(metadata$filename, '/', 2) || '-' || split_part(metadata$filename, '/', 3) || '-01')
, ID number as ($1:c1::number)
, DRUG_NAME string as ($1:c2::string)
, AMOUNT_SOLD number as ($1:c3::number)
)
partition by (sale_month)
location = @external_table_stage
auto_refresh = false
file_format = (format_name=ff_csv)
;


select sale_month, id, drug_name, amount_sold
from frosty_et
order by amount_sold;