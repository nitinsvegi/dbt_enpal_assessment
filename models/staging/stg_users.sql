{{ 
    config(
        unique_key='user_id',
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns',
        tags= ['staging', 'users']
    )
}}

WITH raw AS (
    -- Pull the raw data from Postgres source
    SELECT *
    FROM {{ source('postgres_public', 'users') }}
),

cleaned AS (
    
    SELECT
        id as user_id
        , name AS user_name
        , NULLIF(BTRIM(email), '') AS user_email
        , CURRENT_TIMESTAMP AS dwh_creation_timestamp -- warehouse load timestamp
        , modified::timestamp AS dwh_modified_timestamp
    FROM raw
    WHERE TRUE
        AND id is not null -- filter out any incomplete records
)

SELECT *
FROM cleaned
{% if is_incremental() %}
WHERE dwh_modified_timestamp >= (
    SELECT COALESCE(MAX(dwh_modified_timestamp), '1900-01-01'::timestamp)
    FROM {{ this }}
)
{% endif %}