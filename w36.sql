-- https://frostyfriday.org/2023/03/03/week-36-intermediate/


create or replace procedure check_dependency(
	database_name string, 
    schema_name string, 
    object_name string
)
returns string
language sql
execute as owner
as
$$
DECLARE
    dependencies string;
BEGIN
    select listagg(concat_ws('.', referencing_database, referencing_schema, referencing_object_name), ', ')
    into :dependencies
    from SNOWFLAKE.ACCOUNT_USAGE.OBJECT_DEPENDENCIES
    where REFERENCED_DATABASE = upper(:database_name)
      and REFERENCED_SCHEMA = upper(:schema_name)
      and REFERENCED_OBJECT_NAME = upper(:object_name)
    ;
    
    if (nullif(:dependencies,'') is not null) then
    	return 'Object cannot be dropped because it is referenced by: ' || :dependencies ;
    else
    	return 'Object can be dropped';
    end if;
END;
$$;
