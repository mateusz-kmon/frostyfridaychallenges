-- Create the warehouses
create warehouse if not exists my_xsmall_wh 
    with warehouse_size = XSMALL
    auto_suspend = 120;
    
create warehouse if not exists my_small_wh 
    with warehouse_size = SMALL
    auto_suspend = 120;

-- Create the table
create or replace table week_10
(
    date_time datetime,
    trans_amount double
);

-- Create the stage
create or replace stage week_10_frosty_stage
    url = 's3://frostyfridaychallenges/challenge_10/'
    file_format = (skip_header = 1, type = csv)
    ;



-- Create the stored procedureqry_id
create or replace procedure dynamic_warehouse_data_load(stage_name string, table_name string)
  returns string
  language sql
  execute as caller
as
$$
declare
    no_url exception (-20001, 'No URL for stage found');
    property_value string;
    loaded_total number := 0;
begin

    execute immediate 'show stages like ''' || stage_name || '''';
    select "url" into :property_value from table(result_scan(last_query_id())) limit 1;
    if (property_value is null) then
        raise no_url;
    end if;
    
    execute immediate 'ls @' || stage_name;
    let rs_files resultset := (select "name" as name, "size" as size from table(result_scan(last_query_id())) order by size, name) ;
    let cur cursor for rs_files;
    let sql_copy string;
    for v_row in cur do
        if (v_row.size < 10240) then
            execute immediate 'use warehouse my_xsmall_wh';
        else
            execute immediate 'use warehouse my_small_wh';
        end if;
        sql_copy := 'copy into ' || table_name || ' from @' || stage_name || ' files = (''' || replace(v_row.name, property_value, '') || ''')';
        execute immediate sql_copy;
    end for;
    
    select count(*) into :loaded_total from identifier(:table_name);
    return loaded_total || ' rows were added';

exception
    when statement_error then
        return object_construct('Error type', 'STATEMENT_ERROR',
                                'SQLCODE', sqlcode,
                                'SQLERRM', sqlerrm,
                                'SQLSTATE', sqlstate);
    when no_url then
        return object_construct('Error type', 'NO_URL',
                                'SQLCODE', sqlcode,
                                'SQLERRM', sqlerrm,
                                'SQLSTATE', sqlstate);
    when other then
        return object_construct('Error type', 'Other error',
                                'SQLCODE', sqlcode,
                                'SQLERRM', sqlerrm,
                                'SQLSTATE', sqlstate);
end;
$$;


-- Clear table
truncate table week_10;

-- Call the stored procedure.
call dynamic_warehouse_data_load('week_10_frosty_stage', 'week_10');

-- Check history
select * from table(information_schema.query_history_by_session()) order by start_time desc limit 100;
