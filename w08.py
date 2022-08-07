# https://frostyfriday.org/2022/08/05/week-8-basic/


import streamlit as st
import pandas as pd
import snowflake.connector


# Normally, a secrets file should be saved in C:\Users\<your_user>\.streamlit
# as secrets.toml
ctx = snowflake.connector.connect(**st.secrets["snowflake"])
cs = ctx.cursor()


# WARNING - When aggregating columns in this query, keep the column names the same.
query = """
select date_trunc(week,$2::timestamp) as payment_date, sum($4::float) as amount_spent
from @frostyfridaychallenges/challenge_8/payments.csv
where $1 is not null
group by 1
"""

@st.cache # This keeps a cache in place so the query isn't constantly re-run.
def load_data():
    """
    In Python, def() creates a function. This particular function connects to your Snowflake
    account and executes the query above. If you have no Python experience, I recommend leaving
    this alone.
    """
    cur = ctx.cursor().execute(query)
    payments_df = pd.DataFrame.from_records(iter(cur), columns=[x[0] for x in cur.description])
    payments_df['PAYMENT_DATE'] = pd.to_datetime(payments_df['PAYMENT_DATE'])
    payments_df = payments_df.set_index('PAYMENT_DATE')
    return payments_df


payments_df = load_data() # This creates what we call a 'dataframe' called payments_df, think of this as
                            # a table. To create the table, we use the above function. So, basically,
                            # every time your write 'payments_df' in your code, you're referencing
                            # the result of your query.


def get_min_date():
    """
    This function returns the earliest date present in the dataset.
    When you want to use this value, just write get_min_date().
    """
    return min(payments_df.index.to_list()).date()

def get_max_date():
    """
    This function returns the latest date present in the dataset.
    When you want to use this value, just write get_max_date().
    """
    return max(payments_df.index.to_list()).date()


def app_creation():
    """
    This function is the one your need to edit. 
    """
    min_date = get_min_date()
    max_date = get_max_date()
    st.header(f"Payments in {max_date.year}")
    min_filter = st.slider("Select min date", min_value=min_date, max_value=max_date, value=min_date)
    max_filter = st.slider("Select max date", min_value=min_date, max_value=max_date, value=max_date)
    mask = (payments_df.index >= pd.to_datetime(min_filter)) \
             & (payments_df.index <= pd.to_datetime(max_filter))
    payments_df_filtered = payments_df.loc[mask] #This line creates a new dataframe (table) that filters
                                                    # your results to between the range of your min
                                                    # slider, and your max slider.
    # Create a line chart using the new payments_df_filtered dataframe. 
    st.line_chart(payments_df_filtered)


app_creation() # The function above is now invoked.