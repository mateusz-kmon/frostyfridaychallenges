-- https://frostyfriday.org/2023/02/10/week-33-hard/


create or replace table CLUSTER_DEPTH_MONITORING (
    database_name varchar,
    schema_name varchar,
    table_name varchar,
    clustering_depth float,
    inserted_at timestamp,
    inserted_by varchar
);



create or replace procedure cm_proc()
returns string
language python
runtime_version = '3.8'
packages = ('snowflake-snowpark-python')
handler='run'
execute as owner
as 
$$
from snowflake.snowpark.functions import col, lit, sql_expr, concat_ws, convert_timezone, current_timestamp

def run(session) -> str:
    df = session.table("CM_CLUSTERED_TABLES")
    df = df.select("TABLE_CATALOG", "TABLE_SCHEMA","TABLE_NAME", "FULL_TABLE_NAME", "CLUSTERING_KEY")
    df = df.sort("FULL_TABLE_NAME")

    lt = []
    for row in df.collect():
        rw_dpth = session.range(1, 2).select(
            sql_expr(f"system$clustering_depth('{row['FULL_TABLE_NAME']}', '{row['CLUSTERING_KEY']}')").as_("CLUSTERING_DEPTH"),
            convert_timezone(lit('UTC'), current_timestamp()).as_("INSERTED_AT"),
            sql_expr("system$current_user_task_name()").as_("INSERTED_BY")
        ).collect()
    
        lt.append([
            row['TABLE_CATALOG'],
            row['TABLE_SCHEMA'],
            row['TABLE_NAME'],
            rw_dpth[0]['CLUSTERING_DEPTH'],
            rw_dpth[0]['INSERTED_AT'],
            rw_dpth[0]['INSERTED_BY']
        ])

    df_cm = session.create_dataframe(lt, schema=["DATABASE_NAME", "TABLE_SCHEMA", "TABLE_NAME", "CLUSTERING_DEPTH", "INSERTED_AT", "INSERTED_BY"])
    df_cm.write.save_as_table("CLUSTER_DEPTH_MONITORING", mode="append")
    return 'CM done'
$$;






create or replace task CM_IDENTIFY_TABLES
schedule = 'USING CRON 0 9 L 12 * UTC'
warehouse = compute_wh
comment = 'identifies the tables that are clustered'
as
execute immediate $$
BEGIN
alter session set query_tag='cluster_depth_monitoring';

create or replace transient table CM_CLUSTERED_TABLES
as 
select
  TABLE_CATALOG
, TABLE_SCHEMA
, TABLE_NAME
, concat_ws('.', TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME) as FULL_TABLE_NAME
, CLUSTERING_KEY
from SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.TABLES
where CLUSTERING_KEY is not null;

END;
$$
;



create or replace task CM_INSERT_DETAILS
comment = 'examines the clustering depth'
warehouse = compute_wh
after CM_IDENTIFY_TABLES
as
execute immediate $$
BEGIN
alter session set query_tag='cluster_depth_monitoring';
call cm_proc();
END;
$$
;



create or replace task CM_CLEAN_UP
comment = 'cleans up'
warehouse = compute_wh
after CM_INSERT_DETAILS
as
execute immediate $$
BEGIN
alter session set query_tag='cluster_depth_monitoring';
drop table if exists CM_CLUSTERED_TABLES;
END;
$$
;




select system$task_dependents_enable('CM_IDENTIFY_TABLES');

execute task CM_IDENTIFY_TABLES;



select * 
from CLUSTER_DEPTH_MONITORING
order by INSERTED_AT desc;
