-- https://frostyfriday.org/2022/11/04/week-21-basic/


-- by pivoting
select * 
from hero_powers
unpivot (power_value for power_name in (flight, laser_eyes, invisibility, invincibility, psychic, magic, super_speed, super_strength))
pivot(max(power_name) for power_value in ('++', '+')) as p (hero_name, main_power, secondary_power)
where (main_power is not null or secondary_power is not null)
order by hero_name;


-- by semi-structure query
with jv as (
    select object_construct(*) as raw
    from hero_powers
)
select 
  jv.raw:HERO_NAME::string as hero_name
, max(case when f.value='++' then f.key end) as main_power
, max(case when f.value='+'  then f.key end) as secondary_power
from jv
, lateral flatten(jv.raw) f
where f.value in ('++','+')
group by 1 order by 1;