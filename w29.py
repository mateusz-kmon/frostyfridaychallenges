# https://frostyfriday.org/2023/01/20/week-30-intermediate/


# %%
import os
from snowflake.snowpark import Session
from snowflake.snowpark.functions import col, udf
from snowflake.snowpark.types import IntegerType, TimestampType


connection_parameters = {
"account": os.environ["snowflake_account"],
"user": os.environ["snowflake_user"],
"password": os.environ["snowflake_password"],
"role": os.environ["snowflake_user_role"],
"warehouse": os.environ["snowflake_warehouse"],
"database": os.environ["snowflake_database"],
"schema": os.environ["snowflake_schema"]
}

session = Session.builder.configs(connection_parameters).create()
fiscal_year = udf(lambda x: x.year if x.month<5 else x.year+1, return_type=IntegerType(), input_types=[TimestampType()])


# %%
data = session.table("week29").select(
    col("id"),
    col("first_name"),
    col("surname"),
    col("email"),
    col("start_date"),
    fiscal_year("start_date").alias("fiscal_year")
)

data.show()


# %%
data.group_by("fiscal_year").agg(col("*"), "count").show()


# %%
session.close()