-- https://frostyfriday.org/2023/03/24/week-39-basic/

use FROSTY_FRIDAY.PUBLIC;
use role sysadmin;

create or replace table customer_deets (
    id int,
    name string,
    email string
);

insert into customer_deets values
    (1, 'Jeff Jeffy', 'jeff.jeffy121@gmail.com'),
    (2, 'Kyle Knight', 'kyleisdabest@hotmail.com'),
    (3, 'Spring Hall', 'hall.yay@gmail.com'),
    (4, 'Dr Holly Ray', 'drdr@yahoo.com');



use role securityadmin;
create or replace role all_seeing;
create or replace role basic;
grant role all_seeing to role sysadmin;
grant role basic to role sysadmin;
grant role all_seeing to user admin;
grant role basic to user admin;
grant usage on database FROSTY_FRIDAY to role all_seeing;
grant usage on database FROSTY_FRIDAY to role basic;
grant usage on schema FROSTY_FRIDAY.PUBLIC to role all_seeing;
grant usage on schema FROSTY_FRIDAY.PUBLIC to role basic;
grant select on all tables in schema FROSTY_FRIDAY.PUBLIC to role all_seeing;
grant select on all tables in schema FROSTY_FRIDAY.PUBLIC to role basic;
grant usage on warehouse compute_wh to role all_seeing;
grant usage on warehouse compute_wh to role basic;


use role sysadmin;

create or replace masking policy mp_protect_emails as (val string) returns string ->
case
  when is_role_in_session('all_seeing') then val 
  else repeat('*',5) || regexp_substr(val, '@([\\w.-]+)')
end
;

alter table customer_deets modify column email set masking policy mp_protect_emails;


use role all_seeing;
select * from customer_deets;


use role basic;
select * from customer_deets;
