import streamlit as st
from snowflake.snowpark.session import Session
from snowflake.snowpark import __version__ as snowpark_version
import pandas as pd
import os
import pathlib
from dotenv import load_dotenv

# Create Session object
def create_session_object():
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
    return session


def load_data(session, what):
    in_on = "on" if what=="Grants" else "in"
    snow_df = session.sql(f"show {what} {in_on} ACCOUNT")
    pd_df = pd.DataFrame(data=snow_df.collect())
    return pd_df


def app_creation():
    """
    This is the app entry point.
    """

    st.set_page_config(
        page_title="Snowflake Account Info App",
        layout="wide",
        initial_sidebar_state="expanded",
    )

    st.header("Snowflake Account Info App")
    st.write("Use this app to quickly see high-level info about your Snowflake account.")

    load_dotenv()
    path_to_files = os.path.join(pathlib.Path(__file__).parent.resolve(), "files")
    path_to_logo = pathlib.Path(os.path.join(path_to_files, "ff_logo_trans.png")).as_posix().replace(pathlib.Path(os.getcwd()).as_posix(), ".")

    with st.sidebar:
        st.image(path_to_logo)
        options = ['None','Shares','Roles','Grants','Users','Warehouses','Databases','Schemas','Tables','Views']
        acc_info = st.selectbox("Select what account info you would like to see", options)

        footer_txt = f"App created using Snowpark version {snowpark_version}"
        footer=f"""<style>
.footer {{
position: fixed;
left: 1%;
bottom: 0;
width: 100%;
color: black;
text-align: left;
opacity: 0.5;
}}
</style>
<div class="footer">
<p>{footer_txt}</p>
</div>
"""
        st.markdown(footer,unsafe_allow_html=True)

    session = create_session_object()
    if acc_info != 'None':
        try:
            df = load_data(session, acc_info)
            st.dataframe(df, use_container_width=True)
        except Exception as e:
            st.error(e)



if __name__ == "__main__":
    app_creation()
