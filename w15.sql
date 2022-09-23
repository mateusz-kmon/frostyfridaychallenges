-- https://frostyfriday.org/2022/09/23/week-15-intermediate/

create or replace function udf_bin (price number(11, 2), buckets array)
returns number as 
$$
    select max(f.index)+1
    from table(flatten(buckets)) f
    where price>=f.value
      and array_size(buckets) between 2 and 6
$$;


select 
  sale_date
, price
, udf_bin(price, [1,310000,400000,500000]) as bucket_set1
, udf_bin(price, [210000,350000]) as bucket_set2
, udf_bin(price, [250000,290001,320000,360000,410000,470001]) as bucket_set3
from home_sales
order by 1;