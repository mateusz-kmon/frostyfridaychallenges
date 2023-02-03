-- https://frostyfriday.org/2022/12/09/week-26-intermediate/


create or replace table w26 (dt timestamp);

create notification integration my_email_int
    type=email
    enabled=true
    allowed_recipients=('person1@example.com')
;



create or replace task tk_root
schedule = '1 minute'
warehouse = compute_wh
comment = 'root task'
as
execute immediate $$
DECLARE
dt_now timestamp := current_timestamp();
dt_str string;
BEGIN
dt_str := to_char(convert_timezone('CET', :dt_now), 'yyyy-MM-dd hh:mi:ss');
call system$set_return_value(:dt_str);
insert into w26(dt) values(:dt_now);
END;
$$
;



create or replace task tk_email
comment = 'task email'
warehouse = compute_wh
after tk_root
as
execute immediate $$
DECLARE
pred_val string := ( select system$get_predecessor_return_value('TK_ROOT') );
content string;
BEGIN
content := 'Task has successfully finished on ' || current_account()
    || ' which is deployed on '
    || current_region() || ' region at '
    || :pred_val
;

call system$send_email(
    'my_email_int',
    'person1@example.com',
    'Email Alert: Task has finished.',
    :content
);
END;
$$
;


alter task tk_email resume;
execute task tk_root;


select * from table(information_schema.task_history(task_name=>'tk_root'))  order by scheduled_time desc;
select * from table(information_schema.task_history(task_name=>'tk_email'))  order by scheduled_time desc;


