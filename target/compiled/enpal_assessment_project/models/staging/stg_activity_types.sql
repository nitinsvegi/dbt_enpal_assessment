

WITH raw AS (
    -- Pull the raw data from Postgres source
    SELECT *
    FROM "postgres"."public"."activity_types"
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


    WHERE activity_type_id NOT IN (SELECT activity_type_id FROM "postgres"."pipedrive_analytics"."stg_activity_types")
