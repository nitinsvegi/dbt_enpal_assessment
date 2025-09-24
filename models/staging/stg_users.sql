{{ 
    config(
        unique_key='id',
        materialized='incremental',
        on_schema_change='sync_all_columns'
    )
}}

WITH raw AS (
SELECT *
FROM {{ source('postgres_public', 'users') }}
),
cleaned AS (
SELECT
    id as user_id
    , name AS user_name
    , email AS user_email
    , CURRENT_TIMESTAMP AS dwh_creation_timestamp
    , modified AS dwh_modified_timestamp
FROM raw
WHERE TRUE
    AND id is not null
)

SELECT *
FROM cleaned

{% if is_incremental() %}
    -- Only include new or updated rows
    WHERE id NOT IN (SELECT id FROM {{ this }})
{% endif %}

