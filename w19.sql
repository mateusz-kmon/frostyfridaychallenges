-- https://frostyfriday.org/2022/10/21/week-19-basic/


-- number of years to generate
set years_to_generate = 30;
set start_date = to_date('2000-01-01','yyyy-mm-dd');
set end_date = dateadd(d, -1, dateadd(y, $years_to_generate, '2000-01-01'))::date;
set days = (select datediff(d, $start_date, $end_date)+1);
select $start_date, $end_date, $days;


-- 0: the week needs to have 4 days in a given year;
-- 1: a week with January 1st always belongs to a given year.
alter session set week_of_year_policy = 1;

create or replace table my_date_dimension as 
select 
  dateadd(d, (row_number() over (order by null))-1, $start_date) as calendar_date
, year(calendar_date) as calendar_year
, monthname(calendar_date) as month_short
, to_char(calendar_date,'mmmm') as month_name
, day(calendar_date) as day_of_month
, dayofweekiso(calendar_date) as day_of_week
, week(calendar_date) as week_of_year
, dayofyear(calendar_date) as day_of_year
from table(generator(rowcount=>$days))
;

-- date dim
select * from my_date_dimension order by 1;



-- the function to calculate date diff
create or replace function calculate_business_days(from_date date, thru_date date, include_2nd boolean)
  returns number
as '
select count(*)
from my_date_dimension 
where day_of_week not in (6,7) 
and calendar_date between from_date and (thru_date - (not include_2nd)::number)
';


-- quick check
select 
  calculate_business_days('2020-11-2', '2020-11-6', true)  as including
, calculate_business_days('2020-11-2', '2020-11-6', false) as excluding
;


-- testing data
create table testing_data (
id INT,
start_date DATE,
end_date DATE
);
insert into testing_data (id, start_date, end_date) values (1, '11/11/2020', '9/3/2022');
insert into testing_data (id, start_date, end_date) values (2, '12/8/2020', '1/19/2022');
insert into testing_data (id, start_date, end_date) values (3, '12/24/2020', '1/15/2022');
insert into testing_data (id, start_date, end_date) values (4, '12/5/2020', '3/3/2022');
insert into testing_data (id, start_date, end_date) values (5, '12/24/2020', '6/20/2022');
insert into testing_data (id, start_date, end_date) values (6, '12/24/2020', '5/19/2022');
insert into testing_data (id, start_date, end_date) values (7, '12/31/2020', '5/6/2022');
insert into testing_data (id, start_date, end_date) values (8, '12/4/2020', '9/16/2022');
insert into testing_data (id, start_date, end_date) values (9, '11/27/2020', '4/14/2022');
insert into testing_data (id, start_date, end_date) values (10, '11/20/2020', '1/18/2022');
insert into testing_data (id, start_date, end_date) values (11, '12/1/2020', '3/31/2022');
insert into testing_data (id, start_date, end_date) values (12, '11/30/2020', '7/5/2022');
insert into testing_data (id, start_date, end_date) values (13, '11/28/2020', '6/19/2022');
insert into testing_data (id, start_date, end_date) values (14, '12/21/2020', '9/7/2022');
insert into testing_data (id, start_date, end_date) values (15, '12/13/2020', '8/15/2022');
insert into testing_data (id, start_date, end_date) values (16, '11/4/2020', '3/22/2022');
insert into testing_data (id, start_date, end_date) values (17, '12/24/2020', '8/29/2022');
insert into testing_data (id, start_date, end_date) values (18, '11/29/2020', '10/13/2022');
insert into testing_data (id, start_date, end_date) values (19, '12/10/2020', '7/31/2022');
insert into testing_data (id, start_date, end_date) values (20, '11/1/2020', '10/23/2021');

-- test should return nothing
select *
, dayofweekiso(end_date) as end_date_day_of_week
, calculate_business_days(start_date, end_date, true)  as including
, calculate_business_days(start_date, end_date, false) as excluding
from testing_data
where
(
     (end_date_day_of_week not in (6,7) and including= excluding)
  or (end_date_day_of_week     in (6,7) and including<>excluding)
)
order by 1;
