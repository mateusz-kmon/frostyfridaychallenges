-- https://frostyfriday.org/2023/03/17/week-38-basic/

-- Creating a stream on view
create or replace stream strm_employee_sales on view employee_sales;



-- Checking if change_tracking is enabled:
show tables like 'employees';
show tables like 'sales';
show views like 'employee_sales';

-- Otherwise
-- alter table employees set change_tracking = true;
-- alter table sales set change_tracking = true;
-- alter view employee_sales set change_tracking = true;


-- The table for stream consumption
create or replace table deleted_sales (
  id number
, name string
, department string
, sale_amount decimal(10,2)
, metadata$row_id string
, metadata$action string
, metadata$isupdate boolean
);


-- Changes to the base tables
delete from sales where id=1;
delete from sales where id=2;
delete from employees where id=1;
delete from employees where id=2;
delete from sales where id=3;


-- Consuming the stream
insert into deleted_sales
      (id, name, department, sale_amount, metadata$row_id, metadata$action, metadata$isupdate)
select id, name, department, sale_amount, metadata$row_id, metadata$action, metadata$isupdate
from strm_employee_sales
;

--CDC
select * from deleted_sales;
