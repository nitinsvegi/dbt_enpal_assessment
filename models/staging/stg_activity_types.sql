{{ 
    config(
        unique_key='activity_type_id',
        materialized='incremental',
        on_schema_change='sync_all_columns',
        tags= ['staging', 'activity_types']
    )
}}

WITH raw AS (
    -- Pull the raw data from Postgres source
    SELECT *
    FROM {{ source('postgres_public', 'activity_types') }}
),
cleaned AS (
    SELECT
        id AS activity_type_id
        , name AS activity_type_name -- Each activity type defines the category of an activity
        , active AS is_activity_type_active
        , type AS activity_type_short
        , CURRENT_TIMESTAMP AS dwh_creation_timestamp
        , CURRENT_TIMESTAMP AS dwh_modified_timestamp
    FROM raw
    WHERE TRUE
        AND id IS NOT NULL
)

SELECT *
FROM cleaned

{% if is_incremental() %}
    WHERE activity_type_id NOT IN (SELECT activity_type_id FROM {{ this }})
{% endif %}