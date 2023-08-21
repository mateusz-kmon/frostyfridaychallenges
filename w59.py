# https://frostyfriday.org/2023/08/18/week-59-intermediate/
# http://s3.eu-west-1.amazonaws.com/frostyfridaychallenges/challenge_59/age_and_income.csv
# https://docs.snowflake.com/en/developer-guide/snowpark-ml/index
# https://docs.snowflake.com/en/developer-guide/snowpark-ml/snowpark-ml-modeling#snowpark-ml-modeling-classes


# %%
from snowflake.snowpark import Session
from snowflake.snowpark.version import VERSION
from snowflake.ml.modeling.tree import DecisionTreeClassifier
import json


# %%
connection_parameters = json.load(open('credentials/connection.json'))
session = Session.builder.configs(connection_parameters).create()
session.sql_simplifier_enabled = True

# %%
# test connection
snowflake_environment = session.sql('SELECT current_user(), current_version()').collect()
snowpark_version = VERSION

# Current Environment Details
print('\nConnection Established with the following parameters:')
print('User                        : {}'.format(snowflake_environment[0][0]))
print('Role                        : {}'.format(session.get_current_role()))
print('Database                    : {}'.format(session.get_current_database()))
print('Schema                      : {}'.format(session.get_current_schema()))
print('Warehouse                   : {}'.format(session.get_current_warehouse()))
print('Snowflake version           : {}'.format(snowflake_environment[0][1]))
print('Snowpark for Python version : {}.{}.{}'.format(snowpark_version[0],snowpark_version[1],snowpark_version[2]))




# %%
# prepare data
session.sql("""
   create or replace stage ff_w59 
    url = 's3://frostyfridaychallenges/challenge_59/'
""").collect()

session.sql("""
    create or replace file format fmt_csv_prod
    type = csv
    parse_header = true
""").collect()

session.sql("""
    create or replace table week59
    using template (
        select array_agg(object_construct(*))
        from table(
            infer_schema(
                location => '@ff_w59/age_and_income.csv'
            , file_format => 'fmt_csv_prod'
            , ignore_case => true
            )
        )
    )
""").collect()

session.sql("""
    copy into week59
    from @ff_w59/age_and_income.csv
    file_format = (format_name = 'fmt_csv_prod')
    match_by_column_name = case_insensitive
""").collect()





# %%
#Load table
week59 = session.table('week59').to_pandas()


# %%
# Initialize the DecisionTreeClassifier with column names
model = DecisionTreeClassifier()
model.set_input_cols(['AGE','MONTHLY_INCOME'])
model.set_label_cols(['MADE_PURCHASE'])
model.set_sample_weight_col(['SAMPLE_WEIGHT'])
model.set_output_cols(['PREDICTED_PURCHASE'])



# %%
# Fit the model to the data
model.fit(week59)


# %%
# Make predictions
prediction_results = model.predict(week59)


# %%
# Display the predictions
print(prediction_results[['PREDICTED_PURCHASE']])


# %%
session.close()
# %%
