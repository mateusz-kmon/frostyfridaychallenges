-- https://frostyfriday.org/2022/11/30/week-25-beginner/



create or replace temporary file format ff_json
type = json;

create or replace temporary stage frostyfridaychallenges
url = 's3://frostyfridaychallenges/'
;


create or replace temp table weather_raw 
as
select  $1 as raw
from @frostyfridaychallenges/challenge_25 (file_format=>ff_json)
order by 1,2;


create or replace temp view weather_parsed
as
select 
  w.value:timestamp::timestamp as date
, w.value:icon::string as icon
, w.value:temperature::float as temperature
, w.value:precipitation::float as precipitation
, w.value:wind_speed::float as wind
, w.value:relative_humidity::float as humidity
from weather_raw r 
, lateral flatten(input=>r.raw:weather) w
;


create or replace temp view weather_agg
as
select 
  date_trunc(d, date) as date
, array_unique_agg(icon) as icon_array
, avg(temperature) as avg_temperature
, sum(precipitation) as total_precipitation
, avg(wind) as avg_wind
, avg(humidity) as avg_humidity
from weather_parsed
group by 1
;


select * from weather_agg order by date desc;