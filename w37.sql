-- https://frostyfriday.org/2023/03/10/week-37-intermediate/


create or replace storage integration week37_si
    type = external_stage
    storage_provider = 's3'
    storage_aws_role_arn = 'arn:aws:iam::184545621756:role/week37'
    enabled = true
    storage_allowed_locations = ('s3://frostyfridaychallenges/challenge_37/');


create or replace stage week37_stg
    url='s3://frostyfridaychallenges/challenge_37/'
    storage_integration = week37_si
    directory = (
        enable = true 
        auto_refresh = false
    );


select
  relative_path
, size
, file_url
, build_scoped_file_url(@week37_stg, relative_path) as scoped_file_url
, build_stage_file_url(@week37_stg, relative_path) as stage_file_url
, get_presigned_url(@week37_stg, relative_path) as presigned_url
from directory(@week37_stg);
