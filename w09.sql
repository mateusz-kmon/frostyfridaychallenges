use role accountadmin;

grant apply masking policy on account to role sysadmin;



use role securityadmin;

grant usage on database <db_name> to role foo1;
grant usage on database <db_name> to role foo2;

grant usage on schema <db_name>.<schema_name> to role foo1;
grant usage on schema <db_name>.<schema_name> to role foo2;

grant select on table <db_name>.<schema_name>.data_to_be_masked to role foo1;
grant select on table <db_name>.<schema_name>.data_to_be_masked to role foo2;

grant usage on warehouse <warehouse_name> to role foo1;
grant usage on warehouse <warehouse_name> to role foo2;




use role sysadmin;
use database <db_name>;
use schema <schema_name>;

create or replace tag sensitive_data allowed_values 'high', 'low';

alter table data_to_be_masked modify column
 first_name set tag sensitive_data = 'low'
,last_name  set tag sensitive_data = 'high'
;

create or replace masking policy sensitive_data_tag_string as (val string) returns string ->
  case
    when system$get_tag_on_current_column('sensitive_data')='low'  and (is_role_in_session('FOO1') or is_role_in_session('FOO2')) then val
    when system$get_tag_on_current_column('sensitive_data')='high' and is_role_in_session('FOO2') then val
    else repeat('*',6)
  end
;

alter tag sensitive_data set masking policy sensitive_data_tag_string;


use role accountadmin;
select * from data_to_be_masked;

use role foo1;
select * from data_to_be_masked;

use role foo2;
select * from data_to_be_masked;