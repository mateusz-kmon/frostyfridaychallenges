-- https://frostyfriday.org/2022/11/18/week-23-basic/

select 
  max_by(hero_name, villains_defeated) as best_hero
, min_by(hero_name, villains_defeated) as worst_hero 
from w31;
