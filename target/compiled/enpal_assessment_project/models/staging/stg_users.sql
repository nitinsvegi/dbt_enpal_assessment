

WITH raw AS (
SELECT *
FROM "postgres"."public"."users"
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

