{{ 
    config(
        unique_key='user_id',
        materialized='incremental',
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
        , email AS user_email
        , CURRENT_TIMESTAMP AS dwh_creation_timestamp -- warehouse load timestamp
        , modified AS dwh_modified_timestamp
    FROM raw
    WHERE TRUE
        AND id is not null -- filter out any incomplete records
)

SELECT *
FROM cleaned

{% if is_incremental() %}
      -- Only insert rows that don’t already exist in the target table
    WHERE user_id NOT IN (SELECT user_id FROM {{ this }})
{% endif %}

