--  https://frostyfridaychallenges.s3.eu-west-1.amazonaws.com/challenge_4/Spanish_Monarchs.json


create or replace stage frostyfridaychallenges
url = 's3://frostyfridaychallenges/'
;

create or replace file format ff_json
type = json;


ls @frostyfridaychallenges/challenge_4/;
select $1 from @frostyfridaychallenges/challenge_4/Spanish_Monarchs.json (file_format=>ff_json) ;


create or replace transient table w04_t1 (
    raw variant
);

truncate table w04_t1;
copy into w04_t1
from @frostyfridaychallenges/challenge_4/
file_format = (type=json strip_outer_array=true) 
files = ('Spanish_Monarchs.json')
;


select 
  row_number() over (order by m.value:Birth::date) as id
, m.index + 1 as inter_house_id
, t.raw:Era::string as era
, h.value:House::string as house
, m.value:Name::string as name
, m.value:Nickname[0]::string as nickname_1
, m.value:Nickname[1]::string as nickname_2
, m.value:Nickname[2]::string as nickname_3
, m.value:Birth::date as birth
, m.value:"Place of Birth"::string as place_of_birth
, m.value:"Start of Reign"::date as start_of_reign
, m.value:"Consort\/Queen Consort"[0]::string as queen_or_queen_consort_1
, m.value:"Consort\/Queen Consort"[1]::string as queen_or_queen_consort_2
, m.value:"Consort\/Queen Consort"[2]::string as queen_or_queen_consort_3
, m.value:"End of Reign"::date as end_of_reign
, m.value:"Duration"::string as duration
, m.value:"Death"::date as death
, split(m.value:"Age at Time of Death"::string, ' ')[0]::number as age_at_time_of_death_years
, m.value:"Place of Death"::string as place_of_death
, m.value:"Burial Place"::string as burial_place
from w04_t1 t
, lateral flatten(input=>t.raw:Houses) h
, lateral flatten(input=>h.value:Monarchs) m
order by 1
;
