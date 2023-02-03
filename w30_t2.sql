use role sysadmin;
use &db_dev.dev_user;
use warehouse &warehouse_name;

CREATE or replace TABLE departments(dep_id varchar, dep_name varchar);

INSERT INTO departments VALUES
('d001','Marketing'),
('d002','Finance'),
('d003','Human Resources'),
('d004','Production'),
('d005','Development'),
('d006','Quality Management'),
('d007','Sales'),
('d008','Research'),
('d009','Customer Service');