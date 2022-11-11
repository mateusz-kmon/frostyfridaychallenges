use role sysadmin;

-- Code for creating the secure view
create or replace secure view secure_cities as
select uuid_string() as id, city, district 
from week22;

grant select on view secure_cities to role rep1;
grant select on view secure_cities to role rep2;


-- alter table week22 drop row access policy rap_cities;

create or replace row access policy rap_cities as (id number) returns boolean -> 
(
       ( is_role_in_session('rep1') and id%2=1 )
    or ( is_role_in_session('rep2') and id%2=0 )
    or ( is_role_in_session('sysadmin') )
);

alter table week22 add row access policy rap_cities on (id);



-- Get the result of queries
use role rep1;
select * from frosty_friday.challenges.secure_cities;

use role rep2;
select * from frosty_friday.challenges.secure_cities;


