# %%
from snowflake.snowpark.session import Session
from snowflake.snowpark.types import IntegerType, FloatType
from snowflake.snowpark.functions import col, year
from sklearn.linear_model import LinearRegression


# %%
# Session
connection_parameters = {
   "account": "<account_identifier>",
   "user": "<username>",
   "password": "<password>",
   "warehouse": "compute_wh",
   "role": "accountadmin",
   "database": "frosty_friday",
   "schema": "public"
}
session = Session.builder.configs(connection_parameters).create()

# test if we have a connection
session.sql("select current_warehouse() wh, current_database() db, current_schema() schema, current_version() v").show()


# %%
session.sql("CREATE STAGE IF NOT EXISTS udf_stage;").show()


# %%
session.sql('''
SELECT "Date", "Value"
FROM ECONOMY_DATA_ATLAS.ECONOMY.BEANIPA
WHERE "Table Name" = 'Price Indexes For Personal Consumption Expenditures By Major Type Of Product'
AND "Indicator Name" = 'Personal consumption expenditures (PCE)'
AND "Frequency" = 'A'
ORDER BY "Date"
''').show()


# %%
# Let Snowflake perform filtering using the Snowpark pushdown and display results in a Pandas dataframe
snow_df_pce = (session.table("ECONOMY_DATA_ATLAS.ECONOMY.BEANIPA")
    .filter(col('"Table Name"') == 'Price Indexes For Personal Consumption Expenditures By Major Type Of Product')
    .filter(col('"Indicator Name"') == 'Personal consumption expenditures (PCE)')
    .filter(col('"Frequency"') == 'A')
    .filter(col('"Date"') >= '1972-01-01')
    .filter(col('"Date"') <= '2020-01-01')
)
pd_df_pce_year = snow_df_pce.select(year(col('"Date"')).alias('"Year"'), col('"Value"').alias('PCE') ).to_pandas()
pd_df_pce_year



# %%
# train model with PCE index
x = pd_df_pce_year["Year"].to_numpy().reshape(-1,1)
y = pd_df_pce_year["PCE"].to_numpy()
model = LinearRegression().fit(x, y)

# test model for 2021
predictYear = 2021
pce_pred = model.predict([[predictYear]])

# run the prediction for 2021
print ('Prediction for '+str(predictYear)+': '+ str(round(pce_pred[0],2)))


# %%
def predict_pce(predictYear: int) -> float:
    return model.predict([[predictYear]])[0].round(2).astype(float)

_ = session.udf.register(
    predict_pce,
    return_type=FloatType(),
    input_type=IntegerType(),
    packages= ["pandas","scikit-learn"],
    is_permanent=True, 
    name="predict_pce_udf", 
    replace=True,
    stage_location="@udf_stage"
)

# %%
session.sql("select predict_pce_udf(2021)").show()
# 116.22

# %%
session.sql("select predict_pce_udf(2024)").show()
# 121.7