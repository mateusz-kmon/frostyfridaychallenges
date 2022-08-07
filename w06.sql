-- https://frostyfriday.org/2022/07/22/week-6-hard/


create or replace stage frostyfridaychallenges
url = 's3://frostyfridaychallenges/'
;


select $1, $2, $3, $4, $5, $6 
from @frostyfridaychallenges/challenge_6/nations_and_regions.csv
;

select $1, $2, $3, $4, $5, $6 
from @frostyfridaychallenges/challenge_6/westminster_constituency_points.csv
;

create or replace transient table nations_and_regions (
  nation_or_region_name string
, type string
, sequence_num int
, longitude float
, latitude float
, part int
);

create or replace transient table westminster_constituency_points (
  constituency string
, sequence_num int
, longitude float
, latitude float
, part int
);


copy into nations_and_regions
from @frostyfridaychallenges/challenge_6/nations_and_regions.csv
file_format = (skip_header=1)
;

copy into westminster_constituency_points
from @frostyfridaychallenges/challenge_6/westminster_constituency_points.csv
file_format = (skip_header=1 field_optionally_enclosed_by='"')
;


with region as (
    select 
      nation_or_region_name
    , part
    , st_makepolygon( to_geography('linestring(' || 
        listagg(longitude || ' ' || latitude, ', ') within group (order by sequence_num) 
      ||')') ) as pol
    from nations_and_regions
    group by nation_or_region_name, part
)
, constituency as (
    select 
      constituency
    , part
    , st_makepolygon( to_geography('linestring(' || 
        listagg(longitude || ' ' || latitude, ', ') within group (order by sequence_num) 
      ||')') ) as pol 
    from westminster_constituency_points
    group by constituency, part
)
select r.nation_or_region_name, count(distinct c.constituency) as cnt
from region r
join constituency c on st_intersects(r.pol, c.pol)
group by 1 
order by cnt desc
;
