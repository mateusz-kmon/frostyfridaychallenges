-- https://frostyfriday.org/2022/10/28/week-20-hard/


create or replace procedure schema_clone_with_copy_grants(
  database_name string
, schema_name string
, target_database string
, cloned_schema_name string
, at_or_before_statement string
)
  returns varchar
  language sql
  execute as caller
as
declare
    msg varchar;
    sql varchar;
begin
    sql := 'create schema if not exists ';
    sql := sql || target_database || '.' || cloned_schema_name;
    sql := sql || ' clone ' || database_name || '.' || schema_name;
    sql := sql || coalesce(' ' || at_or_before_statement,'');
    execute immediate sql;

    let rs_grants resultset := (
        select 'grant ' || privilege_type || ' on ' || object_type || ' ' || :target_database || '.' || :cloned_schema_name || ' to '|| grantee || ';' as cmd
        from information_schema.object_privileges s
        where object_type='SCHEMA'
        and object_catalog=upper(:database_name)
        and object_name=upper(:schema_name)
        and privilege_type not in (
             'CREATE CLASS','CREATE DIRECTORY TABLE','CREATE EVENT TABLE'
            ,'CREATE ICEBERG TABLE','CREATE INSTANCE','CREATE MODULE'
            ,'CREATE SERVICE','CREATE STREAMLIT'
            ,'CREATE IMAGE REPOSITORY','CREATE NETWORK RULE'
        )
        and not exists (
            select * 
            from information_schema.object_privileges t
            where t.object_type='SCHEMA'
            and t.object_catalog=upper(:target_database)
            and t.object_name=upper(:cloned_schema_name)
            and s.grantee = t.grantee
            and s.privilege_type = t.privilege_type
        )
        order by 1
    ) ;
    let cur cursor for rs_grants;
    for v_row in cur do
        execute immediate v_row.cmd;
    end for;

    msg := concat(:target_database, '.', :cloned_schema_name, ' succesfully cloned from ', :database_name, '.', :schema_name);
    return msg;
    
exception
    when other then
        return 
            object_construct(
                  'Error type'
                , 'Other error'
                , 'SQLCODE', sqlcode
                , 'SQLERRM', sqlerrm
                , 'SQLSTATE', sqlstate
            );
end;




-- Test the procedure
drop schema if exists frosty_friday.cold_lonely_clone;
call frosty_friday.public.schema_clone_with_copy_grants(
  'frosty_friday'
, 'cold_lonely_schema'
, 'frosty_friday'
, 'cold_lonely_clone'
, null
);

select *
from table(information_schema.query_history_by_session())
order by start_time desc;

select *
from information_schema.object_privileges s
where object_type='SCHEMA'
and object_catalog=upper('frosty_friday')
and object_name=upper('cold_lonely_clone')
;




-- Test the argument at_or_before_statement 
drop schema if exists frosty_friday.cold_lonely_clone;
create or replace table cold_lonely_schema.table_two (key int, value varchar);
call system$wait(10);
call frosty_friday.public.schema_clone_with_copy_grants(
  'frosty_friday'
, 'cold_lonely_schema'
, 'frosty_friday'
, 'cold_lonely_clone'
, 'at (offset => -15*1)'
);

select table_name from information_schema.tables where table_schema=upper('cold_lonely_schema') order by 1;
-- TABLE_ONE
-- TABLE_TWO

select table_name from information_schema.tables where table_schema=upper('cold_lonely_clone') order by 1;
-- TABLE_ONE
