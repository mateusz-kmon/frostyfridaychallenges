--https://frostyfriday.org/2022/07/15/week-5-basic/


create or replace transient table ff_week_5 (
 start_int number
);

insert into ff_week_5
select * from values
 (1)
,(2)
,(3)
;

create or replace function timesthree(start_int number)
returns string
language python
runtime_version = '3.8'
handler='h'
as $$
def h(start_int):
    return 3*start_int
$$;


SELECT timesthree(start_int)
FROM FF_week_5;
