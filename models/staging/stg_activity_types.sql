{{ 
    config(
        unique_key='activity_type_id',
        materialized='view',
        tags= ['staging', 'activity_types']
    )
}}

WITH raw AS (
    
    SELECT *
    FROM {{ source('postgres_public', 'activity_types') }}
),

cleaned AS (

    SELECT
        id AS activity_type_id
        , name AS activity_type_name -- Each activity type defines the category of an activity
        , type AS activity_type_short
        , active AS is_activity_type_active
    FROM raw
    WHERE TRUE
        AND id IS NOT NULL
)

SELECT *
FROM cleaned