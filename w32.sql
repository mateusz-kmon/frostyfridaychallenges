use role useradmin;
create user if not exists user1 with password='abc123';
create user if not exists user2 with password='abc123';
create role if not exists policy_admin;





use role securityadmin;
grant usage on database demo_db to role policy_admin;
grant usage, create session policy on schema demo_db.public to role policy_admin;
grant apply session policy on account to role policy_admin;
grant apply session policy on user user1 to role policy_admin;
grant apply session policy on user user2 to role policy_admin;
grant role policy_admin to role sysadmin;


grant usage on warehouse compute_wh to role securityadmin;
begin
    let sql := 'grant role policy_admin to user ' || current_user();
    execute immediate sql;
    return 0;
end;
revoke usage on warehouse compute_wh from role securityadmin;




use role policy_admin;
create session policy if not exists session_policy_ui
  session_ui_idle_timeout_mins = 8
  comment = 'Session policy for UI'
;

create session policy if not exists session_policy_clients
  session_idle_timeout_mins = 10
  comment = 'Session policy for Snowflake clients'
;


alter user user1 set session policy session_policy_ui;
alter user user2 set session policy session_policy_clients;




use role sysadmin;

select *
from table(information_schema.policy_references(
    policy_name => 'session_policy_ui'
))
union all
select *
from table(information_schema.policy_references(
    policy_name => 'session_policy_clients'
));


show session policies;
describe session policy session_policy_ui;
describe session policy session_policy_clients;
