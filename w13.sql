-- Snowflake way
select 
  id
, product
, stock_amount
, coalesce(stock_amount, lag(stock_amount) ignore nulls over (partition by product order by date_of_check, id)) as stock_amount_filled_out
, date_of_check
from testing_data
order by product, date_of_check, id;


-- Other way
with lne_dt as (
    select c.product, c.date_of_check, max(lne.date_of_check) as last_non_empty_date
    from testing_data c
    join testing_data lne on c.product=lne.product and c.date_of_check>=lne.date_of_check and lne.stock_amount is not null
    group by c.product, c.date_of_check
)
, lne_id as (
    select c.product, c.date_of_check, max(lne.id) as last_non_empty_id
    from lne_dt c
    join testing_data lne on 
            lne.product = c.product
        and lne.date_of_check between c.last_non_empty_date and c.date_of_check
        and lne.stock_amount is not null
    group by c.product, c.date_of_check
)
select
  testing_data.id
, testing_data.product
, testing_data.stock_amount
, sm.stock_amount as stock_amount_filled_out
, testing_data.date_of_check
from testing_data 
join lne_id on 
        testing_data.product=lne_id.product 
    and testing_data.date_of_check=lne_id.date_of_check
join testing_data sm on lne_id.last_non_empty_id=sm.id
order by testing_data.product, testing_data.date_of_check, testing_data.id;