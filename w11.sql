-- Set the database and schema
use database frosty_friday;
use schema challenges;


create or replace file format ff_csv
  type = csv
  skip_header=1
;

-- Create the stage that points at the data.
create stage week_11_frosty_stage
    url = 's3://frostyfridaychallenges/challenge_11/'
    file_format = (format_name=ff_csv);

-- Create the table as a CTAS statement.
create or replace table week11 as
select m.$1 as milking_datetime,
        m.$2 as cow_number,
        m.$3 as fat_percentage,
        m.$4 as farm_code,
        m.$5 as centrifuge_start_time,
        m.$6 as centrifuge_end_time,
        m.$7 as centrifuge_kwph,
        m.$8 as centrifuge_electricity_used,
        m.$9 as centrifuge_processing_time,
        m.$10 as task_used
from @week_11_frosty_stage (file_format => 'ff_csv', pattern => '.*milk_data.*[.]csv') m;


-- TASK 1: Remove all the centrifuge dates and centrifuge kwph and replace them with NULLs WHERE fat = 3. 
-- Add note to task_used.
create or replace task whole_milk_updates
    warehouse = my_xsmall_wh
    schedule = '1400 minutes'
as
    update week11 set
      centrifuge_start_time = null
    , centrifuge_end_time = null
    , centrifuge_kwph = null
    , task_used = system$current_user_task_name() || ' at ' || convert_timezone('America/Los_Angeles', current_timestamp())
    where try_to_number(fat_percentage,38,2) = 3
;

    
-- TASK 2: Calculate centrifuge processing time (difference between start and end time) WHERE fat != 3. 
-- Add note to task_used.
create or replace task skim_milk_updates
    warehouse = my_xsmall_wh
    after whole_milk_updates
as
    update week11 set
      centrifuge_processing_time = datediff(mi, try_to_timestamp(centrifuge_start_time, 'yyyy-mm-dd hh:mi:ss'), try_to_timestamp(centrifuge_end_time, 'yyyy-mm-dd hh:mi:ss'))
    , centrifuge_electricity_used = trim(to_char(datediff(mi, try_to_timestamp(centrifuge_start_time, 'yyyy-mm-dd hh:mi:ss'), try_to_timestamp(centrifuge_end_time, 'yyyy-mm-dd hh:mi:ss'))/60 * centrifuge_kwph, '999.00'))
    , task_used = system$current_user_task_name() || ' at ' || convert_timezone('America/Los_Angeles', current_timestamp())
    where try_to_number(fat_percentage,38,2) != 3
;


-- Enable all tasks
select system$task_dependents_enable('WHOLE_MILK_UPDATES');

-- Manually execute the task.
execute task whole_milk_updates;

-- Disable the root task
alter task whole_milk_updates suspend;


-- Check the execution
select *
from table(information_schema.task_history(task_name=>'WHOLE_MILK_UPDATES'))
union all
select *
from table(information_schema.task_history(task_name=>'SKIM_MILK_UPDATES'))
order by scheduled_time;


select *
from table(
    information_schema.complete_task_graphs(
        result_limit => 10,
        root_task_name=>'WHOLE_MILK_UPDATES')
)
;


-- Check that the data looks as it should.
select * from week11;
select * from week11 where try_to_number(fat_percentage,38,2) = 1;

-- Check that the numbers are correct.
select task_used, count(*) as row_count from week11 group by task_used;