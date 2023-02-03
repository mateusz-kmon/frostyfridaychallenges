-- https://frostyfriday.org/2023/01/06/week-28-intermediate/

with covid as (
    select iso3166_1 as country_code, date
    from covid19_epidemiological_data.public.ecdc_global
    where last_reported_flag 
)
, weather as (
    select  "Country Name" as country, "Indicator Name", "Value", "Country RegionId" as country_code, "Date" as date
    from daily_weather_data.kndwd_data_pack.noaacd2019r
    where "Indicator Name"='Mean temperature (Fahrenheit)'
    and "Measure Name"='Value'
    qualify 1 = rank() over (partition by "Date", "Country RegionId" order by "Stations Latitude" desc, "Value" desc)
)
select w.country, w.date, w."Indicator Name", w."Value"
from weather w 
join covid c 
     on w.country_code=c.country_code 
    --and w.date=c.date
    and w.date='2020-08-09'
order by 1;