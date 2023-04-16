-- https://frostyfriday.org/2023/04/14/week-41-basic/

create or replace procedure statement_creator()
    returns Table()
    language python
    runtime_version = 3.8
    packages =('snowflake-snowpark-python')
    handler = 'main'
    as '
# The Snowpark package is required for Python Worksheets.
# You can add more packages by selecting them using the Packages control and then importing them.

import snowflake.snowpark as snowpark
from itertools import zip_longest

def main(session: snowpark.Session): 
    # Your code goes here, inside the "main" handler.
    data_str = """
We Love Frosty Friday
Python Worksheets Are Very Cool
"""
    lt_of_rows = [x.split() for x in data_str.split("\\n")[1:-1]]
    lt_of_data = list(zip_longest(*lt_of_rows))

    dataframe = session.create_dataframe(
        data = lt_of_data,
        schema = ["STATEMENT1", "STATEMENT2"]
    )

    # Return value will appear in the Results tab.
    return dataframe
';


call statement_creator()