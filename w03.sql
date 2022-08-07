--https://frostyfriday.org/2022/07/15/week-3-basic/


create or replace stage frostyfridaychallenges
url = 's3://frostyfridaychallenges/'
;


ls @frostyfridaychallenges/challenge_3/;
-- https://frostyfridaychallenges.s3.eu-west-1.amazonaws.com/challenge_3/keywords.csv

select 
metadata$filename as file_name,
metadata$file_row_number as file_row_numer,
$1, $2, $3, $4
from @frostyfridaychallenges/challenge_3/keywords.csv;

create or replace transient table w03_t1 (
    keyword string, added_by string, nonsense string
);

truncate table w03_t1;
copy into w03_t1
from @frostyfridaychallenges/challenge_3/
file_format = (skip_header=1)
files = ('keywords.csv')
;



select 
metadata$filename as file_name,
metadata$file_row_number as file_row_numer,
$1, $2, $3, $4, $5, $6
from @frostyfridaychallenges/challenge_3/week3_data2_stacy_forgot_to_upload.csv
;

create or replace transient table w03_t2 (
    id int, first_name string, last_name string, catch_phrase string, timestamp date
);



select * from w03_t1;
set ptrn = (select listagg('.*' || keyword || '.*[.]csv', '|') from w03_t1);

truncate table w03_t2;
copy into w03_t2
from @frostyfridaychallenges/challenge_3/
file_format = (skip_header=1, date_format='mm/dd/yyyy')
pattern = $ptrn
;

select * from w03_t2;
