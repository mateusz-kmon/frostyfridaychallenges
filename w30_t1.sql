use role sysadmin;
use secondary roles all;

create database if not exists &db_dev;
create schema if not exists &db_dev.security;
create schema if not exists &db_dev.dev_user;
create database if not exists &db_tst;
create schema if not exists &db_tst.security;
create database if not exists &db_acc;
create schema if not exists &db_acc.security;
create database if not exists &db_prd;
create schema if not exists &db_prd.security;

create warehouse if not exists &warehouse_name
with
warehouse_size = SMALL
auto_suspend = 60
auto_resume = true
min_cluster_count = 1
max_cluster_count = 1
initially_suspended = true;




use role securityadmin;
create user if not exists security_user password = '&password';
create user if not exists dev_user password = '&password';
create user if not exists regular_user password = '&password';

create role if not exists dev_role;
create role if not exists security_role;

grant role dev_role to role sysadmin;
grant role dev_role to user dev_user;
grant role security_role to role sysadmin;
grant role security_role to user security_user;


grant usage on database &db_dev to role dev_role;
grant usage on database &db_tst to role dev_role;
grant usage on database &db_acc to role dev_role;
grant usage on database &db_prd to role dev_role;

grant create schema on database &db_dev to role dev_role;
grant create schema on database &db_tst to role dev_role;
grant create schema on database &db_acc to role dev_role;
grant create schema on database &db_prd to role dev_role;

grant usage, create table on all schemas in database &db_dev to role dev_role;
grant usage, create table on all schemas in database &db_tst to role dev_role;
grant usage, create table on all schemas in database &db_acc to role dev_role;
grant usage, create table on all schemas in database &db_prd to role dev_role;

grant usage, create table on future schemas in database &db_dev to role dev_role;
grant usage, create table on future schemas in database &db_tst to role dev_role;
grant usage, create table on future schemas in database &db_acc to role dev_role;
grant usage, create table on future schemas in database &db_prd to role dev_role;

revoke create table on schema &db_dev.security from role dev_role;
revoke create table on schema &db_tst.security from role dev_role;
revoke create table on schema &db_acc.security from role dev_role;
revoke create table on schema &db_prd.security from role dev_role;

grant select on all tables in database &db_dev to role dev_role;
grant select on all tables in database &db_tst to role dev_role;
grant select on all tables in database &db_acc to role dev_role;
grant select on all tables in database &db_prd to role dev_role;

grant select on future tables in database &db_dev to role dev_role;
grant select on future tables in database &db_tst to role dev_role;
grant select on future tables in database &db_acc to role dev_role;
grant select on future tables in database &db_prd to role dev_role;

grant select on all views in database &db_dev to role dev_role;
grant select on all views in database &db_tst to role dev_role;
grant select on all views in database &db_acc to role dev_role;
grant select on all views in database &db_prd to role dev_role;

grant select on future views in database &db_dev to role dev_role;
grant select on future views in database &db_tst to role dev_role;
grant select on future views in database &db_acc to role dev_role;
grant select on future views in database &db_prd to role dev_role;




grant usage on database &db_dev to role security_role;
grant usage on database &db_tst to role security_role;
grant usage on database &db_acc to role security_role;
grant usage on database &db_prd to role security_role;

grant create schema on database &db_dev to role security_role;
grant create schema on database &db_tst to role security_role;
grant create schema on database &db_acc to role security_role;
grant create schema on database &db_prd to role security_role;

grant usage, create table on all schemas in database &db_dev to role security_role;
grant usage, create table on all schemas in database &db_tst to role security_role;
grant usage, create table on all schemas in database &db_acc to role security_role;
grant usage, create table on all schemas in database &db_prd to role security_role;

grant usage, create table on future schemas in database &db_dev to role security_role;
grant usage, create table on future schemas in database &db_tst to role security_role;
grant usage, create table on future schemas in database &db_acc to role security_role;
grant usage, create table on future schemas in database &db_prd to role security_role;

grant select on all tables in database &db_dev to role security_role;
grant select on all tables in database &db_tst to role security_role;
grant select on all tables in database &db_acc to role security_role;
grant select on all tables in database &db_prd to role security_role;

grant select on future tables in database &db_dev to role security_role;
grant select on future tables in database &db_tst to role security_role;
grant select on future tables in database &db_acc to role security_role;
grant select on future tables in database &db_prd to role security_role;

grant select on all views in database &db_dev to role security_role;
grant select on all views in database &db_tst to role security_role;
grant select on all views in database &db_acc to role security_role;
grant select on all views in database &db_prd to role security_role;

grant select on future views in database &db_dev to role security_role;
grant select on future views in database &db_tst to role security_role;
grant select on future views in database &db_acc to role security_role;
grant select on future views in database &db_prd to role security_role;


grant usage on database &db_prd to role public;
grant usage on schema &db_prd.public to role public;
grant select on all tables in schema &db_prd.public to role public;
grant select on future tables in schema &db_prd.public to role public;
grant select on all views in schema &db_prd.public to role public;
grant select on future views in schema &db_prd.public to role public;


grant usage on warehouse &warehouse_name to role dev_role;
grant usage on warehouse &warehouse_name to role security_role;
grant usage on warehouse &warehouse_name to role public;

!source &second_script
