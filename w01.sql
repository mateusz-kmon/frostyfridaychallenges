--https://frostyfriday.org/2022/07/14/week-1/


create or replace stage frostyfridaychallenges
url = 's3://frostyfridaychallenges/'
;

ls @frostyfridaychallenges/challenge_1;
select metadata$filename, metadata$file_row_number, $1 from @frostyfridaychallenges/challenge_1 order by 1,2;

create or replace transient table w01_t1 (
 file_name string
,file_row_number string
,result string
);

truncate table w01_t1;
copy into w01_t1
from (
    select metadata$filename, metadata$file_row_number, $1
    from @frostyfridaychallenges/challenge_1
)
file_format = (skip_header=1, null_if=('NULL','totally_empty'))
;

select * from w01_t1 where result is not null order by 1,2;
