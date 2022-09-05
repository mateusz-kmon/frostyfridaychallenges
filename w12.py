import streamlit as st
import snowflake.connector
import os
import pathlib


ctx = snowflake.connector.connect(**st.secrets["snowflake"])
cs = ctx.cursor()


@st.cache
def load_schemes():
    """
    Loads all schemes form a database starting by world (case insensitive).
    """
    sql = """select schema_name from information_schema.schemata where schema_name ilike 'world%' order by 1"""
    results = cs.execute(sql).fetchall()
    out = [t[0] for t in results]
    return out


@st.cache
def load_tables_in_schema(schema_name: str):
    """
    Loades all tables from a given schema.
    """
    sql = f"""select table_name from information_schema.tables where table_schema='{schema_name}' order by 1;"""
    results = cs.execute(sql).fetchall()
    out = [t[0] for t in results]
    return out


def upload_file(schema: str, table: str, uploaded_file):
    """
    Temporarily saves the uploaded_file locally to pass it to a Snowfalke table stage.
    Then copies the file from the stage to the table.
    """
    path_to_uploaded_file = os.path.join(pathlib.Path(__file__).parent, uploaded_file.name)
    with open(path_to_uploaded_file, "wb") as f:
        f.write(uploaded_file.getbuffer())

    sql = f"put file://{path_to_uploaded_file} @{schema}.%{table} overwrite=true"
    cs.execute(sql)
    os.remove(path_to_uploaded_file)

    sql = f"copy into {schema}.{table} file_format = (skip_header=1, field_optionally_enclosed_by='\"') purge = true"
    try:
        results = cs.execute(sql).fetchone()
        if (results[5]>=results[4]):
            raise Exception(f"Copy into errors_seen: {results[5]} is greater or equal to allowable error_limit: {results[4]}")
        return f"Your upload was a success. You uploaded {results[3]} rows."
    except snowflake.connector.errors.ProgrammingError as e:
        sql = f"rm @{schema}.%{table}"
        cs.execute(sql).fetchone()
        raise(e)


def app_creation():
    """
    This is the app entry point.
    """
    st.title("Manual CSV to Snowflake Table Uploader")
    with st.sidebar:
        st.image('http://frostyfridaychallenges.s3.amazonaws.com/challenge_12/logo.png')
        st.write("Instructions:")
        st.write("- Select the schema from the available")
        st.write("- Then select the table which will automatically update to reflect your schema choice.")
        st.write("- Check that the table corresponds to that which you want to ingest into.")
        st.write("- Select the file you want to ingest.")
        st.write("- You should see an upload success message detailing how many rows were ingested.")

    schema = st.radio("Select schema:", load_schemes())
    table = st.radio("Select table to upload to:", load_tables_in_schema(schema))
    uploaded_file = st.file_uploader(label=f"Select file to ingest into {schema}.{table}", type="csv", accept_multiple_files=False)
    if uploaded_file is not None:
        try:
            st.write(upload_file(schema, table, uploaded_file))
        except Exception as e:
            st.error(e)
    else:
        st.write("Awaiting file to upload...")


app_creation()
