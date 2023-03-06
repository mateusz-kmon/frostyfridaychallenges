-- https://frostyfriday.org/2023/02/17/week-34-data-structuring/


-- Using recursive CTE
with recursive pc as (
    select
      code
    , 1 as lvl
    , code as Level_1
    , null::string as Level_2
    , null::string as Level_3
    , null::string as Level_4
    , null::string as Level_5
    , null::string as Level_6
    , null::string as Level_7
    from start_data
    where code_parent is null 
        and current_date() between valid_from and valid_until
    union all
    select
      coalesce(c.code, pc.code) as code
    , pc.lvl + 1 as lvl
    , pc.Level_1
    , case when pc.lvl + 1 = 2 then coalesce(c.code, pc.code) else pc.Level_2 end as Level_2
    , case when pc.lvl + 1 = 3 then coalesce(c.code, pc.code) else pc.Level_3 end as Level_3
    , case when pc.lvl + 1 = 4 then coalesce(c.code, pc.code) else pc.Level_4 end as Level_4
    , case when pc.lvl + 1 = 5 then coalesce(c.code, pc.code) else pc.Level_5 end as Level_5
    , case when pc.lvl + 1 = 6 then coalesce(c.code, pc.code) else pc.Level_6 end as Level_6
    , case when pc.lvl + 1 = 7 then coalesce(c.code, pc.code) else pc.Level_7 end as Level_7
    from pc
    left join start_data c
         on pc.code = c.code_parent
        and current_date() between c.valid_from and c.valid_until
    where pc.lvl + 1 <= 7
)
select Level_1, Level_2, Level_3, Level_4, Level_5, Level_6, Level_7
from pc 
where lvl=7
;




-- Using Connect By
with h as (
    select
    code
    , sys_connect_by_path(code, ',') as path
    from start_data
    where is_lowest_level
    start with code_parent is null 
        and current_date() between valid_from and valid_until
    connect by code_parent = prior code
        and current_date() between prior valid_from and prior valid_until
)
select 
  coalesce(nullif(split_part(path, ',', 2), ''), code) as Level_1
, coalesce(nullif(split_part(path, ',', 3), ''), code) as Level_2
, coalesce(nullif(split_part(path, ',', 4), ''), code) as Level_3
, coalesce(nullif(split_part(path, ',', 5), ''), code) as Level_4
, coalesce(nullif(split_part(path, ',', 6), ''), code) as Level_5
, coalesce(nullif(split_part(path, ',', 7), ''), code) as Level_6
, coalesce(nullif(split_part(path, ',', 8), ''), code) as Level_7
from h
;