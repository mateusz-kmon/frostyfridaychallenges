-- https://frostyfridaychallenges.s3.eu-west-1.amazonaws.com/challenge_2/employees.parquet


create or replace stage frostyfridaychallenges
url = 's3://frostyfridaychallenges/'
;

create or replace file format ff_parquet
type = parquet;

ls @frostyfridaychallenges/challenge_2;
select $1 from @frostyfridaychallenges/challenge_2/employees.parquet (file_format=>ff_parquet) ;


select 
$$ create or replace transient table w02_employees ($$ || (
  select replace(generate_column_description(array_agg(object_construct(*)), 'table'), '"')
  from table (infer_schema(location=>'@frostyfridaychallenges/challenge_2/employees.parquet', file_format=>'ff_parquet'))
) || $$ ); $$ as sql
;


create or replace transient table w02_employees (
  email TEXT, country TEXT, country_code TEXT, education TEXT, postcode TEXT, first_name TEXT, street_name TEXT, job_title TEXT, city TEXT, employee_id NUMBER(38, 0), last_name TEXT, time_zone TEXT, street_num NUMBER(38, 0), payroll_iban TEXT, suffix TEXT, dept TEXT, title TEXT 
);



select listagg(p.expression, ', ') within group (order by t.ordinal_position)
from table(
  infer_schema(
    location=>'@frostyfridaychallenges/challenge_2/employees.parquet'
    , file_format=>'ff_parquet'
    )
) p
join information_schema.columns t on upper(p.column_name) = t.column_name
where t.table_name=upper('w02_employees')
;

truncate table w02_employees;
copy into w02_employees
from (
select
$1:email::TEXT, $1:country::TEXT, $1:country_code::TEXT, $1:education::TEXT, $1:postcode::TEXT, $1:first_name::TEXT, $1:street_name::TEXT, $1:job_title::TEXT, $1:city::TEXT, $1:employee_id::NUMBER(38, 0), $1:last_name::TEXT, $1:time_zone::TEXT, $1:street_num::NUMBER(38, 0), $1:payroll_iban::TEXT, $1:suffix::TEXT, $1:dept::TEXT, $1:title::TEXT
from @frostyfridaychallenges/challenge_2/employees.parquet 
(file_format=>ff_parquet) 
)
;


create or replace view w02_v_employees as
select employee_id, dept, job_title 
from w02_employees;

create or replace stream str_w02_v_employees on view w02_v_employees;


UPDATE w02_employees SET COUNTRY = 'Japan'                      WHERE EMPLOYEE_ID = 8;
UPDATE w02_employees SET LAST_NAME = 'Forester'                 WHERE EMPLOYEE_ID = 22;
UPDATE w02_employees SET DEPT = 'Marketing'                     WHERE EMPLOYEE_ID = 25;
UPDATE w02_employees SET TITLE = 'Ms'                           WHERE EMPLOYEE_ID = 32;
UPDATE w02_employees SET JOB_TITLE = 'Senior Financial Analyst' WHERE EMPLOYEE_ID = 68;


select * from str_w02_v_employees order by employee_id, metadata$row_id, metadata$action;
