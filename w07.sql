--https://frostyfriday.org/2022/07/29/week-7-intermediate/


select tr.tag_name, tr.tag_value, min(ah.query_id), concat_ws('.',tr.object_database, tr.object_schema, tr.object_name) as table_name, qh.role_name
from snowflake.account_usage.query_history qh
join snowflake.account_usage.access_history ah on qh.query_id=ah.query_id
, lateral flatten(input=>ah.direct_objects_accessed) oa
join snowflake.account_usage.tag_references tr
    on concat_ws('.',tr.object_database, tr.object_schema, tr.object_name) = oa.value:objectName::varchar
where tr.tag_name='SECURITY_CLASS' and tr.tag_value='Level Super Secret A+++++++'
group by 1,2,4,5;