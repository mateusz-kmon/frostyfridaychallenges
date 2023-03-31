-- https://frostyfriday.org/2023/03/31/week-40-basic/


-- Setup
use role accountadmin;

-- Create a database from the share.
CREATE DATABASE SNOWFLAKE_SAMPLE_DATA FROM SHARE SFC_SAMPLES.SAMPLE_DATA;

-- Grant the PUBLIC role access to the database.
-- Optionally change the role name to restrict access to a subset of users.
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO ROLE PUBLIC;
grant usage on WAREHOUSE compute_wh to role public;
grant usage on DATABASE frosty_friday to role public;
grant all on SCHEMA frosty_friday.public to role public;




-- Discovery
use role public;
use SNOWFLAKE_SAMPLE_DATA.TPCH_SF100;


select 
  sum(l_quantity * l_extendedprice * (1 - l_discount)) as Revenue
, SYSTEM$TYPEOF(Revenue)
from lineitem l
join orders o on l.l_orderkey=o.o_orderkey
join customer c on o.o_custkey=c.c_custkey
join nation n on c.c_nationkey=n.n_nationkey
join region r on n.n_regionkey=r.r_regionkey
where r.r_name='EUROPE'
limit 3
;



-- Solution
create or replace function frosty_friday.public.revenue()
returns number(38,6)
memoizable
as $$
select sum(l_quantity * l_extendedprice * (1 - l_discount))
from snowflake_sample_data.tpch_sf100.lineitem l
join snowflake_sample_data.tpch_sf100.orders o on l.l_orderkey=o.o_orderkey
join snowflake_sample_data.tpch_sf100.customer c on o.o_custkey=c.c_custkey
join snowflake_sample_data.tpch_sf100.nation n on c.c_nationkey=n.n_nationkey
join snowflake_sample_data.tpch_sf100.region r on n.n_regionkey=r.r_regionkey
where r.r_name='EUROPE'
$$;


select frosty_friday.public.revenue() as revenue;
-- first  execution: 17s
-- second execution: 143ms