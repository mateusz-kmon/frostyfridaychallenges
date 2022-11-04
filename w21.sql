-- https://frostyfriday.org/2022/11/04/week-21-basic/

select * 
from hero_powers
unpivot (power_value for power_name in (flight, laser_eyes, invisibility, invincibility, psychic, magic, super_speed, super_strength))
pivot(max(power_name) for power_value in ('++', '+')) as p (hero_name, main_power, secondary_power)
where (main_power is not null or secondary_power is not null)
order by hero_name;
